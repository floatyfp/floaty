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

// // Riverpod provider for MediaController
// final mediaControllerProvider =
//     StateNotifierProvider<MediaController, MediaPlayerState>(
//         (ref) => MediaController(ref));

// class MediaController extends StateNotifier<MediaPlayerState> {
//   PackageInfo? packageInfo;
//   String userAgent = 'FloatyClient/error, CFNetwork';

//   FloatyAudioHandler? audioHandler;
//   WindowsMediaControls? windowsControls;

//   Player? _mediaKit;
//   BetterPlayerController? _betterPlayerController;
//   IvsPlayer? _ivsPlayer;
//   PlayerType? selectedPlayerType;
//   PlayerType? loadedPlayerType;
//   late final Logger _log;
//   final flavor =
//       String.fromEnvironment('FLUTTER_FLAVOR', defaultValue: 'release');

//   // Stream controllers
//   final StreamController<Duration> _positionController =
//       StreamController<Duration>.broadcast();
//   final StreamController<Duration> _durationController =
//       StreamController<Duration>.broadcast();
//   final StreamController<bool> _playingController =
//       StreamController<bool>.broadcast();
//   final StreamController<bool> _playerCompletedController =
//       StreamController<bool>.broadcast();

//   // Public stream getters
//   Stream<Duration> get positionStream => _positionController.stream;
//   Stream<Duration> get durationStream => _durationController.stream;
//   Stream<bool> get playingStream => _playingController.stream;
//   Stream<bool> get playerCompletedStream => _playerCompletedController.stream;

//   //getters
//   double get volume => _volume;
//   Duration get position => _position;
//   Duration get duration => _duration;
//   bool get playing => _isPlaying;
//   bool get subtitlesEnabled => _subtitlesEnabled;
//   VideoController? get videoController => _videoController;
//   BetterPlayerController? get betterPlayerController => _betterPlayerController;
//   bool get currentLive => _live;
//   String? get currentPostId => _currentPostId;

//   Future<void> changeState(MediaPlayerState newState) async {
//     state = newState;
//   }

//   //player values
//   bool _isPlaying = false;
//   Duration _position = Duration.zero;
//   Duration _duration = Duration.zero;
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

//   MediaController(Ref ref) : super(MediaPlayerState.none) {
//     _log = Logger('MediaController');
//     _log.info('Initializing MediaController...');
//     InitalizePlayer();
//   }

//   void InitalizePlayer() async {
//     //init userAgent
//     packageInfo = await PackageInfo.fromPlatform();
//     const flavor =
//         String.fromEnvironment('FLUTTER_FLAVOR', defaultValue: 'release');
//     userAgent =
//         'FloatyClient/${packageInfo?.version}+${packageInfo?.buildNumber}-$flavor, CFNetwork';

//     //init audio handler and windows controls
//     // Initialize media player
//     if (!Platform.isWindows) {
//       // For non-Windows platforms, initialize audio service
//       audioHandler = await AudioService.init(
//         builder: () => FloatyAudioHandler(this),
//         config: const AudioServiceConfig(
//           androidNotificationChannelId: 'uk.bw86.floaty.channel.audio',
//           androidNotificationChannelName: 'Video/Audio Playback',
//           androidNotificationIcon: 'mipmap/ic_notification',
//         ),
//       );
//     }

//     // Initialize Windows-specific controls
//     if (Platform.isWindows) {
//       windowsControls = WindowsMediaControls(this);
//       await windowsControls?.initialize();
//     }

//     Logger.root.info('Audio Controls Initialized!');

//     //init selected player
//     selectedPlayerType = await Settings().getEnum<PlayerType>('vod_player',
//         defaultValue: Platform.isAndroid || Platform.isIOS
//             ? PlayerType.betterPlayer
//             : PlayerType.mediaKit);
//     loadPlayer(selectedPlayerType!);
//   }

