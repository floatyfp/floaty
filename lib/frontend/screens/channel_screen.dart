import 'package:floaty/backend/fpapi.dart';
import 'package:flutter/material.dart';
import 'package:floaty/frontend/root.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:floaty/frontend/elements.dart';
import 'package:floaty/backend/definitions.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

// ignore: must_be_immutable
class ChannelScreen extends StatefulWidget {
  const ChannelScreen({super.key, required this.channelName, this.subName});
  final String channelName;
  final String? subName;

  @override
  // ignore: library_private_types_in_public_api
  _ChannelScreenState createState() => _ChannelScreenState();
}

class _ChannelScreenState extends State<ChannelScreen> {
  bool isRootChannel = true;
  bool isLoading = true;
  dynamic channel;
  dynamic rootchannel;
  int selectedIndex = 0;
  dynamic response;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      load();
    });
  }

  @override
  void didUpdateWidget(ChannelScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.channelName != widget.channelName ||
        oldWidget.subName != widget.subName) {
      setState(() {
        isRootChannel = true;
        isLoading = true;
      });
      load(); // Re-run initialization logic with new parameters
    }
  }

  void load() async {
    if (widget.subName != null) {
      isRootChannel = false;
      final response =
          await FPApiRequests().getCreator(urlname: widget.channelName);
      rootchannel = response;
      channel = response.channels?.firstWhere(
        (channel) => channel.urlname == widget.subName,
      );
      rootLayoutKey.currentState?.setAppBar(Text(channel.title));
    } else {
      isRootChannel = true;
      channel = await FPApiRequests().getCreator(urlname: widget.channelName);
      rootchannel = channel;
      rootLayoutKey.currentState?.setAppBar(Text(channel.title));
    }
    response = await FPApiRequests().getStats(rootchannel.id!);
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    // Calculate sizes based on screen width
    double profileImageRadius = (screenWidth * 0.1).clamp(44.0, 52.0);
    double fontSize = (screenWidth * 0.06).clamp(4.0, 30.0);

    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : Scaffold(
            body: OverflowBox(
              child: Stack(
                children: [
                  SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header content (profile image, banner, etc.)

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
                                      const BoxConstraints(maxHeight: 350),
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
                                        Colors.black.withOpacity(0.4),
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
                                            Text(
                                              channel?.title ?? 'Channel Name',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: fontSize,
                                                fontWeight: FontWeight.bold,
                                              ),
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
                            child: Row(
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
                          ),

                          // Expanded widget to make sure the main content fits within available space
                          isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : selectedIndex == 0
                                  ? HomeContent(
                                      channel: channel,
                                      isRootChannel: isRootChannel,
                                    )
                                  : selectedIndex == 1
                                      ? AboutContent(
                                          channel: channel,
                                          rootchannel: rootchannel,
                                          stats: response)
                                      : LiveContent(channel: channel),
                        ],
                      )),
                  Positioned(
                    top: 6,
                    left: 0,
                    right: 0,
                    child: Container(
                      color: Colors.transparent,
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
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
  }

  Widget _buildNavButton(String title, int index) {
    final bool isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue.withOpacity(0.4) // Selected button background
              : Colors.grey.withOpacity(0.7), // Unselected button background
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

class HomeContent extends StatefulWidget {
  final dynamic channel;
  final bool? isRootChannel;
  const HomeContent({super.key, this.channel, this.isRootChannel});

  @override
  // ignore: library_private_types_in_public_api
  _HomeContentState createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  static const _pageSize = 20;
  final PagingController<int, BlogPostCard> _pagingController =
      PagingController<int, BlogPostCard>(firstPageKey: 0);
  List<ContentCreatorListLastItems> lastElements = [];
  List<BlogPostModelV3> newposts = [];
  bool isLastPage = false;
  int fetchafter = 0;

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      dynamic home;
      List<String> channelid = [];
      if (widget.isRootChannel ?? true) {
        channelid = [widget.channel.id!];
      } else {
        channelid = [widget.channel.creator!];
      }
      if (lastElements.isNotEmpty) {
        if (widget.isRootChannel ?? true) {
          home = await FPApiRequests().getMultiCreatorVideoFeed(
              channelid, _pageSize,
              lastElements: lastElements);
        } else {
          home = await FPApiRequests().getSubchannelVideoFeed(
              channelid, _pageSize, widget.channel.id, fetchafter);
          fetchafter = fetchafter + 20;
        }
      } else {
        if (widget.isRootChannel ?? true) {
          home = await FPApiRequests()
              .getMultiCreatorVideoFeed(channelid, _pageSize);
        } else {
          home = await FPApiRequests().getSubchannelVideoFeed(
              channelid, _pageSize, widget.channel.id, fetchafter);
          fetchafter = fetchafter + 20;
        }
      }

      if (widget.isRootChannel ?? true) {
        newposts = home.blogPosts ?? [];
      } else {
        newposts = home;
      }
      if (widget.isRootChannel ?? true) {
        lastElements = home.lastElements ?? [];

        isLastPage =
            !lastElements.any((element) => element.moreFetchable ?? false);
      } else {
        isLastPage = home!.length < _pageSize;
      }

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
  Widget build(BuildContext context) {
    return Expanded(
        child: Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(left: 4, right: 4),
        child: Column(
          children: [
            Expanded(
              child: PagedGridView<int, BlogPostCard>(
                pagingController: _pagingController,
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 300,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                  childAspectRatio: 1.12,
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
          ],
        ),
      ),
    ));
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }
}

class AboutContent extends StatelessWidget {
  final dynamic channel;
  final dynamic rootchannel;
  final dynamic stats;
  const AboutContent({super.key, this.channel, this.rootchannel, this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width > 1000 ? 1000 : double.infinity,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          // Social media icons row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (channel.socialLinks.discord != null)
                TextButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(0.2),
                      backgroundColor: const Color.fromRGBO(114, 137, 218, 1.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                    ),
                    onPressed: () {
                      launchUrl(Uri.parse(channel.socialLinks.discord!));
                    },
                    child: const Padding(
                        padding: EdgeInsets.only(top: 11.0, bottom: 11.0),
                        child: FaIcon(
                          size: 25,
                          FontAwesomeIcons.discord,
                          color: Colors.white,
                        ))),
              if (channel.socialLinks.twitter != null)
                const SizedBox(width: 8.0),
              if (channel.socialLinks.twitter != null)
                TextButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(0.2),
                      backgroundColor: const Color.fromRGBO(29, 161, 242, 1.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                    ),
                    onPressed: () {
                      launchUrl(Uri.parse(channel.socialLinks.twitter!));
                    },
                    child: const Padding(
                        padding: EdgeInsets.only(top: 11.0, bottom: 11.0),
                        child: FaIcon(
                          size: 25,
                          FontAwesomeIcons.twitter,
                          color: Colors.white,
                        ))),
              if (channel.socialLinks.youtube != null)
                const SizedBox(width: 8.0),
              if (channel.socialLinks.youtube != null)
                TextButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(0.2),
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                    ),
                    onPressed: () {
                      launchUrl(Uri.parse(channel.socialLinks.youtube!));
                    },
                    child: const Padding(
                        padding: EdgeInsets.only(top: 11.0, bottom: 11.0),
                        child: FaIcon(
                          size: 25,
                          FontAwesomeIcons.youtube,
                          color: Colors.white,
                        ))),
              if (channel.socialLinks.facebook != null)
                const SizedBox(width: 8.0),
              if (channel.socialLinks.facebook != null)
                TextButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(0.2),
                      backgroundColor: const Color.fromRGBO(59, 89, 152, 1.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                    ),
                    onPressed: () {
                      launchUrl(Uri.parse(channel.socialLinks.facebook!));
                    },
                    child: const Padding(
                        padding: EdgeInsets.only(top: 11.0, bottom: 11.0),
                        child: FaIcon(
                          size: 25,
                          FontAwesomeIcons.facebook,
                          color: Colors.white,
                        ))),
              if (channel.socialLinks.instagram != null)
                const SizedBox(width: 8.0),
              if (channel.socialLinks.instagram != null)
                TextButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(0.2),
                      backgroundColor: const Color.fromRGBO(217, 49, 117, 1.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                    ),
                    onPressed: () {
                      launchUrl(Uri.parse(channel.socialLinks.instagram!));
                    },
                    child: const Padding(
                        padding: EdgeInsets.only(top: 11.0, bottom: 11.0),
                        child: FaIcon(
                          size: 25,
                          FontAwesomeIcons.instagram,
                          color: Colors.white,
                        ))),
              if (channel.socialLinks.website != null)
                const SizedBox(width: 8.0),
              if (channel.socialLinks.website != null)
                TextButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(0.2),
                      backgroundColor: const Color.fromRGBO(76, 146, 169, 1.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                    ),
                    onPressed: () {
                      launchUrl(Uri.parse(channel.socialLinks.website!));
                    },
                    child: const Padding(
                        padding: EdgeInsets.only(top: 11.0, bottom: 11.0),
                        child: FaIcon(
                          size: 25,
                          FontAwesomeIcons.globe,
                          color: Colors.white,
                        ))),
            ],
          ),
          const SizedBox(height: 16.0),
          // Button row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...rootchannel.discordServers.map((discordServer) =>
                  Row(children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromRGBO(114, 137, 218, 1.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                      ),
                      onPressed: () {
                        launchUrl(Uri.parse(discordServer.inviteLink!));
                      },
                      icon: const Padding(
                          padding: EdgeInsets.only(top: 10.0, bottom: 10.0),
                          child: FaIcon(
                            FontAwesomeIcons.discord,
                            color: Colors.white,
                          )),
                      label: Padding(
                        padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
                        child:
                            Text(discordServer.guildName ?? "Unknown Server"),
                      ),
                    ),
                    if (rootchannel.discordServers.length > 1 &&
                        rootchannel.discordServers.last != discordServer)
                      const SizedBox(width: 8.0),
                  ])),
            ],
          ),
          if (stats.totalSubcriberCount != null || stats.totalIncome != null)
            const SizedBox(height: 16.0),
          if (stats.totalSubcriberCount != null || stats.totalIncome != null)
            Center(
                child: Container(
              width: MediaQuery.of(context).size.width > 400
                  ? 400
                  : double.infinity,
              padding:
                  const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A), // Dark background color
                borderRadius: BorderRadius.circular(16.0), // Rounded corners
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  if (stats.totalSubcriberCount != null)
                    StatColumn(
                      value: stats.totalSubcriberCount.toString(),
                      label: 'Subscribers',
                    ),
                  if (stats.totalIncome != null)
                    StatColumn(
                      value: '\$${stats.totalIncome.toString()}',
                      label: 'Per Month',
                    ),
                ],
              ),
            )),
        ],
      ),
    );
  }
}

