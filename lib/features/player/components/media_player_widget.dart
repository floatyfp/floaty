import 'package:better_player_plus/better_player_plus.dart';
import 'package:floaty/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:simple_pip_mode/simple_pip.dart' show SimplePip;
import '../controllers/media_player_service.dart';
import '../models/video_quality.dart';
import 'dart:io';
import 'package:floaty/features/player/components/audio_controls.dart';
import 'package:floaty/features/player/theme/audio_controls_theme.dart';
import 'package:floaty/features/player/components/popup_menu_controls.dart';
import 'package:go_router/go_router.dart';

class MediaPlayerWidget extends ConsumerStatefulWidget {
  final String whitelabelName;
  final String mediaUrl;
  final MediaType mediaType;
  final bool live;
  final dynamic attachment;
  final List<VideoQuality>? qualities;
  final int startFrom;
  final BuildContext contextBuild;
  final String? title;
  final String? artist;
  final String? artistImage;
  final String? postId;
  final String? artworkUrl;
  final bool discoverable;
  final MediaPlayerState initialState;
  final List<Map<String, dynamic>>? textTracks;

  const MediaPlayerWidget({
    super.key,
    required this.whitelabelName,
    required this.mediaUrl,
    required this.mediaType,
    required this.attachment,
    required this.contextBuild,
    this.qualities,
    this.initialState = MediaPlayerState.main,
    required this.startFrom,
    required this.title,
    required this.artist,
    required this.artistImage,
    required this.postId,
    required this.artworkUrl,
    required this.discoverable,
    required this.live,
    this.textTracks,
  });

  @override
  ConsumerState<MediaPlayerWidget> createState() => _MediaPlayerWidgetState();
}

