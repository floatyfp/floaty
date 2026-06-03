import 'dart:io';
import 'package:dio/dio.dart';
import 'package:floaty/features/api/models/definitions.dart';
import 'dart:async';
import 'package:floaty/features/api/repositories/fpapi.dart';
import 'package:floaty/features/authentication/services/oauth2_service.dart';
import 'package:floaty/features/player/models/seekbar_chapter.dart';
import 'package:floaty/features/discordrpc/controllers/discord_rpc_controller.dart';
import 'package:floaty/whitelabels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_discord_rpc/flutter_discord_rpc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pip/pip.dart';
import 'package:window_manager/window_manager.dart';
import 'package:audio_service/audio_service.dart';
import 'package:logging/logging.dart';
import 'audio_handler.dart';
import 'windows_media_controls.dart';
import '../models/video_quality.dart';
import 'package:floaty/features/player/models/subtitle_style.dart';
import 'package:floaty/settings.dart';

enum PlayerType {
  mediaKit,
  // betterPlayer,
}

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
    NotifierProvider<MediaPlayerService, MediaPlayerState>(
        MediaPlayerService.new);

class MediaPlayerService extends Notifier<MediaPlayerState> {
  PackageInfo? packageInfo;
  String userAgent = 'FloatyClient/error';
  static final MediaPlayerService _instance = MediaPlayerService._internal();
  PlayerType? selectedPlayerType;
  PlayerType? loadedPlayerType;
  static Player? mediaKitPlayer;
  Player get mediaKit => mediaKitPlayer!;
  FloatyAudioHandler? audioHandler;
  WindowsMediaControls? windowsControls;
  final Logger _log = Logger('MediaPlayerService');
  bool _initialized = false;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  Duration _buffer = Duration.zero;
  bool _buffering = false;
  double _playbackSpeed = 1.0;
  double _volume = 1.0;
  String? _currentMediaUrl;
  MediaType? _currentMediaType;
  String? _currentTitle;
  String? _currentArtist;
  String? _currentArtistImage;
  String? _currentThumbnailUrl;
  ImageModel? _currentTimelineSprite;
  String? _currentPostId;
  bool _currentDiscoverable = false;
  bool _live = false;
  bool _isOffline = false;
  ContentPostV3Response? _offlinePost;
  String? _offlineAttachmentId;
  String? _offlineFilePath;
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
  List<SeekbarChapter>? _chapters;
  String? _whitelabelName;
  WhiteLabel? _whitelabel;
  final Pip _pipController = Pip();
  bool _betterPlayerPipActive = false;
  bool get betterPlayerPipActive => _betterPlayerPipActive;
  void setBetterPlayerPipActive() {
    _betterPlayerPipActive = true;
  }

  void clearBetterPlayerPipActive() {
    _betterPlayerPipActive = false;
    changeState(MediaPlayerState.main);
  }

  final StreamController<bool> _playingController =
      StreamController<bool>.broadcast();
  final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();
  final StreamController<Duration> _durationController =
      StreamController<Duration>.broadcast();
  final StreamController<Duration> _bufferController =
      StreamController<Duration>.broadcast();
  final StreamController<double> _volumeController =
      StreamController<double>.broadcast();
  final StreamController<bool> _completedController =
      StreamController<bool>.broadcast();
  final StreamController<bool> _bufferingController =
      StreamController<bool>.broadcast();
  final StreamController<double> _playbackSpeedController =
      StreamController<double>.broadcast();
  final StreamController<String?> _subtitleTextController =
      StreamController<String?>.broadcast();
  Stream<String?> get subtitleTextStream => _subtitleTextController.stream;
  List<_VttCue> _currentCues = [];
  final StreamController<SubtitleStyle> _subtitleStyleController =
      StreamController<SubtitleStyle>.broadcast();
  Stream<SubtitleStyle> get subtitleStyleStream =>
      _subtitleStyleController.stream;
  // Stream to signal that PiP has exited (used by UI to pop overlays)
  final StreamController<bool> _pipExitController =
      StreamController<bool>.broadcast();
  Stream<bool> get pipExitStream => _pipExitController.stream;
  late SubtitleStyle _subtitleStyle = SubtitleStyle.defaultStyle();
  SubtitleStyle get currentSubtitleStyle => _subtitleStyle;
  // Getters
  VideoController? get videoController => _videoController;
  bool get isPlaying => _isPlaying;
  bool get playing => _isPlaying;
  Duration get buffer => _buffer;
  bool get buffering => _buffering;
  Duration get currentPosition => _position;
  Duration get currentDuration => _duration;
  Duration get audioDuration => _duration;
  double get playbackSpeed => _playbackSpeed;
  double get volumeLevel => _volume;
  VideoQuality? get currentQuality => _currentQuality;
  List<VideoQuality> get availableQualities => _availableQualities;
  bool get subtitlesEnabled => _subtitlesEnabled;
  List<Map<String, dynamic>>? get textTracks => _currentTextTracks;
  int? get currentSubtitleTrackIndex => _currentSubtitleTrackIndex;
  String? get currentTitle => _currentTitle;
  String? get currentArtist => _currentArtist;
  String? get currentArtistImage => _currentArtistImage;
  String? get currentThumbnailUrl => _currentThumbnailUrl;
  String? get currentMediaUrl => _currentMediaUrl;
  ImageModel? get currentTimelineSprite => _currentTimelineSprite;
  String? get currentPostId => _currentPostId;
  bool get currentLive => _live;
  bool get isOffline => _isOffline;
  ContentPostV3Response? get offlinePost => _offlinePost;
  String? get offlineAttachmentId => _offlineAttachmentId;
  String? get offlineFilePath => _offlineFilePath;
  String? get currentAttachmentId => _currentAttachment?.id;
  dynamic get currentAttachment => _currentAttachment;
  String? get selectedMediaName => _currentMediaType?.name;
  Pip get pipController => _pipController;
  MediaPlayerState get mediastate => state;
  List<SeekbarChapter>? get chapters => _chapters;
  // Unified stream getters
  Stream<bool> get playingStream => _playingController.stream;
  Stream<Duration> get positionStream => _positionController.stream;
  Stream<Duration> get durationStream => _durationController.stream;
  Stream<Duration> get bufferStream => _bufferController.stream;
  Stream<double> get volumeStream => _volumeController.stream;
  Stream<bool> get completedStream => _completedController.stream;
  Stream<bool> get bufferingStream => _bufferingController.stream;
  Stream<double> get playbackSpeedStream => _playbackSpeedController.stream;
  factory MediaPlayerService() {
    return _instance;
  }

