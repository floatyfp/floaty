// import 'dart:io';
// import 'dart:async';
// import 'package:floaty/features/api/repositories/fpapi.dart';
// import 'package:floaty/features/router/views/root_layout.dart';
// import 'package:floaty/features/discordrpc/controllers/discord_rpc_controller.dart';
// import 'package:floaty/whitelabels.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_discord_rpc/flutter_discord_rpc.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
// import 'package:media_kit/media_kit.dart';
// import 'package:media_kit_video/media_kit_video.dart';
// import 'package:package_info_plus/package_info_plus.dart';
// import 'package:window_manager/window_manager.dart';
// import 'package:audio_service/audio_service.dart';
// import 'package:logging/logging.dart';
// import 'audio_handler.dart';
// import 'windows_media_controls.dart';
// import '../models/video_quality.dart';
// import 'package:floaty/settings.dart';
// import 'package:simple_pip_mode/simple_pip.dart';
// import 'package:better_player_plus/better_player_plus.dart';
// import 'package:ivs_broadcaster/Player/ivs_player.dart';

// enum PlayerType {
//   mediaKit,
//   betterPlayer,
//   awsIvs,
// }

// enum MediaType {
//   audio,
//   video,
//   image,
// }

// enum MediaPlayerState {
//   none,
//   main,
//   mini,
//   pip,
// }

// final mediaPlayerServiceProvider =
//     StateNotifierProvider<MediaPlayerService, MediaPlayerState>(
//         (ref) => MediaPlayerService());

// class MediaPlayerService extends StateNotifier<MediaPlayerState> {
//   PackageInfo? packageInfo;
//   String userAgent = 'FloatyClient/error, CFNetwork';
//   static final MediaPlayerService _instance = MediaPlayerService._internal();

//   PlayerType? selectedPlayerType;
//   PlayerType? loadedPlayerType;

//   static Player? mediaKitPlayer;
//   BetterPlayerController? _betterPlayerController;
//   IvsPlayer? _ivsPlayer;

//   Player get mediaKit => mediaKitPlayer!;
//   BetterPlayerController get betterPlayer => _betterPlayerController!;
//   IvsPlayer get ivsPlayer => _ivsPlayer!;

//   BetterPlayerController? betterPlayerController;
//   FloatyAudioHandler? audioHandler;
//   WindowsMediaControls? windowsControls;
//   late final Logger _log;

//   bool _isPlaying = false;
//   Duration _position = Duration.zero;
//   Duration _duration = Duration.zero;
//   Duration _buffer = Duration.zero;
//   bool _buffering = false;
//   bool _completed = false;
//   double _playbackSpeed = 1.0;
//   double _volume = 1.0;
//   String? _currentMediaUrl;
//   MediaType? _currentMediaType;
//   String? _currentTitle;
//   String? _currentArtist;
//   String? _currentArtistImage;
//   String? _currentThumbnailUrl;
//   String? _currentPostId;
//   bool _currentDiscoverable = false;
//   bool _live = false;
//   dynamic _currentAttachment;
//   VideoQuality? _currentQuality;
//   List<VideoQuality> _availableQualities = [];
//   VideoController? _videoController;
//   Duration? _lastReportedPosition;
//   List<Map<String, dynamic>>? _currentTextTracks;
//   bool _subtitlesEnabled = false;
//   int? _currentSubtitleTrackIndex;
//   bool _pip = false;
//   Size? _restoreSize;

//   String? _whitelabelName;
//   WhiteLabel? _whitelabel;

//   late SimplePip _simplePip;

//   // Unified broadcast streams for common player events
//   // Consumers can subscribe regardless of the underlying player implementation
//   final StreamController<bool> _playingController =
//       StreamController<bool>.broadcast();
//   final StreamController<Duration> _positionController =
//       StreamController<Duration>.broadcast();
//   final StreamController<Duration> _durationController =
//       StreamController<Duration>.broadcast();
//   final StreamController<Duration> _bufferController =
//       StreamController<Duration>.broadcast();
//   final StreamController<double> _volumeController =
//       StreamController<double>.broadcast();
//   final StreamController<bool> _completedController =
//       StreamController<bool>.broadcast();
//   final StreamController<bool> _bufferingController =
//       StreamController<bool>.broadcast();
//   final StreamController<double> _playbackSpeedController =
//       StreamController<double>.broadcast();

