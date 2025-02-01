import 'package:floaty/backend/definitions.dart';
import 'package:flutter/material.dart';
import 'package:floaty/backend/fpapi.dart';
import 'package:floaty/frontend/elements.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:floaty/frontend/root.dart';
import 'package:intl/intl.dart';

class HistoryListItem {
  final String? header;
  final BlogPostCard? post;

  HistoryListItem.header(this.header) : post = null;
  HistoryListItem.post(this.post) : header = null;
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final PagingController<int, HistoryListItem> _pagingController =
      PagingController(firstPageKey: 0);

  int _offset = 0;
  static const _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener(_fetchPage);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      rootLayoutKey.currentState?.setAppBar(const Text('History'));
    });
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  List<HistoryListItem> _processHistoryItems(List<HistoryModelV3> items) {
    List<HistoryListItem> processedItems = [];
    DateTime? currentDate;

    for (var item in items) {
      final watchedDate = item.updatedAt ?? DateTime.now();

      if (currentDate == null || !_isSameDay(currentDate, watchedDate)) {
        final headerText = _getDateHeader(watchedDate);
        processedItems.add(HistoryListItem.header(headerText));
        currentDate = watchedDate;
      }

      processedItems.add(
        HistoryListItem.post(
          BlogPostCard(
            item.blogPost,
            response: GetProgressResponse(
              id: item.contentId,
              progress: item.progress,
            ),
          ),
        ),
      );
    }

    return processedItems;
  }

  String _getDateHeader(DateTime date) {
    final now = DateTime.now();

    if (_isSameDay(date, now)) {
      return 'Today';
    }

    if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
      return 'Yesterday';
    }

    final difference = now.difference(date).inDays;
    if (difference < 7) {
      return DateFormat.EEEE().format(date);
    }

    return DateFormat.yMMMMd().format(date);
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  void _fetchPage(int pageKey) async {
    try {
      final items = await FPApiRequests().getHistory(offset: _offset);

      if (!mounted) return;

      final isLastPage = items.length < _pageSize;
      final processedItems = _processHistoryItems(items);

      setState(() {
        _offset += _pageSize;
      });

      _pagingController.appendPage(
          processedItems, isLastPage ? null : pageKey + 1);
    } catch (error) {
      if (mounted) {
        _pagingController.error = 'An error occurred loading history';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: LayoutBuilder(builder: (context, constraints) {
          return PagedGridView<int, HistoryListItem>(
            pagingController: _pagingController,
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent:
                  constraints.maxWidth <= 450 ? constraints.maxWidth : 300,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
              childAspectRatio: constraints.maxWidth <= 450 ? 1.2 : 1.175,
            ),
            builderDelegate: PagedChildBuilderDelegate<HistoryListItem>(
              animateTransitions: true,
              itemBuilder: (context, item, index) {
                if (item.header != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        item.header!,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }

                if (item.post != null) {
                  return item.post ??
                      Padding(
                          padding: EdgeInsets.all(
                              constraints.maxWidth <= 450 ? 4 : 2),
                          child: item.post);
                } else {
                  return const SizedBox.shrink();
                }
              },
              noItemsFoundIndicatorBuilder: (context) => const Center(
                child: Text("No items found."),
              ),
            ),
          );
        }),
      ),
    );
  }
}
