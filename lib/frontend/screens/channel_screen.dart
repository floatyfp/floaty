import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:floaty/backend/fpapi.dart';
import 'package:floaty/frontend/root.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:floaty/frontend/elements.dart';
import 'package:floaty/backend/definitions.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:floaty/providers/channel_provider.dart';
import 'package:auto_size_text/auto_size_text.dart';

// ignore: must_be_immutable
class ChannelScreen extends ConsumerWidget {
  const ChannelScreen({super.key, required this.channelName, this.subName});
  final String channelName;
  final String? subName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channelScreenStateNotifier =
        ref.watch(channelScreenProvider.notifier);

    return ChannelScreenStateWrapper(
      channelName: channelName,
      subName: subName,
      channelScreenStateNotifier: channelScreenStateNotifier,
    );
  }
}

class ChannelScreenStateWrapper extends ConsumerStatefulWidget {
  final String channelName;
  final String? subName;
  final ChannelScreenStateNotifier channelScreenStateNotifier;

  const ChannelScreenStateWrapper({
    super.key,
    required this.channelName,
    this.subName,
    required this.channelScreenStateNotifier,
  });

  @override
  // ignore: library_private_types_in_public_api
  _ChannelScreenStateWrapperState createState() =>
      _ChannelScreenStateWrapperState();
}