//   // Getters
//   VideoController? get videoController => _videoController;
//   bool get isPlaying => _isPlaying;
//   bool get playing => _isPlaying;
//   Duration get buffer => _buffer;
//   bool get buffering => _buffering;
//   Duration get currentPosition => _position;
//   Duration get audioDuration => _duration;
//   double get playbackSpeed => _playbackSpeed;
//   double get volumeLevel => _volume;
//   VideoQuality? get currentQuality => _currentQuality;
//   List<VideoQuality> get availableQualities => _availableQualities;
//   bool get subtitlesEnabled => _subtitlesEnabled;
//   List<Map<String, dynamic>>? get textTracks => _currentTextTracks;
//   int? get currentSubtitleTrackIndex => _currentSubtitleTrackIndex;
//   String? get currentTitle => _currentTitle;
//   String? get currentArtist => _currentArtist;
//   String? get currentArtistImage => _currentArtistImage;
//   String? get currentThumbnailUrl => _currentThumbnailUrl;
//   String? get currentPostId => _currentPostId;
//   bool get currentLive => _live;
//   String? get currentAttachmentId => _currentAttachment?.id;
//   dynamic get currentAttachment => _currentAttachment;
//   String? get selectedMediaName => _currentMediaType?.name;
//   SimplePip get simplePip => _simplePip;
//   MediaPlayerState get mediastate => state;

//   // Unified stream getters
//   Stream<bool> get playingStream => _playingController.stream;
//   Stream<Duration> get positionStream => _positionController.stream;
//   Stream<Duration> get durationStream => _durationController.stream;
//   Stream<Duration> get bufferStream => _bufferController.stream;
//   Stream<double> get volumeStream => _volumeController.stream;
//   Stream<bool> get completedStream => _completedController.stream;
//   Stream<bool> get bufferingStream => _bufferingController.stream;
//   Stream<double> get playbackSpeedStream => _playbackSpeedController.stream;

//   factory MediaPlayerService() {
//     return _instance;
//   }

//   MediaPlayerService._internal() : super(MediaPlayerState.none) {
//     _log = Logger('MediaPlayerService');
//     MediaKit.ensureInitialized();
//     _log.info('Initializing MediaPlayerService...');
//     mediaKitPlayer = Player();
//     _init(); // Initialize
//   }

//   Future<void> _init() async {
//     selectedPlayerType = await Settings().getEnum<PlayerType>('vod_player',
//         defaultValue: Platform.isAndroid || Platform.isIOS
//             ? PlayerType.betterPlayer
//             : PlayerType.mediaKit);
//     print('Selected player type: $selectedPlayerType');
//     await loadPlayer(selectedPlayerType ??
//         (Platform.isAndroid || Platform.isIOS
//             ? PlayerType.betterPlayer
//             : PlayerType.mediaKit));
//     await _startSession();
//   }

//   Future<void> loadPlayer(PlayerType playerType) async {
//     if (playerType == loadedPlayerType) return;
//     if (loadedPlayerType != null) {
//       switch (loadedPlayerType) {
//         case PlayerType.mediaKit:
//           await mediaKitPlayer!.dispose();
//           mediaKitPlayer = null;
//           break;
//         case PlayerType.betterPlayer:
//           _betterPlayerController?.dispose(forceDispose: true);
//           _betterPlayerController = null;
//           break;
//         case PlayerType.awsIvs:
//           _ivsPlayer?.stopPlayer();
//           _ivsPlayer = null;
//           break;
//         default:
//           break;
//       }
//     }
//     print('Loading player: $playerType');
//     switch (playerType) {
//       case PlayerType.mediaKit:
//         _log.info('Loading MediaKit player...');
//         try {
//           mediaKitPlayer = Player();
//           MediaKit.ensureInitialized();
//           loadedPlayerType = playerType;
//         } catch (e) {
//           _log.severe('Failed to load MediaKit player', e);
//         }
//         break;
//       case PlayerType.betterPlayer:
//         _log.info('No initialization required for BetterPlayer.');
//         break;
//       case PlayerType.awsIvs:
//         _ivsPlayer = IvsPlayer();
//         _log.info('Loading AWS IVS player...');
//         break;
//     }
//     _setupPlayerListeners();
//     _log.info('MediaPlayerService initialization completed successfully');
//   }

//   void _setupPlayerListeners() {
//     const flavor =
//         String.fromEnvironment('FLUTTER_FLAVOR', defaultValue: 'release');
//     // _simplePip = SimplePip(
//     //   onPipExited: () {
//     //     if (_live) {
//     //       rootLayoutKey.currentContext?.go('/live/$currentPostId');
//     //     } else {
//     //       rootLayoutKey.currentContext?.go('/post/$currentPostId');
//     //     }
//     //   },
//     // );

//     // if (_live == true) {
//     //   (globalPlayer!.platform as NativePlayer)
//     //       .setProperty('profile', 'low-latency');
//     // } else {
//     //   (globalPlayer!.platform as NativePlayer)
//     //       .setProperty('profile', 'default');
//     // }

//     switch (loadedPlayerType!) {
//       case PlayerType.mediaKit:
//         mediaKit.stream.position.listen((position) {
//           _position = position;
//           _positionController.add(position);
//         });

