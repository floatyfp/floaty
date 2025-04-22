//before you say it this is a very terribly rigged together audio player made from code stolen of the video player please dont judge this was purely added to make sure we supported media attachments for like the very little usage they get on floatplane

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:floaty/features/player/theme/audio_controls_theme.dart';
import 'package:floaty/features/player/components/audio_control_buttons.dart';
import 'package:floaty/features/player/controllers/media_player_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';

class AudioControls extends ConsumerStatefulWidget {
  final AudioControlsThemeData theme;

  const AudioControls({
    super.key,
    required this.theme,
  });

  @override
  ConsumerState<AudioControls> createState() => _AudioControlsState();
}

class _AudioControlsState extends ConsumerState<AudioControls> {
  late Player _player;
  Timer? _timer;
  bool visible = true;
  bool mount = true;
  double _volume = 1.0;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;

  AudioControlsThemeData get theme => widget.theme;

  @override
  void initState() {
    super.initState();
    final mediaService = ref.read(mediaPlayerServiceProvider.notifier);
    _player = mediaService.player;

    // Listen to player state changes
    _player.stream.position.listen((position) {
      if (mounted) {
        setState(() => _position = position);
      }
    });

    _player.stream.duration.listen((duration) {
      if (mounted) {
        setState(() => _duration = duration);
      }
    });

    _player.stream.volume.listen((volume) {
      if (mounted) {
        setState(() => _volume = volume / 100);
      }
    });

    _player.stream.playing.listen((playing) {
      if (mounted) {
        setState(() => _isPlaying = playing);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void onHover() {
    _timer?.cancel();
    if (mounted) {
      setState(() {
        visible = true;
        mount = true;
      });
    }
  }

  void onEnter() {
    _timer?.cancel();
    if (mounted) {
      setState(() {
        visible = true;
        mount = true;
      });
    }
  }

  void onExit() {
    _timer = Timer(theme.controlsHoverDuration, () {
      if (mounted) {
        setState(() {
          visible = false;
        });
      }
    });
  }

  void _handleSeek(Duration position) {
    final mediaService = ref.read(mediaPlayerServiceProvider.notifier);
    mediaService.seek(position);
  }

  void _handleVolumeChange(double volume) {
    final mediaService = ref.read(mediaPlayerServiceProvider.notifier);
    mediaService.setVolume(volume);
  }

  void _handlePlayPause() {
    final mediaService = ref.read(mediaPlayerServiceProvider.notifier);
    if (_isPlaying) {
      mediaService.pause();
    } else {
      mediaService.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        focusColor: const Color(0x00000000),
        hoverColor: const Color(0x00000000),
        splashColor: const Color(0x00000000),
        highlightColor: const Color(0x00000000),
      ),
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.space): _handlePlayPause,
          const SingleActivator(LogicalKeyboardKey.arrowLeft): () {
            _handleSeek(_position - const Duration(seconds: 5));
          },
          const SingleActivator(LogicalKeyboardKey.arrowRight): () {
            _handleSeek(_position + const Duration(seconds: 5));
          },
          const SingleActivator(LogicalKeyboardKey.arrowUp): () {
            _handleVolumeChange(_volume + 0.1);
          },
          const SingleActivator(LogicalKeyboardKey.arrowDown): () {
            _handleVolumeChange(_volume - 0.1);
          },
        },
        child: Stack(
          children: [
            // Main content area (transparent for interaction)
            Positioned.fill(
              child: GestureDetector(
                onTap: _handlePlayPause,
                behavior: HitTestBehavior.translucent,
                child: const SizedBox(),
              ),
            ),
            //top controls
            Positioned(
              left: 0,
              top: 0,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  final mediaService =
                      ref.read(mediaPlayerServiceProvider.notifier);
                  mediaService.changeState(MediaPlayerState.none);
                  mediaService.stop();
                  Navigator.pop(context);
                },
              ),
            ),
            // Controls overlay at bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Seek bar
                    Container(
                      height: theme.seekBarContainerHeight,
                      margin: theme.seekBarMargin,
                      child: MaterialSeekBar(
                        height: theme.seekBarHeight,
                        color: theme.seekBarColor,
                        activeColor: theme.seekBarPositionColor,
                        bufferColor: theme.seekBarBufferColor,
                        thumbSize: theme.seekBarThumbSize,
                        thumbColor: theme.seekBarThumbColor,
                        position: _position,
                        duration: _duration,
                        onSeekStart: () {},
                        onSeek: _handleSeek,
                        onSeekEnd: () {},
                      ),
                    ),
                    // Bottom controls
                    Container(
                      height: theme.buttonBarHeight,
                      margin: theme.bottomButtonBarMargin,
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          MaterialPlayOrPauseButton(
                            iconSize: 28.0,
                            isPlaying: _isPlaying,
                            onPressed: _handlePlayPause,
                          ),
                          MaterialPositionIndicator(
                            position: _position,
                            duration: _duration,
                          ),
                          const Spacer(),
                          MaterialVolumeButton(
                            iconSize: 24.0,
                            volume: _volume,
                            onVolumeChanged: _handleVolumeChange,
                          ),
                          PopupMenuButton<String>(
                            icon:
                                const Icon(Icons.settings, color: Colors.white),
                            itemBuilder: (context) => [
                              PopupMenuItem<String>(
                                value: 'playback_speed',
                                child: PopupMenuButton<double>(
                                  child: const Text('Playback Speed'),
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                        value: 0.5, child: Text('0.5x')),
                                    const PopupMenuItem(
                                        value: 1.0, child: Text('1.0x')),
                                    const PopupMenuItem(
                                        value: 1.5, child: Text('1.5x')),
                                    const PopupMenuItem(
                                        value: 2.0, child: Text('2.0x')),
                                  ],
                                  onSelected: (speed) {
                                    final mediaService = ref.read(
                                        mediaPlayerServiceProvider.notifier);
                                    mediaService.setSpeed(speed);
                                  },
                                ),
                              ),
                            ],
                            onSelected: (_) {},
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
