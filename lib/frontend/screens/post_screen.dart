// ignore_for_file: use_build_context_synchronously

import 'package:floaty/frontend/elements.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:floaty/providers/post_provider.dart';
import 'package:floaty/frontend/root.dart';
import 'package:floaty/backend/fpapi.dart';
import 'package:floaty/backend/definitions.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:fwfh_url_launcher/fwfh_url_launcher.dart';
import 'dart:math';
import 'package:floaty/frontend/widgets/media_player_widget.dart';
import 'package:floaty/services/media/media_player_service.dart';
import 'package:floaty/services/media/video_quality.dart';
import 'dart:convert';
import 'package:floaty/settings.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:floaty/backend/download_manager.dart';
import 'package:auto_size_text/auto_size_text.dart';

enum ScreenLayout { small, medium, wide }

class VideoDetailPage extends ConsumerStatefulWidget {
  const VideoDetailPage({super.key, required this.postId});
  final String postId;
  @override
  ConsumerState<VideoDetailPage> createState() => _VideoDetailPageState();
}

class _VideoDetailPageState extends ConsumerState<VideoDetailPage> {
  late String postId;
  late MediaPlayerService _mediaService;
  final _commentController = TextEditingController();
  final _focusNode = FocusNode();
  final _attachmentScrollController = ScrollController();
  late Future<Widget> _mediaContentFuture;
  int _currentLength = 0;
  final int _pageSize = 20;
  String fetchafter = '0';
  String sortBy = 'createdAt';
  String sortOrder = 'DESC';
  String? _selectedAttachmentId;
  bool text = false;
  bool isWan = false;
  String letsBeHonestItsLateTime = '';
  bool hundredpercentlate = false;
  String preShowRange = '';
  String preShowDuration = '';
  String mainShowRange = '';
  String mainShowDuration = '';
  String latenessString = '';
  String? mediaUrl;
  MediaType selectedMediaType = MediaType.video; // Default
  late MediaPlayerService mediaService;
  late MediaPlayerState mediaState;
  late List<PopupMenuEntry<String>> menuItems;

  final List<CommentModel> _comments = [];
  bool _isLoadingComments = false;
  bool _hasMoreComments = true;

  @override
  void initState() {
    super.initState();
    postId = widget.postId;
    _mediaContentFuture = Future(() async {
      // Wait for post to be loaded
      if (postId.isEmpty) {
        postId = mediaService.currentPostId ?? '';
      }
      while (ref
          .read(postProvider(
              postId.isEmpty ? mediaService.currentPostId ?? '' : postId))
          .isLoading) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return _buildMediaContent();
    });

    _commentController.addListener(_updateCharCount);

    _loadComments();
  }

  //whenplane intergration
  //100% not converted from the browser extension
  String? extractShowDate(String title) {
    final titleRegex = RegExp(
        r" - WAN Show ((January|February|March|April|May|June|July|August|September|October|November|December) \d{1,2}, \d{4})");
    final match = titleRegex.firstMatch(title);

    if (match != null) {
      String dateString =
          match.group(1)!; // Extracted date as "February 14, 2025"

      // Parse into DateTime object
      DateTime parsedDate = DateFormat("MMMM d, yyyy").parse(dateString);

      // Convert to YYYY/MM/DD format
      return DateFormat("yyyy/MM/dd").format(parsedDate);
    }

    return null;
  }

  String formatDate(String rawDate) {
    final date = DateTime.parse(rawDate);
    return "${date.year}/${addZero(date.month)}/${addZero(date.day)}";
  }

  String addZero(int n) => n > 9 ? "$n" : "0$n";

  String convertTimeFormat(String date1, String date2, bool length) {
    DateTime start = DateTime.parse(date1).toUtc();
    DateTime end = DateTime.parse(date2).toUtc();

    if (length) {
      return formatDuration(end.difference(start));
    } else {
      return "${formatTime(start)} - ${formatTime(end)}";
    }
  }

  String formatTime(DateTime date) {
    return "${addZero(date.hour)}:${addZero(date.minute)}";
  }

  String formatDuration(Duration duration) {
    return [
      if (duration.inHours > 0) "${duration.inHours}h",
      if (duration.inMinutes.remainder(60) > 0)
        "${duration.inMinutes.remainder(60)}m",
      if (duration.inSeconds.remainder(60) > 0)
        "${duration.inSeconds.remainder(60)}s"
    ].join(" ");
  }

