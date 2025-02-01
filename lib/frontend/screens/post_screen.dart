import 'package:floaty/frontend/elements.dart';
import 'package:flutter/material.dart';
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
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:floaty/frontend/widgets/media_player_widget.dart';
import 'package:floaty/services/media/media_player_service.dart';
import 'package:floaty/services/media/video_quality.dart';
import 'dart:convert';
import 'package:floaty/settings.dart';

enum ScreenLayout { small, medium, wide }

class VideoDetailPage extends StatefulWidget {
  const VideoDetailPage({super.key, required this.postId});
  final String postId;
  @override
  State<VideoDetailPage> createState() => _VideoDetailPageState();
}

class _VideoDetailPageState extends State<VideoDetailPage> {
  late String postId;
  ContentPostV3Response? _post;
  StreamSubscription<ContentPostV3Response>? _postSubscription;
  bool isLoading = true;
  bool _isLiked = false;
  bool _isDisliked = false;
  int _likeCount = 0;
  int _dislikeCount = 0;
  bool _isExpanded = false;
  List<BlogPostModelV3> recommendedPosts = [];
  Map<String, GetProgressResponse> progressMap = {};
  final PagingController<int, CommentModel> _pagingController =
      PagingController(firstPageKey: 0);
  final int _pageSize = 20;
  String fetchafter = '0';
  String sortBy = 'createdAt';
  String sortOrder = 'DESC';
  final _commentController = TextEditingController();
  final _focusNode = FocusNode();
  int _currentLength = 0;
  String? _selectedAttachmentId;
  final _attachmentScrollController = ScrollController();
  late Future<Widget> _mediaContentFuture;
  bool text = false;

  @override
  void initState() {
    super.initState();
    postId = widget.postId;
    _mediaContentFuture = Future(() async {
      // Wait for post details to be loaded
      await _getPostDetails();
      return _buildMediaContent();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setAppTitle();
    });
    _commentController.addListener(_updateCharCount);

    _pagingController.addPageRequestListener((pageKey) {
      _fetchComments(pageKey);
    });
  }

  Future<void> _getPostDetails() async {
    // Create a completer to wait for the post details
    final completer = Completer<void>();
    bool isCompleted = false;

    _postSubscription = FPApiRequests().getBlogPost(postId).listen(
      (post) {
        if (!isCompleted) {
          setState(() {
            _post = post;
            isLoading = false;
            if (post.title != null) {
              rootLayoutKey.currentState?.setAppBar(Text(post.title!));
            }
            _isLiked = post.userInteraction.contains("like");
            _isDisliked = post.userInteraction.contains("dislike");
            _likeCount = post.likes ?? 0;
            _dislikeCount = post.dislikes ?? 0;
            if (_post!.attachmentOrder.isNotEmpty) {
              _selectedAttachmentId = _post!.attachmentOrder.first;
            }
          });
          isCompleted = true;
          completer.complete();
          isLoading = false;
        }
      },
      onError: (error) {
        if (!isCompleted) {
          setState(() {
            isLoading = false;
          });
          isCompleted = true;
          completer.completeError(error);
        }
      },
    );

    await completer.future;

    final dynamic recommended = await FPApiRequests().getRecommended(postId);
    setState(() {
      recommendedPosts = recommended;
    });
    final List<String> postIds = recommendedPosts
        .where((post) => post.id != null)
        .map((post) => post.id!)
        .toList();
    final dynamic progress = await FPApiRequests().getVideoProgress(postIds);
    progressMap = {};
    if (progress is List) {
      for (var progress in progress) {
        if (progress is GetProgressResponse && progress.id != null) {
          progressMap[progress.id!] = progress;
        }
      }
    }
  }

  void setAppTitle() {
    rootLayoutKey.currentState?.setAppBar(const Text('Loading...'));
  }

