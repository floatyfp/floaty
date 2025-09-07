import 'dart:io';
import 'package:floaty/features/player/controllers/media_player_service.dart';
import 'package:smtc_windows/smtc_windows.dart';

class WindowsMediaControls {
  final MediaPlayerService mediaService;
  late SMTCWindows _smtc;
  bool _isInitialized = false;

  WindowsMediaControls(this.mediaService);

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
        endTimeMs: mediaService.audioDuration.inMilliseconds,
        positionMs: mediaService.currentPosition.inMilliseconds,
        minSeekTimeMs: 0,
        maxSeekTimeMs: mediaService.audioDuration.inMilliseconds,
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
          mediaService.play();
          _smtc.setPlaybackStatus(PlaybackStatus.playing);
          break;
        case PressedButton.pause:
          mediaService.pause();
          _smtc.setPlaybackStatus(PlaybackStatus.paused);
          break;
        case PressedButton.next:
          mediaService.seek(mediaService.currentPosition +
              Duration(seconds: 10)); // Skip forward 10 seconds
          break;
        case PressedButton.previous:
          mediaService.seek(mediaService.currentPosition -
              Duration(seconds: 10)); // Rewind 10 seconds
          break;
        default:
          break;
      }
    });

    // Update SMTC state based on player state
    mediaService.playingStream.listen((playing) {
      _smtc.setPlaybackStatus(
        playing ? PlaybackStatus.playing : PlaybackStatus.paused,
      );
    });

    mediaService.positionStream.listen((position) {
      _smtc.updateTimeline(
        PlaybackTimeline(
          startTimeMs: 0,
          endTimeMs: mediaService.audioDuration.inMilliseconds,
          positionMs: position.inMilliseconds,
          minSeekTimeMs: 0,
          maxSeekTimeMs: mediaService.audioDuration.inMilliseconds,
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