  @override
  MediaPlayerState build() {
    _log.info('Initializing MediaPlayerService via Notifier build...');
    _init(); // Initialize
    return MediaPlayerState.none;
  }

  MediaPlayerService._internal() {
    _log.info('Initializing MediaPlayerService via singleton...');
    _init(); // Initialize
  }
  Future<void> _init() async {
    if (_initialized) {
      _log.info('MediaPlayerService: _init already called, skipping');
      return;
    }
    _initialized = true;
    packageInfo = await PackageInfo.fromPlatform();
    const flavor =
        String.fromEnvironment('FLUTTER_FLAVOR', defaultValue: 'release');
    userAgent =
        'FloatyClient/${packageInfo?.version}+${packageInfo?.buildNumber}-$flavor';
    // // Load player type from settings (stored as string)
    // final playerTypeString = await Settings().getKey('player_backend');
    // if (playerTypeString.isEmpty) {
    //   selectedPlayerType = Platform.isAndroid || Platform.isIOS
    //       ? PlayerType.betterPlayer
    //       : PlayerType.mediaKit;
    // } else {
    //   selectedPlayerType = PlayerType.values.firstWhere(
    //     (e) => e.toString() == 'PlayerType.$playerTypeString',
    //     orElse: () => Platform.isAndroid || Platform.isIOS
    //         ? PlayerType.betterPlayer
    //         : PlayerType.mediaKit,
    //   );
    // }
    _log.info('Selected player type: $selectedPlayerType');
    // await loadPlayer(selectedPlayerType ??
    //     (Platform.isAndroid || Platform.isIOS
    //         ? PlayerType.betterPlayer
    //         : PlayerType.mediaKit));
    await loadPlayer(PlayerType.mediaKit);
    await _startSession();
    _subtitlesEnabled =
        await settings.getBool('subtitles_enabled', defaultValue: false);
    _currentSubtitleTrackIndex =
        await settings.getDynamic('subtitle_track_index', defaultValue: 0);
    // Load subtitle style
    try {
      final size = (await settings.getDynamic('subtitle_style_size',
          defaultValue: 24)) as num;
      final weightStr = (await settings.getKey('subtitle_style_weight'));
      final bg = (await settings.getDynamic('subtitle_style_bg_opacity',
          defaultValue: 0.5)) as num;
      final colorStr = await settings.getKey('subtitle_style_color');
      _subtitleStyle = SubtitleStyle(
        fontSize: size.toDouble(),
        fontWeight:
            _fontWeightFromString(weightStr.isEmpty ? 'Semi Bold' : weightStr),
        backgroundOpacity: bg.toDouble(),
        color: _colorFromHex(colorStr.isEmpty ? '#FFFFFF' : colorStr),
      );
    } catch (_) {
      _subtitleStyle = SubtitleStyle.defaultStyle();
    }
    _subtitleStyleController.add(_subtitleStyle);
  }

  Future<void> loadPlayer(PlayerType playerType) async {
    _log.info('Loading player: $playerType');
    if (playerType == loadedPlayerType) return;
    if (loadedPlayerType != null) {
      switch (loadedPlayerType) {
        case PlayerType.mediaKit:
          await mediaKitPlayer!.dispose();
          mediaKitPlayer = null;
          break;
        // case PlayerType.betterPlayer:
        //   _betterPlayerController?.dispose(forceDispose: true);
        //   _betterPlayerController = null;
        //   break;
        default:
          break;
      }
    }
    switch (playerType) {
      case PlayerType.mediaKit:
        _log.info('Loading MediaKit player...');
        try {
          mediaKitPlayer = Player();
          MediaKit.ensureInitialized();
          loadedPlayerType = playerType;
        } catch (e) {
          _log.severe('Failed to load MediaKit player', e);
        }
        break;
      // case PlayerType.betterPlayer:
      //   _log.info('No initialization required for BetterPlayer.');
      //   loadedPlayerType = playerType;
      //   break;
    }
    _setupPlayerListeners();
    _log.info('MediaPlayerService initialization completed successfully');
  }