//         mediaKit.stream.duration.listen((duration) {
//           _duration = duration;
//           _durationController.add(duration);
//         });

//         mediaKit.stream.volume.listen((volume) {
//           _volume = volume / 100; // Convert from 0-100 to 0-1
//           _volumeController.add(_volume);
//         });

//         mediaKit.stream.playing.listen((playing) {
//           _isPlaying = playing;
//           _playingController.add(playing);
//         });

//         mediaKit.stream.buffer.listen((buffer) {
//           _buffer = buffer;
//           _bufferController.add(buffer);
//         });

//         mediaKit.stream.buffering.listen((buffering) {
//           _buffering = buffering;
//           _bufferingController.add(buffering);
//         });

//         mediaKit.stream.completed.listen((completed) {
//           _completed = completed;
//           _completedController.add(completed);
//         });

//         mediaKit.stream.rate.listen((rate) {
//           _playbackSpeed = rate;
//           _playbackSpeedController.add(rate);
//         });
//         break;
//       case PlayerType.betterPlayer:
//         _betterPlayerController!.addEventsListener((progress) async {
//           _position =
//               _betterPlayerController!.videoPlayerController!.value.position;
//           _positionController.add(_position);
//           if (_live != true) {
//             if (_lastReportedPosition == null ||
//                 _position.inMinutes > _lastReportedPosition!.inMinutes) {
//               _lastReportedPosition = _position;

//               fpApiRequests.progress(
//                   _whitelabel?.friendlyName ??
//                       (await whitelabels.getSelectedWhitelabel()).friendlyName,
//                   _currentAttachment.id!,
//                   _position.inSeconds,
//                   _currentMediaType == MediaType.video ? 'video' : 'audio');
//             }
//           }
//         });

//         _betterPlayerController!.addEventsListener((play) {
//           _isPlaying = true;
//           _playingController.add(_isPlaying);
//         });

//         _betterPlayerController!.addEventsListener((pause) {
//           _isPlaying = false;
//           _playingController.add(_isPlaying);
//         });

//         _betterPlayerController!.addEventsListener((finished) {
//           _playingController.add(false);
//           _completed = true;
//           _completedController.add(_completed);
//         });

//         _betterPlayerController!.addEventsListener((bufferingStart) {
//           _bufferingController.add(true);
//           _buffering = true;
//         });

//         _betterPlayerController!.addEventsListener((bufferingEnd) {
//           _bufferingController.add(false);
//           _buffering = false;
//         });

//         _betterPlayerController!.addEventsListener((setSpeed) {
//           _playbackSpeedController
//               .add(_betterPlayerController!.videoPlayerController!.value.speed);
//           _playbackSpeed =
//               _betterPlayerController!.videoPlayerController!.value.speed;
//         });
//         break;
//       case PlayerType.awsIvs:
//         _ivsPlayer!.positionStream.stream.listen((progress) async {
//           print(progress);
//           _position = progress;
//           _positionController.add(_position);
//         });

//         _ivsPlayer!.playeStateStream.stream.listen((play) {
//           if (play.name == 'PlayerStatePlaying') {
//             _isPlaying = true;
//             _playingController.add(_isPlaying);
//           } else {
//             _isPlaying = false;
//             _playingController.add(_isPlaying);
//           }
//           if (play.name == 'PlayerStateEnded') {
//             _completedController.add(true);
//           }
//         });

//         _ivsPlayer!.durationStream.stream.listen((duration) {
//           _duration = duration;
//           _durationController.add(_duration);
//         });
//         break;
//     }

//     positionStream.listen((position) async {
//       _position = position;
//       _positionController.add(position);
//       if (_live != true) {
//         if (_lastReportedPosition == null ||
//             position.inMinutes > _lastReportedPosition!.inMinutes) {
//           _lastReportedPosition = position;

//           fpApiRequests.progress(
//               (await whitelabels.getSelectedWhitelabel()).friendlyName,
//               _currentAttachment.id!,
//               position.inSeconds,
//               _currentMediaType == MediaType.video ? 'video' : 'audio');
//         }
//       }
//     });

//     if (_live != true) {
//       completedStream.listen((completed) async {
//         fpApiRequests.progress(
//             (await whitelabels.getSelectedWhitelabel()).friendlyName,
//             _currentAttachment.id!,
//             _duration.inSeconds,
//             _currentMediaType == MediaType.video ? 'video' : 'audio');
//       });
//     }

