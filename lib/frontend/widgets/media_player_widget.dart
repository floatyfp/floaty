import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../services/media/media_player_service.dart';
import '../../services/media/video_quality.dart';
import 'dart:io';
import 'package:floaty/frontend/widgets/audio_controls.dart';
import 'package:floaty/frontend/widgets/audio_controls_theme.dart';

class MediaPlayerWidget extends ConsumerStatefulWidget {
  final String mediaUrl;
  final MediaType mediaType;
  final dynamic attachment;
  final MediaPlayerState initialState;
  final List<VideoQuality>? qualities;
  final int startFrom;
  final String title;
  final String artist;
  final String artworkUrl;

  const MediaPlayerWidget({
    super.key,
    required this.mediaUrl,
    required this.mediaType,
    required this.attachment,
    this.qualities,
    this.initialState = MediaPlayerState.main,
    required this.startFrom,
    required this.title,
    required this.artist,
    required this.artworkUrl,
  });

  @override
  ConsumerState<MediaPlayerWidget> createState() => _MediaPlayerWidgetState();
}

class _MediaPlayerWidgetState extends ConsumerState<MediaPlayerWidget> {
  late MediaPlayerService _mediaService;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _mediaService = ref.read(mediaPlayerServiceProvider.notifier);
    await _mediaService.setSource(
      widget.mediaUrl,
      widget.mediaType,
      attachment: widget.attachment,
      qualities: widget.qualities,
      start: Duration(seconds: widget.startFrom),
      title: widget.title,
      artist: widget.artist,
      thumbnailUrl: widget.artworkUrl,
    );
    await _mediaService.changeState(widget.initialState);
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
      if (widget.mediaType != MediaType.image) {
        _mediaService.play();
      }
    }
  }

  double speedvar = 1.0;
  Widget _buildMediaContent() {
    switch (widget.mediaType) {
      case MediaType.video:
        final videoController = _mediaService.videoController;
        if (videoController == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!Platform.isAndroid && !Platform.isIOS) {
          return MaterialDesktopVideoControlsTheme(
            normal: MaterialDesktopVideoControlsThemeData(
              buttonBarButtonSize: 24.0,
              buttonBarButtonColor: Colors.white,
              topButtonBar: [
                MaterialDesktopCustomButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
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
                Spacer(),
                MaterialDesktopCustomButton(
                  icon: const Icon(Icons.picture_in_picture),
                  onPressed: () {
                    _mediaService.changeState(MediaPlayerState.pip);
                  },
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.settings),
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      value: 'quality',
                      child: PopupMenuButton<VideoQuality>(
                        child: Text('Quality'),
                        itemBuilder: (context) =>
                            widget.qualities!.map((quality) {
                          return PopupMenuItem<VideoQuality>(
                            value: quality,
                            child: Row(
                              children: [
                                Text(quality.label),
                                if (quality == _mediaService.currentQuality)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 8.0),
                                    child: Icon(Icons.check, size: 16),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                        onSelected: (quality) {
                          _mediaService.changeQuality(quality);
                        },
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'playback_speed',
                      child: PopupMenuButton<double>(
                        child: Text('Playback Speed'),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                              value: 0.5,
                              child: Row(
                                children: [
                                  Text('0.5x'),
                                  if (speedvar == 0.5)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 8.0),
                                      child: Icon(Icons.check, size: 16),
                                    ),
                                ],
                              )),
                          PopupMenuItem(
                              value: 1.0,
                              child: Row(
                                children: [
                                  Text('1.0x'),
                                  if (speedvar == 1.0)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 8.0),
                                      child: Icon(Icons.check, size: 16),
                                    ),
                                ],
                              )),
                          PopupMenuItem(
                              value: 1.25,
                              child: Row(
                                children: [
                                  Text('1.25x'),
                                  if (speedvar == 1.25)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 8.0),
                                      child: Icon(Icons.check, size: 16),
                                    ),
                                ],
                              )),
                          PopupMenuItem(
                              value: 1.5,
                              child: Row(
                                children: [
                                  Text('1.5x'),
                                  if (speedvar == 1.5)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 8.0),
                                      child: Icon(Icons.check, size: 16),
                                    ),
                                ],
                              )),
                          PopupMenuItem(
                              value: 1.75,
                              child: Row(
                                children: [
                                  Text('1.75x'),
                                  if (speedvar == 1.75)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 8.0),
                                      child: Icon(Icons.check, size: 16),
                                    ),
                                ],
                              )),
                          PopupMenuItem(
                              value: 2.0,
                              child: Row(
                                children: [
                                  Text('2.0x'),
                                  if (speedvar == 2.0)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 8.0),
                                      child: Icon(Icons.check, size: 16),
                                    ),
                                ],
                              )),
                          PopupMenuItem(
                            value: speedvar,
                            child: Row(
                              children: [
                                Text('Custom'),
                                // we don't talk about this
                                if (speedvar != 0.5 &&
                                    speedvar != 1.0 &&
                                    speedvar != 1.25 &&
                                    speedvar != 1.5 &&
                                    speedvar != 1.75 &&
                                    speedvar != 2.0)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 8.0),
                                    child: Icon(Icons.check, size: 16),
                                  ),
                              ],
                            ),
                            onTap: () => _showCustomSpeedDialog(context),
                          ),
                        ],
                        onSelected: (speed) {
                          _mediaService.setSpeed(speed);
                          speedvar = speed;
                        },
                      ),
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
              topButtonBar: [
                MaterialDesktopCustomButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
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
                Spacer(),
                MaterialDesktopCustomButton(
                  icon: const Icon(Icons.picture_in_picture),
                  onPressed: () {
                    _mediaService.changeState(MediaPlayerState.pip);
                  },
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.settings),
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      value: 'quality',
                      child: PopupMenuButton<VideoQuality>(
                        child: Text('Quality'),
                        itemBuilder: (context) =>
                            widget.qualities!.map((quality) {
                          return PopupMenuItem<VideoQuality>(
                            value: quality,
                            child: Row(
                              children: [
                                Text(quality.label),
                                if (quality == _mediaService.currentQuality)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 8.0),
                                    child: Icon(Icons.check, size: 16),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                        onSelected: (quality) {
                          _mediaService.changeQuality(quality);
                        },
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'playback_speed',
                      child: PopupMenuButton<double>(
                        child: Text('Playback Speed'),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                              value: 0.5,
                              child: Row(
                                children: [
                                  Text('0.5x'),
                                  if (speedvar == 0.5)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 8.0),
                                      child: Icon(Icons.check, size: 16),
                                    ),
                                ],
                              )),
                          PopupMenuItem(
                              value: 1.0,
                              child: Row(
                                children: [
                                  Text('1.0x'),
                                  if (speedvar == 1.0)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 8.0),
                                      child: Icon(Icons.check, size: 16),
                                    ),
                                ],
                              )),
                          PopupMenuItem(
                              value: 1.25,
                              child: Row(
                                children: [
                                  Text('1.25x'),
                                  if (speedvar == 1.25)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 8.0),
                                      child: Icon(Icons.check, size: 16),
                                    ),
                                ],
                              )),
                          PopupMenuItem(
                              value: 1.5,
                              child: Row(
                                children: [
                                  Text('1.5x'),
                                  if (speedvar == 1.5)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 8.0),
                                      child: Icon(Icons.check, size: 16),
                                    ),
                                ],
                              )),
                          PopupMenuItem(
                              value: 1.75,
                              child: Row(
                                children: [
                                  Text('1.75x'),
                                  if (speedvar == 1.75)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 8.0),
                                      child: Icon(Icons.check, size: 16),
                                    ),
                                ],
                              )),
                          PopupMenuItem(
                              value: 2.0,
                              child: Row(
                                children: [
                                  Text('2.0x'),
                                  if (speedvar == 2.0)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 8.0),
                                      child: Icon(Icons.check, size: 16),
                                    ),
                                ],
                              )),
                          PopupMenuItem(
                            value: speedvar,
                            child: Row(
                              children: [
                                Text('Custom'),
                                // we don't talk about this
                                if (speedvar != 0.5 &&
                                    speedvar != 1.0 &&
                                    speedvar != 1.25 &&
                                    speedvar != 1.5 &&
                                    speedvar != 1.75 &&
                                    speedvar != 2.0)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 8.0),
                                    child: Icon(Icons.check, size: 16),
                                  ),
                              ],
                            ),
                            onTap: () => _showCustomSpeedDialog(context),
                          ),
                        ],
                        onSelected: (speed) {
                          _mediaService.setSpeed(speed);
                          speedvar = speed;
                        },
                      ),
                    ),
                  ],
                  onSelected: (value) {},
                ),
                MaterialDesktopFullscreenButton(),
              ],
            ),
            child: Video(
              controller: videoController,
              //TODO: setting
              pauseUponEnteringBackgroundMode: false,
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
              topButtonBar: [
                MaterialCustomButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _mediaService.stop();
                    Navigator.pop(context);
                  },
                ),
              ],
              bottomButtonBar: [
                MaterialPositionIndicator(),
                Spacer(),
                MaterialCustomButton(
                  icon: const Icon(Icons.picture_in_picture),
                  onPressed: () {
                    _mediaService.changeState(MediaPlayerState.pip);
                  },
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.settings),
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      value: 'quality',
                      child: PopupMenuButton<VideoQuality>(
                        child: Text('Quality'),
                        itemBuilder: (context) =>
                            widget.qualities!.map((quality) {
                          return PopupMenuItem<VideoQuality>(
                            value: quality,
                            child: Row(
                              children: [
                                Text(quality.label),
                                if (quality == _mediaService.currentQuality)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 8.0),
                                    child: Icon(Icons.check, size: 16),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                        onSelected: (quality) {
                          _mediaService.changeQuality(quality);
                        },
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'playback_speed',
                      child: PopupMenuButton<double>(
                        child: Text('Playback Speed'),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                              value: 0.5,
                              child: Row(
                                children: [
                                  Text('0.5x'),
                                  if (speedvar == 0.5)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 8.0),
                                      child: Icon(Icons.check, size: 16),
                                    ),
                                ],
                              )),
                          PopupMenuItem(
                              value: 1.0,
                              child: Row(
                                children: [
                                  Text('1.0x'),
                                  if (speedvar == 1.0)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 8.0),
                                      child: Icon(Icons.check, size: 16),
                                    ),
                                ],
                              )),
                          PopupMenuItem(
                              value: 1.25,
                              child: Row(
                                children: [
                                  Text('1.25x'),
                                  if (speedvar == 1.25)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 8.0),
                                      child: Icon(Icons.check, size: 16),
                                    ),
                                ],
                              )),
                          PopupMenuItem(
                              value: 1.5,
                              child: Row(
                                children: [
                                  Text('1.5x'),
                                  if (speedvar == 1.5)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 8.0),
                                      child: Icon(Icons.check, size: 16),
                                    ),
                                ],
                              )),
                          PopupMenuItem(
                              value: 1.75,
                              child: Row(
                                children: [
                                  Text('1.75x'),
                                  if (speedvar == 1.75)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 8.0),
                                      child: Icon(Icons.check, size: 16),
                                    ),
                                ],
                              )),
                          PopupMenuItem(
                              value: 2.0,
                              child: Row(
                                children: [
                                  Text('2.0x'),
                                  if (speedvar == 2.0)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 8.0),
                                      child: Icon(Icons.check, size: 16),
                                    ),
                                ],
                              )),
                          PopupMenuItem(
                            value: speedvar,
                            child: Row(
                              children: [
                                Text('Custom'),
                                // we don't talk about this
                                if (speedvar != 0.5 &&
                                    speedvar != 1.0 &&
                                    speedvar != 1.25 &&
                                    speedvar != 1.5 &&
                                    speedvar != 1.75 &&
                                    speedvar != 2.0)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 8.0),
                                    child: Icon(Icons.check, size: 16),
                                  ),
                              ],
                            ),
                            onTap: () => _showCustomSpeedDialog(context),
                          ),
                        ],
                        onSelected: (speed) {
                          _mediaService.setSpeed(speed);
                        },
                      ),
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
              topButtonBar: [
                MaterialCustomButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _mediaService.stop();
                    Navigator.pop(context);
                  },
                ),
              ],
              bottomButtonBar: [
                MaterialPositionIndicator(),
                Spacer(),
                MaterialCustomButton(
                  icon: const Icon(Icons.picture_in_picture),
                  onPressed: () {
                    _mediaService.changeState(MediaPlayerState.pip);
                  },
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.settings),
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      value: 'quality',
                      child: PopupMenuButton<VideoQuality>(
                        child: Text('Quality'),
                        itemBuilder: (context) =>
                            widget.qualities!.map((quality) {
                          return PopupMenuItem<VideoQuality>(
                            value: quality,
                            child: Row(
                              children: [
                                Text(quality.label),
                                if (quality == _mediaService.currentQuality)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 8.0),
                                    child: Icon(Icons.check, size: 16),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                        onSelected: (quality) {
                          _mediaService.changeQuality(quality);
                        },
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'playback_speed',
                      child: PopupMenuButton<double>(
                        child: Text('Playback Speed'),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                              value: 0.5,
                              child: Row(
                                children: [
                                  Text('0.5x'),
                                  if (speedvar == 0.5)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 8.0),
                                      child: Icon(Icons.check, size: 16),
                                    ),
                                ],
                              )),
                          PopupMenuItem(
                              value: 1.0,
                              child: Row(
                                children: [
                                  Text('1.0x'),
                                  if (speedvar == 1.0)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 8.0),
                                      child: Icon(Icons.check, size: 16),
                                    ),
                                ],
                              )),
                          PopupMenuItem(
                              value: 1.25,
                              child: Row(
                                children: [
                                  Text('1.25x'),
                                  if (speedvar == 1.25)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 8.0),
                                      child: Icon(Icons.check, size: 16),
                                    ),
                                ],
                              )),
                          PopupMenuItem(
                              value: 1.5,
                              child: Row(
                                children: [
                                  Text('1.5x'),
                                  if (speedvar == 1.5)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 8.0),
                                      child: Icon(Icons.check, size: 16),
                                    ),
                                ],
                              )),
                          PopupMenuItem(
                              value: 1.75,
                              child: Row(
                                children: [
                                  Text('1.75x'),
                                  if (speedvar == 1.75)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 8.0),
                                      child: Icon(Icons.check, size: 16),
                                    ),
                                ],
                              )),
                          PopupMenuItem(
                              value: 2.0,
                              child: Row(
                                children: [
                                  Text('2.0x'),
                                  if (speedvar == 2.0)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 8.0),
                                      child: Icon(Icons.check, size: 16),
                                    ),
                                ],
                              )),
                          PopupMenuItem(
                            value: speedvar,
                            child: Row(
                              children: [
                                Text('Custom'),
                                // we don't talk about this
                                if (speedvar != 0.5 &&
                                    speedvar != 1.0 &&
                                    speedvar != 1.25 &&
                                    speedvar != 1.5 &&
                                    speedvar != 1.75 &&
                                    speedvar != 2.0)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 8.0),
                                    child: Icon(Icons.check, size: 16),
                                  ),
                              ],
                            ),
                            onTap: () => _showCustomSpeedDialog(context),
                          ),
                        ],
                        onSelected: (speed) {
                          _mediaService.setSpeed(speed);
                        },
                      ),
                    ),
                  ],
                  onSelected: (value) {},
                ),
                MaterialFullscreenButton(),
              ],
            ),
            child: Video(
              controller: videoController,
              //TODO: setting
              pauseUponEnteringBackgroundMode: false,
            ),
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
          seekBarPositionColor: const Color(0xFFFF0000),
          seekBarBufferColor: const Color(0x3DFFFFFF),
          seekBarThumbSize: 12.0,
          seekBarThumbColor: const Color(0xFFFF0000),
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
      case MediaPlayerState.pip:
        return _buildPipPlayer();
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

  Widget _buildPipPlayer() {
    return Align(
      alignment: Alignment.bottomRight,
      child: GestureDetector(
        onTap: () => _mediaService.changeState(MediaPlayerState.main),
        child: Container(
          width: 320,
          height: 180,
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(20),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _buildMediaContent(),
          ),
        ),
      ),
    );
  }

  void _showCustomSpeedDialog(BuildContext context) {
    double customSpeed = speedvar;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Select Playback Speed'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Slider(
                    value: customSpeed,
                    min: 0.1,
                    max: 4.0,
                    divisions: 100,
                    label: '${customSpeed.toStringAsFixed(1)}x',
                    onChanged: (value) {
                      setState(() {
                        customSpeed = value;
                      });
                    },
                  ),
                  Text('${customSpeed.toStringAsFixed(1)}x'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _mediaService.setSpeed(customSpeed);
                    speedvar = customSpeed;
                  },
                  child: const Text('Set Speed'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return _buildMediaPlayer();
  }

  @override
  void dispose() {
    _mediaService.changeState(MediaPlayerState.none);
    super.dispose();
  }
}