  void _setupPlayerListeners() async {
    const flavor =
        String.fromEnvironment('FLUTTER_FLAVOR', defaultValue: 'release');
    switch (loadedPlayerType!) {
      case PlayerType.mediaKit:
        mediaKit.stream.position.listen((position) {
          _position = position;
          _positionController.add(position);
        });
        mediaKit.stream.duration.listen((duration) {
          _duration = duration;
          _durationController.add(duration);
        });
        mediaKit.stream.volume.listen((volume) {
          _volume = volume / 100; // Convert from 0-100 to 0-1
          _volumeController.add(_volume);
        });
        mediaKit.stream.playing.listen((playing) {
          _isPlaying = playing;
          _playingController.add(playing);
        });
        mediaKit.stream.buffer.listen((buffer) {
          _buffer = buffer;
          _bufferController.add(buffer);
        });
        mediaKit.stream.buffering.listen((buffering) {
          _buffering = buffering;
          _bufferingController.add(buffering);
        });
        mediaKit.stream.completed.listen((completed) {
          _completedController.add(completed);
        });
        mediaKit.stream.rate.listen((rate) {
          _playbackSpeed = rate;
          _playbackSpeedController.add(rate);
        });
        await _pipController
            .registerStateChangedObserver(PipStateChangedObserver(
          onPipStateChanged: (state, error) {
            switch (state) {
              case PipState.pipStateStarted:
                break;
              case PipState.pipStateStopped:
                _pipExitController.add(true);
                break;
              case PipState.pipStateFailed:
                _pipExitController.add(true);
                _log.warning('PiP failed: $error');
                break;
            }
          },
        ));
        break;
      // case PlayerType.betterPlayer:
      //   _betterPlayerController!.addEventsListener((progress) async {
      //     _position =
      //         _betterPlayerController!.videoPlayerController!.value.position;
      //     _positionController.add(_position);
      //     final duration =
      //         _betterPlayerController!.videoPlayerController!.value.duration;
      //     if (duration != _duration) {
      //       _duration = duration ?? Duration.zero;
      //       _durationController.add(_duration);
      //     }
      //     final playing =
      //         _betterPlayerController!.videoPlayerController!.value.isPlaying;
      //     if (playing != _isPlaying) {
      //       _isPlaying = playing;
      //       _playingController.add(_isPlaying);
      //     }
      //     final completed = _betterPlayerController!
      //             .videoPlayerController!.value.position ==
      //         _betterPlayerController!.videoPlayerController!.value.duration;
      //     if (completed != _completed) {
      //       _completed = completed;
      //       _completedController.add(_completed);
      //     }
      //   });
      //   _betterPlayerController!.addEventsListener((setSpeed) {
      //     final speed =
      //         _betterPlayerController!.videoPlayerController!.value.speed;
      //     if (speed != _playbackSpeed) {
      //       _playbackSpeedController.add(speed);
      //       _playbackSpeed = speed;
      //     }
      //   });
      //   break;
    }
    positionStream.listen((position) async {
      if (_live != true) {
        if (_lastReportedPosition == null ||
            position.inMinutes > _lastReportedPosition!.inMinutes) {
          _lastReportedPosition = position;
          fpApiRequests.progress(
              (await whitelabels.getSelectedWhitelabel()).friendlyName,
              _currentAttachment.id!,
              position.inSeconds,
              _currentMediaType == MediaType.video ? 'video' : 'audio');
        }
      }
      if (_subtitlesEnabled && _currentCues.isNotEmpty) {
        final text = _activeTextFor(position);
        _subtitleTextController.add(text);
      } else {
        _subtitleTextController.add(null);
      }
    });
    if (_live != true) {
      completedStream.listen((completed) async {
        fpApiRequests.progress(
            (await whitelabels.getSelectedWhitelabel()).friendlyName,
            _currentAttachment.id!,
            _duration.inSeconds,
            _currentMediaType == MediaType.video ? 'video' : 'audio');
      });
    }
    if (isDiscordRPCSupported &&
        _currentArtist?.toLowerCase() != 'ecc squad' &&
        _currentArtist?.toLowerCase() != 'eccsquad' &&
        _currentDiscoverable) {
      durationStream.listen((duration) {
        if (duration == Duration.zero) {
          discordRPCController.updateRPC(
              _whitelabelName ?? 'Unknown Whitelabel',
              _currentTitle ?? 'Unknown Title',
              _currentArtist ?? 'Unknown Artist',
              _currentArtistImage ?? flavor,
              _currentThumbnailUrl ?? 'https://floaty.fyi/assets/floaty.png',
              _currentPostId ?? '');
        } else {
          discordRPCController.updateRPC(
            _whitelabelName ?? 'Unknown Whitelabel',
            _currentTitle ?? 'Unknown Title',
            _currentArtist ?? 'Unknown Artist',
            _currentArtistImage ?? flavor,
            _currentThumbnailUrl ?? 'https://floaty.fyi/assets/floaty.png',
            _currentPostId ?? '',
            timestamps: RPCTimestamps(
              start: DateTime.now().millisecondsSinceEpoch -
                  _position.inMilliseconds,
              end: DateTime.now().millisecondsSinceEpoch +
                  (duration - _position).inMilliseconds,
            ),
          );
        }
      });
      playingStream.listen((playing) {
        if (playing == false) {
          discordRPCController.updateRPC(
              _whitelabelName ?? 'Unknown Whitelabel',
              _currentTitle ?? 'Unknown Title',
              _currentArtist ?? 'Unknown Artist',
              _currentArtistImage ?? flavor,
              _currentThumbnailUrl ?? 'https://floaty.fyi/assets/floaty.png',
              _currentPostId ?? '');
        } else {
          discordRPCController.updateRPC(
            _whitelabelName ?? 'Unknown Whitelabel',
            _currentTitle ?? 'Unknown Title',
            _currentArtist ?? 'Unknown Artist',
            _currentArtistImage ?? flavor,
            _currentThumbnailUrl ?? 'https://floaty.fyi/assets/floaty.png',
            _currentPostId ?? '',
            timestamps: RPCTimestamps(
              start: DateTime.now().millisecondsSinceEpoch -
                  _position.inMilliseconds,
              end: DateTime.now().millisecondsSinceEpoch +
                  (_duration - _position).inMilliseconds,
            ),
          );
        }
      });
      positionStream.listen((position) {
        discordRPCController.updateRPC(
          _whitelabelName ?? 'Unknown Whitelabel',
          _currentTitle ?? 'Unknown Title',
          _currentArtist ?? 'Unknown Artist',
          _currentArtistImage ?? flavor,
          _currentThumbnailUrl ?? 'https://floaty.fyi/assets/floaty.png',
          _currentPostId ?? '',
          timestamps: RPCTimestamps(
            start: DateTime.now().millisecondsSinceEpoch -
                _position.inMilliseconds,
            end: DateTime.now().millisecondsSinceEpoch +
                (_duration - _position).inMilliseconds,
          ),
        );
      });
    }
  }