//     if (_currentArtist?.toLowerCase() != 'ecc squad' && !Platform.isMacOS ||
//         _currentArtist?.toLowerCase() != 'eccsquad' && !Platform.isMacOS ||
//         !_currentDiscoverable && !Platform.isMacOS) {
//       durationStream.listen((duration) {
//         if (duration == Duration.zero) {
//           discordRPCController.updateRPC(
//               _whitelabelName ?? 'Unknown Whitelabel',
//               _currentTitle ?? 'Unknown Title',
//               _currentArtist ?? 'Unknown Artist',
//               _currentArtistImage ?? flavor,
//               _currentThumbnailUrl ?? 'https://floaty.fyi/assets/floaty.png',
//               _currentPostId ?? '');
//         } else {
//           discordRPCController.updateRPC(
//             _whitelabelName ?? 'Unknown Whitelabel',
//             _currentTitle ?? 'Unknown Title',
//             _currentArtist ?? 'Unknown Artist',
//             _currentArtistImage ?? flavor,
//             _currentThumbnailUrl ?? 'https://floaty.fyi/assets/floaty.png',
//             _currentPostId ?? '',
//             timestamps: RPCTimestamps(
//               start: DateTime.now().millisecondsSinceEpoch -
//                   _position.inMilliseconds,
//               end: DateTime.now().millisecondsSinceEpoch +
//                   (duration - _position).inMilliseconds,
//             ),
//           );
//         }
//       });

//       playingStream.listen((playing) {
//         if (playing == false) {
//           discordRPCController.updateRPC(
//               _whitelabelName ?? 'Unknown Whitelabel',
//               _currentTitle ?? 'Unknown Title',
//               _currentArtist ?? 'Unknown Artist',
//               _currentArtistImage ?? flavor,
//               _currentThumbnailUrl ?? 'https://floaty.fyi/assets/floaty.png',
//               _currentPostId ?? '');
//         } else {
//           discordRPCController.updateRPC(
//             _whitelabelName ?? 'Unknown Whitelabel',
//             _currentTitle ?? 'Unknown Title',
//             _currentArtist ?? 'Unknown Artist',
//             _currentArtistImage ?? flavor,
//             _currentThumbnailUrl ?? 'https://floaty.fyi/assets/floaty.png',
//             _currentPostId ?? '',
//             timestamps: RPCTimestamps(
//               start: DateTime.now().millisecondsSinceEpoch -
//                   _position.inMilliseconds,
//               end: DateTime.now().millisecondsSinceEpoch +
//                   (_duration - _position).inMilliseconds,
//             ),
//           );
//         }
//       });

//       positionStream.listen((position) {
//         discordRPCController.updateRPC(
//           _whitelabelName ?? 'Unknown Whitelabel',
//           _currentTitle ?? 'Unknown Title',
//           _currentArtist ?? 'Unknown Artist',
//           _currentArtistImage ?? flavor,
//           _currentThumbnailUrl ?? 'https://floaty.fyi/assets/floaty.png',
//           _currentPostId ?? '',
//           timestamps: RPCTimestamps(
//             start: DateTime.now().millisecondsSinceEpoch -
//                 _position.inMilliseconds,
//             end: DateTime.now().millisecondsSinceEpoch +
//                 (_duration - _position).inMilliseconds,
//           ),
//         );
//       });
//     }
//   }

//   Future pipfalse() async {
//     _pip = false;
//     windowManager.setSize(_restoreSize ?? Size(480, 270));
//     _restoreSize = null;
//     windowManager.setAlwaysOnTop(false);
//     windowManager.center();
//     windowManager.setTitleBarStyle(TitleBarStyle.normal);
//   }

//   Future<void> _ensureInitialized() async {
//     //TODO
//     packageInfo = await PackageInfo.fromPlatform();
//     const flavor =
//         String.fromEnvironment('FLUTTER_FLAVOR', defaultValue: 'release');
//     userAgent =
//         'FloatyClient/${packageInfo?.version}+${packageInfo?.buildNumber}-$flavor, CFNetwork';
//   }

//   Future<void> _startSession() async {
//     Logger.root.info('starting audio service...');

//     // Initialize media player
//     if (!Platform.isWindows) {
//       // For non-Windows platforms, initialize audio service
//       audioHandler = await AudioService.init(
//         builder: () => FloatyAudioHandler(this),
//         config: const AudioServiceConfig(
//           androidNotificationChannelId: 'uk.bw86.floaty.channel.audio',
//           androidNotificationChannelName: 'Audio playback',
//           androidNotificationIcon: 'mipmap/ic_notification',
//         ),
//       );
//     }

//     // Initialize Windows-specific controls
//     if (Platform.isWindows) {
//       windowsControls = WindowsMediaControls(this);
//       await windowsControls?.initialize();
//     }

//     Logger.root.info('audio player initialized!');
//   }