//   Future<void> loadPlayer(PlayerType playerType) async {
//     if (playerType == loadedPlayerType) return;
//     if (loadedPlayerType != null) {
//       switch (loadedPlayerType!) {
//         case PlayerType.mediaKit:
//           await _mediaKit?.dispose();
//           _mediaKit = null;
//           break;
//         case PlayerType.betterPlayer:
//           _betterPlayerController?.dispose(forceDispose: true);
//           _betterPlayerController = null;
//           break;
//         case PlayerType.awsIvs:
//           _ivsPlayer?.stopPlayer();
//           _ivsPlayer = null;
//           break;
//       }
//     }
//     switch (playerType) {
//       case PlayerType.mediaKit:
//         _log.info('Loading MediaKit player...');
//         try {
//           _mediaKit = Player();
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
//   }

//   playerListeners() async {
//     switch (loadedPlayerType!) {
//       case PlayerType.mediaKit:
//         _mediaKit?.stream.position.listen((position) async {
//           _position = position;
//           _positionController.add(position);
//           if (_live != true) {
//             if (_lastReportedPosition == null ||
//                 position.inMinutes > _lastReportedPosition!.inMinutes) {
//               _lastReportedPosition = position;

//               fpApiRequests.progress(
//                   _whitelabel?.friendlyName ??
//                       (await whitelabels.getSelectedWhitelabel()).friendlyName,
//                   _currentAttachment.id!,
//                   position.inSeconds,
//                   _currentMediaType == MediaType.video ? 'video' : 'audio');
//             }
//           }
//         });

//         _mediaKit?.stream.duration.listen((duration) {
//           _duration = duration;
//           _durationController.add(duration);
//         });

//         _mediaKit?.stream.playing.listen((playing) {
//           _isPlaying = playing;
//           _playingController.add(playing);
//         });

//         _mediaKit?.stream.completed.listen((completed) {
//           _playingController.add(false);
//           _playerCompletedController.add(completed);
//         });

//         if (_live != true) {
//           _mediaKit?.stream.completed.listen((completed) async {
//             fpApiRequests.progress(
//                 _whitelabel?.friendlyName ??
//                     (await whitelabels.getSelectedWhitelabel()).friendlyName,
//                 _currentAttachment.id!,
//                 _duration.inSeconds,
//                 _currentMediaType == MediaType.video ? 'video' : 'audio');
//           });
//         }
//         break;
//       case PlayerType.betterPlayer:
//         _betterPlayerController!.addEventsListener((progress) async {
//           _position = progress.parameters?['progress'] ?? Duration.zero;
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
//           _isPlaying = play.parameters?['play'] ?? true;
//           _playingController.add(_isPlaying);
//         });

//         _betterPlayerController!.addEventsListener((pause) {
//           _isPlaying = pause.parameters?['pause'] ?? false;
//           _playingController.add(_isPlaying);
//         });

//         _betterPlayerController!.addEventsListener((finished) {
//           _playingController.add(false);
//           _playerCompletedController
//               .add(finished.parameters?['finished'] ?? true);
//         });

//         if (_live != true) {
//           _betterPlayerController!.addEventsListener((finished) async {
//             fpApiRequests.progress(
//                 _whitelabel?.friendlyName ??
//                     (await whitelabels.getSelectedWhitelabel()).friendlyName,
//                 _currentAttachment.id!,
//                 _duration.inSeconds,
//                 _currentMediaType == MediaType.video ? 'video' : 'audio');
//           });
//         }
//         break;
//       case PlayerType.awsIvs:
//         _ivsPlayer!.positionStream.stream.listen((progress) async {
//           _position = progress;
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

//         _ivsPlayer!.playeStateStream.stream.listen((play) {
//           print(play);
//           //TODO:
//           // _isPlaying = play.parameters?['play'] ?? true;
//           // _playingController.add(_isPlaying);
//         });
//         break;
//     }
//     if (_currentArtist?.toLowerCase() != 'ecc squad' && !Platform.isMacOS ||
//         _currentArtist?.toLowerCase() != 'eccsquad' && !Platform.isMacOS ||
//         !_currentDiscoverable && !Platform.isMacOS) {
//       durationStream.listen((duration) async {
//         if (duration == Duration.zero) {
//           discordRPCController.updateRPC(
//               _whitelabel?.friendlyName ??
//                   (await whitelabels.getSelectedWhitelabel()).friendlyName,
//               _currentTitle ?? 'Unknown Title',
//               _currentArtist ?? 'Unknown Artist',
//               _currentArtistImage ?? flavor,
//               _currentThumbnailUrl ?? 'https://floaty.fyi/assets/floaty.png',
//               _currentPostId ?? '');
//         } else {
//           discordRPCController.updateRPC(
//             _whitelabel?.friendlyName ??
//                 (await whitelabels.getSelectedWhitelabel()).friendlyName,
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

