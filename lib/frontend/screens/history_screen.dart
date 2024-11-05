import 'package:floaty/backend/definitions.dart';
import 'package:flutter/material.dart';
import 'package:floaty/backend/fpapi.dart';
import 'package:floaty/frontend/elements.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:floaty/frontend/root.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final PagingController<int, BlogPostCard> _pagingController =
      PagingController<int, BlogPostCard>(firstPageKey: 0);
  List<String> creatorIds = [];
  int offset = 0;
  List<BlogPostModelV3> newposts = [];
  bool isLastPage = false;

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setapptitle();
    });
  }

  void setapptitle() {
    rootLayoutKey.currentState?.setAppBar(const Text('History'));
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final historyResponse = await FPApiRequests().getHistory(offset: offset);
      print(historyResponse);

      offset = offset + 20;

      final isLastPage = historyResponse.length < 20;

      final newPosts = historyResponse.map((historyItem) {
        return BlogPostCard(
          historyItem.blogPost,
          response: GetProgressResponse(
              id: historyItem.contentId, progress: historyItem.progress),
        );
      }).toList();

      // Append the new page data to the paging controller
      _pagingController.appendPage(newPosts, isLastPage ? null : pageKey + 1);
    } catch (error) {
      print(error);
      _pagingController.error = error;
    }
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
        padding: const EdgeInsets.only(left: 4, right: 4),
        child: PagedGridView<int, BlogPostCard>(
          pagingController: _pagingController,
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 300,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
            childAspectRatio: 1.14,
          ),
          builderDelegate: PagedChildBuilderDelegate<BlogPostCard>(
            animateTransitions: true,
            itemBuilder: (context, item, index) {
              return BlogPostCard(item.blogPost, response: item.response);
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