//   Future<dynamic> setSource(
//     String whitelabelName,
//     String url,
//     MediaType type,
//     bool live, {
//     String? title,
//     String? artist,
//     String? artistImage,
//     String? postId,
//     String? thumbnailUrl,
//     dynamic attachment,
//     bool? discoverable,
//     List<VideoQuality>? qualities,
//     Map<String, String>? headers,
//     Duration start = Duration.zero,
//     List<Map<String, dynamic>>? textTracks,
//   }) async {
//     dynamic controller;
//     _log.info('Setting source: $url');
//     // await _ensureInitialized();

//     // Don't reinitialize if the URL hasn't changed
//     if (_currentMediaUrl == url) {
//       _log.info('Source URL unchanged, skipping initialization');
//       return;
//     }

//     try {
//       _log.info('Updating media source...');
//       _whitelabelName = whitelabelName;
//       _live = live;
//       _currentMediaUrl = url;
//       _currentMediaType = type;
//       _currentTitle = title;
//       _currentArtist = artist;
//       _currentArtistImage = artistImage;
//       _currentPostId = postId;
//       _currentThumbnailUrl = thumbnailUrl;
//       _currentDiscoverable = discoverable ?? false;
//       _currentAttachment = attachment;
//       _currentTextTracks = textTracks;
//       _currentSubtitleTrackIndex = textTracks?.isNotEmpty == true ? 0 : null;

//       if (qualities != null) {
//         _availableQualities = qualities;
//         _currentQuality = qualities.first;
//         String? preferredQuality = await settings.getKey('preferred_quality');
//         if (preferredQuality.isNotEmpty) {
//           VideoQuality? selectedQuality = qualities.firstWhere(
//             (quality) => quality.label == preferredQuality,
//             orElse: () => qualities.first, // Fallback to the first quality
//           );
//           _currentQuality = selectedQuality; // Just use the URL directly
//         } else {
//           // Check for 1080p quality
//           VideoQuality? defaultQuality = qualities.firstWhere(
//               (quality) => quality.label == '1080p',
//               orElse: () => qualities
//                   .first // Fallback to the first quality if 1080p doesn't exist
//               );
//           _currentQuality = defaultQuality;
//         }
//       }

//       _log.info(
//           'Setting up media with text tracks: ${textTracks?.length ?? 0}');

//       final subtitleList = textTracks
//               ?.map((track) => {
//                     'title': track['language'] ?? 'Unknown',
//                     'language': track['language'] ?? 'und',
//                     'url': track['src'],
//                     'selected': textTracks.indexOf(track) == 0,
//                   })
//               .toList() ??
//           [];

//       _whitelabel =
//           whitelabels.getWhitelabel(_whitelabelName ?? 'Unknown Whitelabel');

//       switch (loadedPlayerType!) {
//         case PlayerType.mediaKit:
//           await mediaKit.stop();
//           final media = Media(
//             url,
//             httpHeaders: headers ??
//                 {
//                   'User-Agent': userAgent,
//                   'Cookie': await settings.getAuthTokenFromCookieJar() ?? '',
//                   'Referer': 'https://www.${_whitelabel?.domain}/',
//                   'Origin': 'https://www.${_whitelabel?.domain}',
//                 },
//             start: start,
//             extras: {
//               'subtitle': subtitleList,
//             },
//           );

//           await mediaKit.open(media);
//           _log.info('Media opened successfully');

//           // Initialize subtitle track if available
//           if (textTracks?.isNotEmpty == true && subtitlesEnabled) {
//             final defaultTrack = textTracks!.first;

//             await mediaKit.setSubtitleTrack(
//               SubtitleTrack.uri(
//                 defaultTrack['src'],
//                 title: defaultTrack['language'],
//                 language: defaultTrack['language'],
//               ),
//             );
//             _currentSubtitleTrackIndex = 0;
//           } else {
//             _currentTextTracks = textTracks;
//             _currentSubtitleTrackIndex = 0;
//           }