class _MediaPlayerWidgetState extends ConsumerState<MediaPlayerWidget> {
  bool subtitlesEnabled = false;
  late MediaPlayerService _mediaService;
  bool _isInitialized = false;
  late bool _pipAvailable;
  bool _mediakit = true;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    bool mediakit = true;
    subtitlesEnabled =
        ref.read(mediaPlayerServiceProvider.notifier).subtitlesEnabled;
    if (Platform.isAndroid) _pipAvailable = await SimplePip.isPipAvailable;
    _mediaService = ref.read(mediaPlayerServiceProvider.notifier);
    final controller = await _mediaService.setSource(
      widget.whitelabelName,
      widget.mediaUrl,
      widget.mediaType,
      widget.live,
      attachment: widget.attachment,
      qualities: widget.qualities,
      start: Duration(seconds: widget.startFrom),
      title: widget.title,
      artist: widget.artist,
      artistImage: widget.artistImage,
      postId: widget.postId,
      thumbnailUrl: widget.artworkUrl,
      discoverable: widget.discoverable,
      textTracks: widget.textTracks,
    );
    // if (controller is BetterPlayerController) {
    //   mediakit = false;
    // } else if (controller is VideoController) {
    //   mediakit = true;
    // }
    await _mediaService.changeState(widget.initialState);
    if (mounted) {
      setState(() {
        _isInitialized = true;
        _mediakit = mediakit;
      });
      if (widget.mediaType != MediaType.image) {
        _mediaService.play();
      }
    }
  }

  Widget _buildMediaContent() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    switch (widget.mediaType) {
      case MediaType.video:
        if (_mediakit) {
          final videoController = _mediaService.videoController;
          if (videoController == null) {
            return const Center(
                child: CircularProgressIndicator(
              color: Colors.white,
            ));
          }
          if (!Platform.isAndroid && !Platform.isIOS) {
            return MaterialDesktopVideoControlsTheme(
              normal: MaterialDesktopVideoControlsThemeData(
                buttonBarButtonSize: 24.0,
                buttonBarButtonColor: Colors.white,
                seekBarThumbColor: Colors.white,
                seekBarPositionColor: colorScheme.primary,
                topButtonBar: [
                  MaterialDesktopCustomButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _mediaService.changeState(MediaPlayerState.none);
                      _mediaService.stop();
                      Navigator.pop(context);
                    },
                  ),
                ],
                bottomButtonBar: [
                  MaterialDesktopSkipPreviousButton(),
                  MaterialDesktopPlayOrPauseButton(),
                  MaterialDesktopSkipNextButton(),
                  MaterialDesktopVolumeButton(),
                  MaterialDesktopPositionIndicator(),
                  const Spacer(),
                  if (widget.textTracks?.isNotEmpty == true)
                    StatefulBuilder(
                      builder: (context, setState) {
                        return MaterialDesktopCustomButton(
                          icon: Icon(
                            subtitlesEnabled
                                ? Icons.closed_caption
                                : Icons.closed_caption_off,
                            color: Colors.white,
                          ),
                          onPressed: () async {
                            final subtitles =
                                await _mediaService.toggleSubtitles();
                            setState(() {
                              subtitlesEnabled = subtitles;
                            });
                          },
                        );
                      },
                    ),
                  MaterialDesktopCustomButton(
                    icon: const Icon(Icons.picture_in_picture),
                    onPressed: () {
                      _mediaService.changeState(MediaPlayerState.pip);
                      if (!mounted) return;
                      widget.contextBuild.go('/pip', extra: {
                        'controller': _mediaService.videoController,
                        'postId': widget.postId,
                        'live': _mediaService.currentLive,
                      });
                    },
                  ),
                  if (mounted)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.settings, color: Colors.white),
                      itemBuilder: (context) => [
                        if (widget.textTracks?.isNotEmpty == true)
                          subtitlePopupMenuItem(
                            mediaService: _mediaService,
                            textTracks: widget.textTracks!,
                          ),
                        if (widget.qualities?.isNotEmpty == true)
                          qualityPopupMenuItem(
                            mediaService: _mediaService,
                            qualities: widget.qualities!,
                          ),
                        playbackSpeedPopupMenuItem(
                          mediaService: _mediaService,
                        ),
                      ],
                      onSelected: (value) {},
                    ),
                  MaterialDesktopFullscreenButton(),
                ],
              ),
              fullscreen: MaterialDesktopVideoControlsThemeData(
                buttonBarButtonSize: 24.0,
                buttonBarButtonColor: Colors.white,
                seekBarThumbColor: Colors.white,
                seekBarPositionColor: colorScheme.primary,
                bottomButtonBar: [
                  MaterialDesktopSkipPreviousButton(),
                  MaterialDesktopPlayOrPauseButton(),
                  MaterialDesktopSkipNextButton(),
                  MaterialDesktopVolumeButton(),
                  MaterialDesktopPositionIndicator(),
                  const Spacer(),
                  if (widget.textTracks?.isNotEmpty == true)
                    StatefulBuilder(
                      builder: (context, setState) {
                        return MaterialDesktopCustomButton(
                          icon: Icon(
                            subtitlesEnabled
                                ? Icons.closed_caption
                                : Icons.closed_caption_off,
                            color: Colors.white,
                          ),
                          onPressed: () async {
                            final subtitles =
                                await _mediaService.toggleSubtitles();
                            setState(() {
                              subtitlesEnabled = subtitles;
                            });
                          },
                        );
                      },
                    ),
                  MaterialDesktopCustomButton(
                    icon: const Icon(Icons.picture_in_picture),
                    onPressed: () {
                      _mediaService.changeState(MediaPlayerState.pip);
                      if (!mounted) return;
                      widget.contextBuild.go('/pip', extra: {
                        'controller': _mediaService.videoController,
                        'postId': widget.postId,
                        'live': _mediaService.currentLive,
                      });
                    },
                  ),
                  if (mounted)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.settings, color: Colors.white),
                      itemBuilder: (context) => [
                        if (widget.textTracks?.isNotEmpty == true)
                          subtitlePopupMenuItem(
                            mediaService: _mediaService,
                            textTracks: widget.textTracks!,
                          ),
                        if (widget.qualities?.isNotEmpty == true)
                          qualityPopupMenuItem(
                            mediaService: _mediaService,
                            qualities: widget.qualities!,
                          ),
                        playbackSpeedPopupMenuItem(
                          mediaService: _mediaService,
                        ),
                      ],
                      onSelected: (value) {},
                    ),
                  MaterialDesktopFullscreenButton(),
                ],
              ),
              child: FutureBuilder(
                future: settings.getBool('pause_on_background'),
                builder: (context, snapshot) {
                  return Video(
                    controller: videoController,
                    pauseUponEnteringBackgroundMode: snapshot.data ?? true,
                  );
                },
              ),
            );
          } else {
            return MaterialVideoControlsTheme(
              normal: MaterialVideoControlsThemeData(
                volumeGesture: true,
                brightnessGesture: true,
                seekGesture: true,
                gesturesEnabledWhileControlsVisible: true,
                seekOnDoubleTap: true,
                buttonBarButtonSize: 24.0,
                buttonBarButtonColor: Colors.white,
                seekBarThumbColor: Colors.white,
                seekBarPositionColor: colorScheme.primary,
                seekBarAlignment: Alignment.bottomCenter,
                topButtonBar: [
                  MaterialCustomButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _mediaService.changeState(MediaPlayerState.none);
                      _mediaService.stop();
                      Navigator.pop(context);
                    },
                  ),
                ],
                bottomButtonBar: [
                  MaterialPositionIndicator(),
                  const Spacer(),
                  if (widget.textTracks?.isNotEmpty == true)
                    StatefulBuilder(
                      builder: (context, setState) {
                        return MaterialCustomButton(
                          icon: Icon(
                            subtitlesEnabled
                                ? Icons.closed_caption
                                : Icons.closed_caption_off,
                            color: Colors.white,
                          ),
                          onPressed: () async {
                            final subtitles =
                                await _mediaService.toggleSubtitles();
                            setState(() {
                              subtitlesEnabled = subtitles;
                            });
                          },
                        );
                      },
                    ),
                  if (!Platform.isIOS && _pipAvailable)
                    MaterialCustomButton(
                      icon: const Icon(Icons.picture_in_picture),
                      onPressed: () {
                        _mediaService.enterpip();
                        _mediaService.changeState(MediaPlayerState.pip);
                        if (!mounted) return;
                        widget.contextBuild.go('/pip', extra: {
                          'controller': _mediaService.videoController,
                          'postId': widget.postId,
                          'live': _mediaService.currentLive,
                        });
                      },
                    ),
                  if (mounted)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.settings, color: Colors.white),
                      itemBuilder: (context) => [
                        if (widget.textTracks?.isNotEmpty == true)
                          subtitlePopupMenuItem(
                            mediaService: _mediaService,
                            textTracks: widget.textTracks!,
                          ),
                        if (widget.qualities?.isNotEmpty == true)
                          qualityPopupMenuItem(
                            mediaService: _mediaService,
                            qualities: widget.qualities!,
                          ),
                        playbackSpeedPopupMenuItem(
                          mediaService: _mediaService,
                        ),
                      ],
                      onSelected: (value) {},
                    ),
                  MaterialFullscreenButton(),
                ],
              ),
              fullscreen: MaterialVideoControlsThemeData(
                volumeGesture: true,
                brightnessGesture: true,
                seekGesture: true,
                gesturesEnabledWhileControlsVisible: true,
                seekOnDoubleTap: true,
                buttonBarButtonSize: 24.0,
                buttonBarButtonColor: Colors.white,
                seekBarThumbColor: Colors.white,
                seekBarPositionColor: colorScheme.primary,
                seekBarAlignment: Alignment(0.0, -2.0),
                bottomButtonBar: [
                  MaterialPositionIndicator(),
                  const Spacer(),
                  if (widget.textTracks?.isNotEmpty == true)
                    StatefulBuilder(
                      builder: (context, setState) {
                        return MaterialCustomButton(
                          icon: Icon(
                            subtitlesEnabled
                                ? Icons.closed_caption
                                : Icons.closed_caption_off,
                            color: Colors.white,
                          ),
                          onPressed: () async {
                            final subtitles =
                                await _mediaService.toggleSubtitles();
                            setState(() {
                              subtitlesEnabled = subtitles;
                            });
                          },
                        );
                      },
                    ),
                  if (!Platform.isIOS && _pipAvailable)
                    MaterialCustomButton(
                      icon: const Icon(Icons.picture_in_picture),
                      onPressed: () {
                        _mediaService.enterpip();
                        _mediaService.changeState(MediaPlayerState.pip);
                        if (!mounted) return;
                        widget.contextBuild.go('/pip', extra: {
                          'controller': _mediaService.videoController,
                          'postId': widget.postId,
                          'live': _mediaService.currentLive,
                        });
                      },
                    ),
                  if (mounted)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.settings, color: Colors.white),
                      itemBuilder: (context) => [
                        if (widget.textTracks?.isNotEmpty == true)
                          subtitlePopupMenuItem(
                            mediaService: _mediaService,
                            textTracks: widget.textTracks!,
                          ),
                        if (widget.qualities?.isNotEmpty == true)
                          qualityPopupMenuItem(
                            mediaService: _mediaService,
                            qualities: widget.qualities!,
                          ),
                        playbackSpeedPopupMenuItem(
                          mediaService: _mediaService,
                        ),
                      ],
                      onSelected: (value) {},
                    ),
                  MaterialFullscreenButton(),
                ],
              ),
              child: FutureBuilder(
                future: settings.getBool('pause_on_background'),
                builder: (context, snapshot) {
                  return Video(
                    controller: videoController,
                    pauseUponEnteringBackgroundMode: snapshot.data ?? true,
                  );
                },
              ),
            );
          }
        } else {
          final videoController = _mediaService.betterPlayerController;
          if (videoController == null) {
            return const Center(
                child: CircularProgressIndicator(
              color: Colors.white,
            ));
          }
          return BetterPlayer(
            controller: videoController,
          );
        }
      case MediaType.audio:
        final theme = AudioControlsThemeData(
          modifyVolumeOnScroll: false,
          hideMouseOnControlsRemoval: false,
          playAndPauseOnTap: true,
          bottomButtonBarMargin:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          seekBarMargin: const EdgeInsets.symmetric(horizontal: 16.0),
          seekBarHeight: 4.0,
          seekBarHoverHeight: 4.0,
          seekBarContainerHeight: 40.0,
          seekBarColor: const Color(0x3DFFFFFF),
          seekBarThumbColor: Colors.white,
          seekBarPositionColor: colorScheme.primary,
          seekBarBufferColor: const Color(0x3DFFFFFF),
          seekBarThumbSize: 12.0,
          buttonBarHeight: 48.0,
          buttonBarButtonSize: 32.0,
        );

        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.black,
          ),
          child: AudioControls(
            theme: theme,
          ),
        );
      case MediaType.image:
        return Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(widget.mediaUrl),
              fit: BoxFit.fitHeight,
            ),
          ),
        );
    }
  }

  Widget _buildMediaPlayer() {
    final playerState = ref.watch(mediaPlayerServiceProvider);

    switch (playerState) {
      case MediaPlayerState.none:
        return const SizedBox.shrink();
      case MediaPlayerState.main:
        return _buildMainPlayer();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildMainPlayer() {
    return Scaffold(
      body: Center(
        child: _buildMediaContent(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(
          child: CircularProgressIndicator(
        color: Colors.white,
      ));
    }

    return _buildMediaPlayer();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
