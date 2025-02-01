import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:media_kit/media_kit.dart';
import 'package:logging/logging.dart';
import 'dart:async';
import 'package:flutter/material.dart';

class FloatyAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final Player _player;
  MediaItem? _currentMedia;
  final _log = Logger('FloatyAudioHandler');

  FloatyAudioHandler(this._player) {
    _init();
  }

  Future<void> _init() async {
    try {
      _log.info('Initializing FloatyAudioHandler');

      // Set initial playback state
      playbackState.add(PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
          MediaAction.skipToNext,
          MediaAction.skipToPrevious,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: AudioProcessingState.idle,
        playing: false,
      ));

      // Configure audio session
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());

      debugPrint('I HAVE BEEN PRINTED YOUR MASTER');
      session.interruptionEventStream.listen((_) async {
        debugPrint('I HAVE BEEN CALLED UPON YOUR MASTER');
        await pause();
      });

      // TODO: add settings for these
      // Handle audio interruptions
      session.interruptionEventStream.listen((event) async {
        if (event.begin) {
          switch (event.type) {
            case AudioInterruptionType.duck:
              _player.setVolume(30);
              debugPrint('DUCK');
              break;
            case AudioInterruptionType.pause:
              await pause();
              debugPrint('PAUSE');
              break;
            case AudioInterruptionType.unknown:
              await pause();
              debugPrint('UNKNOWN');
              break;
          }
        } else {
          switch (event.type) {
            case AudioInterruptionType.duck:
              _player.setVolume(100);
              debugPrint('DUCKUP');
              break;
            case AudioInterruptionType.pause:
              if (playbackState.value.playing) await play();
              debugPrint('PAUSEUP');
              break;
            case AudioInterruptionType.unknown:
              debugPrint('UNKNOWNUP');
              break;
          }
        }
      });
      _setupPlayerListeners();
      _log.info('FloatyAudioHandler initialized successfully');
    } catch (e, stack) {
      _log.severe('Error initializing FloatyAudioHandler', e, stack);
      rethrow;
    }
  }

  void _updatePlaybackState(bool playing,
      {AudioProcessingState? processingState}) {
    final duration = _currentMedia?.duration ?? const Duration(minutes: 5);
    playbackState.add(playbackState.value.copyWith(
      controls: _getControls(playing),
      systemActions: {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
        MediaAction.skipToNext,
        MediaAction.skipToPrevious,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: processingState ?? AudioProcessingState.ready,
      playing: playing,
      updatePosition: _player.state.position,
      bufferedPosition: duration,
      speed: 1.0,
    ));
  }

  List<MediaControl> _getControls(bool playing) {
    return [
      MediaControl.skipToPrevious,
      playing ? MediaControl.pause : MediaControl.play,
      MediaControl.skipToNext,
    ];
  }

  void _setupPlayerListeners() {
    _player.stream.playing.listen((playing) {
      _updatePlaybackState(playing);
    });

    _player.stream.position.listen((position) {
      final duration = _currentMedia?.duration ?? const Duration(minutes: 5);
      playbackState.add(playbackState.value.copyWith(
        updatePosition: position,
        bufferedPosition: duration,
      ));
    });

    _player.stream.duration.listen((duration) {
      if (_currentMedia != null) {
        final updatedMedia = _currentMedia!.copyWith(duration: duration);
        _currentMedia = updatedMedia;
        mediaItem.add(updatedMedia);
        _updatePlaybackState(_player.state.playing);
      }
    });

    _player.stream.completed.listen((completed) {
      if (completed) {
        _updatePlaybackState(false,
            processingState: AudioProcessingState.completed);
      }
    });
  }

  @override
  Future<void> play() async {
    try {
      _log.info('Playing audio: ${_currentMedia?.title}');
      await _player.play();
      _updatePlaybackState(true);
    } catch (e, stack) {
      _log.severe('Error playing audio', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> pause() async {
    try {
      _log.info('Pausing audio: ${_currentMedia?.title}');
      await _player.pause();
      _updatePlaybackState(false);
    } catch (e, stack) {
      _log.severe('Error pausing audio', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> stop() async {
    try {
      _log.info('Stopping audio: ${_currentMedia?.title}');
      await _player.stop();
      _updatePlaybackState(false, processingState: AudioProcessingState.idle);
    } catch (e, stack) {
      _log.severe('Error stopping audio', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
      _updatePlaybackState(_player.state.playing);
    } catch (e, stack) {
      _log.severe('Error seeking audio', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> skipToNext() async {
    try {
      final newPosition = _player.state.position + const Duration(seconds: 5);
      await seek(newPosition);
    } catch (e, stack) {
      _log.severe('Error seeking forward', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> skipToPrevious() async {
    try {
      final newPosition = _player.state.position - const Duration(seconds: 5);
      await seek(newPosition.isNegative ? Duration.zero : newPosition);
    } catch (e, stack) {
      _log.severe('Error seeking backward', e, stack);
      rethrow;
    }
  }

  Future<void> setVolume(double volume) async {
    try {
      await _player.setVolume(volume * 100);
    } catch (e, stack) {
      _log.severe('Error setting volume', e, stack);
      rethrow;
    }
  }

  Future<void> setMedia(MediaItem mediaItem) async {
    try {
      _log.info('Setting media: ${mediaItem.title}');

      // Start with a temporary duration, will be updated by stream
      mediaItem = mediaItem.copyWith(
        playable: true,
        displayTitle: mediaItem.title,
        displaySubtitle: mediaItem.artist,
        duration: const Duration(minutes: 5), // Temporary duration
      );
      _currentMedia = mediaItem;

      // Update both the current mediaItem and queue
      super.mediaItem.add(mediaItem);
      queue.add([mediaItem]);

      playbackState.add(PlaybackState(
        controls: _getControls(false),
        systemActions: {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
          MediaAction.skipToNext,
          MediaAction.skipToPrevious,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: AudioProcessingState.ready,
        playing: false,
        updatePosition: Duration.zero,
        bufferedPosition: const Duration(
            minutes: 5), // Will be updated when real duration arrives
        speed: 1.0,
      ));
    } catch (e, stack) {
      _log.severe('Error setting media', e, stack);
      rethrow;
    }
  }

  Future<void> dispose() async {
    try {
      _log.info('Disposing audio handler');
      await stop();
    } catch (e, stack) {
      _log.severe('Error disposing audio handler', e, stack);
      rethrow;
    }
  }
}
