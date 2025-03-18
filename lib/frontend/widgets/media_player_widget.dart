import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../services/media/media_player_service.dart';
import '../../services/media/video_quality.dart';
import 'dart:io';
import 'package:floaty/frontend/widgets/audio_controls.dart';
import 'package:floaty/frontend/widgets/audio_controls_theme.dart';
import 'package:go_router/go_router.dart';

class MediaPlayerWidget extends ConsumerStatefulWidget {
  final String mediaUrl;
  final MediaType mediaType;
  final bool live;
  final dynamic attachment;
  final List<VideoQuality>? qualities;
  final int startFrom;
  final BuildContext contextBuild;
  final String? title;
  final String? artist;
  final String? postId;
  final String? artworkUrl;
  final MediaPlayerState initialState;
  final List<Map<String, dynamic>>? textTracks;

  const MediaPlayerWidget({
    super.key,
    required this.mediaUrl,
    required this.mediaType,
    required this.attachment,
    required this.contextBuild,
    this.qualities,
    this.initialState = MediaPlayerState.main,
    required this.startFrom,
    required this.title,
    required this.artist,
    required this.postId,
    required this.artworkUrl,
    required this.live,
    this.textTracks,
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
      widget.live,
      attachment: widget.attachment,
      qualities: widget.qualities,
      start: Duration(seconds: widget.startFrom),
      title: widget.title,
      artist: widget.artist,
      postId: widget.postId,
      thumbnailUrl: widget.artworkUrl,
      textTracks: widget.textTracks,
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
              seekBarPositionColor: Theme.of(context).colorScheme.primary,
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
                const Spacer(),
                if (widget.textTracks?.isNotEmpty == true)
                  MaterialDesktopCustomButton(
                    icon: Icon(
                      Icons.closed_caption,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      _mediaService.toggleSubtitles();
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
                    });
                  },
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.settings),
                  itemBuilder: (context) => [
                    if (widget.textTracks?.isNotEmpty == true)
                      PopupMenuItem<String>(
                        value: 'subtitles',
                        child: PopupMenuButton<int>(
                          child: const Text('Subtitles'),
                          itemBuilder: (context) =>
                              widget.textTracks!.asMap().entries.map((entry) {
                            final index = entry.key;
                            final track = entry.value;
                            return PopupMenuItem<int>(
                              value: index,
                              child: Row(
                                children: [
                                  Text(track['language'] ?? 'Unknown'),
                                  if (index ==
                                      _mediaService.currentSubtitleTrackIndex)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 8.0),
                                      child: Icon(Icons.check, size: 16),
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                          onSelected: (index) {
                            _mediaService.setSubtitleTrack(index);
                          },
                        ),
                      ),
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
              seekBarThumbColor: Colors.white,
              seekBarPositionColor: Theme.of(context).colorScheme.primary,
              bottomButtonBar: [
                MaterialDesktopSkipPreviousButton(),
                MaterialDesktopPlayOrPauseButton(),
                MaterialDesktopSkipNextButton(),
                MaterialDesktopVolumeButton(),
                MaterialDesktopPositionIndicator(),
                const Spacer(),
                if (widget.textTracks?.isNotEmpty == true)
                  MaterialDesktopCustomButton(
                    icon: Icon(
                      Icons.closed_caption,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      _mediaService.toggleSubtitles();
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
                    });
                  },
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.settings),
                  itemBuilder: (context) => [
                    if (widget.textTracks?.isNotEmpty == true)
                      PopupMenuItem<String>(
                        value: 'subtitles',
                        child: PopupMenuButton<int>(
                          child: const Text('Subtitles'),
                          itemBuilder: (context) =>
                              widget.textTracks!.asMap().entries.map((entry) {
                            final index = entry.key;
                            final track = entry.value;
                            return PopupMenuItem<int>(
                              value: index,
                              child: Row(
                                children: [
                                  Text(track['language'] ?? 'Unknown'),
                                  if (index ==
                                      _mediaService.currentSubtitleTrackIndex)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 8.0),
                                      child: Icon(Icons.check, size: 16),
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                          onSelected: (index) {
                            _mediaService.setSubtitleTrack(index);
                          },
                        ),
                      ),
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
              seekBarThumbColor: Colors.white,
              seekBarPositionColor: Theme.of(context).colorScheme.primary,
              seekBarAlignment: Alignment.bottomCenter,
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
                const Spacer(),
                if (widget.textTracks?.isNotEmpty == true)
                  MaterialCustomButton(
                    icon: Icon(
                      Icons.closed_caption,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      _mediaService.toggleSubtitles();
                    },
                  ),
                if (!Platform.isIOS)
                  MaterialCustomButton(
                    icon: const Icon(Icons.picture_in_picture),
                    onPressed: () {
                      _mediaService.enterpip();
                      _mediaService.changeState(MediaPlayerState.pip);
                      if (!mounted) return;
                      widget.contextBuild.go('/pip', extra: {
                        'controller': _mediaService.videoController,
                        'postId': widget.postId,
                      });
                    },
                  ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.settings),
                  itemBuilder: (context) => [
                    if (widget.textTracks?.isNotEmpty == true)
                      PopupMenuItem<String>(
                        value: 'subtitles',
                        child: PopupMenuButton<int>(
                          child: const Text('Subtitles'),
                          itemBuilder: (context) =>
                              widget.textTracks!.asMap().entries.map((entry) {
                            final index = entry.key;
                            final track = entry.value;
                            return PopupMenuItem<int>(
                              value: index,
                              child: Row(
                                children: [
                                  Text(track['language'] ?? 'Unknown'),
                                  if (index ==
                                      _mediaService.currentSubtitleTrackIndex)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 8.0),
                                      child: Icon(Icons.check, size: 16),
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                          onSelected: (index) {
                            _mediaService.setSubtitleTrack(index);
                          },
                        ),
                      ),
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
              seekBarThumbColor: Colors.white,
              seekBarPositionColor: Theme.of(context).colorScheme.primary,
              seekBarAlignment: Alignment(0.0, -2.0),
              bottomButtonBar: [
                MaterialPositionIndicator(),
                const Spacer(),
                if (widget.textTracks?.isNotEmpty == true)
                  MaterialCustomButton(
                    icon: Icon(
                      Icons.closed_caption,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      _mediaService.toggleSubtitles();
                    },
                  ),
                if (!Platform.isIOS)
                  MaterialCustomButton(
                    icon: const Icon(Icons.picture_in_picture),
                    onPressed: () {
                      _mediaService.enterpip();
                      _mediaService.changeState(MediaPlayerState.pip);
                      if (!mounted) return;
                      widget.contextBuild.go('/pip', extra: {
                        'controller': _mediaService.videoController,
                        'postId': widget.postId,
                      });
                    },
                  ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.settings),
                  itemBuilder: (context) => [
                    if (widget.textTracks?.isNotEmpty == true)
                      PopupMenuItem<String>(
                        value: 'subtitles',
                        child: PopupMenuButton<int>(
                          child: const Text('Subtitles'),
                          itemBuilder: (context) =>
                              widget.textTracks!.asMap().entries.map((entry) {
                            final index = entry.key;
                            final track = entry.value;
                            return PopupMenuItem<int>(
                              value: index,
                              child: Row(
                                children: [
                                  Text(track['language'] ?? 'Unknown'),
                                  if (index ==
                                      _mediaService.currentSubtitleTrackIndex)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 8.0),
                                      child: Icon(Icons.check, size: 16),
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                          onSelected: (index) {
                            _mediaService.setSubtitleTrack(index);
                          },
                        ),
                      ),
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
          seekBarThumbColor: Colors.white,
          seekBarPositionColor: Theme.of(context).colorScheme.primary,
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
