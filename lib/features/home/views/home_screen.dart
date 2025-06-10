import 'package:floaty/features/api/models/definitions.dart';
import 'package:floaty/features/post/components/blog_post_card.dart';
import 'package:flutter/material.dart';
import 'package:floaty/features/api/repositories/fpapi.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:floaty/features/router/views/root_layout.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _pageSize = 20;
  late final PagingController<int, BlogPostCard> _pagingController;
  List<String> creatorIds = [];
  List<ContentCreatorListLastItems> lastElements = [];

  @override
  void initState() {
    super.initState();
    _pagingController = PagingController<int, BlogPostCard>(
      getNextPageKey: (state) => (state.keys?.last ?? 0) + 1,
      fetchPage: _fetchPage,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setAppTitle();
    });
  }

  void setAppTitle() {
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

  Future<List<BlogPostCard>> _fetchPage(int pageKey) async {
    if (!mounted) return [];
    try {
      creatorIds = await _getCreatorIds();
      if (!mounted || creatorIds.isEmpty) return [];

      ContentCreatorListV3Response? home;
      if (lastElements.isNotEmpty) {
        home = await fpApiRequests.getMultiCreatorVideoFeed(
            creatorIds, _pageSize,
            lastElements: lastElements);
      } else {
        home =
            await fpApiRequests.getMultiCreatorVideoFeed(creatorIds, _pageSize);
      }

      if (!mounted) return [];

      final newPosts = home.blogPosts ?? [];
      lastElements = home.lastElements ?? [];

      List<String> blogPostIds = newPosts
          .map((post) => post.id)
          .where((id) => id != null)
          .cast<String>()
          .toList();
      List<GetProgressResponse> progressResponses =
          await fpApiRequests.getVideoProgress(blogPostIds);

      if (!mounted) return [];

      Map<String, GetProgressResponse?> progressMap = {
        for (var progress in progressResponses) progress.id!: progress
      };

      return newPosts.map((post) {
        return BlogPostCard(post, response: progressMap[post.id]);
      }).toList();
    } catch (error) {
      return [];
    }
  }

  @override
  void dispose() {
    if (mounted) {
      _pagingController.dispose();
    }
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
            return PagingListener<int, BlogPostCard>(
              controller: _pagingController,
              builder: (context, state, fetchNextPage) {
                return useList
                    ? PagedListView<int, BlogPostCard>(
                        state: state,
                        fetchNextPage: fetchNextPage,
                        builderDelegate:
                            PagedChildBuilderDelegate<BlogPostCard>(
                          invisibleItemsThreshold: 6,
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
                          noItemsFoundIndicatorBuilder: (context) =>
                              const Center(
                            child: Text("No items found."),
                          ),
                        ),
                      )
                    : PagedGridView<int, BlogPostCard>(
                        state: state,
                        fetchNextPage: fetchNextPage,
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 300,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                          childAspectRatio: 1.175,
                        ),
                        builderDelegate:
                            PagedChildBuilderDelegate<BlogPostCard>(
                          invisibleItemsThreshold: 12,
                          animateTransitions: true,
                          itemBuilder: (context, item, index) => Padding(
                            padding: const EdgeInsets.all(4),
                            child: BlogPostCard(item.blogPost,
                                response: item.response,
                                key: Key(item.blogPost.id ?? '')),
                          ),
                          noItemsFoundIndicatorBuilder: (context) =>
                              const Center(
                            child: Text("No items found."),
                          ),
                        ),
                      );
              },
            );
          }),
        ),
      ),
    );
  }
}