//           if (type == MediaType.video) {
//             _videoController = VideoController(mediaKit);
//           }
//           controller = _videoController;
//           break;
//         case PlayerType.betterPlayer:
//           betterPlayerController = BetterPlayerController(
//               BetterPlayerConfiguration(
//                 fit: BoxFit.contain,
//                 autoPlay: true,
//                 autoDetectFullscreenDeviceOrientation: true,
//                 autoDetectFullscreenAspectRatio: true,
//                 autoDispose: true,
//                 startAt: start,
//                 handleLifecycle: false,
//               ),
//               betterPlayerDataSource: BetterPlayerDataSource(
//                 BetterPlayerDataSourceType.network,
//                 url,
//                 headers: headers ??
//                     {
//                       'User-Agent': userAgent,
//                       'Cookie':
//                           await settings.getAuthTokenFromCookieJar() ?? '',
//                       'Referer': 'https://www.${_whitelabel?.domain}/',
//                       'Origin': 'https://www.${_whitelabel?.domain}',
//                     },
//                 resolutions: qualities?.asMap().map((index, quality) =>
//                         MapEntry(quality.label, quality.url)) ??
//                     {},
//                 subtitles: textTracks?.map((track) {
//                       return BetterPlayerSubtitlesSource(
//                         type: BetterPlayerSubtitlesSourceType.network,
//                         name: track['language'],
//                         urls: [track['src']],
//                       );
//                     }).toList() ??
//                     [],
//                 videoFormat: BetterPlayerVideoFormat.hls,
//               ));
//           controller = betterPlayerController;
//           break;
//         case PlayerType.awsIvs:
//           _ivsPlayer!.stopPlayer();
//           _ivsPlayer!.startPlayer(url, autoPlay: true);
//           break;
//       }
//       // Update media metadata
//       if (type == MediaType.audio || type == MediaType.video) {
//         await _updateMediaMetadata(title, artist, artistImage, thumbnailUrl);
//       }

//       _log.info('Source set successfully');

//       return controller;
//     } catch (e) {
//       _log.severe('Error setting source: $e');
//       rethrow;
//     }
//   }

//   Future<void> _updateMediaMetadata(
//     String? title,
//     String? artist,
//     String? artistImage,
//     String? thumbnailUrl,
//   ) async {
//     if (!Platform.isWindows && audioHandler != null) {
//       await audioHandler!.setMedia(MediaItem(
//         id: _currentMediaUrl!,
//         title: title ?? 'Unknown Title',
//         artist: artist,
//         artUri: thumbnailUrl != null ? Uri.parse(thumbnailUrl) : null,
//         playable: true,
//         displayTitle: title ?? 'Unknown Title',
//         displaySubtitle: artist,
//         duration: _duration,
//         extras: {
//           'postId': _currentPostId,
//         },
//       ));

//       // Update playback state after setting media0
//       if (_isPlaying) {
//         await audioHandler!.play();
//       } else {
//         await audioHandler!.pause();
//       }
//     }

//     if (Platform.isWindows) {
//       windowsControls?.updateMetadata(
//         title: title ?? 'Unknown Title',
//         artist: artist,
//         thumbnailUrl: thumbnailUrl,
//       );
//     }

//     const flavor =
//         String.fromEnvironment('FLUTTER_FLAVOR', defaultValue: 'release');

//     if (_currentArtist?.toLowerCase() != 'ecc squad' && !Platform.isMacOS ||
//         _currentArtist?.toLowerCase() != 'eccsquad' && !Platform.isMacOS ||
//         !_currentDiscoverable && !Platform.isMacOS) {
//       discordRPCController.updateRPC(
//           _whitelabelName ?? 'Unknown Whitelabel',
//           title ?? 'Unknown Title',
//           artist ?? 'Unknown Artist',
//           artistImage ?? flavor,
//           thumbnailUrl ?? 'https://floaty.fyi/assets/floaty.png',
//           _currentPostId ?? '');
//     }
//   }

//   Future<void> enterpip() async {
//     switch (loadedPlayerType!) {
//       case PlayerType.mediaKit:
//         _simplePip.enterPipMode(aspectRatio: (
//           mediaKit.state.width ?? 16,
//           mediaKit.state.height ?? 9
//         ));
//         break;
//       case PlayerType.betterPlayer:
//         // betterPlayerController!.enablePictureInPicture(betterPlayerGlobalKey!);
//         break;
//       case PlayerType.awsIvs:
//         // TODO
//         break;
//     }
//   }

//   Future<void> play() async {
//     switch (loadedPlayerType!) {
//       case PlayerType.mediaKit:
//         // await _ensureInitialized();
//         if (_currentMediaType == MediaType.audio ||
//             _currentMediaType == MediaType.video) {
//           await mediaKit.play();
//           if (!Platform.isWindows) {
//             await audioHandler?.play();
//           }
//           _isPlaying = true;
//         }
//       case PlayerType.betterPlayer:
//         if (betterPlayerController != null) {
//           if (_currentMediaType == MediaType.audio ||
//               _currentMediaType == MediaType.video) {
//             await betterPlayerController!.play();
//             _isPlaying = true;
//           }
//         }
//       case PlayerType.awsIvs:
//         _ivsPlayer!.resume();
//         break;
//     }
//   }