//       playingStream.listen((playing) async {
//         if (playing == false) {
//           discordRPCController.updateRPC(
//               _whitelabel?.friendlyName ??
//                   (await whitelabels.getSelectedWhitelabel()).friendlyName,
//               _currentTitle ?? 'Unknown Title',
//               _currentArtist ?? 'Unknown Artist',
//               _currentArtistImage ?? flavor,
//               _currentThumbnailUrl ?? 'https://floaty.fyi/assets/floaty.png',
//               _currentPostId ?? '');
//         } else {
//           discordRPCController.updateRPC(
//             _whitelabel?.friendlyName ??
//                 (await whitelabels.getSelectedWhitelabel()).friendlyName,
//             _currentTitle ?? 'Unknown Title',
//             _currentArtist ?? 'Unknown Artist',
//             _currentArtistImage ?? flavor,
//             _currentThumbnailUrl ?? 'https://floaty.fyi/assets/floaty.png',
//             _currentPostId ?? '',
//             timestamps: RPCTimestamps(
//               start: DateTime.now().millisecondsSinceEpoch -
//                   _mediaKit?.state.position.inMilliseconds,
//               end: DateTime.now().millisecondsSinceEpoch +
//                   (_duration - _position).inMilliseconds,
//             ),
//           );
//         }
//       });
//     }
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
//     if (loadedPlayerType == null) return 'player not initialized';
//     if (loadedPlayerType == PlayerType.mediaKit) MediaKit.ensureInitialized();

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

//       _whitelabel = whitelabels.getWhitelabel(_whitelabelName!);

//       switch (loadedPlayerType!) {
//         case PlayerType.mediaKit:
//           await _mediaKit?.stop();
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
//           );

//           await _mediaKit?.open(media);
//           _log.info('Media opened successfully');

//           if (type == MediaType.video) {
//             _videoController = VideoController(_mediaKit?);
//           }
//           controller = _videoController;
//           break;
//         case PlayerType.betterPlayer:
//           _betterPlayerController = BetterPlayerController(
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
//                 videoFormat: BetterPlayerVideoFormat.hls,
//               ));
//           controller = _betterPlayerController;
//           break;
//         case PlayerType.awsIvs:
//           // TODO
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
//           _whitelabel?.name ?? '',
//           title ?? 'Unknown Title',
//           artist ?? 'Unknown Artist',
//           artistImage ?? flavor,
//           thumbnailUrl ?? 'https://floaty.fyi/assets/floaty.png',
//           _currentPostId ?? '');
//     }
//   }

//   Future<void> play() async {
//     switch (loadedPlayerType) {
//       case PlayerType.mediaKit:
//         if (_mediaKit != null &&
//             (_currentMediaType == MediaType.audio ||
//                 _currentMediaType == MediaType.video)) {
//           await _mediaKit?.play();
//           if (!Platform.isWindows) {
//             await audioHandler!.play();
//           }
//           _isPlaying = true;
//         }
//         break;
//       case PlayerType.betterPlayer:
//         if (_betterPlayerController != null) {
//           if (_currentMediaType == MediaType.audio ||
//               _currentMediaType == MediaType.video) {
//             await _betterPlayerController!.play();
//             _isPlaying = true;
//           }
//         }
//         break;
//       case PlayerType.awsIvs:
//         if (_ivsPlayer != null) {
//           _ivsPlayer!.resume();
//           _isPlaying = true;
//         }
//         break;
//       case null:
//         throw StateError('No player loaded');
//     }
//   }

