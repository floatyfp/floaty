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

  Future<List<String>> _getCreatorIds() {
    if (!mounted) return Future.value([]);
    
    Completer<List<String>> completer = Completer();

    FPApiRequests().getSubscribedCreatorsIds().listen((ids) {
      if (!mounted) {
        if (!completer.isCompleted) {
          completer.complete([]);
        }
        return;
      }
      setState(() {
        creatorIds = ids;
      });
      if (!completer.isCompleted) {
        completer.complete(ids);
      }
    }, onError: (error) {
      if (!completer.isCompleted) {
        completer.completeError(error);
      }
    });

    return completer.future;
  }

  Future<void> _fetchPage(int pageKey) async {
    if (!mounted) return;
    
    try {
      creatorIds = await _getCreatorIds();
      if (!mounted) return;

      ContentCreatorListV3Response? home;
      if (lastElements.isNotEmpty) {
        home = await FPApiRequests().getMultiCreatorVideoFeed(
            creatorIds, _pageSize,
            lastElements: lastElements);
      } else {
        home = await FPApiRequests()
            .getMultiCreatorVideoFeed(creatorIds, _pageSize);
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
          await FPApiRequests().getVideoProgress(blogPostIds);

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
      body: Padding(
        padding: const EdgeInsets.only(left: 4, right: 4),
        child: LayoutBuilder(builder: (context, constraints) {
          return PagedGridView<int, BlogPostCard>(
            pagingController: _pagingController,
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent:
                  constraints.maxWidth <= 450 ? constraints.maxWidth : 300,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
              childAspectRatio: constraints.maxWidth <= 450 ? 1.2 : 1.175,
            ),
            builderDelegate: PagedChildBuilderDelegate<BlogPostCard>(
              animateTransitions: true,
              itemBuilder: (context, item, index) {
                return Padding(
                    padding:
                        EdgeInsets.all(constraints.maxWidth <= 450 ? 4 : 2),
                    child:
                        BlogPostCard(item.blogPost, response: item.response));
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