class LiveContent extends StatelessWidget {
  final dynamic channel;
  const LiveContent({super.key, this.channel});

  @override
  Widget build(BuildContext context) {
    return Text("Live Content for Channel: ${channel?.title ?? 'Loading...'}");
  }
}

// class Header extends StatefulWidget {
//   final dynamic channel;
//   final dynamic rootchannel;
//   final dynamic stats;
//   const Header({super.key});
//     int selectedIndex = 0;

//   @override
//   Widget build(BuildContext context) {
//           double screenWidth = MediaQuery.of(context).size.width;

//       // Calculate sizes based on screen width
//     double profileImageRadius = (screenWidth * 0.1).clamp(44.0, 52.0);
//     double fontSize = (screenWidth * 0.06).clamp(4.0, 30.0);

//     Widget _buildNavButton(String title, int index) {
//     final bool isSelected = selectedIndex == index;
//     return GestureDetector(
//       onTap: () => setState(() => selectedIndex = index),
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 300),
//         curve: Curves.easeInOut,
//         padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
//         decoration: BoxDecoration(
//           color: isSelected
//               ? Colors.blue.withOpacity(0.4) // Selected button background
//               : Colors.grey.withOpacity(0.7), // Unselected button background
//           borderRadius: BorderRadius.circular(8),
//         ),
//         child: Text(
//           title,
//           style: TextStyle(
//             color: isSelected ? Colors.blue : Colors.white,
//             fontSize: 18,
//             fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//           ),
//         ),
//       ),
//     );
//   }

  //   return Column(children: [
  //     Stack(
  //                 children: [
  //                   SizedBox(
  //                       width: MediaQuery.of(context).size.width,
  //                       height: MediaQuery.of(context).size.height,
  //                       child: Column(
  //                         mainAxisSize: MainAxisSize.min,
  //                         children: [
  //                           // Header content (profile image, banner, etc.)

  //                           Stack(
  //                             clipBehavior: Clip.none,
  //                             alignment: Alignment.bottomLeft,
  //                             children: [
  //                               Positioned.fill(
  //                                 child: Container(
  //                                   decoration: BoxDecoration(
  //                                     color: Colors.grey.shade800,
  //                                   ),
  //                                 ),
  //                               ),
  //                               Center(
  //                                 child: ConstrainedBox(
  //                                   constraints:
  //                                       const BoxConstraints(maxHeight: 350),
  //                                   child: AspectRatio(
  //                                     aspectRatio: 3.827,
  //                                     child: Container(
  //                                       decoration: BoxDecoration(
  //                                         image: DecorationImage(
  //                                           image: NetworkImage(
  //                                             channel?.cover?.path ??
  //                                                 'https://example.com/default-banner.jpg',
  //                                           ),
  //                                           fit: BoxFit.fitHeight,
  //                                         ),
  //                                       ),
  //                                     ),
  //                                   ),
  //                                 ),
  //                               ),
  //                               Positioned.fill(
  //                                 child: Container(
  //                                   decoration: BoxDecoration(
  //                                     gradient: LinearGradient(
  //                                       begin: Alignment.topCenter,
  //                                       end: Alignment.bottomCenter,
  //                                       colors: [
  //                                         Colors.transparent,
  //                                         Colors.black.withOpacity(0.4),
  //                                       ],
  //                                     ),
  //                                   ),
  //                                 ),
  //                               ),
  //                               Positioned(
  //                                   bottom: -profileImageRadius,
  //                                   left: 12,
  //                                   child: Row(
  //                                       crossAxisAlignment:
  //                                           CrossAxisAlignment.center,
  //                                       children: [
  //                                         CircleAvatar(
  //                                           radius: profileImageRadius,
  //                                           backgroundImage: NetworkImage(
  //                                             channel?.icon?.path ??
  //                                                 'https://example.com/default-profile.jpg',
  //                                           ),
  //                                         ),
  //                                         const SizedBox(
  //                                           width: 10,
  //                                         ),
  //                                         Column(
  //                                           crossAxisAlignment:
  //                                               CrossAxisAlignment.start,
  //                                           children: [
  //                                             Text(
  //                                               channel?.title ??
  //                                                   'Channel Name',
  //                                               style: TextStyle(
  //                                                 color: Colors.white,
  //                                                 fontSize: fontSize,
  //                                                 fontWeight: FontWeight.bold,
  //                                               ),
  //                                             ),
  //                                             const Padding(
  //                                                 padding: EdgeInsets.symmetric(
  //                                                     vertical: 10)),
  //                                             const Padding(
  //                                                 padding: EdgeInsets.only(
  //                                                     bottom: 30)),
  //                                           ],
  //                                         ),
  //                                       ])),
  //                             ],
  //                           ),
  //                           SizedBox(
  //                             height: 60,
  //                             child: Row(
  //                               crossAxisAlignment: CrossAxisAlignment.center,
  //                               children: [
  //                                 Padding(
  //                                   padding: EdgeInsets.only(
  //                                       left: profileImageRadius * 2 + 20),
  //                                 ),
  //                                 _buildNavButton("Home", 0),
  //                                 const SizedBox(width: 10),
  //                                 _buildNavButton("About", 1),
  //                                 if (rootchannel?.liveStream != null)
  //                                   const SizedBox(width: 10),
  //                                 if (rootchannel?.liveStream != null)
  //                                   _buildNavButton("Live", 2),
  //                               ],
  //                             ),
  //                           ),
  //                           ],))])]);
  // }