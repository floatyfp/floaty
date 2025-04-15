import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:floaty/providers/profile_provider.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:floaty/frontend/root.dart';
import 'package:floaty/backend/fpapi.dart';
import 'package:go_router/go_router.dart';
import 'package:timelines_plus/timelines_plus.dart';
import 'dart:convert';

// ignore: must_be_immutable
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, required this.userName});
  final String userName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileScreenStateNotifier =
        ref.watch(profileScreenProvider.notifier);

    return ProfileScreenStateWrapper(
      userName: userName,
      profileScreenStateNotifier: profileScreenStateNotifier,
    );
  }
}

class ProfileScreenStateWrapper extends ConsumerStatefulWidget {
  final String userName;
  final ProfileScreenStateNotifier profileScreenStateNotifier;

  const ProfileScreenStateWrapper({
    super.key,
    required this.userName,
    required this.profileScreenStateNotifier,
  });

  @override
  // ignore: library_private_types_in_public_api
  _ProfileScreenStateWrapperState createState() =>
      _ProfileScreenStateWrapperState();
}

class _ProfileScreenStateWrapperState
    extends ConsumerState<ProfileScreenStateWrapper> {
  bool isLoading = true;
  bool isActivityLoading = true;
  List<DateModel>? parseddates;

  dynamic user;
  dynamic activity;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      load();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ref.listenManual<int>(
      profileScreenProvider.select((state) => state.selectedIndex),
      (previous, next) {},
    );
  }

  @override
  void didUpdateWidget(ProfileScreenStateWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userName != widget.userName) {
      ref.read(profileScreenProvider.notifier).resetState();
      load();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void load() async {
    final res = await fpApiRequests.getNamedUser(widget.userName);
    setState(() {
      user = res;
      rootLayoutKey.currentState?.setAppBar(Text(user[0]['username']));
      isLoading = false;
    });
    parseActivityData();
  }

  Future<void> parseActivityData() async {
    final res = jsonDecode(await fpApiRequests.getActivity(user[0]['id']));
    final activityData = res['activity'] as List<dynamic>;
    Map<String, List<CommentData>> commentsByDate = {};
    for (var item in activityData) {
      DateTime dateTime = DateTime.parse(item['time']);
      String formattedDate =
          "${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}";
      CommentData comment = CommentData(
        time: dateTime,
        comment: item['comment'],
        postTitle: item['postTitle'],
        postId: item['postId'],
        creatorTitle: item['creatorTitle'],
        creatorUrl: item['creatorUrl'],
      );

      if (!commentsByDate.containsKey(formattedDate)) {
        commentsByDate[formattedDate] = [];
      }
      commentsByDate[formattedDate]!.add(comment);
    }
    List<DateModel> dates = commentsByDate.entries.map((entry) {
      return DateModel(
        date: entry.key,
        comments: entry.value,
      );
    }).toList();
    dates.sort((a, b) {
      return b.comments.first.time.compareTo(a.comments.first.time);
    });
    for (var dateModel in dates) {
      dateModel.comments.sort((a, b) => b.time.compareTo(a.time));
    }
    if (mounted) {
      setState(() {
        parseddates = dates;
        isActivityLoading = false;
      });
    }
  }

  Widget profileHeader({bool smol = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          color: const Color.fromARGB(255, 40, 40, 40),
          height: 110,
          child: Padding(
            padding: EdgeInsets.only(left: 20),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          backgroundImage:
                              user[0]['profileImage']['path'] != null &&
                                      user[0]['profileImage']['path'].isNotEmpty
                                  ? CachedNetworkImageProvider(
                                      user[0]['profileImage']['path'] ??
                                          'https://example.com/default-profile.jpg',
                                    )
                                  : AssetImage('assets/placeholder.png'),
                          radius: 20,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              user[0]['username'] ?? 'Username',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildNavButton("Activity", 0, smol: true),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget legacyChannelHeader() {
    double screenWidth = MediaQuery.of(context).size.width;

    double profileImageRadius = (screenWidth * 0.1).clamp(44.0, 52.0);
    double fontSize = (screenWidth * 0.06).clamp(4.0, 30.0);
    return Column(
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
                constraints: const BoxConstraints(maxHeight: 300),
                child: AspectRatio(
                  aspectRatio: 3.827,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
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
                      Colors.transparent,
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: profileImageRadius,
                        backgroundImage:
                            user[0]['profileImage']['path'] != null &&
                                    user[0]['profileImage']['path'].isNotEmpty
                                ? CachedNetworkImageProvider(
                                    user[0]['profileImage']['path']!,
                                  )
                                : AssetImage('assets/placeholder.png'),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AutoSizeText(
                            user[0]['username'] ?? 'Username',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: fontSize,
                              fontWeight: FontWeight.bold,
                            ),
                            stepGranularity: 0.25,
                            textScaleFactor: 0.95,
                          ),
                          const Padding(
                              padding: EdgeInsets.symmetric(vertical: 10)),
                          const Padding(padding: EdgeInsets.only(bottom: 30)),
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
                    padding: EdgeInsets.only(left: profileImageRadius * 2 + 20),
                  ),
                  _buildNavButton("Activity", 0),
                ],
              ),
            ])),
      ],
    );
  }

  void onPostTap(String postId) {
    context.push('/post/$postId');
  }

  void onCreatorTap(String creatorUrl) {
    context.push('/channel/$creatorUrl');
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : LayoutBuilder(
            builder: (context, constraints) {
              final bool smol = constraints.maxWidth < 460;
              return Scaffold(
                body: Stack(
                  children: [
                    CustomScrollView(
                      controller: ref.watch(profileScreenProvider
                                  .select((s) => s.selectedIndex)) ==
                              0
                          ? _scrollController
                          : null,
                      slivers: [
                        SliverToBoxAdapter(
                          //TODO: setting
                          child: profileHeader(
                            smol: smol,
                          ), //legacyChannelHeader(), :
                        ),
                        if (isLoading)
                          const SliverFillRemaining(
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (ref.watch(profileScreenProvider
                                .select((s) => s.selectedIndex)) ==
                            0)
                          SliverPadding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4.0),
                            sliver: SliverLayoutBuilder(
                              builder: (context, constraints) {
                                return isActivityLoading
                                    ? const SliverFillRemaining(
                                        child: Center(
                                        child: CircularProgressIndicator(),
                                      ))
                                    : SliverPadding(
                                        padding: const EdgeInsets.all(4.0),
                                        sliver: SliverFillRemaining(
                                            child: ActivityTimeline(
                                                dates: parseddates!,
                                                onPostTap: onPostTap,
                                                onCreatorTap: onCreatorTap)));
                              },
                            ),
                          )
                        else
                          const SliverFillRemaining(
                            child: Center(child: CircularProgressIndicator()),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
  }

  Widget _buildNavButton(String title, int index, {bool smol = false}) {
    final bool isSelected =
        ref.watch(profileScreenProvider.select((s) => s.selectedIndex)) ==
            index;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        widget.profileScreenStateNotifier.updateSelectedIndex(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.4)
              : Colors.grey.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(smol ? 5 : 8),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.white,
            fontSize: smol ? 13 : 18,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class DateModel {
  final String date;
  final List<CommentData> comments;

  DateModel({
    required this.date,
    required this.comments,
  });
}

class CommentData {
  final DateTime time;
  final String comment;
  final String postTitle;
  final String postId;
  final String creatorTitle;
  final String creatorUrl;

  CommentData({
    required this.time,
    required this.comment,
    required this.postTitle,
    required this.postId,
    required this.creatorTitle,
    required this.creatorUrl,
  });
}

class ActivityTimeline extends StatelessWidget {
  final List<DateModel> dates;
  final Function(String)? onPostTap;
  final Function(String)? onCreatorTap;

  const ActivityTimeline({
    super.key,
    required this.dates,
    this.onPostTap,
    this.onCreatorTap,
  });

  @override
  Widget build(BuildContext context) {
    return dates.isEmpty
        ? Center(child: Text('No Activity'))
        : TimelineTheme(
            data: TimelineThemeData(
              nodePosition: 0,
              color: Colors.blue,
              indicatorTheme: const IndicatorThemeData(
                size: 15.0,
                position: 0.0,
              ),
              connectorTheme: const ConnectorThemeData(
                thickness: 2.5,
              ),
            ),
            child: Timeline.builder(
              itemCount: dates.length,
              itemBuilder: (context, dateIndex) {
                final dateModel = dates[dateIndex];

                return TimelineTile(
                  nodeAlign: TimelineNodeAlign.start,
                  node: TimelineNode(
                    indicator: DotIndicator(
                      color: Colors.blue,
                      size: 12,
                    ),
                    startConnector: dateIndex == 0
                        ? null
                        : SolidLineConnector(
                            color: Colors.blue,
                            indent: 12,
                          ),
                    endConnector: dateIndex == dates.length - 1
                        ? null
                        : SolidLineConnector(
                            color: Colors.blue,
                          ),
                  ),
                  contents: Padding(
                    padding: const EdgeInsets.fromLTRB(20.0, 0, 20.0, 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date header
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            dateModel.date,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        // All comments for this date
                        ...dateModel.comments.map((comment) => Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: RichText(
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 2,
                                          text: TextSpan(
                                            style: TextStyle(
                                              color: Colors.grey[400],
                                              fontSize: 14,
                                            ),
                                            children: [
                                              TextSpan(
                                                  text: 'Posted a comment on '),
                                              TextSpan(
                                                text: comment.postTitle,
                                                style: const TextStyle(
                                                  color: Colors.blue,
                                                ),
                                                recognizer:
                                                    TapGestureRecognizer()
                                                      ..onTap = () {
                                                        onPostTap?.call(
                                                            comment.postId);
                                                      },
                                              ),
                                              TextSpan(text: ' by '),
                                              TextSpan(
                                                text: comment.creatorTitle,
                                                style: const TextStyle(
                                                  color: Colors.blue,
                                                ),
                                                recognizer:
                                                    TapGestureRecognizer()
                                                      ..onTap = () {
                                                        onCreatorTap?.call(
                                                            comment.creatorUrl);
                                                      },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      border:
                                          Border.all(color: Colors.grey[800]!),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    child: Text(
                                      comment.comment,
                                      style: TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ))
                      ],
                    ),
                  ),
                );
              },
            ),
          );
  }
}