  @override
  void dispose() {
    Future.microtask(() async {
      if (mediaService.isPlaying) {
        mediaService.changeState(MediaPlayerState.mini);
      }
    });

    Future.microtask(() async {
      if (selectedMediaType == MediaType.video ||
          selectedMediaType == MediaType.audio) {
        fpApiRequests.progress(
          _selectedAttachmentId ?? '',
          _mediaService.currentPosition.inSeconds,
          selectedMediaType.name,
        );
      }
    });
    _commentController.removeListener(_updateCharCount);
    _commentController.dispose();
    _focusNode.dispose();
    _attachmentScrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(VideoDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (postId != widget.postId) {
      postId = widget.postId;
      setState(() {
        _mediaContentFuture = Future(() async {
          return _buildMediaContent();
        });
      });
    }
  }

  void _updateCharCount() {
    setState(() {
      _currentLength = _commentController.text.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    _mediaService = ref.watch(mediaPlayerServiceProvider.notifier);
    final postState = ref.watch(postProvider(widget.postId));
    menuItems = ref.watch(menuItemsProvider);

    return postState.isLoading
        ? const Center(child: CircularProgressIndicator())
        : Scaffold(
            body: RefreshIndicator(
            onRefresh: () async {
              _loadComments();
            },
            child: SingleChildScrollView(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 1000;
                  final isMedium = constraints.maxWidth > 700 &&
                      constraints.maxWidth <= 1000;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: text == false ? double.infinity : 0,
                        height: text == false
                            ? min(
                                constraints.maxWidth * 9 / 16,
                                MediaQuery.of(context).size.height - 250,
                              )
                            : 0,
                        decoration: BoxDecoration(
                          color: Colors.black,
                        ),
                        child: FutureBuilder<Widget>(
                          future: _mediaContentFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator(
                                color: Colors.white,
                              ));
                            } else if (snapshot.hasError) {
                              return Center(
                                  child: Text('Error: ${snapshot.error}'));
                            } else {
                              return snapshot.data!;
                            }
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: isWide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: _buildMainContent(constraints),
                                  ),
                                  const SizedBox(width: 24),
                                  _buildRecommendedSection(constraints,
                                      layout: ScreenLayout.wide),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildMainContent(constraints),
                                  _buildRecommendedSection(
                                    constraints,
                                    layout: isMedium
                                        ? ScreenLayout.medium
                                        : ScreenLayout.small,
                                  ),
                                ],
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ));
  }

  Future<Widget> _buildMediaContent() async {
    mediaService = ref.read(mediaPlayerServiceProvider.notifier);
    mediaState = ref.read(mediaPlayerServiceProvider);
    List<Map<String, dynamic>> textTrack = [];
    try {
      final postState = ref.watch(postProvider(widget.postId));
      final post = postState.post;
      if (post == null) {
        return const Center(
            child: CircularProgressIndicator(
          color: Colors.white,
        ));
      }

      int progress = 0;

      // If no attachments, show no content
      if (post.attachmentOrder.isEmpty) {
        text = true;
        return const SizedBox.shrink();
      }

      // If no attachment found, default to first
      _selectedAttachmentId ??= post.attachmentOrder.first;

      // Find the selected attachment
      dynamic selectedAttachment;

      // Search through video attachments
      for (final video
          in ref.read(postProvider(widget.postId)).post!.videoAttachments) {
        if (video.id == _selectedAttachmentId) {
          selectedAttachment = video;
          selectedMediaType = MediaType.video;
          break;
        }
      }

      // If not found, search through audio attachments
      if (selectedAttachment == null) {
        for (final audio
            in ref.read(postProvider(widget.postId)).post!.audioAttachments) {
          if (audio.id == _selectedAttachmentId) {
            selectedAttachment = audio;
            selectedMediaType = MediaType.audio;
            break;
          }
        }
      }

      // If not found, search through picture attachments
      if (selectedAttachment == null) {
        for (final picture
            in ref.read(postProvider(widget.postId)).post!.pictureAttachments) {
          if (picture.id == _selectedAttachmentId) {
            selectedAttachment = picture;
            selectedMediaType = MediaType.image;
            break;
          }
        }
      }

      // Determine media URL based on attachment type
      List<VideoQuality>? qualities;
      if (selectedAttachment != null) {
        if (selectedAttachment is VideoAttachmentModel) {
          final res = await fpApiRequests.getDelivery(
              'onDemand', _selectedAttachmentId!);
          final decoded = jsonDecode(res);
          qualities = await fetchVideoQualities(decoded, true);

          final prores =
              await fpApiRequests.getContent('video', _selectedAttachmentId!);
          final decodedpro = jsonDecode(prores);
          if (decodedpro['progress'] != null) {
            progress = decodedpro['progress'];
          }

          textTrack = (decodedpro['textTracks'] as List?)
                  ?.cast<Map<String, dynamic>>() ??
              [];

          // Determine the default quality using the Settings class
          String? preferredQuality =
              await Settings().getKey('preferred_quality');
          if (preferredQuality.isNotEmpty) {
            VideoQuality? selectedQuality = qualities.firstWhere(
              (quality) => quality.label == preferredQuality,
              orElse: () => qualities!.first, // Fallback to the first quality
            );
            mediaUrl = selectedQuality.url; // Just use the URL directly
          } else {
            // Check for 1080p quality
            VideoQuality? defaultQuality = qualities.firstWhere(
              (quality) => quality.label == '1080p',
              orElse: () => qualities!
                  .first, // Fallback to the first quality if 1080p doesn't exist
            );
            mediaUrl = defaultQuality.url;
          }
        } else if (selectedAttachment is AudioAttachmentModel) {
          final res = await fpApiRequests.getDelivery(
              'onDemand', _selectedAttachmentId!);
          final decoded = jsonDecode(res);
          qualities = await fetchVideoQualities(decoded, false);

          final prores =
              await fpApiRequests.getContent('audio', _selectedAttachmentId!);
          final decodedpro = jsonDecode(prores);
          if (decodedpro['progress'] != null) {
            progress = decodedpro['progress'];

            textTrack = (decodedpro['textTracks'] as List?)
                    ?.cast<Map<String, dynamic>>() ??
                [];
          }

          // Determine the default quality using the Settings class
          String? preferredQuality =
              await Settings().getKey('preferred_quality');
          if (preferredQuality.isNotEmpty) {
            VideoQuality? selectedQuality = qualities.firstWhere(
              (quality) => quality.label == preferredQuality,
              orElse: () => qualities!.first, // Fallback to the first quality
            );
            mediaUrl = selectedQuality.url; // Just use the URL directly
          } else {
            // Check for 1080p quality
            VideoQuality? defaultQuality = qualities.firstWhere(
                (quality) => quality.label == '1080p',
                orElse: () => qualities!
                    .first // Fallback to the first quality if 1080p doesn't exist
                );
            mediaUrl = defaultQuality.url;
          }
        } else if (selectedAttachment is PictureAttachmentModel) {
          final res =
              await fpApiRequests.getContent('picture', _selectedAttachmentId!);
          final decoded = jsonDecode(res);
          mediaUrl = decoded['imageFiles'][0]['path'];
        }
      }

      // If multiple attachments, add navigation
      if (ref.read(postProvider(widget.postId)).post!.attachmentOrder.length >
          1) {
        return Stack(
          children: [
            MediaPlayerWidget(
              contextBuild: context,
              mediaUrl: mediaUrl!,
              mediaType: selectedMediaType,
              attachment: selectedAttachment,
              qualities:
                  selectedMediaType == MediaType.image ? null : qualities,
              initialState: MediaPlayerState.main,
              startFrom: progress,
              textTracks: textTrack.isEmpty ? null : textTrack,
              live: false,
              title: ref.read(postProvider(widget.postId)).post?.title ??
                  'Unknown Title',
              artist:
                  ref.read(postProvider(widget.postId)).post?.channel?.title ??
                      'Unknown Creator',
              postId: widget.postId,
              artworkUrl:
                  ref.read(postProvider(widget.postId)).post!.thumbnail?.path ??
                      '',
            ),
            // Left navigation arrow
            Positioned(
              left: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  icon: const Icon(Icons.chevron_left,
                      color: Colors.white, size: 32),
                  onPressed: () {
                    final currentIndex = ref
                        .read(postProvider(widget.postId))
                        .post!
                        .attachmentOrder
                        .indexOf(_selectedAttachmentId!);
                    final prevIndex = (currentIndex -
                            1 +
                            ref
                                .read(postProvider(widget.postId))
                                .post!
                                .attachmentOrder
                                .length) %
                        ref
                            .read(postProvider(widget.postId))
                            .post!
                            .attachmentOrder
                            .length;
                    setState(() {
                      _selectedAttachmentId = ref
                          .read(postProvider(widget.postId))
                          .post!
                          .attachmentOrder[prevIndex];
                      _mediaContentFuture =
                          _buildMediaContent(); // Rebuild media content
                    });
                  },
                ),
              ),
            ),
            // Right navigation arrow
            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  icon: const Icon(Icons.chevron_right,
                      color: Colors.white, size: 32),
                  onPressed: () {
                    final currentIndex = ref
                        .read(postProvider(widget.postId))
                        .post!
                        .attachmentOrder
                        .indexOf(_selectedAttachmentId!);
                    final nextIndex = (currentIndex + 1) %
                        ref
                            .read(postProvider(widget.postId))
                            .post!
                            .attachmentOrder
                            .length;
                    setState(() {
                      _selectedAttachmentId = ref
                          .read(postProvider(widget.postId))
                          .post!
                          .attachmentOrder[nextIndex];
                      _mediaContentFuture =
                          _buildMediaContent(); // Rebuild media content
                    });
                  },
                ),
              ),
            ),
          ],
        );
      }

      // If only one attachment
      return MediaPlayerWidget(
        contextBuild: context,
        mediaUrl: mediaUrl!,
        live: false,
        mediaType: selectedMediaType,
        attachment: selectedAttachment,
        qualities:
            selectedMediaType == MediaType.video && selectedAttachment != null
                ? qualities
                : null,
        initialState: MediaPlayerState.main,
        startFrom: progress,
        textTracks: textTrack.isEmpty ? null : textTrack,
        title: ref.read(postProvider(widget.postId)).post?.title ??
            'Unknown Title',
        artist: ref.read(postProvider(widget.postId)).post?.channel?.title ??
            'Unknown Creator',
        postId: widget.postId,
        artworkUrl:
            ref.read(postProvider(widget.postId)).post!.thumbnail?.path ?? '',
      );
    } catch (e) {
      return const Center(
          child: CircularProgressIndicator(
        color: Colors.white,
      ));
    }
  }

  Future<List<VideoQuality>> fetchVideoQualities(
      Map<String, dynamic> deliveryResponse, bool video) async {
    List<VideoQuality> qualities = [];

    // Extract base URL from origins
    String baseUrl = deliveryResponse['groups'][0]['origins'][0]['url'];

    // Access the groups and their variants
    for (var group in deliveryResponse['groups']) {
      for (var variant in group['variants']) {
        // Check if the variant is enabled
        if (variant['enabled']) {
          if (video = true) {
            qualities.add(VideoQuality(
              url:
                  '$baseUrl${variant['url']}', // Concatenate base URL with the variant URL
              label: variant['label'],
            ));
          } else {
            qualities.add(VideoQuality(
              url:
                  '$baseUrl${variant['url']}', // Concatenate base URL with the variant URL
              label: variant['label'],
            ));
          }
        }
      }
    }

    return qualities;
  }

  String _getSortDisplayText() {
    if (sortBy == 'createdAt' && sortOrder == 'DESC') {
      return 'newest';
    } else if (sortBy == 'createdAt' && sortOrder == 'ASC') {
      return 'oldest';
    } else if (sortBy == 'score' && sortOrder == 'DESC') {
      return 'highest_rated';
    } else if (sortBy == 'score' && sortOrder == 'ASC') {
      return 'lowest_rated';
    } else {
      return 'newest';
    }
  }

