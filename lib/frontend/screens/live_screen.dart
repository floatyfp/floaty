import 'dart:convert';
import 'dart:core';

import 'package:dio/dio.dart';
import 'package:floaty/backend/fpwebsockets.dart';
import 'package:floaty/frontend/elements.dart';
import 'package:floaty/providers/live_status_provider.dart';
import 'package:floaty/frontend/screens/live_chat.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:resizable_widget/resizable_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math';
import 'package:floaty/backend/fpapi.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:floaty/backend/definitions.dart';
import 'dart:ui';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:floaty/frontend/widgets/media_player_widget.dart';
import 'package:floaty/services/media/media_player_service.dart';
import 'package:floaty/backend/whenplaneintergration.dart';

class LiveVideoWidget extends ConsumerStatefulWidget {
  final CreatorModelV3 creatorInfo;
  final bool compact;

  const LiveVideoWidget({
    super.key,
    required this.creatorInfo,
    this.compact = false,
  });

  @override
  ConsumerState<LiveVideoWidget> createState() => _LiveVideoWidgetState();
}

class _LiveVideoWidgetState extends ConsumerState<LiveVideoWidget> {
  bool offline = true;
  bool isChat = false;
  bool isWhenplane = false;
  late CreatorModelV3? realCreatorInfo;
  String? mediaUrl;
  late MediaPlayerService mediaService;
  Map<String, dynamic>? fpstats;
  bool isFPSTATSloading = true;

  @override
  void initState() {
    super.initState();
    realCreatorInfo = widget.creatorInfo;
    checker();
  }

  @override
  void dispose() {
    Future.microtask(() async {
      if (mediaService.playing &&
          mediaService.mediastate == MediaPlayerState.main) {
        mediaService.changeState(MediaPlayerState.mini);
      }
    });
    super.dispose();
  }

  void checker() async {
    bool isMrTechTips = widget.creatorInfo.urlname == 'linustechtips';
    if (isMrTechTips) {
      final stats = await whenPlaneIntegration.floatplanestats();
      setState(() {
        fpstats = jsonDecode(stats);
        isFPSTATSloading = false;
      });
    }
    mediaService = ref.read(mediaPlayerServiceProvider.notifier);
    final delivery = await fpApiRequests.getDelivery(
        'live', widget.creatorInfo.liveStream?.id ?? '');
    final deliveryData = jsonDecode(delivery);
    mediaUrl =
        '${deliveryData['groups'][0]['origins'][0]['url']}${deliveryData['groups'][0]['variants'][0]['url']}';
    while (offline == true) {
      final response = await Dio().get(mediaUrl!);
      if (response.statusCode == 200) {
        if (mounted) {
          realCreatorInfo = await fpApiRequests
              .getCreator(urlname: widget.creatorInfo.urlname)
              .first;
          if (isMrTechTips) {
            final stats = await whenPlaneIntegration.floatplanestats();
            setState(() {
              fpstats = jsonDecode(stats);
            });
          }
          setState(() {
            offline = false;
          });
        }
      }
      await Future.delayed(const Duration(seconds: 5));
    }
    while (offline == false) {
      final response = await Dio().get(mediaUrl!);
      if (response.statusCode == 404) {
        if (mounted) {
          if (isMrTechTips) {
            final stats = await whenPlaneIntegration.floatplanestats();
            setState(() {
              fpstats = jsonDecode(stats);
            });
          }
          setState(() {
            offline = true;
          });
          checker();
        }
      }
      await Future.delayed(const Duration(minutes: 1));
    }
  }

  void onExit() {
    setState(() {
      isChat = false;
    });
  }

  void onWPExit() {
    setState(() {
      isWhenplane = false;
    });
  }

  String timeDifference(String iso8601) {
    DateTime unixTime = DateTime.now();
    DateTime isoTime = DateTime.parse(iso8601);

    Duration diff = unixTime.difference(isoTime).abs();

    int days = diff.inDays;
    int hours = diff.inHours.remainder(24);
    int minutes = diff.inMinutes.remainder(60);

    List<String> parts = [];
    if (days > 0) parts.add("$days day${days > 1 ? 's' : ''}");
    if (hours > 0) parts.add("$hours hour${hours > 1 ? 's' : ''}");
    if (minutes > 0) parts.add("$minutes minute${minutes > 1 ? 's' : ''}");

    return parts.isNotEmpty ? parts.join(" ") : "0 minutes";
  }