//   Future<void> pause() async {
//     switch (loadedPlayerType) {
//       case PlayerType.mediaKit:
//         if (_mediaKit != null &&
//             (_currentMediaType == MediaType.audio ||
//                 _currentMediaType == MediaType.video)) {
//           await _mediaKit?.pause();
//           if (!Platform.isWindows) {
//             await audioHandler?.pause();
//           }
//           _isPlaying = false;
//         }
//         break;
//       case PlayerType.betterPlayer:
//         if (_betterPlayerController != null) {
//           if (_currentMediaType == MediaType.audio ||
//               _currentMediaType == MediaType.video) {
//             await _betterPlayerController!.pause();
//             _isPlaying = false;
//           }
//         }
//         break;
//       case PlayerType.awsIvs:
//         if (_ivsPlayer != null) {
//           _ivsPlayer!.pause();
//           _isPlaying = false;
//         }
//         break;
//       case null:
//         throw StateError('No player loaded');
//     }
//   }

//   Future<void> playpause() async {
//     switch (loadedPlayerType) {
//       case PlayerType.mediaKit:
//         if (_mediaKit != null &&
//             (_currentMediaType == MediaType.audio ||
//                 _currentMediaType == MediaType.video)) {
//           if (_isPlaying) {
//             await pause();
//           } else {
//             await play();
//           }
//         }
//         break;
//       case PlayerType.betterPlayer:
//         if (_betterPlayerController != null) {
//           if (_currentMediaType == MediaType.audio ||
//               _currentMediaType == MediaType.video) {
//             if (_isPlaying) {
//               await pause();
//             } else {
//               await play();
//             }
//           }
//         }
//         break;
//       case PlayerType.awsIvs:
//         if (_ivsPlayer != null) {
//           if (_isPlaying) {
//             await pause();
//           } else {
//             await play();
//           }
//         }
//         break;
//       case null:
//         throw StateError('No player loaded');
//     }
//   }

//   Future<void> seek(Duration position) async {
//     switch (loadedPlayerType) {
//       case PlayerType.mediaKit:
//         if (_mediaKit != null &&
//             (_currentMediaType == MediaType.audio ||
//                 _currentMediaType == MediaType.video)) {
//           await _mediaKit?.seek(position);
//           if (!Platform.isWindows) {
//             await audioHandler?.seek(position);
//           }
//           _position = position;
//         }
//         break;
//       case PlayerType.betterPlayer:
//         if (_betterPlayerController != null) {
//           if (_currentMediaType == MediaType.audio ||
//               _currentMediaType == MediaType.video) {
//             await _betterPlayerController!.seekTo(position);
//             _position = position;
//           }
//         }
//         break;
//       case PlayerType.awsIvs:
//         // TODO
//         break;
//       case null:
//         throw StateError('No player loaded');
//     }
//   }

//   Future<void> setVolume(double volume) async {
//     switch (loadedPlayerType) {
//       case PlayerType.mediaKit:
//         if (_mediaKit != null &&
//             (_currentMediaType == MediaType.audio ||
//                 _currentMediaType == MediaType.video)) {
//           await _mediaKit?.setVolume(volume * 100); // Convert from 0-1 to 0-100
//           if (!Platform.isWindows) {
//             await audioHandler?.setVolume(volume);
//           }
//           _volume = volume;
//         }
//         break;
//       case PlayerType.betterPlayer:
//         if (_betterPlayerController != null) {
//           if (_currentMediaType == MediaType.audio ||
//               _currentMediaType == MediaType.video) {
//             await _betterPlayerController!.setVolume(volume);
//             _volume = volume;
//           }
//         }
//         break;
//       case PlayerType.awsIvs:
//         if (_ivsPlayer != null) {
//           _ivsPlayer!.muteUnmute();
//           _volume = _volume == 0 ? 1 : 0;
//         }
//         break;
//       case null:
//         throw StateError('No player loaded');
//     }
//   }

//   Future<void> stop() async {
//     switch (loadedPlayerType) {
//       case PlayerType.mediaKit:
//         await _mediaKit?.stop();
//         _mediaKit = null;
//         break;
//       case PlayerType.betterPlayer:
//         _betterPlayerController?.dispose();
//         _betterPlayerController = null;
//         break;
//       case PlayerType.awsIvs:
//         _ivsPlayer?.stopPlayer();
//         _ivsPlayer = null;
//         break;
//       case null:
//         throw StateError('No player loaded');
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
