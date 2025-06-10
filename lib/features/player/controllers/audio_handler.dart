import 'package:audio_service/audio_service.dart';
import 'package:floaty/settings.dart';
import 'package:media_kit/media_kit.dart';
import 'package:logging/logging.dart';
import 'dart:async';
import 'package:audio_session/audio_session.dart';

class FloatyAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final Player _player;

  AudioSession? session;
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

  void _setupPlayerListeners() async {
    _player.stream.playing.listen((playing) {
      _updatePlaybackState(playing);
      session?.setActive(playing);
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
    // Configure audio session
    session = await AudioSession.instance;
    await session?.configure(
      const AudioSessionConfiguration.speech().copyWith(
        androidWillPauseWhenDucked: true,
      ),
    );

    session?.interruptionEventStream.listen((event) async {
      if (event.begin) {
        switch (event.type) {
          case AudioInterruptionType.duck:
            settings.setDynamic('audio_volume', _player.state.volume);
            _player.setVolume(30);
            break;
          case AudioInterruptionType.pause:
            pause();
            break;
          case AudioInterruptionType.unknown:
            pause();
            break;
        }
      } else {
        switch (event.type) {
          case AudioInterruptionType.duck:
            _player.setVolume(
                (await settings.getDynamic('audio_volume')) as double? ?? 100);
            break;
          case AudioInterruptionType.pause:
            play();
            break;
          case AudioInterruptionType.unknown:
            play();
            break;
        }
      }
    });
    session?.becomingNoisyEventStream.listen((_) {
      pause();
    });
  }

  @override
  Future<void> play() async {
    try {
      _log.info('Playing audio: ${_currentMedia?.title}');
      await _player.play();
      _updatePlaybackState(true);
      await session?.setActive(true);
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
      await session?.setActive(false);
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
      await super.stop();
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
        id: mediaItem.id,
        title: mediaItem.title,
        artist: mediaItem.artist,
        artUri: mediaItem.artUri,
        playable: true,
        displayTitle: mediaItem.title,
        displaySubtitle: mediaItem.artist,
        duration: mediaItem.duration,
        extras: mediaItem.extras,
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
