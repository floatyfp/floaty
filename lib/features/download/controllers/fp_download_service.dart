import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:floaty/settings.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:floaty/features/download/models/fp_download.dart';
import 'package:floaty/features/download/controllers/fp_download_isolate.dart';
import 'package:floaty/features/download/controllers/download_log.dart';
import 'package:floaty/features/download/controllers/fp_download_url_helper.dart';
import 'package:floaty/features/api/models/definitions.dart';

Directory selectOfflineStorageDirectory({
  required Directory applicationSupportDirectory,
  required bool useExternalStorage,
  Directory? externalStorageDirectory,
}) {
  if (useExternalStorage && externalStorageDirectory != null) {
    return externalStorageDirectory;
  }
  return applicationSupportDirectory;
}

/// Floatplane Download Service - UI client for the FP download isolate
class FPDownloadService {
  static final FPDownloadService _instance = FPDownloadService._internal();
  factory FPDownloadService() => _instance;
  FPDownloadService._internal();

  bool running = false;
  int queueSize = 0;
  int activeDownloads = 0;
  int rateLimitedCount = 0;

  final List<Map<String, dynamic>> _downloads = [];
  final StreamController<Map<String, dynamic>> _serviceEvents =
      StreamController.broadcast();

  Database? _db;
  DownloadLog? _logger;
  FPDownloadIsolateManager? _isolateManager;
  String? _offlinePath;

  // Notifications
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _notificationsInitialized = false;
  static const int _notificationIdStart = 9000;
  static const String _channelId = 'floaty_fp_downloads';
  static const String _channelName = 'Video Downloads';
  final Map<int, DateTime> _lastNotificationUpdate = {};

  Stream<Map<String, dynamic>> get serviceEvents => _serviceEvents.stream;
  String? get offlinePath => _offlinePath;

  /// Initialize the download service
  Future<void> init(Database db) async {
    _db = db;
    _logger = DownloadLog();
    await _logger!.open();

    _logger!.log('[FPDownloadService] Initializing...');

    // Setup offline directory - ALWAYS use app's internal storage for offline library
    // The custom download_path is only for external downloads (useExternalPath=true)
    final appSupportDirectory = await getApplicationSupportDirectory();
    final externalStorageDirectory =
        Platform.isAndroid ? await getExternalStorageDirectory() : null;
    final directory = selectOfflineStorageDirectory(
      applicationSupportDirectory: appSupportDirectory,
      externalStorageDirectory: externalStorageDirectory,
      useExternalStorage: Platform.isAndroid,
    );
    _offlinePath = p.join(directory.path, 'floatplane_offline');
    await Directory(_offlinePath!).create(recursive: true);
    _logger!.log(
        '[FPDownloadService] Offline library path (internal): $_offlinePath');

    // Initialize notifications
    await _initNotifications();

    // Initialize isolate manager (no auth needed - URLs are pre-authenticated)
    _isolateManager = FPDownloadIsolateManager();
    await _isolateManager!.start(
      _db!.path,
      await _getSettings(),
    );
    _logger!.log('[FPDownloadService] Isolate manager started');

    // Listen for isolate responses
    _isolateManager!.responses.listen(_handleIsolateResponse);

    // Request initial data
    _isolateManager!.sendMessage(FPCoordinatorMessage(type: 'getDownloads'));

    _logger!.log('[FPDownloadService] Initialized');
  }

  Future<Map<String, dynamic>> _getSettings() async {
    final downloadThreads =
        await settings.getDynamic('download_threads', defaultValue: 2);
    final packageInfo = await PackageInfo.fromPlatform();
    const flavor =
        String.fromEnvironment('FLUTTER_FLAVOR', defaultValue: 'release');
    return {
      'downloadThreads': downloadThreads,
      'userAgent':
          'FloatyClient/${packageInfo.version}+${packageInfo.buildNumber}-$flavor',
      'offlinePath': _offlinePath,
    };
  }

  Future<void> _initNotifications() async {
    try {
      final dbusSessionBusAddress =
          Platform.environment['DBUS_SESSION_BUS_ADDRESS'];
      if (Platform.isLinux &&
          (dbusSessionBusAddress == null || dbusSessionBusAddress.isEmpty)) {
        _logger?.log(
            '[FPDownloadService] Skipping notifications; D-Bus session bus is unavailable');
        _notificationsInitialized = false;
        return;
      }

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: false,
      );
      const macosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: false,
      );
      const linuxSettings = LinuxInitializationSettings(
        defaultActionName: 'Open notification',
      );
      // Provide Windows initialization settings when running on Windows
      final windowsSettings = Platform.isWindows
          ? WindowsInitializationSettings(
              appName: 'Floaty',
              appUserModelId: 'uk.bw86.floaty',
              guid: 'd2f7b3e5-1c7a-4b0a-8c2f-3e8b9d1a2b3c',
            )
          : null;

