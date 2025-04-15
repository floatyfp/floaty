import 'package:floaty/backend/definitions.dart';
import 'package:flutter/material.dart';
import 'package:floaty/backend/fpapi.dart';
import 'package:floaty/frontend/elements.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:floaty/frontend/root.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _pageSize = 20;
  final PagingController<int, BlogPostCard> _pagingController =
      PagingController<int, BlogPostCard>(firstPageKey: 0);
  List<String> creatorIds = [];
  List<ContentCreatorListLastItems> lastElements = [];
  List<BlogPostModelV3> newposts = [];
  bool isLastPage = false;
  bool firstPage = true;
  int pageloadint = 0;

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
    rootLayoutKey.currentState?.setAppBar(const Text('Home'));
  }

  Future<List<String>> _getCreatorIds() async {
    if (!mounted) return [];
    if (creatorIds.isNotEmpty) return creatorIds;
    try {
      creatorIds = await fpApiRequests.getSubscribedCreatorsIds().first;
    } catch (error) {
      creatorIds = [];
    }
    return creatorIds;
  }

  Future<void> _fetchPage(int pageKey) async {
    if (!mounted) return;
    try {
      creatorIds = await _getCreatorIds();
      if (!mounted) return;
      if (creatorIds.isEmpty) {
        if (!mounted) return;
        newposts = [];
        isLastPage = true;
        return;
      }

      ContentCreatorListV3Response? home;
      if (lastElements.isNotEmpty) {
        home = await fpApiRequests.getMultiCreatorVideoFeed(
            creatorIds, _pageSize,
            lastElements: lastElements);
      } else {
        home =
            await fpApiRequests.getMultiCreatorVideoFeed(creatorIds, _pageSize);
      }

      if (!mounted) return;

      newposts = home.blogPosts ?? [];
      lastElements = home.lastElements ?? [];
      isLastPage =
          !lastElements.any((element) => element.moreFetchable ?? false);

      List<String> blogPostIds = newposts
          .map((post) => post.id)
          .where((id) => id != null)
          .cast<String>()
          .toList();
      List<GetProgressResponse> progressResponses =
          await fpApiRequests.getVideoProgress(blogPostIds);

      if (!mounted) return;

      Map<String, GetProgressResponse?> progressMap = {
        for (var progress in progressResponses) progress.id!: progress
      };

      _pagingController.appendPage(
        newposts.map((post) {
          return BlogPostCard(post, response: progressMap[post.id]);
        }).toList(),
        isLastPage ? null : pageKey + 1,
      );
    } catch (error) {
      if (mounted) {
        _pagingController.error = error;
      }
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
      body: RefreshIndicator(
        onRefresh: () async {
          lastElements = [];
          _pagingController.refresh();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: LayoutBuilder(builder: (context, constraints) {
            final useList = constraints.maxWidth <= 450;
            return useList
                ? PagedListView<int, BlogPostCard>(
                    pagingController: _pagingController,
                    builderDelegate: PagedChildBuilderDelegate<BlogPostCard>(
                      animateTransitions: true,
                      itemBuilder: (context, item, index) => Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        child: BlogPostCard(item.blogPost,
                            response: item.response,
                            key: Key(item.blogPost.id ?? '')),
                      ),
                      noItemsFoundIndicatorBuilder: (context) => const Center(
                        child: Text("No items found."),
                      ),
                    ),
                  )
                : PagedGridView<int, BlogPostCard>(
                    pagingController: _pagingController,
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 300,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                      childAspectRatio: 1.175,
                    ),
                    builderDelegate: PagedChildBuilderDelegate<BlogPostCard>(
                      animateTransitions: true,
                      itemBuilder: (context, item, index) => Padding(
                        padding: const EdgeInsets.all(4),
                        child: BlogPostCard(item.blogPost,
                            response: item.response,
                            key: Key(item.blogPost.id ?? '')),
                      ),
                      noItemsFoundIndicatorBuilder: (context) => const Center(
                        child: Text("No items found."),
                      ),
                    ),
                  );
          }),
        ),
      ),
    );
  }
}
