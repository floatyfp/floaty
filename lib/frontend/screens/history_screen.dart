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
      PagingController<int, HistoryListItem>(firstPageKey: 0);
  int offset = 0;
  DateTime? lastDate;

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setAppTitle();
    });
  }

  void setAppTitle() {
    rootLayoutKey.currentState?.setAppBar(const Text('History'));
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final historyResponse = await FPApiRequests().getHistory(offset: offset);
      offset += 20;
      final isLastPage = historyResponse.length < 20;

      List<HistoryListItem> itemsWithHeaders = [];
      for (var historyItem in historyResponse) {
        DateTime watchedDate = historyItem.updatedAt ?? DateTime.now();
        String formattedDate;

        if (lastDate == null || !isSameDay(lastDate!, watchedDate)) {
          final now = DateTime.now();

          if (isSameDay(watchedDate, now)) {
            formattedDate = "Today";
          } else if (isSameDay(
              watchedDate, now.subtract(const Duration(days: 1)))) {
            formattedDate = "Yesterday";
          } else {
            final difference = now.difference(watchedDate).inDays;
            if (difference < 7) {
              formattedDate = DateFormat.EEEE().format(watchedDate);
            } else {
              formattedDate = DateFormat.yMMMMd().format(watchedDate);
            }
          }

          itemsWithHeaders.add(HistoryListItem.header(formattedDate));
          lastDate = watchedDate;
        }

        itemsWithHeaders.add(HistoryListItem.post(
          BlogPostCard(historyItem.blogPost,
              response: GetProgressResponse(
                  id: historyItem.contentId, progress: historyItem.progress)),
        ));
      }

      _pagingController.appendPage(
          itemsWithHeaders, isLastPage ? null : pageKey + 1);
    } catch (error) {
      _pagingController.error = error;
    }
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: PagedGridView<int, HistoryListItem>(
          pagingController: _pagingController,
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 300,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
            childAspectRatio: 1.12,
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
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              } else if (item.post != null) {
                return item.post!;
              }
              return const SizedBox.shrink();
            },
            noItemsFoundIndicatorBuilder: (context) => const Center(
              child: Text("No items found."),
            ),
          ),
        ),
      ),
    );
  }
}