      final initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
        macOS: macosSettings,
        linux: linuxSettings,
        windows: windowsSettings,
      );

      await _notificationsPlugin.initialize(initSettings);

      if (Platform.isAndroid) {
        await _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(
              const AndroidNotificationChannel(
                _channelId,
                _channelName,
                description: 'Floatplane video download notifications',
                importance: Importance.low,
              ),
            );
      }

      _notificationsInitialized = true;
      _logger?.log('[FPDownloadService] Notifications initialized');
    } catch (e) {
      _logger
          ?.log('[FPDownloadService] Failed to initialize notifications: $e');
      _notificationsInitialized = false;
    }
  }

  void _handleIsolateResponse(FPIsolateResponse response) {
    _logger?.log('[FPDownloadService] Response: ${response.type}');

    switch (response.type) {
      case 'stateChange':
        running = response.data?['running'] ?? false;
        queueSize = response.data?['queueSize'] ?? 0;
        activeDownloads = response.data?['activeDownloads'] ?? 0;
        rateLimitedCount = response.data?['rateLimited'] ?? 0;
        _serviceEvents.add({
          'type': 'stateChange',
          'running': running,
          'queueSize': queueSize,
          'activeDownloads': activeDownloads,
          'rateLimited': rateLimitedCount,
        });
        break;

      case 'progress':
        final downloads = response.data?['downloads'] as List?;
        if (downloads != null) {
          for (var d in downloads) {
            _updateNotification(d);
          }
          _serviceEvents.add({
            'type': 'progress',
            'data': downloads,
          });
        }
        break;

      case 'downloadsAdded':
        _serviceEvents.add({
          'type': 'downloadsAdded',
          'count': response.data?['count'] ?? 0,
        });
        break;

      case 'downloadsList':
        _downloads.clear();
        final downloads = response.data?['downloads'] as List?;
        if (downloads != null) {
          for (var d in downloads) {
            _downloads.add(Map<String, dynamic>.from(d));
          }
        }
        _serviceEvents.add({
          'type': 'downloadsList',
          'downloads': _downloads,
        });
        break;

      case 'downloadComplete':
        final id = response.data?['id'] as int?;
        final title = response.data?['title'] as String?;
        if (id != null) {
          _showCompletionNotification(id, title ?? 'Download');
          _lastNotificationUpdate.remove(id);
        }
        _serviceEvents.add({
          'type': 'downloadComplete',
          'data': response.data,
        });
        break;

      case 'rateLimited':
        final id = response.data?['id'] as int?;
        if (id != null) {
          _showRateLimitNotification(id);
          _lastNotificationUpdate.remove(id);
        }
        _serviceEvents.add({
          'type': 'rateLimited',
          'data': response.data,
        });
        break;

      case 'downloadError':
        final id = response.data?['id'] as int?;
        if (id != null) {
          _showErrorNotification(id);
          _lastNotificationUpdate.remove(id);
        }
        _serviceEvents.add({
          'type': 'downloadError',
          'data': response.data,
        });
        break;

      case 'urlExpired':
        // Handle expired download URL - need to refresh
        final id = response.data?['id'] as int?;
        final attachmentId = response.data?['attachmentId'] as String?;
        final qualityLabel = response.data?['qualityLabel'] as String?;
        final whitelabel = response.data?['whitelabel'] as String?;
        final title = response.data?['title'] as String?;

        if (id != null &&
            attachmentId != null &&
            qualityLabel != null &&
            whitelabel != null) {
          _logger?.log('[FPDownloadService] URL expired for: $title');
          // Request new URL from main isolate
          _serviceEvents.add({
            'type': 'urlExpired',
            'data': {
              'id': id,
              'attachmentId': attachmentId,
              'qualityLabel': qualityLabel,
              'whitelabel': whitelabel,
              'title': title,
            },
          });

          // Attempt automatic refresh of the download URL
          FPDownloadUrlHelper.refreshDownloadUrl(
            attachmentId: attachmentId,
            attachmentTitle: title ?? '',
            qualityLabel: qualityLabel,
            whitelabel: whitelabel,
          ).then((result) {
            if (result.success && result.newUrl != null) {
              _logger?.log('[FPDownloadService] Refreshed URL for: $title');
              updateDownloadUrl(id, result.newUrl!);
            } else if (result.isRateLimited) {
              _logger?.log(
                  '[FPDownloadService] Rate limited while refreshing URL for: $title');
            } else {
              _logger?.log(
                  '[FPDownloadService] Failed to refresh URL for: $title - ${result.error}');
            }
          });
        }
        break;
    }
  }

  /// Update download URL after refresh
  void updateDownloadUrl(int id, String newUrl) {
    _isolateManager?.sendMessage(
      FPCoordinatorMessage(
        type: 'updateDownloadUrl',
        data: {'id': id, 'newUrl': newUrl},
      ),
    );
  }

  /// Start/Resume downloads
  Future<void> start() async {
    running = true;
    _isolateManager?.sendMessage(FPCoordinatorMessage(type: 'start'));
  }

  /// Stop/Pause downloads
  Future<void> stop() async {
    running = false;
    _isolateManager?.sendMessage(FPCoordinatorMessage(type: 'stop'));
  }

  /// Get all downloads
  List<Map<String, dynamic>> getDownloads() {
    return _downloads;
  }

  /// Add download from post and attachment
  Future<void> addDownload({
    required ContentPostV3Response post,
    required dynamic attachment,
    required String qualityLabel,
    required String downloadUrl,
    required String whitelabel,
    String? creatorName,
    String? channelName,
    bool useExternalPath = false,
  }) async {
    final isVideo = attachment is VideoAttachmentModel;
    final attachmentId =
        isVideo ? (attachment).id : (attachment as AudioAttachmentModel).id;
    final title = isVideo
        ? (attachment).title
        : (attachment as AudioAttachmentModel).title;

    // Load filename and path settings
    final filenameTemplate = await settings.getDynamic('download_filename',
        defaultValue: '%title% (%quality%)');
    final useCreatorFolder =
        await settings.getBool('creator_folder', defaultValue: true);
    final useChannelFolder = await settings.getBool('channel_folder');

    // Apply template to generate filename
    final creator = creatorName ?? post.creator?.title ?? 'Unknown';
    final channel = channelName ?? post.channel?.title ?? 'Unknown';
    final extension = isVideo ? 'mp4' : 'mp3';

    String filename = filenameTemplate
        .replaceAll('%creator%', creator)
        .replaceAll('%channel%', channel)
        .replaceAll('%title%', title)
        .replaceAll('%quality%', qualityLabel);
    filename = _sanitizeFilename(filename);

    // Determine base path based on destination
    String basePath;
    if (useExternalPath) {
      // Use custom download path or system downloads directory
      final customPath = await settings.getDynamic('download_path');
      if (customPath != null) {
        basePath = customPath;
      } else {
        // Fallback to downloads directory
        final downloadsDir = await getDownloadsDirectory();
        if (downloadsDir != null) {
          basePath = downloadsDir.path;
        } else {
          // Ultimate fallback to app directory
          final appDir = await getApplicationDocumentsDirectory();
          basePath = p.join(appDir.path, 'downloads');
        }
      }
    } else {
      // Use offline library path (app's internal storage)
      basePath = _offlinePath!;
    }

    // For external downloads, use temp path during download, then move on completion
    String tempFilePath;
    String finalFilePath;

    if (useExternalPath) {
      // Store in app's temp directory during download
      tempFilePath = p.join(_offlinePath!, '$filename.$extension');

      // Build final path with user's folder organization settings for external storage
      List<String> finalPathComponents = [basePath];
      if (useCreatorFolder && useChannelFolder) {
        // Both enabled: Creator/Channel/file
        finalPathComponents.add(_sanitizeFilename(creator));
        finalPathComponents.add(_sanitizeFilename(channel));
      } else if (useCreatorFolder) {
        // Only creator: Creator/file
        finalPathComponents.add(_sanitizeFilename(creator));
      } else if (useChannelFolder) {
        // Only channel: Channel/file
        finalPathComponents.add(_sanitizeFilename(channel));
      }
      finalPathComponents.add('$filename.$extension');
      finalFilePath = p.joinAll(finalPathComponents);
    } else {
      // Offline downloads: always organize by creator (ignore user settings)
      tempFilePath =
          p.join(basePath, _sanitizeFilename(creator), '$filename.$extension');
      finalFilePath = tempFilePath; // Same path for offline
    }

    final downloadData = {
      'postId': post.id,
      'attachmentId': attachmentId,
      'attachmentType': isVideo ? 'video' : 'audio',
      'title': title,
      'creatorName': creatorName ?? post.creator?.title,
      'channelName': channelName ?? post.channel?.title,
      'thumbnailPath': isVideo
          ? (attachment).thumbnail.path ?? ''
          : post.thumbnail?.path ?? '',
      'qualityLabel': qualityLabel,
      'downloadUrl': downloadUrl,
      'filePath': tempFilePath,
      'finalFilePath': finalFilePath,
      'useExternalPath': useExternalPath,
      'duration': isVideo
          ? (attachment).duration
          : (attachment as AudioAttachmentModel).duration.toDouble(),
      'whitelabel': whitelabel,
      'blogPostJson': jsonEncode(post.toJson()),
      'postTitle': post.title,
      'postDescription': post.text,
      'releaseDate': post.releaseDate?.toIso8601String(),
    };

    _isolateManager?.sendMessage(
      FPCoordinatorMessage(type: 'addDownloads', data: {
        'downloads': [downloadData]
      }),
    );

    // Auto-start if not running
    if (!running) {
      await start();
    }
  }

  /// Remove download from queue
  Future<void> removeDownload(int id) async {
    _isolateManager?.sendMessage(
      FPCoordinatorMessage(type: 'removeDownload', data: {'id': id}),
    );
  }

  /// Retry failed/rate-limited downloads
  Future<void> retryDownloads() async {
    _isolateManager?.sendMessage(FPCoordinatorMessage(type: 'retryDownloads'));
  }

  /// Remove downloads by state
  Future<void> removeDownloads(FPDownloadState state) async {
    _isolateManager?.sendMessage(
      FPCoordinatorMessage(type: 'removeByState', data: {'state': state.index}),
    );
  }

  /// Remove offline content by file path
  Future<void> removeOfflineContent(String filePath) async {
    _isolateManager?.sendMessage(
      FPCoordinatorMessage(
          type: 'removeOfflineContent', data: {'filePath': filePath}),
    );
  }

  /// Check if attachment is available offline by checking if file exists
  bool isAvailableOffline(String attachmentId) {
    if (_offlinePath == null || _offlinePath!.isEmpty) return false;

    try {
      final dir = Directory(_offlinePath!);
      if (!dir.existsSync()) return false;

      // Search for file with this attachment ID
      final files = dir.listSync(recursive: true);
      for (final entity in files) {
        if (entity is File) {
          final path = entity.path.toLowerCase();
          if ((path.endsWith('.mp4') || path.endsWith('.mp3')) &&
              !path.endsWith('.part')) {
            // Check filename contains attachment ID or check metadata
            // For now, just check if any offline videos exist
            return true;
          }
        }
      }
    } catch (e) {
      _logger?.log('[FPDownloadService] Error checking offline: $e');
    }

    return false;
  }

  /// Get offline file path for attachment - caller should scan directory if needed
  String? getOfflineFilePath(String attachmentId) {
    // This method is deprecated - callers should scan the offline directory directly
    return null;
  }

  String _sanitizeFilename(String input) {
    return input
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  void _updateNotification(Map<String, dynamic> download) {
    if (!_notificationsInitialized) return;
    if (!(Platform.isAndroid || Platform.isIOS)) return;

    final id = download['id'] as int;
    final state = download['state'] as int;

    if (state != FPDownloadState.downloading.index) return;

    final filesize = download['filesize'] as int? ?? 0;
    if (filesize == 0) return;

    // Throttle updates
    final now = DateTime.now();
    final lastUpdate = _lastNotificationUpdate[id];
    if (lastUpdate != null && now.difference(lastUpdate).inMilliseconds < 500) {
      return;
    }
    _lastNotificationUpdate[id] = now;

    final title = download['title'] as String? ?? 'Download';
    final received = download['received'] as int? ?? 0;
    final progress = (received / filesize * 100).toInt();

    _notificationsPlugin.show(
      _notificationIdStart + id,
      'Downloading: $title',
      '$progress%',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Floatplane video download notifications',
          importance: Importance.low,
          priority: Priority.low,
          showProgress: true,
          maxProgress: 100,
          progress: progress,
          ongoing: true,
          onlyAlertOnce: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: false,
          presentBadge: true,
        ),
      ),
    );
  }

  Future<void> _showCompletionNotification(int id, String title) async {
    if (!_notificationsInitialized) return;

    await _notificationsPlugin.show(
      _notificationIdStart + id,
      'Download Complete',
      title,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Floatplane video download notifications',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
        ),
      ),
    );
  }

  Future<void> _showRateLimitNotification(int id) async {
    if (!_notificationsInitialized) return;

    await _notificationsPlugin.show(
      _notificationIdStart + id,
      'Download Paused',
      'Rate limited - will retry automatically',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Floatplane video download notifications',
          importance: Importance.low,
          priority: Priority.low,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: false,
          presentBadge: true,
        ),
      ),
    );
  }

  Future<void> _showErrorNotification(int id) async {
    if (!_notificationsInitialized) return;

    await _notificationsPlugin.show(
      _notificationIdStart + id,
      'Download Failed',
      'An error occurred',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Floatplane video download notifications',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
        ),
      ),
    );
  }

  Future<void> dispose() async {
    await stop();
    await _isolateManager?.stop();
    await _logger?.close();
    await _serviceEvents.close();
  }
}

// Global instance
final fpDownloadService = FPDownloadService();