class _ChannelScreenStateWrapperState
    extends ConsumerState<ChannelScreenStateWrapper> {
  bool isRootChannel = true;
  bool isLoading = true;
  dynamic channel;
  dynamic rootchannel;
  dynamic response;
  bool searchfieldvisible = false;
  // ignore: unused_field
  double _filterPanelHeight = 0;
  dynamic home;
  static const _pageSize = 20;
  final PagingController<int, BlogPostCard> _pagingController =
      PagingController<int, BlogPostCard>(firstPageKey: 0);
  List<BlogPostModelV3> newposts = [];
  bool isLastPage = false;
  int fetchafter = 0;
  final ScrollController _scrollController = ScrollController();
  bool _showFloatingNav = false;
  double _scrollThreshold = 0;

  int pageloadint = 0;

  void _toggleSearch() {
    if (!searchfieldvisible &&
        ref.watch(channelScreenProvider.select((s) => s.selectedIndex)) == 0) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
    widget.channelScreenStateNotifier.toggleSearch();
  }

  void _handleResize(Size size) {
    if (searchfieldvisible) {
      setState(() {
        _filterPanelHeight = size.height;
      });
    }
  }

  void _handleFilterChange(
    String searchQuery,
    Set<String> contentTypes,
    RangeValues durationRange,
    DateTime? startDate,
    DateTime? endDate,
    bool isAscending,
  ) {
    // Update Riverpod state
    ref.read(channelScreenProvider.notifier).updateFilters(
          searchQuery: searchQuery,
          contentTypes: contentTypes,
          durationRange: durationRange,
          startDate: startDate,
          endDate: endDate,
          isAscending: isAscending,
        );

    fetchafter = 0;
    _pagingController.refresh();
  }

  void _calculateScrollThreshold() {
    final screenWidth = MediaQuery.of(context).size.width;
    final bannerHeight = (screenWidth / 3.827).clamp(0.0, 300.0);
    final profileImageRadius = (screenWidth * 0.1).clamp(44.0, 52.0);
    _scrollThreshold = bannerHeight - profileImageRadius + 50;
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final showFloating = _scrollController.offset > _scrollThreshold;
      if (showFloating != _showFloatingNav) {
        setState(() {
          _showFloatingNav = showFloating;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      load();
      _calculateScrollThreshold();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _calculateScrollThreshold();
    ref.listenManual<int>(
      channelScreenProvider.select((state) => state.selectedIndex),
      (previous, next) {
        if (next == 2 && context.mounted) {
          context.push('/live/${widget.channelName}');
          ref.read(channelScreenProvider.notifier).resetSelectedIndex();
        }
      },
    );
  }

  @override
  void didUpdateWidget(ChannelScreenStateWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.channelName != widget.channelName ||
        oldWidget.subName != widget.subName) {
      ref.read(channelScreenProvider.notifier).resetState();
      load();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _pagingController.dispose();
    super.dispose();
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final state = ref.read(channelScreenProvider);
      home = await fpApiRequests.getChannelVideoFeed(
        rootchannel.id,
        _pageSize,
        fetchafter,
        channel: !isRootChannel ? channel.id : null,
        searchQuery: state.searchQuery,
        durationRange: state.durationRange,
        fromDate: state.startDate,
        toDate: state.endDate,
        isAscending: state.isAscending,
        contentTypes: state.selectedContentTypes,
      );
      fetchafter = fetchafter + 20;

      newposts = home;
      isLastPage = home!.length < _pageSize;

      List<String> blogPostIds = newposts
          .map((post) => post.id)
          .where((id) => id != null)
          .cast<String>()
          .toList();
      List<GetProgressResponse> progressResponses =
          await fpApiRequests.getVideoProgress(blogPostIds);

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
      _pagingController.error = error;
    }
  }

  void getStats() async {
    final stats = await fpApiRequests.getStats(rootchannel.id!);
    if (mounted) {
      setState(() {
        response = stats;
        isLoading = false;
      });
    }
  }

  void load() {
    bool statsFetched = false;

    if (widget.subName != null) {
      isRootChannel = false;

      fpApiRequests.getCreator(urlname: widget.channelName).listen((creator) {
        setState(() {
          rootchannel = creator;
          channel = creator.channels?.firstWhere(
            (channel) => channel.urlname == widget.subName,
          );
          rootLayoutKey.currentState?.setAppBar(Text(channel.title));

          if (!statsFetched && rootchannel.id != null) {
            statsFetched = true;
            getStats();
          }
        });
      });
    } else {
      isRootChannel = true;

      fpApiRequests.getCreator(urlname: widget.channelName).listen((creator) {
        setState(() {
          channel = creator;
          rootchannel = creator;
          rootLayoutKey.currentState?.setAppBar(Text(channel.title));

          if (!statsFetched && rootchannel.id != null) {
            statsFetched = true;
            getStats();
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    double profileImageRadius = (screenWidth * 0.1).clamp(44.0, 52.0);
    double fontSize = (screenWidth * 0.06).clamp(4.0, 30.0);

    _calculateScrollThreshold();

    final showNav =
        ref.watch(channelScreenProvider.select((s) => s.selectedIndex)) == 0 &&
            (_showFloatingNav &&
                _scrollController.hasClients &&
                _scrollController.offset > _scrollThreshold);

    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : Scaffold(
            body: RefreshIndicator(
            onRefresh: () async {
              fetchafter = 0;
              _pagingController.refresh();
            },
            child: Stack(
              children: [
                CustomScrollView(
                  controller: ref.watch(channelScreenProvider
                              .select((s) => s.selectedIndex)) ==
                          0
                      ? _scrollController
                      : null,
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.bottomLeft,
                            children: [
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ),
                              Center(
                                child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxHeight: 300),
                                  child: AspectRatio(
                                    aspectRatio: 3.827,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        image: DecorationImage(
                                          image: NetworkImage(
                                            channel?.cover?.path ??
                                                'https://example.com/default-banner.jpg',
                                          ),
                                          fit: BoxFit.fitHeight,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withValues(alpha: 0.4),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                  bottom: -profileImageRadius,
                                  left: 12,
                                  child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        CircleAvatar(
                                          radius: profileImageRadius,
                                          backgroundImage: NetworkImage(
                                            channel?.icon?.path ??
                                                'https://example.com/default-profile.jpg',
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            AutoSizeText(
                                              channel?.title ?? 'Channel Name',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: fontSize,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              stepGranularity: 0.25,
                                              textScaleFactor: 0.95,
                                            ),
                                            const Padding(
                                                padding: EdgeInsets.symmetric(
                                                    vertical: 10)),
                                            const Padding(
                                                padding: EdgeInsets.only(
                                                    bottom: 30)),
                                          ],
                                        ),
                                      ])),
                            ],
                          ),
                          SizedBox(
                              height: 60,
                              child: Row(children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.only(
                                          left: profileImageRadius * 2 + 20),
                                    ),
                                    _buildNavButton("Home", 0),
                                    const SizedBox(width: 10),
                                    _buildNavButton("About", 1),
                                    if (rootchannel?.liveStream != null)
                                      const SizedBox(width: 10),
                                    if (rootchannel?.liveStream != null)
                                      _buildNavButton("Live", 2),
                                  ],
                                ),
                                const Spacer(),
                                Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: SizedBox(
                                    height: 50,
                                    width: 50,
                                    child: AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 350),
                                      transitionBuilder: (Widget child,
                                          Animation<double> animation) {
                                        final isSearchIcon =
                                            child.key == const ValueKey(false);
                                        return Stack(
                                          children: [
                                            FadeTransition(
                                              opacity: animation,
                                              child: RotationTransition(
                                                turns: isSearchIcon
                                                    ? Tween(
                                                            begin: 0.5,
                                                            end: 1.0)
                                                        .animate(
                                                            CurvedAnimation(
                                                                parent:
                                                                    animation,
                                                                curve: Curves
                                                                    .easeInOut))
                                                    : Tween(
                                                            begin: 1.5,
                                                            end: 1.0)
                                                        .animate(CurvedAnimation(
                                                            parent: animation,
                                                            curve: Curves
                                                                .easeInOut)),
                                                child: child,
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                      child: IconButton(
                                        key: ValueKey(ref.watch(
                                            channelScreenProvider.select(
                                                (s) => s.searchFieldVisible))),
                                        onPressed: _toggleSearch,
                                        icon: Icon(
                                          ref.watch(channelScreenProvider
                                                  .select((s) =>
                                                      s.searchFieldVisible))
                                              ? Icons.close
                                              : Icons.search,
                                          color: Colors.grey.shade200,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ])),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: ClipRect(
                              child: AnimatedSize(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeInOut,
                                child: ref.watch(channelScreenProvider
                                        .select((s) => s.searchFieldVisible))
                                    ? LayoutBuilder(
                                        builder: (context, constraints) {
                                          WidgetsBinding.instance
                                              .addPostFrameCallback((_) {
                                            _handleResize(Size(
                                                constraints.maxWidth,
                                                constraints.maxHeight));
                                          });
                                          return Center(
                                            child: FilterPanel(
                                              onSizeChanged: _handleResize,
                                              parentWidth: constraints.maxWidth,
                                              onFilterChanged:
                                                  _handleFilterChange,
                                              initialContentTypes: ref.watch(
                                                  channelScreenProvider.select(
                                                      (s) => s
                                                          .selectedContentTypes)),
                                              initialSearchQuery: ref.watch(
                                                  channelScreenProvider.select(
                                                      (s) => s.searchQuery)),
                                              initialDurationRange: ref.watch(
                                                  channelScreenProvider.select(
                                                      (s) => s.durationRange)),
                                              initialStartDate: ref.watch(
                                                  channelScreenProvider.select(
                                                      (s) => s.startDate)),
                                              initialEndDate: ref.watch(
                                                  channelScreenProvider.select(
                                                      (s) => s.endDate)),
                                              initialIsAscending: ref.watch(
                                                  channelScreenProvider.select(
                                                      (s) => s.isAscending)),
                                            ),
                                          );
                                        },
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isLoading)
                      const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (ref.watch(channelScreenProvider
                            .select((s) => s.selectedIndex)) ==
                        0)
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        sliver: SliverLayoutBuilder(
                          builder: (context, constraints) {
                            final useList = constraints.crossAxisExtent <= 450;
                            return useList
                                ? PagedSliverList<int, BlogPostCard>(
                                    pagingController: _pagingController,
                                    builderDelegate:
                                        PagedChildBuilderDelegate<BlogPostCard>(
                                      animateTransitions: true,
                                      itemBuilder: (context, item, index) =>
                                          Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 2,
                                        ),
                                        child: BlogPostCard(item.blogPost,
                                            response: item.response),
                                      ),
                                      noItemsFoundIndicatorBuilder: (context) =>
                                          const Center(
                                        child: Text("No items found."),
                                      ),
                                    ),
                                  )
                                : PagedSliverGrid<int, BlogPostCard>(
                                    pagingController: _pagingController,
                                    gridDelegate:
                                        const SliverGridDelegateWithMaxCrossAxisExtent(
                                      maxCrossAxisExtent: 300,
                                      crossAxisSpacing: 4,
                                      mainAxisSpacing: 4,
                                      childAspectRatio: 1.175,
                                    ),
                                    builderDelegate:
                                        PagedChildBuilderDelegate<BlogPostCard>(
                                      animateTransitions: true,
                                      itemBuilder: (context, item, index) =>
                                          Padding(
                                        padding: const EdgeInsets.all(4),
                                        child: BlogPostCard(item.blogPost,
                                            response: item.response),
                                      ),
                                      noItemsFoundIndicatorBuilder: (context) =>
                                          const Center(
                                        child: Text("No items found."),
                                      ),
                                    ),
                                  );
                          },
                        ),
                      )
                    else if (ref.watch(channelScreenProvider
                            .select((s) => s.selectedIndex)) ==
                        1)
                      SliverToBoxAdapter(
                        child: AboutContent(
                          channel: channel,
                          rootchannel: rootchannel,
                          stats: response,
                        ),
                      )
                    else if (ref.watch(channelScreenProvider
                            .select((s) => s.selectedIndex)) ==
                        2)
                      SliverToBoxAdapter(
                        child: LiveContent(channel: channel),
                      )
                    else
                      const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()),
                      ),
                  ],
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  top: showNav ? 0 : -60,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Theme.of(context).scaffoldBackgroundColor,
                          Theme.of(context)
                              .scaffoldBackgroundColor
                              .withValues(alpha: 0.9),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildNavButton("Home", 0),
                        const SizedBox(width: 10),
                        _buildNavButton("About", 1),
                        if (rootchannel?.liveStream != null)
                          const SizedBox(width: 10),
                        if (rootchannel?.liveStream != null)
                          _buildNavButton("Live", 2),
                        const SizedBox(width: 10),
                        _buildNavButton(
                            ref.watch(channelScreenProvider
                                    .select((s) => s.searchFieldVisible))
                                ? "Close"
                                : "Search",
                            -1),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ));
  }

  Widget _buildNavButton(String title, int index) {
    final bool isSelected =
        ref.watch(channelScreenProvider.select((s) => s.selectedIndex)) ==
            index;
    return GestureDetector(
      onTap: () {
        if (index == -1) {
          _toggleSearch();
        } else {
          widget.channelScreenStateNotifier.updateSelectedIndex(index);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue.withValues(alpha: 0.4)
              : Colors.grey.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.blue : Colors.white,
            fontSize: 18,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  final dynamic channel;
  final bool? isRootChannel;
  const HomeContent({super.key, this.channel, this.isRootChannel});

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class AboutContent extends StatelessWidget {
  final dynamic channel;
  final dynamic rootchannel;
  final dynamic stats;
  const AboutContent({super.key, this.channel, this.rootchannel, this.stats});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1000),
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //TODO: MIGRATE AWAY FROM FLUTTER_MARKDOWN
            MarkdownBody(
              data: channel.about ?? '',
              styleSheet:
                  MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                p: const TextStyle(fontSize: 16.0),
              ),
            ),
            const SizedBox(height: 12.0),
            const Divider(),
            const SizedBox(height: 12.0),
            Center(
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 600,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final buttonSize =
                        (constraints.maxWidth * 0.06).clamp(40.0, 50.0);
                    final iconSize = (buttonSize * 0.5).clamp(20.0, 25.0);

                    return Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: [
                        if (channel.socialLinks.discord != null)
                          SizedBox(
                            width: buttonSize,
                            height: buttonSize,
                            child: TextButton(
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                backgroundColor:
                                    const Color.fromRGBO(114, 137, 218, 1.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5.0),
                                ),
                              ),
                              onPressed: () {
                                launchUrl(
                                    Uri.parse(channel.socialLinks.discord!));
                              },
                              child: Center(
                                child: FaIcon(
                                  FontAwesomeIcons.discord,
                                  size: iconSize,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        if (channel.socialLinks.twitter != null)
                          SizedBox(
                            width: buttonSize,
                            height: buttonSize,
                            child: TextButton(
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                backgroundColor:
                                    const Color.fromRGBO(29, 161, 242, 1.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5.0),
                                ),
                              ),
                              onPressed: () {
                                launchUrl(
                                    Uri.parse(channel.socialLinks.twitter!));
                              },
                              child: Center(
                                child: FaIcon(
                                  FontAwesomeIcons.twitter,
                                  size: iconSize,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        if (channel.socialLinks.youtube != null)
                          SizedBox(
                            width: buttonSize,
                            height: buttonSize,
                            child: TextButton(
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                backgroundColor: Colors.red,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5.0),
                                ),
                              ),
                              onPressed: () {
                                launchUrl(
                                    Uri.parse(channel.socialLinks.youtube!));
                              },
                              child: Center(
                                child: FaIcon(
                                  FontAwesomeIcons.youtube,
                                  size: iconSize,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        if (channel.socialLinks.facebook != null)
                          SizedBox(
                            width: buttonSize,
                            height: buttonSize,
                            child: TextButton(
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                backgroundColor:
                                    const Color.fromRGBO(59, 89, 152, 1.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5.0),
                                ),
                              ),
                              onPressed: () {
                                launchUrl(
                                    Uri.parse(channel.socialLinks.facebook!));
                              },
                              child: Center(
                                child: FaIcon(
                                  FontAwesomeIcons.facebook,
                                  size: iconSize,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        if (channel.socialLinks.instagram != null)
                          SizedBox(
                            width: buttonSize,
                            height: buttonSize,
                            child: TextButton(
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                backgroundColor:
                                    const Color.fromRGBO(217, 49, 117, 1.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5.0),
                                ),
                              ),
                              onPressed: () {
                                launchUrl(
                                    Uri.parse(channel.socialLinks.instagram!));
                              },
                              child: Center(
                                child: FaIcon(
                                  FontAwesomeIcons.instagram,
                                  size: iconSize,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        if (channel.socialLinks.website != null)
                          SizedBox(
                            width: buttonSize,
                            height: buttonSize,
                            child: TextButton(
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                backgroundColor:
                                    const Color.fromRGBO(76, 146, 169, 1.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5.0),
                                ),
                              ),
                              onPressed: () {
                                launchUrl(
                                    Uri.parse(channel.socialLinks.website!));
                              },
                              child: Center(
                                child: FaIcon(
                                  FontAwesomeIcons.globe,
                                  size: iconSize,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            Center(
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 800,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: rootchannel.discordServers
                          .map<Widget>((discordServer) {
                        const iconSize = 24.0;

                        return Padding(
                          padding: const EdgeInsets.only(
                              right: 2, left: 2, top: 10, bottom: 10),
                          child: IntrinsicWidth(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromRGBO(114, 137, 218, 1.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5.0),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                  horizontal: 12,
                                ),
                              ),
                              onPressed: () {
                                launchUrl(Uri.parse(discordServer.inviteLink!));
                              },
                              icon: const FaIcon(
                                FontAwesomeIcons.discord,
                                size: iconSize,
                                color: Colors.white,
                              ),
                              label: Text(
                                discordServer.guildName ?? "Unknown Server",
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ),
            if (stats.totalSubcriberCount != null || stats.totalIncome != null)
              const SizedBox(height: 16.0),
            if (stats.totalSubcriberCount != null || stats.totalIncome != null)
              Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final maxWidth = constraints.maxWidth;
                    final containerWidth = (maxWidth * 0.8).clamp(300.0, 500.0);

                    return Container(
                      width: containerWidth,
                      padding: EdgeInsets.symmetric(
                        vertical: 16.0,
                        horizontal: containerWidth * 0.06,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          if (stats.totalSubcriberCount != null)
                            Expanded(
                              child: StatColumn(
                                value: stats.totalSubcriberCount.toString(),
                                label: 'Subscribers',
                              ),
                            ),
                          if (stats.totalSubcriberCount != null &&
                              stats.totalIncome != null)
                            const SizedBox(width: 16.0),
                          if (stats.totalIncome != null)
                            Expanded(
                              child: StatColumn(
                                value: '\$${stats.totalIncome.toString()}',
                                label: 'Per Month',
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class LiveContent extends StatelessWidget {
  final dynamic channel;
  const LiveContent({super.key, this.channel});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
