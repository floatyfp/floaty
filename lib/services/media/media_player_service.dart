// ignore_for_file: unused_field

import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:window_manager/window_manager.dart';
import 'package:audio_service/audio_service.dart';
import 'package:logging/logging.dart';
import 'audio_handler.dart';
import 'windows_media_controls.dart';
import 'video_quality.dart';
import 'package:floaty/settings.dart';

enum MediaType {
  audio,
  video,
  image,
}

enum MediaPlayerState {
  none,
  main,
  mini,
  pip,
}

class MediaPlayerService extends StateNotifier<MediaPlayerState> {
  static final MediaPlayerService _instance = MediaPlayerService._internal();

  factory MediaPlayerService() {
    return _instance;
  }

  MediaPlayerService._internal() : super(MediaPlayerState.none) {
    _log = Logger('MediaPlayerService');
    globalPlayer = Player(); // Initialize player immediately
  }

  static Player? globalPlayer;
  Player get player => globalPlayer!;
  FloatyAudioHandler? audioHandler;
  WindowsMediaControls? windowsControls;
  late final Logger _log;

  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _volume = 1.0;
  String? _currentMediaUrl;
  MediaType? _currentMediaType;
  String? _currentTitle;
  String? _currentArtist;
  dynamic _currentAttachment;
  VideoQuality? _currentQuality;
  List<VideoQuality> _availableQualities = [];
  VideoController? _videoController;

  // Getters
  VideoController? get videoController => _videoController;
  bool get isPlaying => _isPlaying;
  Duration get currentPosition => _position;
  Duration get audioDuration => _duration;
  double get volumeLevel => _volume;
  VideoQuality? get currentQuality => _currentQuality;
  List<VideoQuality> get availableQualities => _availableQualities;

  void _setupPlayerListeners() {
    if (globalPlayer == null) return;

    player.stream.position.listen((position) {
      _position = position;
    });

    player.stream.duration.listen((duration) {
      _duration = duration;
    });

    player.stream.volume.listen((volume) {
      _volume = volume / 100; // Convert from 0-100 to 0-1
    });

    player.stream.playing.listen((playing) {
      _isPlaying = playing;
    });
  }

  // Initialization state management
  bool _isInitialized = false;
  Completer<void>? _initializeCompleter;

  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;
    _initializeCompleter = Completer<void>();

