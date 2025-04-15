import 'package:floaty/backend/definitions.dart';
import 'package:flutter/material.dart';
import 'package:floaty/backend/fpapi.dart';
import 'package:floaty/frontend/elements.dart';
import 'package:floaty/frontend/root.dart';
import 'package:intl/intl.dart';

class DateSection {
  final String header;
  final List<BlogPostCard> posts;

  DateSection(this.header, this.posts);
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  List<DateSection> _sections = [];
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;
  int _offset = 0;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      rootLayoutKey.currentState?.setAppBar(const Text('History'));
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    final viewportHeight = _scrollController.position.viewportDimension;

    // Load more when we're 1 viewport height from the bottom
    if (currentScroll >= (maxScroll - viewportHeight) &&
        !_isLoading &&
        _hasMore) {
      _loadHistory();
    }
  }

  String _getDateHeader(DateTime date) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfDate = DateTime(date.year, date.month, date.day);
    final difference = startOfToday.difference(startOfDate).inDays;

    if (difference == 0) {
      return 'Today';
    }

    if (difference == 1) {
      return 'Yesterday';
    }

    // Always use full date format for 7 days or more
    if (difference >= 7) {
      return DateFormat.yMMMMd().format(date);
    }

    // Use day name for less than 7 days
    return DateFormat.EEEE().format(date);
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  DateTime _getDateFromHeader(String header) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    switch (header) {
      case 'Today':
        return startOfToday;
      case 'Yesterday':
        return startOfToday.subtract(const Duration(days: 1));
      default:
        // Try to parse as day name first
        final weekdays = {
          'Monday': 1,
          'Tuesday': 2,
          'Wednesday': 3,
          'Thursday': 4,
          'Friday': 5,
          'Saturday': 6,
          'Sunday': 7,
        };

        if (weekdays.containsKey(header)) {
          // Find the most recent occurrence of this weekday that's less than 7 days ago
          var date = startOfToday;
          while (true) {
            date = date.subtract(const Duration(days: 1));
            if (DateFormat.EEEE().format(date) == header) {
              // Only use weekday name if it's less than 7 days ago
              final diff = startOfToday.difference(date).inDays;
              if (diff < 7) {
                return date;
              }
              break;
            }
          }
        }

        // Parse as full date if not a recent weekday
        return DateFormat.yMMMMd().parse(header);
    }
  }

  Future<void> _loadHistory([bool refresh = false]) async {
    if (_isLoading || (!_hasMore && !refresh)) return;

    final savedScrollPosition = _scrollController.hasClients
        ? _scrollController.offset.toDouble()
        : 0.0;

    setState(() {
      _isLoading = true;
      if (refresh) {
        _error = null;
        _sections = [];
        _offset = 0;
        _hasMore = true;
      }
    });

    try {
      final items = await fpApiRequests.getHistory(offset: _offset);
      final newSections = _processHistoryItems(items);

      if (!mounted) return;

      setState(() {
        if (refresh) {
          _sections = newSections;
        } else {
          _mergeSections(newSections);
          // Restore scroll position after merging sections
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients && !refresh) {
              _scrollController.jumpTo(savedScrollPosition);
            }
          });
        }
        _hasMore = items.isNotEmpty; // Continue loading if we got any items
        _offset += items.length;
        _isLoading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString();
        _isLoading = false;
        if (refresh) {
          _sections = [];
        }
      });
    }
  }

  void _mergeSections(List<DateSection> newSections) {
    // Create a map of existing sections for faster lookup
    final existingSections = Map.fromEntries(
      _sections.map((s) => MapEntry(_getDateFromHeader(s.header), s)),
    );

    for (var newSection in newSections) {
      final date = _getDateFromHeader(newSection.header);
      if (existingSections.containsKey(date)) {
        // Merge with existing section
        existingSections[date]!.posts.addAll(newSection.posts);
      } else {
        // Add new section
        _sections.add(newSection);
      }
    }

    // Re-sort sections after merging
    _sections.sort((a, b) {
      final dateA = _getDateFromHeader(a.header);
      final dateB = _getDateFromHeader(b.header);
      return dateB.compareTo(dateA); // Most recent first
    });
  }

  List<DateSection> _processHistoryItems(List<HistoryModelV3> items) {
    Map<String, List<BlogPostCard>> dateGroups = {};
    DateTime? currentDate;

    for (var item in items) {
      final watchedDate = item.updatedAt ?? DateTime.now();

      if (currentDate == null || !_isSameDay(currentDate, watchedDate)) {
        currentDate = watchedDate;
      }

      final headerText = _getDateHeader(watchedDate);
      dateGroups.putIfAbsent(headerText, () => []);
      dateGroups[headerText]!.add(
        BlogPostCard(
          item.blogPost,
          response: GetProgressResponse(
            id: item.contentId,
            progress: item.progress,
          ),
          key: Key(item.blogPost.id ?? ''),
        ),
      );
    }

    return dateGroups.entries.map((e) => DateSection(e.key, e.value)).toList()
      ..sort((a, b) {
        final dateA = _getDateFromHeader(a.header);
        final dateB = _getDateFromHeader(b.header);
        return dateB.compareTo(dateA); // Most recent first
      });
  }

  @override
  Widget build(BuildContext context) {
    if (_sections.isEmpty && _isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null && _sections.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => _loadHistory(true),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_sections.isEmpty && !_isLoading) {
      return const Scaffold(
        body: Center(
          child: Text(
            'No history found.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => _loadHistory(true),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = 280.0;
            final spacing = 12.0;
            final horizontalPadding = 16.0;
            final availableWidth =
                constraints.maxWidth - (horizontalPadding * 2);
            final columns = (availableWidth / (itemWidth + spacing)).floor();
            final actualWidth =
                (availableWidth - (spacing * (columns - 1))) / columns;

            return ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              itemCount: _sections.length + (_hasMore || _isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _sections.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  );
                }

                final section = _sections[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (index > 0) const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16, left: 4),
                      child: Text(
                        section.header,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: section.posts.map((post) {
                        return SizedBox(
                          width: actualWidth,
                          child: post,
                        );
                      }).toList(),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