//   Future<void> pause() async {
//     switch (loadedPlayerType!) {
//       case PlayerType.mediaKit:
//         // await _ensureInitialized();
//         if (_currentMediaType == MediaType.audio ||
//             _currentMediaType == MediaType.video) {
//           await mediaKit.pause();
//           if (!Platform.isWindows) {
//             await audioHandler?.pause();
//           }
//           _isPlaying = false;
//         }
//       case PlayerType.betterPlayer:
//         if (betterPlayerController != null) {
//           if (_currentMediaType == MediaType.audio ||
//               _currentMediaType == MediaType.video) {
//             await betterPlayerController!.pause();
//             _isPlaying = false;
//           }
//         }
//       case PlayerType.awsIvs:
//         _ivsPlayer!.pause();
//         break;
//     }
//   }

//   Future<void> playpause() async {
//     switch (loadedPlayerType!) {
//       case PlayerType.mediaKit:
//         // await _ensureInitialized();
//         if (_currentMediaType == MediaType.audio ||
//             _currentMediaType == MediaType.video) {
//           if (_isPlaying) {
//             await pause();
//           } else {
//             await play();
//           }
//         }
//       case PlayerType.betterPlayer:
//         if (betterPlayerController != null) {
//           if (_currentMediaType == MediaType.audio ||
//               _currentMediaType == MediaType.video) {
//             if (_isPlaying) {
//               await pause();
//             } else {
//               await play();
//             }
//           }
//         }
//       case PlayerType.awsIvs:
//         if (_isPlaying) {
//           await pause();
//         } else {
//           await play();
//         }
//         break;
//     }
//   }

//   Future<void> seek(Duration position) async {
//     switch (loadedPlayerType!) {
//       case PlayerType.mediaKit:
//         // await _ensureInitialized();
//         if (_currentMediaType == MediaType.audio ||
//             _currentMediaType == MediaType.video) {
//           await mediaKit.seek(position);
//           if (!Platform.isWindows) {
//             await audioHandler?.seek(position);
//           }
//           _position = position;
//         }
//       case PlayerType.betterPlayer:
//         if (betterPlayerController != null) {
//           if (_currentMediaType == MediaType.audio ||
//               _currentMediaType == MediaType.video) {
//             await betterPlayerController!.seekTo(position);
//             _position = position;
//           }
//         }
//       case PlayerType.awsIvs:
//         throw UnimplementedError('AWS IVS does not support seeking');
//     }
//   }

//   Future<void> setVolume(double volume) async {
//     switch (loadedPlayerType!) {
//       case PlayerType.mediaKit:
//         // await _ensureInitialized();
//         if (_currentMediaType == MediaType.audio ||
//             _currentMediaType == MediaType.video) {
//           await mediaKit.setVolume(volume * 100); // Convert from 0-1 to 0-100
//           if (!Platform.isWindows) {
//             await audioHandler?.setVolume(volume);
//           }
//           _volume = volume;
//           _volumeController.add(_volume);
//         }
//       case PlayerType.betterPlayer:
//         if (betterPlayerController != null) {
//           if (_currentMediaType == MediaType.audio ||
//               _currentMediaType == MediaType.video) {
//             await betterPlayerController!.setVolume(volume);
//             _volume = volume;
//             _volumeController.add(_volume);
//           }
//         }
//       case PlayerType.awsIvs:
//         // TODO: replace volume with custom solution
//         break;
//     }
//   }

//   Future<void> changeQuality(VideoQuality quality,
//       {Map<String, String>? headers}) async {
//     //TODO: support crap on other players

//     // if (!_availableQualities.contains(quality)) return;

//     // final position = player.state.position;
//     // final play = player.state.playing;

//     // final media = Media(
//     //   quality.url,
//     //   httpHeaders: headers ??
//     //       {
//     //         'User-Agent': userAgent,
//     //         'Cookie': await settings.getAuthTokenFromCookieJar() ?? '',
//     //       },
//     //   start: position,
//     // );

//     // _currentQuality = quality;
//     // settings.setKey('preferred_quality', quality.label);

//     // await player.open(media, play: play);
//     // _videoController = VideoController(player);
//   }

//   Future<void> changeState(MediaPlayerState newState) async {
//     if (state == newState) {
//       return;
//     }

//     if (mediaKitPlayer == null) {
//       return;
//     }

//     state = newState;

//     switch (newState) {
//       case MediaPlayerState.pip:
//         if (!Platform.isIOS) {
//           if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
//             _restoreSize = await windowManager.getSize();
//             _pip = true;
//             windowManager.setAlwaysOnTop(true);
//             windowManager.unmaximize();
//             windowManager.dock;
//             windowManager.setSize(Size(480, 270));
//             windowManager.setTitleBarStyle(TitleBarStyle.hidden);
//           }
//         }
//         break;
//       case MediaPlayerState.mini:
//         if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
//           if (!_pip) {
//             windowManager.setAlwaysOnTop(false);
//             windowManager.setTitleBarStyle(TitleBarStyle.normal);
//             if (_restoreSize != null) {
//               windowManager.setSize(_restoreSize ?? Size(480, 270));
//               _restoreSize = null;
//               windowManager.center();
//             }
//           }
//         }
//         break;
//       case MediaPlayerState.main:
//         if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
//           if (!_pip) {
//             if (_restoreSize != null) {
//               windowManager.setSize(_restoreSize ?? Size(480, 270));
//               _restoreSize = null;
//               windowManager.center();
//             }
//             windowManager.setAlwaysOnTop(false);
//             windowManager.setTitleBarStyle(TitleBarStyle.normal);
//           }
//         }
//         break;
//       case MediaPlayerState.none:
//         await stop();
//         if (!Platform.isMacOS) {
//           discordRPCController.clearRPC();
//         }
//         break;
//     }
//   }