    try {
      _log.info('Initializing MediaPlayerService');

      await player.setVolume(_volume * 100);

      // Initialize audio service and platform-specific controls
      await _startSession();

      _setupPlayerListeners();
      _isInitialized = true;
      _log.info('MediaPlayerService initialization completed successfully');
      _initializeCompleter!.complete();
    } catch (e, stack) {
      _log.severe('Error initializing MediaPlayerService', e, stack);
      _initializeCompleter!.completeError(e, stack);
      rethrow;
    }
  }

  Future<void> _startSession() async {
    Logger.root.info('starting audio service...');

    // Initialize media player
    if (!Platform.isWindows) {
      // For non-Windows platforms, initialize audio service
      audioHandler = await AudioService.init(
        builder: () => FloatyAudioHandler(player),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'uk.bw86.floaty.channel.audio',
          androidNotificationChannelName: 'Audio playback',
          androidNotificationOngoing: true,
        ),
      );
    }

    // Initialize Windows-specific controls
    if (Platform.isWindows) {
      windowsControls = WindowsMediaControls(player);
      await windowsControls?.initialize();
    }

    Logger.root.info('audio player initialized!');
  }

  Future<void> setSource(
    String url,
    MediaType type, {
    String? title,
    String? artist,
    String? thumbnailUrl,
    dynamic attachment,
    List<VideoQuality>? qualities,
    Map<String, String>? headers,
    Duration start = Duration.zero,
  }) async {
    _log.info('Setting source: $url');
    await _ensureInitialized();

    // Don't reinitialize if the URL hasn't changed
    if (_currentMediaUrl == url) {
      _log.info('Source URL unchanged, skipping initialization');
      return;
    }

    try {
      _log.info('Updating media source...');
      _currentMediaUrl = url;
      _currentMediaType = type;
      _currentTitle = title;
      _currentArtist = artist;
      _currentAttachment = attachment;

      if (qualities != null) {
        _availableQualities = qualities;
        _currentQuality = qualities.first;
        String? preferredQuality = await Settings().getKey('preferred_quality');
        if (preferredQuality.isNotEmpty) {
          VideoQuality? selectedQuality = qualities.firstWhere(
            (quality) => quality.label == preferredQuality,
            orElse: () => qualities.first, // Fallback to the first quality
          );
          _currentQuality = selectedQuality; // Just use the URL directly
        } else {
          // Check for 1080p quality
          VideoQuality? defaultQuality = qualities.firstWhere(
              (quality) => quality.label == '1080p',
              orElse: () => qualities
                  .first // Fallback to the first quality if 1080p doesn't exist
              );
          _currentQuality = defaultQuality;
        }
      }

      await player.stop();

      final media = Media(
        url,
        httpHeaders: headers ??
            {
              'User-Agent':
                  'FloatyClient/1.0.0, CFNetwork', // Default User-Agent
              'Cookie': await Settings().getKey('token'),
            },
        start: start,
      );
      await player.open(media);

      if (type == MediaType.video) {
        _videoController = VideoController(player);
      }

      // // Wait briefly for duration
      // await Future.delayed(const Duration(milliseconds: 100));

      // Update media metadata
      if (type == MediaType.audio || type == MediaType.video) {
        await _updateMediaMetadata(title, artist, thumbnailUrl);
      }

      _log.info('Source set successfully');
    } catch (e) {
      _log.severe('Error setting source: $e');
      rethrow;
    }
  }

  Future<void> _updateMediaMetadata(
    String? title,
    String? artist,
    String? thumbnailUrl,
  ) async {
    if (!Platform.isWindows && audioHandler != null) {
      await audioHandler!.setMedia(MediaItem(
        id: _currentMediaUrl!,
        title: title ?? 'Unknown Title',
        artist: artist,
        artUri: thumbnailUrl != null ? Uri.parse(thumbnailUrl) : null,
        playable: true,
        displayTitle: title ?? 'Unknown Title',
        displaySubtitle: artist,
        duration: _duration,
      ));

      // Update playback state after setting media
      if (_isPlaying) {
        await audioHandler!.play();
      } else {
        await audioHandler!.pause();
      }
    }

    if (Platform.isWindows) {
      windowsControls?.updateMetadata(
        title: title ?? 'Unknown Title',
        artist: artist,
        thumbnailUrl: thumbnailUrl,
      );
    }
  }

  Future<void> play() async {
    await _ensureInitialized();
    if (_currentMediaType == MediaType.audio ||
        _currentMediaType == MediaType.video) {
      await player.play();
      if (!Platform.isWindows) {
        await audioHandler?.play();
      }
      _isPlaying = true;
    }
  }

  Future<void> pause() async {
    await _ensureInitialized();
    if (_currentMediaType == MediaType.audio ||
        _currentMediaType == MediaType.video) {
      await player.pause();
      if (!Platform.isWindows) {
        await audioHandler?.pause();
      }
      _isPlaying = false;
    }
  }

  Future<void> seek(Duration position) async {
    await _ensureInitialized();
    if (_currentMediaType == MediaType.audio ||
        _currentMediaType == MediaType.video) {
      await player.seek(position);
      if (!Platform.isWindows) {
        await audioHandler?.seek(position);
      }
      _position = position;
    }
  }

  Future<void> setVolume(double volume) async {
    await _ensureInitialized();
    if (_currentMediaType == MediaType.audio ||
        _currentMediaType == MediaType.video) {
      await player.setVolume(volume * 100); // Convert from 0-1 to 0-100
      if (!Platform.isWindows) {
        await audioHandler?.setVolume(volume);
      }
      _volume = volume;
    }
  }

  Future<void> changeQuality(VideoQuality quality,
      {Map<String, String>? headers}) async {
    if (!_availableQualities.contains(quality)) return;

    final position = player.state.position;
    final play = player.state.playing;

    final media = Media(
      quality.url,
      httpHeaders: headers ??
          {
            'User-Agent': 'FloatyClient/1.0.0, CFNetwork',
            'Cookie': await Settings().getKey('token'),
          },
      start: position,
    );
    await player.open(media, play: play);
    _videoController = VideoController(player);
  }

  Future<void> changeState(MediaPlayerState newState) async {
    if (state == newState) return;

    switch (newState) {
      case MediaPlayerState.pip:
        if (!Platform.isIOS) {
          if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
            await windowManager.setAlwaysOnTop(true);
            await windowManager.setSize(const Size(320, 180));
          }
        }
        break;
      case MediaPlayerState.mini:
        if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
          await windowManager.setAlwaysOnTop(false);
        }
        break;
      case MediaPlayerState.main:
        if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
          await windowManager.setAlwaysOnTop(false);
          // TODO: Store size and restore on switch
          // await windowManager.setSize(const Size(1280, 720));
        }
        break;
      case MediaPlayerState.none:
        break;
    }

    state = newState;
  }

  Future<void> setSpeed(double speed) async {
    player.setRate(speed);
  }

  @override
  Future<void> dispose() async {
    if (globalPlayer != null) {
      await globalPlayer!.dispose();
      globalPlayer = null;
    }
    if (!Platform.isWindows) {
      await audioHandler?.dispose();
    }
    await windowsControls?.dispose();
    super.dispose();
  }

  Future<void> stop() async {
    await player.stop();
    if (!Platform.isWindows) {
      await audioHandler?.stop();
    }
    await windowsControls?.stop();
  }
}

final mediaPlayerServiceProvider =
    StateNotifierProvider<MediaPlayerService, MediaPlayerState>((ref) {
  return MediaPlayerService();
});
