import 'dart:io';
import 'package:smtc_windows/smtc_windows.dart';
import 'package:media_kit/media_kit.dart';

class WindowsMediaControls {
  final Player _player;
  late SMTCWindows _smtc;
  bool _isInitialized = false;

  WindowsMediaControls(this._player);

  Future<void> initialize() async {
    if (!Platform.isWindows || _isInitialized) return;

    await SMTCWindows.initialize();

    _smtc = SMTCWindows(
      metadata: const MusicMetadata(
        title: 'Unknown Title',
        artist: 'Unknown Artist',
      ),
      timeline: PlaybackTimeline(
        startTimeMs: 0,
        endTimeMs: _player.state.duration.inMilliseconds,
        positionMs: _player.state.position.inMilliseconds,
        minSeekTimeMs: 0,
        maxSeekTimeMs: _player.state.duration.inMilliseconds,
      ),
      config: const SMTCConfig(
        playEnabled: true,
        pauseEnabled: true,
        stopEnabled: false,
        nextEnabled: true,
        prevEnabled: true,
        fastForwardEnabled: false,
        rewindEnabled: false,
      ),
    );

    // Set up button handlers
    _smtc.buttonPressStream.listen((button) {
      switch (button) {
        case PressedButton.play:
          _player.play();
          _smtc.setPlaybackStatus(PlaybackStatus.playing);
          break;
        case PressedButton.pause:
          _player.pause();
          _smtc.setPlaybackStatus(PlaybackStatus.paused);
          break;
        case PressedButton.next:
          _player.seek(_player.state.position +
              Duration(seconds: 10)); // Skip forward 10 seconds
          break;
        case PressedButton.previous:
          _player.seek(_player.state.position -
              Duration(seconds: 10)); // Rewind 10 seconds
          break;
        default:
          break;
      }
    });

    // Update SMTC state based on player state
    _player.stream.playing.listen((playing) {
      _smtc.setPlaybackStatus(
        playing ? PlaybackStatus.playing : PlaybackStatus.paused,
      );
    });

    _player.stream.position.listen((position) {
      _smtc.updateTimeline(
        PlaybackTimeline(
          startTimeMs: 0,
          endTimeMs: _player.state.duration.inMilliseconds,
          positionMs: position.inMilliseconds,
          minSeekTimeMs: 0,
          maxSeekTimeMs: _player.state.duration.inMilliseconds,
        ),
      );
    });

    _isInitialized = true;
  }

  void updateMetadata({
    required String title,
    String? artist,
    String? album,
    String? thumbnailUrl,
  }) {
    if (!Platform.isWindows || !_isInitialized) return;

    _smtc.enableSmtc();
    _smtc.updateMetadata(
      MusicMetadata(
        title: title,
        artist: artist ?? 'Unknown Artist',
        album: album,
        thumbnail: thumbnailUrl,
      ),
    );
  }

  Future<void> dispose() async {
    if (!Platform.isWindows || !_isInitialized) return;
    _smtc.dispose();
    _isInitialized = false;
  }

  Future<void> stop() async {
    if (!Platform.isWindows || !_isInitialized) return;
    _smtc.disableSmtc();
  }
}