  @override
  void dispose() {
    _postSubscription?.cancel();
    _pagingController.dispose();
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
      _getPostDetails();
      setState(() {
        _mediaContentFuture = Future(() async {
          // Wait for post details to be loaded
          await _getPostDetails();
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
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : Scaffold(
            body: SingleChildScrollView(
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
                          color: Colors.grey.shade800,
                        ),
                        child: FutureBuilder<Widget>(
                          future: _mediaContentFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            } else if (snapshot.hasError) {
                              return Center(
                                  child: Text('Error: ${snapshot.error}'));
                            } else {
                              return snapshot.data!; // Return the built widget
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
          );
  }

  Future<Widget> _buildMediaContent() async {
    if (_post == null) {
      return const Center(child: CircularProgressIndicator());
    }

    int progress = 0;

    // If no attachments, show no content
    if (_post!.attachmentOrder.isEmpty) {
      text = true;
      return const SizedBox.shrink();
    }

    // If no attachment found, default to first
    _selectedAttachmentId ??= _post!.attachmentOrder.first;

    // Find the selected attachment
    dynamic selectedAttachment;
    MediaType selectedMediaType = MediaType.video; // Default

    // Search through video attachments
    for (final video in _post!.videoAttachments) {
      if (video.id == _selectedAttachmentId) {
        selectedAttachment = video;
        selectedMediaType = MediaType.video;
        break;
      }
    }

    // If not found, search through audio attachments
    if (selectedAttachment == null) {
      for (final audio in _post!.audioAttachments) {
        if (audio.id == _selectedAttachmentId) {
          selectedAttachment = audio;
          selectedMediaType = MediaType.audio;
          break;
        }
      }
    }

    // If not found, search through picture attachments
    if (selectedAttachment == null) {
      for (final picture in _post!.pictureAttachments) {
        if (picture.id == _selectedAttachmentId) {
          selectedAttachment = picture;
          selectedMediaType = MediaType.image;
          break;
        }
      }
    }

    // Determine media URL based on attachment type
    String? mediaUrl;
    List<VideoQuality>? qualities;
    if (selectedAttachment != null) {
      if (selectedAttachment is VideoAttachmentModel) {
        final res = await FPApiRequests()
            .getDelivery('onDemand', _selectedAttachmentId!);
        final decoded = jsonDecode(res);
        qualities = await fetchVideoQualities(decoded, true);

        final prores =
            await FPApiRequests().getContent('video', _selectedAttachmentId!);
        final decodedpro = jsonDecode(prores);
        if (decodedpro['progress'] != null) {
          progress = decodedpro['progress'];
        }

        // Determine the default quality using the Settings class
        String? preferredQuality = await Settings().getKey('preferred_quality');
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
        final res = await FPApiRequests()
            .getDelivery('onDemand', _selectedAttachmentId!);
        final decoded = jsonDecode(res);
        qualities = await fetchVideoQualities(decoded, false);

        final prores =
            await FPApiRequests().getContent('audio', _selectedAttachmentId!);
        final decodedpro = jsonDecode(prores);
        if (decodedpro['progress'] != null) {
          progress = decodedpro['progress'];
        }

        // Determine the default quality using the Settings class
        String? preferredQuality = await Settings().getKey('preferred_quality');
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
            await FPApiRequests().getContent('picture', _selectedAttachmentId!);
        final decoded = jsonDecode(res);
        mediaUrl = decoded['imageFiles'][0]['path'];
      }
    }

    // If multiple attachments, add navigation
    if (_post!.attachmentOrder.length > 1) {
      return Stack(
        children: [
          MediaPlayerWidget(
            mediaUrl: mediaUrl!,
            mediaType: selectedMediaType,
            attachment: selectedAttachment,
            qualities: selectedMediaType == MediaType.image ? null : qualities,
            initialState: MediaPlayerState.main,
            startFrom: progress,
            title: _post?.title ?? 'Unknown Title',
            artist: _post?.channel?.title ?? 'Unknown Creator',
            artworkUrl: _post!.thumbnail?.path ?? '',
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
                  final currentIndex =
                      _post!.attachmentOrder.indexOf(_selectedAttachmentId!);
                  final prevIndex =
                      (currentIndex - 1 + _post!.attachmentOrder.length) %
                          _post!.attachmentOrder.length;
                  setState(() {
                    _selectedAttachmentId = _post!.attachmentOrder[prevIndex];
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
                  final currentIndex =
                      _post!.attachmentOrder.indexOf(_selectedAttachmentId!);
                  final nextIndex =
                      (currentIndex + 1) % _post!.attachmentOrder.length;
                  setState(() {
                    _selectedAttachmentId = _post!.attachmentOrder[nextIndex];
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
      mediaUrl: mediaUrl!,
      mediaType: selectedMediaType,
      attachment: selectedAttachment,
      qualities:
          selectedMediaType == MediaType.video && selectedAttachment != null
              ? qualities
              : null,
      initialState: MediaPlayerState.main,
      startFrom: progress,
      title: _post?.title ?? 'Unknown Title',
      artist: _post?.channel?.title ?? 'Unknown Creator',
      artworkUrl: _post!.thumbnail?.path ?? '',
    );
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

  List<Widget> _buildInteractionButtons() {
    return [
      IconButton(
        icon: const Icon(Icons.download, color: Colors.white),
        onPressed: () {},
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
              color: _isLiked
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
            color:
                _isLiked ? Theme.of(context).colorScheme.primary : Colors.white,
            fontWeight: FontWeight.bold,
          ),
          child: Text('$_likeCount'),
        ),
        onPressed: () async {
          final res = await FPApiRequests().likeBlogPost(_post!.id!);
          if (res == 'success') {
            setState(() {
              if (_isLiked) {
                _likeCount--;
                _isLiked = false;
              } else {
                _likeCount++;
                if (_isDisliked) {
                  _dislikeCount--;
                  _isDisliked = false;
                }
                _isLiked = true;
              }
            });
          } else if (res == 'removed') {
            setState(() {
              _likeCount--;
              _isLiked = false;
            });
          }
        },
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
              color: _isDisliked
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
            color: _isDisliked
                ? Theme.of(context).colorScheme.primary
                : Colors.white,
            fontWeight: FontWeight.bold,
          ),
          child: Text('$_dislikeCount'),
        ),
        onPressed: () async {
          final res = await FPApiRequests().dislikeBlogPost(_post!.id!);
          if (res == 'success') {
            setState(() {
              if (_isDisliked) {
                _dislikeCount--;
                _isDisliked = false;
              } else {
                _dislikeCount++;
                if (_isLiked) {
                  _likeCount--;
                  _isLiked = false;
                }
                _isDisliked = true;
              }
            });
          } else if (res == 'removed') {
            setState(() {
              _dislikeCount--;
              _isDisliked = false;
            });
          }
        },
      ),
    ];
  }

  Widget _buildMainContent(BoxConstraints constraints) {
    final isSmall = constraints.maxWidth <= 700;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        if (isSmall)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _post?.title ?? 'Unknown Title',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              _post?.tags.isNotEmpty == true
                  ? Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _post!.tags
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
                      _post?.title ?? 'Unknown Title',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    if (_post?.tags.isNotEmpty == true)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _post!.tags
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
            if (_post?.creator?.urlname == _post?.channel?.urlname) {
              context.go('/channel/${_post?.creator?.urlname}');
            } else {
              context.go(
                  '/channel/${_post?.creator?.urlname}/${_post?.channel?.urlname}');
            }
          },
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: CachedNetworkImageProvider(
                    _post?.channel?.icon?.path ?? ''),
                radius: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _post?.channel?.title ?? 'Unknown Creator',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      _post?.releaseDate != null
                          ? 'Posted ${DateFormat('MMMM dd, yyyy').format(_post!.releaseDate!)}'
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
        if (_post != null && (_post!.attachmentOrder.length) > 1) ...[
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints:
                const BoxConstraints(maxHeight: 98), // Increased height
            child: Scrollbar(
              controller: _attachmentScrollController,
              thumbVisibility: true,
              thickness: 5, // Slightly thicker
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
                        ...List.generate(_post!.attachmentOrder.length,
                            (index) {
                          final id = _post!.attachmentOrder[index];
                          Widget? attachmentWidget;

                          // Find the attachment by ID
                          for (final video in _post!.videoAttachments) {
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

                          for (final audio in _post!.audioAttachments) {
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

                          for (final picture in _post!.pictureAttachments) {
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

                          for (final gallery in _post!.galleryAttachments) {
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
                              right: index == _post!.attachmentOrder.length - 1
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
        if (_post?.text != null && _post!.text!.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: _isExpanded ? double.infinity : 48.0,
                    ),
                    child: ClipRect(
                      child: SingleChildScrollView(
                        physics: NeverScrollableScrollPhysics(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: HtmlWidget(
                            _post?.text ?? '',
                            key: UniqueKey(),
                            factoryBuilder: () => _PostWidgetFactory(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (!_isExpanded)
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
                                  .withValues(alpha: 0.0),
                              Theme.of(context).scaffoldBackgroundColor,
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (_post?.text?.length != null && _post!.text!.length > 25)
                Center(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isExpanded ? 'Show Less' : 'Show More',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        Icon(
                          _isExpanded
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
        Divider(color: Colors.grey[800]),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              '${_post?.comments ?? 0} Comments',
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
                    setState(() {
                      sortBy = 'createdAt';
                      sortOrder = 'DESC';
                      fetchafter = '0';
                      _pagingController.refresh();
                    });
                  },
                ),
                DropdownMenuItem(
                  value: 'oldest',
                  child: const Text('Oldest First'),
                  onTap: () {
                    setState(() {
                      sortBy = 'createdAt';
                      sortOrder = 'ASC';
                      fetchafter = '0';
                      _pagingController.refresh();
                    });
                  },
                ),
                DropdownMenuItem(
                  value: 'highest_rated',
                  child: const Text('Highest Rated'),
                  onTap: () {
                    setState(() {
                      sortBy = 'score';
                      sortOrder = 'DESC';
                      fetchafter = '0';
                      _pagingController.refresh();
                    });
                  },
                ),
                DropdownMenuItem(
                  value: 'lowest_rated',
                  child: const Text('Lowest Rated'),
                  onTap: () {
                    setState(() {
                      sortBy = 'score';
                      sortOrder = 'ASC';
                      fetchafter = '0';
                      _pagingController.refresh();
                    });
                  },
                ),
              ],
              onChanged: (String? value) {},
            ),
          ],
        ),
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[800],
              backgroundImage: NetworkImage(
                rootLayoutKey.currentState?.user!.profileImage?.path ?? '',
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
                                        final comment = await FPApiRequests()
                                            .comment(_post!.id ?? '', text);
                                        if (comment != null) {
                                          setState(() {
                                            // research at somepoint this adds the comment to the list and moves the old one down but doesnt move the like stats replies or anything else down.
                                            //_pagingController.itemList
                                            //    ?.insert(0, comment);
                                            fetchafter = '0';
                                            _pagingController.refresh();
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
        PagedListView<int, CommentModel>(
          pagingController: _pagingController,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          builderDelegate: PagedChildBuilderDelegate<CommentModel>(
            itemBuilder: (context, comment, index) {
              return CommentHolder(
                  comment: comment,
                  content: _post ?? ContentPostV3Response(),
                  onReply: (commentId, text) {
                    // Handle reply submission
                  });
            },
            noItemsFoundIndicatorBuilder: (context) => const Center(
              child: Text("No comments found."),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _fetchComments(int pageKey) async {
    try {
      dynamic items;
      if (fetchafter != '0') {
        items = await FPApiRequests().getComments(
            widget.postId, _pageSize, sortBy, sortOrder,
            fetchAfter: fetchafter);
      } else {
        items = await FPApiRequests()
            .getComments(widget.postId, _pageSize, sortBy, sortOrder);
      }
      if (!mounted) return;

      final isLastPage = items.length < _pageSize;

      setState(() {
        if (items.isNotEmpty) {
          fetchafter = items.last.id;
        }

        _pagingController.appendPage(items, isLastPage ? null : pageKey + 1);
      });
    } catch (error) {
      if (mounted) {
        _pagingController.error = 'An error occurred loading comments';
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
            itemCount: recommendedPosts.length,
            itemBuilder: (context, index) {
              final post = recommendedPosts[index];
              return Padding(
                padding: EdgeInsets.all(padding),
                child: BlogPostCard(post, response: progressMap[post.id]),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PostWidgetFactory extends WidgetFactory with UrlLauncherFactory {}