//   Future<void> setSpeed(double speed) async {
//     switch (loadedPlayerType!) {
//       case PlayerType.mediaKit:
//         await mediaKit.setRate(speed);
//         break;
//       case PlayerType.betterPlayer:
//         betterPlayerController!.setSpeed(speed);
//         break;
//       case PlayerType.awsIvs:
//         throw 'Playback speed control is not supported for AWS IVS';
//     }
//   }

//   Future<bool> toggleSubtitles() async {
//     // TODO
//     _subtitlesEnabled = !_subtitlesEnabled;
//     // await settings.setBool('subtitles_enabled', _subtitlesEnabled);
//     // _log.info('Toggling subtitles: ${_subtitlesEnabled ? 'on' : 'off'}');

//     // if (!_subtitlesEnabled) {
//     //   await player.setSubtitleTrack(SubtitleTrack.no());
//     // } else if (_currentSubtitleTrackIndex != null &&
//     //     _currentTextTracks != null) {
//     //   final track = _currentTextTracks![_currentSubtitleTrackIndex!];

//     //   await player.setSubtitleTrack(
//     //     SubtitleTrack.uri(
//     //       track['src'],
//     //       title: track['language'],
//     //       language: track['language'],
//     //     ),
//     //   );
//     // }
//     // state = state;
//     return _subtitlesEnabled;
//   }

//   Future<void> setSubtitleTrack(int index) async {
//     // TODO
//     // if (index == -1) {
//     //   _subtitlesEnabled = false;
//     //   settings.setBool('subtitles_enabled', false);
//     //   _log.info('Turning subtitles off');
//     //   await player.setSubtitleTrack(SubtitleTrack.no());
//     //   state = state;
//     //   return;
//     // }

//     // if (_currentTextTracks == null || index >= _currentTextTracks!.length) {
//     //   _log.warning('Invalid subtitle track index: $index');
//     //   return;
//     // }

//     // _log.info('Setting subtitle track to index $index');
//     // _currentSubtitleTrackIndex = index;
//     // final track = _currentTextTracks![index];

//     // _subtitlesEnabled = true;
//     // settings.setBool('subtitles_enabled', true);

//     // await player.setSubtitleTrack(
//     //   SubtitleTrack.uri(
//     //     track['src'],
//     //     title: track['language'],
//     //     language: track['language'],
//     //   ),
//     // );
//     // state = state;
//   }

//   @override
//   Future<void> dispose() async {
//     switch (loadedPlayerType!) {
//       case PlayerType.betterPlayer:
//         betterPlayerController?.dispose();
//         break;
//       case PlayerType.mediaKit:
//         await mediaKit.dispose();
//         if (mediaKitPlayer != null) {
//           await mediaKitPlayer!.dispose();
//           mediaKitPlayer = null;
//         }
//         break;
//       case PlayerType.awsIvs:
//         _ivsPlayer?.stopPlayer();
//         _ivsPlayer = null;
//         break;
//     }
//     // Close unified stream controllers
//     await _playingController.close();
//     await _positionController.close();
//     await _durationController.close();
//     await _bufferController.close();
//     await _volumeController.close();
//     if (!Platform.isWindows) {
//       await audioHandler?.dispose();
//     } else {
//       await windowsControls?.dispose();
//     }
//     if (!Platform.isMacOS) {
//       discordRPCController.clearRPC();
//     }
//     super.dispose();
//   }

//   Future<void> stop() async {
//     switch (loadedPlayerType!) {
//       case PlayerType.mediaKit:
//         await mediaKit.stop();
//         break;
//       case PlayerType.betterPlayer:
//         betterPlayerController?.dispose();
//         break;
//       case PlayerType.awsIvs:
//         _ivsPlayer?.stopPlayer();
//         break;
//     }
//     if (!Platform.isWindows) {
//       await audioHandler?.stop();
//       await audioHandler?.session?.setActive(false);
//     } else {
//       await windowsControls?.stop();
//     }
//     if (!Platform.isMacOS) {
//       discordRPCController.clearRPC();
//     }
//   }
// }