  Widget offlineScreen() {
    return Container(
      width: double.infinity,
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            fit: BoxFit.contain,
            realCreatorInfo?.liveStream?.offline?.thumbnail?.path ??
                realCreatorInfo?.liveStream?.thumbnail?.path ??
                '',
          ),
          Align(
            alignment: Alignment.center,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AutoSizeText(
                        'This channel is offline',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        textScaleFactor: 0.9,
                        stepGranularity: 0.125,
                      ),
                      const SizedBox(height: 4),
                      AutoSizeText(
                        'Hang around and the stream will start automatically when it goes live!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 14,
                        ),
                        textScaleFactor: 0.75,
                        maxLines: 2,
                        overflowReplacement: SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isMrTechTips = widget.creatorInfo.urlname == 'linustechtips';
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        final availableWidth = constraints.maxWidth;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: min(
                  availableWidth * 9 / 16,
                  availableHeight - 250,
                ),
                child: offline
                    ? isMrTechTips
                        ? widget.compact
                            ? offlineScreen()
                            : WhenplaneScreen(
                                v: true,
                                h: min(
                                  availableWidth * 9 / 16,
                                  availableHeight - 250,
                                ),
                              )
                        : offlineScreen()
                    : MediaPlayerWidget(
                        contextBuild: context,
                        mediaUrl: mediaUrl!,
                        mediaType: MediaType.video,
                        attachment: null,
                        qualities: null,
                        initialState: MediaPlayerState.main,
                        startFrom: 0,
                        live: true,
                        title: realCreatorInfo?.liveStream?.title ??
                            'Unknown Title',
                        artist: realCreatorInfo?.title ?? 'Unknown Creator',
                        postId: realCreatorInfo?.urlname ?? '',
                        artworkUrl:
                            realCreatorInfo?.liveStream?.thumbnail?.path ?? '',
                      ),
              ),
              if (isChat)
                SizedBox(
                  height: availableHeight -
                      min(
                        availableWidth * 9 / 16,
                        availableHeight - 250,
                      ),
                  child: LiveChat(
                      liveId: widget.creatorInfo.liveStream?.id ?? '',
                      exit: true,
                      onExit: onExit),
                ),
              if (isWhenplane)
                SizedBox(
                  height: availableHeight -
                      min(
                        availableWidth * 9 / 16,
                        availableHeight - 250,
                      ),
                  child: WhenplaneCompactHolder(onWPExit),
                ),
              if (!isChat && !isWhenplane)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        offline
                            ? realCreatorInfo?.liveStream?.offline?.title ??
                                realCreatorInfo?.liveStream?.title ??
                                ''
                            : realCreatorInfo?.liveStream?.title ?? '',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      // Channel info
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundImage:
                                realCreatorInfo?.icon?.path != null &&
                                        (realCreatorInfo?.icon?.path ?? '')
                                            .isNotEmpty
                                    ? CachedNetworkImageProvider(
                                        realCreatorInfo?.icon?.path ?? '')
                                    : AssetImage('assets/placeholder.png'),
                            radius: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  realCreatorInfo?.title ?? '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                  ),
                                ),
                                if (isMrTechTips)
                                  Text(
                                    isFPSTATSloading
                                        ? offline
                                            ? 'Offline'
                                            : 'Live'
                                        : offline
                                            ? 'Offline for ${ref.watch(liveStatusProvider(fpstats?["lastLive"]))}'
                                            : 'Live for ${ref.watch(liveStatusProvider(fpstats?["started"]))}',
                                    style: TextStyle(
                                      color: offline
                                          ? Colors.grey[400]
                                          : Colors.red,
                                      fontSize: 14,
                                    ),
                                  ),
                                if (!isMrTechTips)
                                  Text(
                                    offline ? 'Offline' : 'Live',
                                    style: TextStyle(
                                      color: offline
                                          ? Colors.grey[400]
                                          : Colors.red,
                                      fontSize: 14,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Description
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              ClipRect(
                                child: SingleChildScrollView(
                                  physics: const NeverScrollableScrollPhysics(),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0),
                                    child: HtmlWidget(
                                      offline
                                          ? realCreatorInfo?.liveStream?.offline
                                                  ?.description ??
                                              realCreatorInfo
                                                  ?.liveStream?.description ??
                                              ''
                                          : realCreatorInfo
                                                  ?.liveStream?.description ??
                                              '',
                                      key: UniqueKey(),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (widget.compact)
                        Row(
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  isChat = true;
                                });
                              },
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.chat_bubble),
                                  Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 2)),
                                  Text('Live Chat'),
                                ],
                              ),
                            ),
                            if (isMrTechTips) const Spacer(),
                            if (isMrTechTips)
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    isWhenplane = true;
                                  });
                                },
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.flight),
                                    Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 2)),
                                    Text('Whenplane Info'),
                                  ],
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class LiveScreen extends ConsumerStatefulWidget {
  const LiveScreen({super.key, required this.channelName});
  final String channelName;

  @override
  ConsumerState<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends ConsumerState<LiveScreen> {
  bool isLoading = false;
  CreatorModelV3? res;

  @override
  void initState() {
    init();
    super.initState();
  }

  void init() async {
    res = await fpApiRequests.getCreator(urlname: widget.channelName).first;
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (fpWebsockets.connected) {
      fpWebsockets.disconnect();
    }
    return Scaffold(
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : MediaQuery.of(context).size.width < 800
              ? res != null
                  ? LiveVideoWidget(
                      creatorInfo: res!,
                      compact: true,
                    )
                  : const SizedBox.shrink()
              : res != null
                  ? ResizableWidget(
                      percentages: [0.75, 0.25],
                      constraints: [
                        null,
                        BoxConstraints(minWidth: 250, maxWidth: 425)
                      ],
                      children: [
                        LiveVideoWidget(
                          creatorInfo: res!,
                        ),
                        LiveChat(
                          liveId: res?.liveStream?.id ?? '',
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
    );
  }
}