  Future pipfalse() async {
    _pip = false;
    windowManager.setSize(_restoreSize ?? Size(480, 270));
    _restoreSize = null;
    windowManager.setAlwaysOnTop(false);
    windowManager.center();
    windowManager.setTitleBarStyle(TitleBarStyle.normal);
  }

  Future<void> _startSession() async {
    Logger.root.info('starting audio service...');
    // Initialize media player
    if (!Platform.isWindows) {
      // For non-Windows platforms, initialize audio service
      audioHandler = await AudioService.init(
        builder: () => FloatyAudioHandler(this),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'uk.bw86.floaty.channel.audio',
          androidNotificationChannelName: 'Audio playback',
          androidNotificationIcon: 'mipmap/ic_notification',
        ),
      );
    }
    // Initialize Windows-specific controls
    if (Platform.isWindows) {
      windowsControls = WindowsMediaControls(this);
      await windowsControls?.initialize();
    }
    Logger.root.info('audio player initialized!');
  }

  Future<dynamic> setSource(
    String whitelabelName,
    String url,
    MediaType type,
    bool live, {
    String? title,
    String? artist,
    String? artistImage,
    String? postId,
    String? thumbnailUrl,
    dynamic attachment,
    bool? discoverable,
    List<VideoQuality>? qualities,
    Map<String, String>? headers,
    Duration start = Duration.zero,
    List<Map<String, dynamic>>? textTracks,
    ImageModel? timelineSprite,
    List<SeekbarChapter>? chapters,
    bool isOffline = false,
    ContentPostV3Response? offlinePost,
    String? offlineAttachmentId,
    String? offlineFilePath,
  }) async {
    _log.info('MediaPlayerService: setSource called with URL: $url');
    _log.info('MediaPlayerService: title: $title');
    _log.info(
        'MediaPlayerService: isOffline param=$isOffline, offlinePost=${offlinePost != null}, offlineAttachmentId=$offlineAttachmentId, offlineFilePath=$offlineFilePath');
    _log.info(
        'MediaPlayerService: current state - _isOffline=$_isOffline, _currentMediaUrl=$_currentMediaUrl');
    dynamic controller;
    _log.info('Setting source: $url');
    // await _ensureInitialized();
    // Don't reinitialize if the URL hasn't changed (unless it's offline, always preserve offline state)
    if (_currentMediaUrl == url && !isOffline) {
      _log.info('Source URL unchanged, skipping initialization');
      // Return the existing controller so the widget can use it
      switch (loadedPlayerType) {
        case PlayerType.mediaKit:
          return _videoController;
        // case PlayerType.betterPlayer:
        //   return _betterPlayerController;
        default:
          return null;
      }
    }
    try {
      _log.info('Updating media source...');
      _whitelabelName = whitelabelName;
      _live = live;
      _log.info(
          'Setting offline state: _isOffline=$isOffline, _offlinePost=${offlinePost != null}, _offlineAttachmentId=$offlineAttachmentId, _offlineFilePath=$offlineFilePath');
      _isOffline = isOffline;
      _offlinePost = offlinePost;
      _offlineAttachmentId = offlineAttachmentId;
      _offlineFilePath = offlineFilePath;
      _currentMediaUrl = url;
      _currentMediaType = type;
      _currentTitle = title;
      _currentArtist = artist;
      _currentArtistImage = artistImage;
      _currentPostId = postId;
      _currentThumbnailUrl = thumbnailUrl;
      _currentDiscoverable = discoverable ?? false;
      _currentAttachment = attachment;
      _currentTextTracks = textTracks;
      _currentSubtitleTrackIndex = textTracks?.isNotEmpty == true ? 0 : null;
      _currentCues = [];
      _currentTimelineSprite = timelineSprite;
      _chapters = chapters;
      // Auto-initialize custom subtitles if user has them enabled and tracks exist
      if (_subtitlesEnabled && (_currentTextTracks?.isNotEmpty ?? false)) {
        try {
          await setSubtitleTrack(_currentSubtitleTrackIndex ?? 0);
        } catch (e, st) {
          _log.warning('Failed to auto-initialize subtitles: $e', e, st);
        }
      }
      if (qualities != null && qualities.isNotEmpty) {
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
          // Check for 4K quality
          VideoQuality? defaultQuality = qualities.firstWhere(
            (quality) => quality.label == '4K',
            orElse: () => qualities.firstWhere(
                (quality) => quality.label == '1080p',
                orElse: () => qualities.first),
          );
          _currentQuality = defaultQuality;
        }
      }
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
      _whitelabel =
          whitelabels.getWhitelabel(_whitelabelName ?? 'Unknown Whitelabel');
      // SimplePip instance is now created in the overlay with proper exit callback
      // late PlayerType player;
      // final playerTypeString = await Settings().getKey('player_backend');
      // if (playerTypeString.isEmpty) {
      //   player = Platform.isAndroid || Platform.isIOS
      //       ? PlayerType.betterPlayer
      //       : PlayerType.mediaKit;
      // } else {
      //   player = PlayerType.values.firstWhere(
      //     (e) => e.toString() == 'PlayerType.$playerTypeString',
      //     orElse: () => Platform.isAndroid || Platform.isIOS
      //         ? PlayerType.betterPlayer
      //         : PlayerType.mediaKit,
      //   );
      // }
      // if (loadedPlayerType! != player) {
      //   await loadPlayer(player);
      // }
      switch (loadedPlayerType!) {
        case PlayerType.mediaKit:
          if (_live == true) {
            (mediaKit.platform as NativePlayer)
                .setProperty('profile', 'low-latency');
          } else {
            (mediaKit.platform as NativePlayer)
                .setProperty('profile', 'default');
          }
          await mediaKit.stop();
          final media = Media(
            url,
            httpHeaders: headers ??
                {
                  'User-Agent': userAgent,
                  'Referer': 'https://www.${_whitelabel?.domain}/',
                  'Origin': 'https://www.${_whitelabel?.domain}',
                  ...await OAuth2Service.instance
                      .getAuthHeaders(_whitelabel!.friendlyName),
                },
            start: start,
            extras: {
              'subtitle': subtitleList,
            },
          );
          await mediaKit.open(media);
          _log.info('Media opened successfully');
          // We use a custom subtitle overlay; do not activate MediaKit's built-in subtitles
          _currentTextTracks = textTracks;
          _currentSubtitleTrackIndex =
              textTracks?.isNotEmpty == true ? 0 : null;
          if (type == MediaType.video) {
            _videoController = VideoController(mediaKit);
          }
          controller = _videoController;
          break;
        // case PlayerType.betterPlayer:
        //   _betterPlayerController = BetterPlayerController(
        //       BetterPlayerConfiguration(
        //         fit: BoxFit.contain,
        //         autoPlay: true,
        //         autoDetectFullscreenDeviceOrientation: true,
        //         autoDetectFullscreenAspectRatio: true,
        //         autoDispose: false, // Prevent auto-disposal during navigation
        //         startAt: start,
        //         handleLifecycle: false,
        //         useRootNavigator: false,
        //         routePageBuilder: (context, animation1, animation2, child) {
        //           return PiPOverlayPage(
        //             video: child,
        //             mediaService: this,
        //           );
        //         },
        //       ),
        //       betterPlayerDataSource: BetterPlayerDataSource(
        //         BetterPlayerDataSourceType.network,
        //         url,
        //         liveStream: _live,
        //         headers: headers ??
        //             {
        //               'User-Agent': userAgent,
        //               'Referer': 'https://www.${_whitelabel?.domain}/',
        //               'Origin': 'https://www.${_whitelabel?.domain}',
        //               ...await OAuth2Service.instance
        //                   .getAuthHeaders(_whitelabel!.friendlyName),
        //             },
        //         resolutions: qualities?.asMap().map((index, quality) =>
        //                 MapEntry(quality.label, quality.url)) ??
        //             {},
        //         subtitles: const [],
        //         videoFormat: BetterPlayerVideoFormat.hls,
        //       ));
        //   _betterPlayerController!.setControlsEnabled(false);
        //   _setupPlayerListeners();
        //   controller = _betterPlayerController;
        //   break;
      }
      // Update media metadata
      if (type == MediaType.audio || type == MediaType.video) {
        await _updateMediaMetadata(title, artist, artistImage, thumbnailUrl);
      }
      _log.info('Source set successfully');
      return controller;
    } catch (e) {
      _log.severe('Error setting source: $e');
      rethrow;
    }
  }

  Future<void> _updateMediaMetadata(
    String? title,
    String? artist,
    String? artistImage,
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
      // Update playback state after setting media0
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
    const flavor =
        String.fromEnvironment('FLUTTER_FLAVOR', defaultValue: 'release');
    if (isDiscordRPCSupported &&
        _currentArtist?.toLowerCase() != 'ecc squad' &&
        _currentArtist?.toLowerCase() != 'eccsquad' &&
        _currentDiscoverable) {
      discordRPCController.updateRPC(
          _whitelabelName ?? 'Unknown Whitelabel',
          title ?? 'Unknown Title',
          artist ?? 'Unknown Artist',
          artistImage ?? flavor,
          thumbnailUrl ?? 'https://floaty.fyi/assets/floaty.png',
          _currentPostId ?? '');
    }
  }

  Future<void> enterpip({Function? onPipExited, Function? onPipEntered}) async {
    switch (loadedPlayerType!) {
      case PlayerType.mediaKit:
        if (Platform.isAndroid) {
          _pipController.setup(PipOptions(
            autoEnterEnabled: false,
            aspectRatioX: 16,
            aspectRatioY: 9,
            sourceRectHintLeft: 0, // Source rectangle left position
            sourceRectHintTop: 0, // Source rectangle top position
            sourceRectHintRight: 1080, // Source rectangle right position
            sourceRectHintBottom: 720, // Source rectangle bottom position
            // iOS specific options
            sourceContentView: 0, // Source content view
            contentView: 0, // Content view to be displayed in PiP
            preferredContentWidth: 480, // Preferred content width
            preferredContentHeight: 270, // Preferred content height
            controlStyle: 1, // Control style for PiP window
          ));
          _pipController.start();
        } else if (!Platform.isIOS) {
          changeState(MediaPlayerState.pip);
        }
        break;
      // case PlayerType.betterPlayer:
      //   _betterPlayerPipActive = true;
      //   _betterPlayerController!.enablePictureInPicture(betterPlayerGlobalKey);
      //   break;
    }
  }

  /// Called when app resumes and BetterPlayer was in PiP mode
  /// Note: The overlay handles popping itself via WidgetsBindingObserver
  void handleBetterPlayerPipExit() {
    if (_betterPlayerPipActive) {
      _betterPlayerPipActive = false;
      changeState(MediaPlayerState.main);
    }
  }

  Future<void> play() async {
    switch (loadedPlayerType!) {
      case PlayerType.mediaKit:
        // await _ensureInitialized();
        if (_currentMediaType == MediaType.audio ||
            _currentMediaType == MediaType.video) {
          await mediaKit.play();
          _isPlaying = true;
          _playingController.add(_isPlaying);
        }
      // case PlayerType.betterPlayer:
      //   if (_betterPlayerController != null) {
      //     if (_currentMediaType == MediaType.audio ||
      //         _currentMediaType == MediaType.video) {
      //       await _betterPlayerController!.videoPlayerController!.play();
      //       _isPlaying = true;
      //       _playingController.add(_isPlaying);
      //     }
      //   }
    }
  }

  Future<void> pause() async {
    switch (loadedPlayerType!) {
      case PlayerType.mediaKit:
        // await _ensureInitialized();
        if (_currentMediaType == MediaType.audio ||
            _currentMediaType == MediaType.video) {
          await mediaKit.pause();
          _isPlaying = false;
          _playingController.add(_isPlaying);
        }
      // case PlayerType.betterPlayer:
      //   if (_betterPlayerController != null) {
      //     if (_currentMediaType == MediaType.audio ||
      //         _currentMediaType == MediaType.video) {
      //       await _betterPlayerController!.videoPlayerController!.pause();
      //       _isPlaying = false;
      //       _playingController.add(_isPlaying);
      //     }
      //   }
    }
  }

  Future<void> playpause() async {
    if (_isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> seek(Duration position) async {
    switch (loadedPlayerType!) {
      case PlayerType.mediaKit:
        // await _ensureInitialized();
        if (_currentMediaType == MediaType.audio ||
            _currentMediaType == MediaType.video) {
          await mediaKit.seek(position);
          _position = position;
        }
      // case PlayerType.betterPlayer:
      //   if (betterPlayerController != null) {
      //     if (_currentMediaType == MediaType.audio ||
      //         _currentMediaType == MediaType.video) {
      //       await _betterPlayerController!.seekTo(position);
      //       _position = position;
      //     }
      //   }
    }
  }

  Future<void> setVolume(double volume) async {
    switch (loadedPlayerType!) {
      case PlayerType.mediaKit:
        // await _ensureInitialized();
        if (_currentMediaType == MediaType.audio ||
            _currentMediaType == MediaType.video) {
          await mediaKit.setVolume(volume * 100); // Convert from 0-1 to 0-100
          if (!Platform.isWindows) {
            await audioHandler?.setVolume(volume);
          }
          _volume = volume;
          _volumeController.add(_volume);
        }
      // case PlayerType.betterPlayer:
      //   if (betterPlayerController != null) {
      //     if (_currentMediaType == MediaType.audio ||
      //         _currentMediaType == MediaType.video) {
      //       await _betterPlayerController!.setVolume(volume);
      //       _volume = volume;
      //       _volumeController.add(_volume);
      //     }
      //   }
    }
  }

  Future<void> changeQuality(VideoQuality quality,
      {Map<String, String>? headers}) async {
    if (!_availableQualities.contains(quality)) return;
    final position = _position;
    final play = _isPlaying;
    switch (loadedPlayerType!) {
      case PlayerType.mediaKit:
        final media = Media(
          quality.url,
          httpHeaders: headers ??
              {
                'User-Agent': userAgent,
                ...await OAuth2Service.instance
                    .getAuthHeaders(_whitelabel!.friendlyName),
              },
          start: position,
        );
        await mediaKit.open(media, play: play);
        _videoController = VideoController(mediaKit);
        break;
      // case PlayerType.betterPlayer:
      //   _betterPlayerController!.setResolution(quality.url);
      //   break;
    }
    _currentQuality = quality;
    settings.setKey('preferred_quality', quality.label);
  }

  Future<void> changeState(MediaPlayerState newState) async {
    if (state == newState) {
      return;
    }
    if (mediaKitPlayer == null) {
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
        if (!Platform.isWindows) {
          await audioHandler?.stop();
          await audioHandler?.session?.setActive(false);
        } else {
          await windowsControls?.stop();
        }
        if (isDiscordRPCSupported) {
          discordRPCController.clearRPC();
        }
        break;
    }
  }

  Future<void> setSpeed(double speed) async {
    switch (loadedPlayerType!) {
      case PlayerType.mediaKit:
        await mediaKit.setRate(speed);
        break;
      // case PlayerType.betterPlayer:
      //   _betterPlayerController!.setSpeed(speed);
      //   break;
    }
    _playbackSpeed = speed;
  }

  Future<bool> toggleSubtitles({bool? enabled}) async {
    _subtitlesEnabled = enabled ?? !_subtitlesEnabled;
    try {
      await settings.setBool('subtitles_enabled', _subtitlesEnabled);
    } catch (_) {}
    if (!_subtitlesEnabled) {
      _subtitleTextController.add(null);
      return _subtitlesEnabled;
    }
    // If enabling and no cues loaded yet, try loading default track
    if (_currentCues.isEmpty && _currentTextTracks?.isNotEmpty == true) {
      final idx = _currentSubtitleTrackIndex ?? 0;
      await setSubtitleTrack(idx);
    }
    return _subtitlesEnabled;
  }

  Future<void> setSubtitleTrack(int index) async {
    if (index == -1) {
      await toggleSubtitles(enabled: false);
      return;
    }
    if (_currentTextTracks == null ||
        index < 0 ||
        index >= _currentTextTracks!.length) {
      _log.warning('Invalid subtitle track index: $index');
      return;
    }
    await settings.setDynamic('subtitle_track_index', index);
    try {
      final track = _currentTextTracks![index];
      final url = track['src'];
      if (url == null || (url is String && url.isEmpty)) {
        _log.warning('Subtitle track has no URL');
        return;
      }
      _log.fine('Loading subtitle from URL: $url');
      final dio = Dio();
      final resp = await dio.get<String>(url,
          options: Options(responseType: ResponseType.plain));
      final content = resp.data ?? '';
      _currentCues = _parseWebVtt(content);
      _currentSubtitleTrackIndex = index;
      await toggleSubtitles(enabled: true);
      // Immediately emit current text based on latest position
      _subtitleTextController.add(_activeTextFor(_position));
    } catch (e, st) {
      _log.severe('Failed to load subtitles: $e', st);
    }
  }

  // Style helpers & setters
  Future<void> setSubtitleFontSize(double size) async {
    _subtitleStyle = _subtitleStyle.copyWith(fontSize: size);
    _subtitleStyleController.add(_subtitleStyle);
    await settings.setDynamic('subtitle_style_size', size);
  }

  Future<void> setSubtitleFontWeight(FontWeight weight, String label) async {
    _subtitleStyle = _subtitleStyle.copyWith(fontWeight: weight);
    _subtitleStyleController.add(_subtitleStyle);
    await settings.setKey('subtitle_style_weight', label);
  }

  Future<void> setSubtitleBackgroundOpacity(double opacity) async {
    _subtitleStyle = _subtitleStyle.copyWith(backgroundOpacity: opacity);
    _subtitleStyleController.add(_subtitleStyle);
    await settings.setDynamic('subtitle_style_bg_opacity', opacity);
  }

  Future<void> setSubtitleColor(Color color) async {
    _subtitleStyle = _subtitleStyle.copyWith(color: color);
    _subtitleStyleController.add(_subtitleStyle);
    await settings.setKey('subtitle_style_color', _hexFromColor(color));
  }

  Future<void> dispose() async {
    switch (loadedPlayerType!) {
      // case PlayerType.betterPlayer:
      //   betterPlayerController?.dispose();
      //   break;
      case PlayerType.mediaKit:
        await mediaKit.dispose();
        if (mediaKitPlayer != null) {
          await mediaKitPlayer!.dispose();
          mediaKitPlayer = null;
        }
        break;
    }
    // Close unified stream controllers
    await _playingController.close();
    await _positionController.close();
    await _durationController.close();
    await _bufferController.close();
    await _volumeController.close();
    if (!Platform.isWindows) {
      await audioHandler?.dispose();
    } else {
      await windowsControls?.dispose();
    }
    if (isDiscordRPCSupported) {
      discordRPCController.clearRPC();
    }
    await _subtitleTextController.close();
    await _subtitleStyleController.close();
  }

  Future<void> stop() async {
    switch (loadedPlayerType!) {
      case PlayerType.mediaKit:
        await mediaKit.stop();
        break;
      // case PlayerType.betterPlayer:
      //   betterPlayerController?.pause();
      //   break;
    }
  }

  Future<bool> isPipAvailable() async {
    switch (loadedPlayerType!) {
      case PlayerType.mediaKit:
        if (Platform.isAndroid) {
          return await _pipController.isSupported();
        } else if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
          return true;
        } else {
          return false;
        }
      // case PlayerType.betterPlayer:
      //   if (Platform.isAndroid) {
      //     return false;
      //   } else if (Platform.isIOS) {
      //     return betterPlayerController != null &&
      //         await _betterPlayerController!.isPictureInPictureSupported();
      //   }
      //   return false;
    }
  }

  List<SeekbarChapter> parseSeekbarChapters(String input) {
    final List<SeekbarChapter> chapters = [];
    final timestampRegex = RegExp(r"(?:(\d{1,2}):)?(\d{1,2}):(\d{2})");
    Duration? parseMatch(RegExpMatch m) {
      final hStr = m.group(1);
      final mStr = m.group(2);
      final sStr = m.group(3);
      if (mStr == null || sStr == null) return null;
      final h = hStr != null ? int.tryParse(hStr) ?? 0 : 0;
      final mi = int.tryParse(mStr) ?? 0;
      final se = int.tryParse(sStr) ?? 0;
      return Duration(hours: h, minutes: mi, seconds: se);
    }

    final matches = timestampRegex.allMatches(input).toList();
    for (var i = 0; i < matches.length; i++) {
      final m = matches[i];
      final startDur = parseMatch(m);
      if (startDur == null) continue;
      final titleStart = m.end;
      final titleEnd =
          i + 1 < matches.length ? matches[i + 1].start : input.length;
      var title = input.substring(titleStart, titleEnd).trim();
      title = title.replaceFirst(RegExp(r"^[\-\s:]+"), '').trim();
      if (title.isEmpty) title = 'Chapter';
      chapters.add(SeekbarChapter(start: startDur, title: title));
    }
    if (chapters.isNotEmpty && chapters.first.start > Duration.zero) {
      chapters.insert(
          0, const SeekbarChapter(start: Duration.zero, title: 'Intro'));
    }
    chapters.sort((a, b) => a.start.compareTo(b.start));
    final unique = <int>{};
    final out = <SeekbarChapter>[];
    for (final c in chapters) {
      final key = c.start.inSeconds;
      if (unique.add(key)) out.add(c);
    }
    return out;
  }
}