// here you see wasted time because floatplane download api v3 doesnt actually work even if
// you fix the urls not matching because the token v3 generates is invalid

  // String convertV3ToV2(String v3Url) {  //   Uri uri = Uri.parse(v3Url);
  //   String? token = uri.queryParameters['token'];
  //   String? expires = uri.queryParameters['expires'];
  //   String basePath =
  //       uri.pathSegments.take(uri.pathSegments.length - 1).join('/');
  //   String fileName = uri.pathSegments[uri.pathSegments.length - 2];
  //   String v2Url =
  //       '${uri.scheme}://${uri.host}/$basePath/$fileName.mp4?token=$token&expires=$expires';
  //   return v2Url;
  // }

  List<Widget> _buildInteractionButtons() {
    final postState = ref.watch(postProvider(widget.postId));
    final post = postState.post;
    final downloadNotifier = ref.read(downloadOptionsProvider.notifier);

    // Show download button if there's a media attachment
    final hasMediaAttachment = post != null &&
        (post.videoAttachments.isNotEmpty ||
            post.audioAttachments.isNotEmpty ||
            post.pictureAttachments.isNotEmpty);

    Future<void> showDownloadDialog() async {
      downloadNotifier.reset();
      if (selectedMediaType == MediaType.image) {
        downloadNotifier.setOptions([
          DownloadOption(url: mediaUrl!, label: 'PNG'),
        ]);
      } else {
        downloadNotifier.setLoading();
        final data = await fpApiRequests.getDeliveryv2(
            'download', _selectedAttachmentId ?? '');

        if (data != 'Response StatusCode: 429, Body: error code: 1015') {
          final dedata = jsonDecode(data);
          final options = <DownloadOption>[];
          String baseUrl = dedata['cdn'];

          for (var quality in dedata['resource']['data']['qualityLevels']) {
            String qualityName = quality['name'];
            String qualityLabel = quality['label'];

            String videoFile = dedata['resource']['data']['qualityLevelParams']
                [qualityName]['1'];
            String token = dedata['resource']['data']['qualityLevelParams']
                [qualityName]['2'];

            String resourceUri = dedata['resource']['uri']
                .replaceFirst('{qualityLevelParams.1}', videoFile)
                .replaceFirst('{qualityLevelParams.2}', token);
            String curl = '$baseUrl$resourceUri';

            options.add(DownloadOption(url: curl, label: qualityLabel));
          }
          downloadNotifier.setOptions(options);
        } else {
          downloadNotifier.setError('Rate limit exceeded');
        }
      }

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Download Options'),
          content: SizedBox(
            width: 300,
            child: Consumer(
              builder: (context, ref, _) {
                final state = ref.watch(downloadOptionsProvider);

                if (state.isLoading) {
                  return const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (state.error != null) {
                  return ErrorScreen(message: state.error!);
                }

                return SizedBox(
                  height: 200,
                  child: ListView.builder(
                    itemCount: state.options.length,
                    itemBuilder: (context, index) {
                      final option = state.options[index];
                      return ListTile(
                        dense: true,
                        title: Text(option.label),
                        onTap: () async {
                          Navigator.of(context).pop();

                          // Check permissions before starting download
                          final hasPermissions = await DownloadManager()
                              .checkAndRequestPermissions();
                          if (!hasPermissions) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Permission denied for downloads')),
                              );
                            }
                            return;
                          }

                          final task = DownloadTask(
                            url: option.url,
                            filename:
                                '${mediaService.currentAttachment.title} (${option.label})${mediaService.currentAttachment is VideoAttachmentModel ? '.mp4' : mediaService.currentAttachment is AudioAttachmentModel ? '.mp3' : '.png'}',
                            baseDirectory: BaseDirectory.applicationDocuments,
                            updates: Updates.statusAndProgress,
                            requiresWiFi: true,
                            headers: {
                              'User-Agent': 'FloatyClient/1.0.0, CFNetwork',
                            },
                          );

                          try {
                            await FileDownloader().enqueue(task);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'Started downloading ${option.label}')),
                              );
                            }
                            // Move file to downloads after completion
                            await DownloadManager().moveToDownloads(task);
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Failed to start download')),
                              );
                            }
                          }
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    }

    return [
      if (hasMediaAttachment)
        IconButton(
          icon: const Icon(Icons.download, color: Colors.white),
          onPressed: showDownloadDialog,
        ),
      const SizedBox(width: 5),
      TextButton.icon(
        style: TextButton.styleFrom(
          splashFactory: InkRipple.splashFactory,
          overlayColor: Colors.grey[800],
        ),
        icon: AnimatedTheme(
          data: Theme.of(context).copyWith(
            iconTheme: IconThemeData(
              color: postState.isLiked
                  ? Theme.of(context).colorScheme.primary
                  : Colors.white,
            ),
          ),
          duration: const Duration(milliseconds: 200),
          child: const Icon(Icons.thumb_up_outlined),
        ),
        label: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            color: postState.isLiked
                ? Theme.of(context).colorScheme.primary
                : Colors.white,
            fontWeight: FontWeight.bold,
          ),
          child: Text('${postState.likeCount}'),
        ),
        onPressed: () =>
            ref.read(postProvider(widget.postId).notifier).toggleLike(),
      ),
      const SizedBox(width: 5),
      TextButton.icon(
        style: TextButton.styleFrom(
          splashFactory: InkRipple.splashFactory,
          overlayColor: Colors.grey[800],
        ),
        icon: AnimatedTheme(
          data: Theme.of(context).copyWith(
            iconTheme: IconThemeData(
              color: postState.isDisliked
                  ? Theme.of(context).colorScheme.primary
                  : Colors.white,
            ),
          ),
          duration: const Duration(milliseconds: 200),
          child: const Icon(Icons.thumb_down_outlined),
        ),
        label: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            color: postState.isDisliked
                ? Theme.of(context).colorScheme.primary
                : Colors.white,
            fontWeight: FontWeight.bold,
          ),
          child: Text('${postState.dislikeCount}'),
        ),
        onPressed: () =>
            ref.read(postProvider(widget.postId).notifier).toggleDislike(),
      ),
    ];
  }

  Widget _buildMainContent(BoxConstraints constraints) {
    final postState = ref.watch(postProvider(widget.postId));
    final post = postState.post;
    if (post == null) return const SizedBox.shrink();

    Future(() => rootLayoutKey.currentState?.setAppBar(Text(post.title ?? '')));

    final isSmall = constraints.maxWidth <= 700;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        if (isSmall)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AutoSizeText(
                post.title ?? 'Unknown Title',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                stepGranularity: 0.25,
                textScaleFactor: 0.75,
              ),
              post.tags.isNotEmpty == true
                  ? Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: post.tags
                          .map((tag) => Text(
                                '#$tag',
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary),
                              ))
                          .toList(),
                    )
                  : const SizedBox.shrink(),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _buildInteractionButtons(),
              ),
            ],
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.title ?? 'Unknown Title',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    if (post.tags.isNotEmpty == true)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: post.tags
                            .map((tag) => Text(
                                  '#$tag',
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                                ))
                            .toList(),
                      ),
                  ],
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: _buildInteractionButtons(),
              ),
            ],
          ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () {
            if (post.creator?.urlname == post.channel?.urlname) {
              context.go('/channel/${post.creator?.urlname}');
            } else {
              context.go(
                  '/channel/${post.creator?.urlname}/${post.channel?.urlname}');
            }
          },
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage:
                    CachedNetworkImageProvider(post.channel?.icon?.path ?? ''),
                radius: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.channel?.title ?? 'Unknown Creator',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      post.releaseDate != null
                          ? 'Posted ${DateFormat('MMMM dd, yyyy').format(post.releaseDate!)}'
                          : '',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // ignore: unnecessary_null_comparison
        if (post != null && (post.attachmentOrder.length) > 1) ...[
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints:
                const BoxConstraints(maxHeight: 98), // Increased height
            child: Scrollbar(
              controller: _attachmentScrollController,
              thumbVisibility: true,
              radius: const Radius.circular(5),
              interactive: true, // Allow interactive scrollbar
              child: Padding(
                padding:
                    const EdgeInsets.only(bottom: 12), // More bottom padding
                child: SingleChildScrollView(
                  controller: _attachmentScrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                    child: Row(
                      children: [
                        ...List.generate(post.attachmentOrder.length, (index) {
                          final id = post.attachmentOrder[index];
                          Widget? attachmentWidget;

                          // Find the attachment by ID
                          for (final video in post.videoAttachments) {
                            if (video.id == id) {
                              attachmentWidget = StateCard(
                                title: video.title,
                                subtitle: "Video",
                                thumbnail: Image.network(
                                  video.thumbnail.path ?? '',
                                  fit: BoxFit.cover,
                                ),
                                topIcon: const Icon(
                                  Icons.videocam,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                isViewing: false,
                                isSelected: id == _selectedAttachmentId,
                                onTap: () {
                                  setState(() {
                                    _selectedAttachmentId = id;
                                    _mediaContentFuture =
                                        _buildMediaContent(); // Rebuild media content
                                  });
                                },
                              );
                              break;
                            }
                          }

                          for (final audio in post.audioAttachments) {
                            if (audio.id == id) {
                              attachmentWidget = StateCard(
                                title: audio.title,
                                subtitle: "Audio",
                                thumbnail: Container(
                                  color: Colors.grey[900],
                                  child: const Center(
                                    child: Icon(
                                      Icons.audiotrack,
                                      color: Colors.white,
                                      size: 48,
                                    ),
                                  ),
                                ),
                                topIcon: const Icon(
                                  Icons.audiotrack,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                isViewing: false,
                                isSelected: id == _selectedAttachmentId,
                                onTap: () {
                                  setState(() {
                                    _selectedAttachmentId = id;
                                    _mediaContentFuture =
                                        _buildMediaContent(); // Rebuild media content
                                  });
                                },
                              );
                              break;
                            }
                          }

                          for (final picture in post.pictureAttachments) {
                            if (picture.id == id) {
                              attachmentWidget = StateCard(
                                title: picture.title,
                                subtitle: "Picture",
                                thumbnail: Image.network(
                                  picture.thumbnail.path ?? '',
                                  fit: BoxFit.cover,
                                ),
                                topIcon: const Icon(
                                  Icons.image,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                isViewing: false,
                                isSelected: id == _selectedAttachmentId,
                                onTap: () {
                                  setState(() {
                                    _selectedAttachmentId = id;
                                    _mediaContentFuture =
                                        _buildMediaContent(); // Rebuild media content
                                  });
                                },
                              );
                              break;
                            }
                          }

                          for (final gallery in post.galleryAttachments) {
                            if (gallery.id == id) {
                              attachmentWidget = StateCard(
                                title: gallery.title,
                                subtitle: "Gallery",
                                thumbnail: Image.network(
                                  gallery.thumbnail.path ?? '',
                                  fit: BoxFit.cover,
                                ),
                                topIcon: const Icon(
                                  Icons.photo_library,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                isViewing: false,
                                isSelected: id == _selectedAttachmentId,
                                onTap: () {
                                  setState(() {
                                    _selectedAttachmentId = id;
                                    _mediaContentFuture =
                                        _buildMediaContent(); // Rebuild media content
                                  });
                                },
                              );
                              break;
                            }
                          }

                          if (attachmentWidget == null) {
                            return const SizedBox.shrink();
                          }

                          return Padding(
                            padding: EdgeInsets.only(
                              right: index == post.attachmentOrder.length - 1
                                  ? 0
                                  : 16,
                            ),
                            child: attachmentWidget,
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (post.text != null && post.text!.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: postState.isExpanded ? double.infinity : 48.0,
                    ),
                    child: ClipRect(
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: HtmlWidget(
                            post.text ?? '',
                            key: UniqueKey(),
                            factoryBuilder: () => _PostWidgetFactory(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (!postState.isExpanded)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 24.0,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Theme.of(context)
                                  .scaffoldBackgroundColor
                                  .withAlpha(0),
                              Theme.of(context).scaffoldBackgroundColor,
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (post.text?.length != null && post.text!.length > 25)
                Center(
                  child: TextButton(
                    onPressed: () => ref
                        .read(postProvider(widget.postId).notifier)
                        .toggleExpanded(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          postState.isExpanded ? 'Show Less' : 'Show More',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        Icon(
                          postState.isExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        if (postState.isWan)
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 325),
                child: ShowInfoCard(
                    preshowtime: postState.preShowRange ?? '',
                    mainshowtime: postState.mainShowRange ?? '',
                    preshowlength: postState.preShowDuration ?? '',
                    mainshowlength: postState.mainShowDuration ?? '',
                    lateness: postState.hundredpercentlate
                        ? '${postState.letsBeHonestItsLateTime} ${postState.latenessString}'
                        : postState.letsBeHonestItsLateTime ?? '',
                    late: postState.hundredpercentlate),
              ),
            ),
          ),
        Divider(color: Colors.grey[800]),
        Row(
          children: [
            if (rootLayoutKey.currentState?.user?.profileImage?.path != null)
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey[800],
                backgroundImage: NetworkImage(
                  rootLayoutKey.currentState?.user?.profileImage?.path ?? '',
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextField(
                    controller: _commentController,
                    onChanged: (value) {
                      setState(() {
                        _currentLength = value.length;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Write a Comment',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey[800]!),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          Text(
                            '$_currentLength/1500',
                            style: TextStyle(
                              color: _currentLength > 1500
                                  ? Colors.red
                                  : Colors.grey[400],
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _commentController.clear();
                                _currentLength = 0;
                              });
                            },
                            style: TextButton.styleFrom(
                              splashFactory: InkRipple.splashFactory,
                              overlayColor: Colors.grey[800],
                            ),
                            child: const Text(
                              'CANCEL',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed:
                                _currentLength >= 3 && _currentLength <= 1500
                                    ? () async {
                                        final text = _commentController.text;
                                        _commentController.clear();
                                        final comment = await fpApiRequests
                                            .comment(post.id ?? '', text);
                                        if (comment != null) {
                                          setState(() {
                                            _comments.insert(0, comment);
                                          });
                                        }
                                      }
                                    : null,
                            style: TextButton.styleFrom(
                              splashFactory: InkRipple.splashFactory,
                              overlayColor: Colors.grey[800],
                            ),
                            child: Text(
                              'COMMENT',
                              style: TextStyle(
                                color: _currentLength >= 3 &&
                                        _currentLength <= 1500
                                    ? Colors.white
                                    : Colors.grey[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    crossFadeState: _currentLength > 0
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 200),
                  ),
                ],
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              '${post.comments ?? 0} Comments',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width: 6),
            DropdownButton<String>(
              value: _getSortDisplayText(),
              hint: const Text('Sort Comments',
                  style: TextStyle(color: Colors.white)),
              dropdownColor: Colors.grey[800],
              icon: const Icon(Icons.sort, color: Colors.white),
              underline: Container(),
              style: const TextStyle(color: Colors.white),
              items: [
                DropdownMenuItem(
                  value: 'newest',
                  child: const Text('Newest First'),
                  onTap: () {
                    sortBy = 'createdAt';
                    sortOrder = 'DESC';
                    fetchafter = '0';
                    _loadComments();
                  },
                ),
                DropdownMenuItem(
                  value: 'oldest',
                  child: const Text('Oldest First'),
                  onTap: () {
                    sortBy = 'createdAt';
                    sortOrder = 'ASC';
                    fetchafter = '0';
                    _loadComments();
                  },
                ),
                DropdownMenuItem(
                  value: 'highest_rated',
                  child: const Text('Highest Rated'),
                  onTap: () {
                    sortBy = 'score';
                    sortOrder = 'DESC';
                    fetchafter = '0';
                    _loadComments();
                  },
                ),
                DropdownMenuItem(
                  value: 'lowest_rated',
                  child: const Text('Lowest Rated'),
                  onTap: () {
                    sortBy = 'score';
                    sortOrder = 'ASC';
                    fetchafter = '0';
                    _loadComments();
                  },
                ),
              ],
              onChanged: (String? value) {},
            ),
          ],
        ),
        Column(
          children: [
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _comments.length,
              itemBuilder: (context, index) {
                return CommentHolder(
                  key: ValueKey(_comments[index].id),
                  comment: _comments[index],
                  content: post,
                );
              },
            ),
            if (_comments.isEmpty)
              const Center(
                child: Text("No comments found."),
              ),
            if (_hasMoreComments)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: ElevatedButton(
                  onPressed: _isLoadingComments
                      ? null
                      : () async {
                          setState(() {
                            _isLoadingComments = true;
                          });
                          try {
                            dynamic items;
                            if (fetchafter != '0') {
                              items = await fpApiRequests.getComments(
                                widget.postId,
                                _pageSize,
                                sortBy,
                                sortOrder,
                                fetchAfter: fetchafter,
                              );
                            } else {
                              items = await fpApiRequests.getComments(
                                widget.postId,
                                _pageSize,
                                sortBy,
                                sortOrder,
                              );
                            }
                            if (!mounted) return;

                            setState(() {
                              _comments.addAll(items);
                              _hasMoreComments = items.length >= _pageSize;
                              if (items.isNotEmpty) {
                                fetchafter = items.last.id;
                              }
                              _isLoadingComments = false;
                            });
                          } catch (error) {
                            if (mounted) {
                              setState(() {
                                _isLoadingComments = false;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'An error occurred loading comments'),
                                ),
                              );
                            }
                          }
                        },
                  child: _isLoadingComments
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Load More Comments'),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _loadComments() async {
    setState(() {
      _comments.clear();
      _hasMoreComments = true;
      fetchafter = '0';
    });
    try {
      dynamic items;
      if (fetchafter != '0') {
        items = await fpApiRequests.getComments(
          widget.postId,
          _pageSize,
          sortBy,
          sortOrder,
          fetchAfter: fetchafter,
        );
      } else {
        items = await fpApiRequests.getComments(
          widget.postId,
          _pageSize,
          sortBy,
          sortOrder,
        );
      }
      if (!mounted) return;

      setState(() {
        _comments.addAll(items);
        _hasMoreComments = items.length >= _pageSize;
        if (items.isNotEmpty) {
          fetchafter = items.last.id;
        }
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred loading comments'),
          ),
        );
      }
    }
  }

  Widget _buildRecommendedSection(BoxConstraints constraints,
      {required ScreenLayout layout}) {
    final width = layout == ScreenLayout.wide ? 300.0 : constraints.maxWidth;
    final childAspectRatio = constraints.maxWidth <= 450 ? 1.2 : 1.175;
    final padding = constraints.maxWidth <= 450 ? 4.0 : 2.0;

    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 16.0, bottom: 8.0),
            child: Text(
              'Recommended',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const ClampingScrollPhysics(),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent:
                  constraints.maxWidth <= 450 ? constraints.maxWidth : 300,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
              childAspectRatio: childAspectRatio,
            ),
            itemCount:
                ref.read(postProvider(widget.postId)).recommendedPosts.length,
            itemBuilder: (context, index) {
              final post =
                  ref.read(postProvider(widget.postId)).recommendedPosts[index];
              return Padding(
                padding: EdgeInsets.all(padding),
                child: BlogPostCard(post,
                    response: ref
                        .read(postProvider(widget.postId))
                        .progressMap[post.id]),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PostWidgetFactory extends WidgetFactory with UrlLauncherFactory {}
