import 'dart:io';
import 'dart:async';
import 'package:floaty/features/api/repositories/fpapi.dart';
import 'package:floaty/features/router/views/root_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:window_manager/window_manager.dart';
import 'package:audio_service/audio_service.dart';
import 'package:logging/logging.dart';
import 'audio_handler.dart';
import 'windows_media_controls.dart';
import '../models/video_quality.dart';
import 'package:floaty/settings.dart';
import 'package:simple_pip_mode/simple_pip.dart';

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

final mediaPlayerServiceProvider =
    StateNotifierProvider<MediaPlayerService, MediaPlayerState>(
        (ref) => MediaPlayerService());

class MediaPlayerService extends StateNotifier<MediaPlayerState> {
  PackageInfo? packageInfo;
  String userAgent = 'FloatyClient/error, CFNetwork';
  static final MediaPlayerService _instance = MediaPlayerService._internal();

  factory MediaPlayerService() {
    return _instance;
  }

  MediaPlayerService._internal() : super(MediaPlayerState.none) {
    _log = Logger('MediaPlayerService');
    globalPlayer = Player(); // Initialize player immediately
    _subtitlesEnabled = false; // Default value until initialized
    _initSettings(); // Initialize settings
  }

  Future<void> _initSettings() async {
    _subtitlesEnabled = (await Settings().getBool('subtitles_enabled'));
    state = state; // Notify listeners
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
  String? _currentThumbnailUrl;
  String? _currentPostId;
  bool _live = false;
  dynamic _currentAttachment;
  VideoQuality? _currentQuality;
  List<VideoQuality> _availableQualities = [];
  VideoController? _videoController;
  Duration? _lastReportedPosition;
  List<Map<String, dynamic>>? _currentTextTracks;
  bool _subtitlesEnabled = false;
  int? _currentSubtitleTrackIndex;
  bool _pip = false;
  Size? _restoreSize;

  late SimplePip _simplePip;

  // Getters
  VideoController? get videoController => _videoController;
  bool get isPlaying => _isPlaying;
  bool get playing => globalPlayer?.state.playing ?? false;
  Duration get currentPosition => _position;
  Duration get audioDuration => _duration;
  double get volumeLevel => _volume;
  VideoQuality? get currentQuality => _currentQuality;
  List<VideoQuality> get availableQualities => _availableQualities;
  bool get subtitlesEnabled => _subtitlesEnabled;
  List<Map<String, dynamic>>? get textTracks => _currentTextTracks;
  int? get currentSubtitleTrackIndex => _currentSubtitleTrackIndex;
  String? get currentTitle => _currentTitle;
  String? get currentArtist => _currentArtist;
  String? get currentThumbnailUrl => _currentThumbnailUrl;
  String? get currentPostId => _currentPostId;
  bool get currentLive => _live;
  String? get currentAttachmentId => _currentAttachment?.id;
  dynamic get currentAttachment => _currentAttachment;
  String? get selectedMediaName => _currentMediaType?.name;
  SimplePip get simplePip => _simplePip;
  MediaPlayerState get mediastate => state;

  void _setupPlayerListeners() {
    _simplePip = SimplePip(
      onPipExited: () {
        if (_live) {
          rootLayoutKey.currentContext?.go('/live/$currentPostId');
        } else {
          rootLayoutKey.currentContext?.go('/post/$currentPostId');
        }
      },
    );
    if (globalPlayer == null) return;

    if (_live == true) {
      (globalPlayer!.platform as NativePlayer)
          .setProperty('profile', 'low-latency');
    } else {
      (globalPlayer!.platform as NativePlayer)
          .setProperty('profile', 'default');
    }

    player.stream.position.listen((position) {
      _position = position;
      if (_live != true) {
        if (_lastReportedPosition == null ||
            position.inMinutes > _lastReportedPosition!.inMinutes) {
          _lastReportedPosition = position;

          fpApiRequests.progress(_currentAttachment.id!, position.inSeconds,
              _currentMediaType == MediaType.video ? 'video' : 'audio');
        }
      }
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

    if (_live != true) {
      player.stream.completed.listen((completed) {
        fpApiRequests.progress(_currentAttachment.id!, _duration.inSeconds,
            _currentMediaType == MediaType.video ? 'video' : 'audio');
      });
    }
  }

  // Initialization state management
  bool _isInitialized = false;
  Completer<void>? _initializeCompleter;

  Future pipfalse() async {
    _pip = false;
    windowManager.setSize(_restoreSize ?? Size(480, 270));
    _restoreSize = null;
    windowManager.setAlwaysOnTop(false);
    windowManager.center();
    windowManager.setTitleBarStyle(TitleBarStyle.normal);
  }

  Future<void> _ensureInitialized() async {
    packageInfo = await PackageInfo.fromPlatform();
    userAgent =
        'FloatyClient/${packageInfo?.version}+${packageInfo?.buildNumber}, CFNetwork';

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
          androidNotificationIcon: 'mipmap/ic_notification',
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
    MediaType type,
    bool live, {
    String? title,
    String? artist,
    String? postId,
    String? thumbnailUrl,
    dynamic attachment,
    List<VideoQuality>? qualities,
    Map<String, String>? headers,
    Duration start = Duration.zero,
    List<Map<String, dynamic>>? textTracks,
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
      _live = live;
      _currentMediaUrl = url;
      _currentMediaType = type;
      _currentTitle = title;
      _currentArtist = artist;
      _currentPostId = postId;
      _currentThumbnailUrl = thumbnailUrl;
      _currentAttachment = attachment;
      _currentTextTracks = textTracks;
      _currentSubtitleTrackIndex = textTracks?.isNotEmpty == true ? 0 : null;

      if (qualities != null) {
        _availableQualities = qualities;
        _currentQuality = qualities.first;
        String? preferredQuality = await settings.getKey('preferred_quality');
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

      _log.info(
          'Setting up media with text tracks: ${textTracks?.length ?? 0}');

      final subtitleList = textTracks
              ?.map((track) => {
                    'title': track['language'] ?? 'Unknown',
                    'language': track['language'] ?? 'und',
                    'url': track['src'],
                    'selected': textTracks.indexOf(track) == 0,
                  })
              .toList() ??
          [];

      final media = Media(
        url,
        httpHeaders: headers ??
            {
              'User-Agent': userAgent,
              'Cookie': await settings.getAuthTokenFromCookieJar() ?? '',
            },
        start: start,
        extras: {
          'subtitle': subtitleList,
        },
      );

      await player.open(media);
      _log.info('Media opened successfully');

      // Initialize subtitle track if available
      if (textTracks?.isNotEmpty == true && subtitlesEnabled) {
        final defaultTrack = textTracks!.first;

        await player.setSubtitleTrack(
          SubtitleTrack.uri(
            defaultTrack['src'],
            title: defaultTrack['language'],
            language: defaultTrack['language'],
          ),
        );
        _currentSubtitleTrackIndex = 0;
      } else {
        _currentTextTracks = textTracks;
        _currentSubtitleTrackIndex = 0;
      }

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
        extras: {
          'postId': _currentPostId,
        },
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

  Future<void> enterpip() async {
    _simplePip.enterPipMode(aspectRatio: (
      globalPlayer?.state.width ?? 16,
      globalPlayer?.state.height ?? 9
    ));
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

  Future<void> playpause() async {
    await _ensureInitialized();
    if (_currentMediaType == MediaType.audio ||
        _currentMediaType == MediaType.video) {
      if (_isPlaying) {
        await pause();
      } else {
        await play();
      }
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
            'User-Agent': userAgent,
            'Cookie': await settings.getAuthTokenFromCookieJar() ?? '',
          },
      start: position,
    );

    _currentQuality = quality;
    settings.setKey('preferred_quality', quality.label);

    await player.open(media, play: play);
    _videoController = VideoController(player);
  }

  Future<void> changeState(MediaPlayerState newState) async {
    if (state == newState) {
      return;
    }

    if (globalPlayer == null) {
      return;
    }

    state = newState;

    switch (newState) {
      case MediaPlayerState.pip:
        if (!Platform.isIOS) {
          if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
            _restoreSize = await windowManager.getSize();
            _pip = true;
            windowManager.setAlwaysOnTop(true);
            windowManager.unmaximize();
            windowManager.dock;
            windowManager.setSize(Size(480, 270));
            windowManager.setTitleBarStyle(TitleBarStyle.hidden);
          }
        }
        break;
      case MediaPlayerState.mini:
        if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
          if (!_pip) {
            windowManager.setAlwaysOnTop(false);
            windowManager.setTitleBarStyle(TitleBarStyle.normal);
            if (_restoreSize != null) {
              windowManager.setSize(_restoreSize ?? Size(480, 270));
              _restoreSize = null;
              windowManager.center();
            }
          }
        }
        break;
      case MediaPlayerState.main:
        if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
          if (!_pip) {
            if (_restoreSize != null) {
              windowManager.setSize(_restoreSize ?? Size(480, 270));
              _restoreSize = null;
              windowManager.center();
            }
            windowManager.setAlwaysOnTop(false);
            windowManager.setTitleBarStyle(TitleBarStyle.normal);
          }
        }
        break;
      case MediaPlayerState.none:
        await stop();
        break;
    }
  }

  Future<void> setSpeed(double speed) async {
    player.setRate(speed);
  }

  Future<void> toggleSubtitles() async {
    _subtitlesEnabled = !_subtitlesEnabled;
    await settings.setBool('subtitles_enabled', _subtitlesEnabled);
    _log.info('Toggling subtitles: ${_subtitlesEnabled ? 'on' : 'off'}');

    if (!_subtitlesEnabled) {
      await player.setSubtitleTrack(SubtitleTrack.no());
    } else if (_currentSubtitleTrackIndex != null &&
        _currentTextTracks != null) {
      final track = _currentTextTracks![_currentSubtitleTrackIndex!];

      await player.setSubtitleTrack(
        SubtitleTrack.uri(
          track['src'],
          title: track['language'],
          language: track['language'],
        ),
      );
    }
    state = state;
  }

  Future<void> setSubtitleTrack(int index) async {
    if (_currentTextTracks == null || index >= _currentTextTracks!.length) {
      _log.warning('Invalid subtitle track index: $index');
      return;
    }

    _log.info('Setting subtitle track to index $index');
    _currentSubtitleTrackIndex = index;
    final track = _currentTextTracks![index];

    settings.setBool('subtitles_enabled', true);

    await player.setSubtitleTrack(
      SubtitleTrack.uri(
        track['src'],
        title: track['language'],
        language: track['language'],
      ),
    );
    state = state;
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
      // await audioHandler?;
      await audioHandler?.session?.setActive(false);
    }
    await windowsControls?.stop();
  }
}