// Simple WebVTT cue
class _VttCue {
  final Duration start;
  final Duration end;
  final String text;
  _VttCue(this.start, this.end, this.text);
}

extension on MediaPlayerService {
  FontWeight _fontWeightFromString(String s) {
    switch (s.toLowerCase()) {
      case 'extra light':
        return FontWeight.w200;
      case 'light':
        return FontWeight.w300;
      case 'medium':
        return FontWeight.w500;
      case 'semi bold':
        return FontWeight.w600;
      case 'bold':
        return FontWeight.w700;
      default:
        return FontWeight.w600;
    }
  }

  String _hexFromColor(Color c) {
    return '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

  Color _colorFromHex(String hex) {
    String h = hex.replaceAll('#', '');
    if (h.length == 6) {
      h = 'FF$h';
    }
    return Color(int.parse(h, radix: 16));
  }

  List<_VttCue> _parseWebVtt(String content) {
    final lines = content.replaceAll('\r\n', '\n').split('\n');
    final cues = <_VttCue>[];
    int i = 0;
    // Skip optional WEBVTT header
    if (lines.isNotEmpty &&
        lines[0].trim().toUpperCase().startsWith('WEBVTT')) {
      // skip header line
      i = 1;
    }
    while (i < lines.length) {
      // Skip comments & empty lines
      if (lines[i].trim().isEmpty || lines[i].startsWith('NOTE')) {
        i++;
        continue;
      }
      // Optional cue id
      String line = lines[i];
      if (!line.contains('-->')) {
        i++;
        if (i >= lines.length) break;
        line = lines[i];
      }
      if (!line.contains('-->')) {
        // Not a timing line, skip
        i++;
        continue;
      }
      final parts = line.split('-->');
      final startStr = parts[0].trim();
      final endAndSettings = parts[1].trim();
      final endStr = endAndSettings.split(RegExp(r"\s")).first;
      final start = _parseTimestamp(startStr);
      final end = _parseTimestamp(endStr);
      i++;
      final buffer = <String>[];
      while (i < lines.length && lines[i].trim().isNotEmpty) {
        buffer.add(lines[i]);
        i++;
      }
      final text = buffer.join('\n');
      if (start != null && end != null) {
        cues.add(_VttCue(start, end, text));
      }
      // skip empty line
      i++;
    }
    return cues;
  }

  Duration? _parseTimestamp(String s) {
    // 00:00:01.000 or 00:01.000
    final ts = s.trim();
    final parts = ts.split(':');
    int hours = 0, minutes = 0;
    double seconds = 0;
    if (parts.length == 3) {
      hours = int.tryParse(parts[0]) ?? 0;
      minutes = int.tryParse(parts[1]) ?? 0;
      seconds = double.tryParse(parts[2].replaceAll(',', '.')) ?? 0;
    } else if (parts.length == 2) {
      minutes = int.tryParse(parts[0]) ?? 0;
      seconds = double.tryParse(parts[1].replaceAll(',', '.')) ?? 0;
    } else {
      return null;
    }
    final millis = (seconds * 1000).round();
    return Duration(hours: hours, minutes: minutes, milliseconds: millis);
  }

  String? _activeTextFor(Duration position) {
    final ms = position.inMilliseconds;
    for (final c in _currentCues) {
      if (ms >= c.start.inMilliseconds && ms <= c.end.inMilliseconds) {
        return c.text;
      }
    }
    return null;
  }
}
