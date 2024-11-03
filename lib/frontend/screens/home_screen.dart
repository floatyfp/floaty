import 'package:floaty/backend/definitions.dart';
import 'package:flutter/material.dart';
import 'package:floaty/backend/fpapi.dart';
import 'package:floaty/frontend/elements.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:floaty/frontend/root.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
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
    rootLayoutKey.currentState?.setAppBarTitle('Home');
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      creatorIds = await FPApiRequests().getSubscribedCreatorsIds();

      ContentCreatorListV3Response? home;
      if (lastElements.isNotEmpty) {
        home = await FPApiRequests()
            .getHomeFeed(creatorIds, _pageSize, lastElements);
      } else {
        home = await FPApiRequests().getHomeFeed(creatorIds, _pageSize);
      }

      newposts = home.blogPosts ?? [];
      lastElements = home.lastElements ?? [];

      isLastPage =
          !lastElements.any((element) => element.moreFetchable ?? false);

      // Fetch video progress for the new blog posts
      List<String> blogPostIds = newposts
          .map((post) => post.id)
          .where((id) => id != null)
          .cast<String>()
          .toList();
      List<GetProgressResponse> progressResponses =
          await FPApiRequests().getVideoProgress(blogPostIds);

      // Create a mapping of blog post ID to progress response
      Map<String, GetProgressResponse?> progressMap = {
        for (var progress in progressResponses) progress.id!: progress
      };

      // Append the fetched blog posts to the paging controller with their progress
      _pagingController.appendPage(
        newposts.map((post) {
          return BlogPostCard(post, response: progressMap[post.id]);
        }).toList(),
        isLastPage ? null : pageKey + 1,
      );
    } catch (error) {
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
        padding: const EdgeInsets.all(0),
        child: PagedGridView<int, BlogPostCard>(
          pagingController: _pagingController,
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 300,
            crossAxisSpacing: 0,
            mainAxisSpacing: 0,
            childAspectRatio: 1.14,
          ),
          builderDelegate: PagedChildBuilderDelegate<BlogPostCard>(
            animateTransitions: true,
            itemBuilder: (context, item, index) {
              return BlogPostCard(item.blogPost, response: item.response);
            },
            noItemsFoundIndicatorBuilder: (context) => Center(
              child: Text("No items found."),
            ),
          ),
        ),
      ),
    );
  }
}
