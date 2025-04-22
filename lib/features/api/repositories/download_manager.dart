import 'package:background_downloader/background_downloader.dart';
import 'dart:io' show Platform;
import 'dart:async' show Completer, StreamSubscription;

class DownloadManager {
  static final DownloadManager _instance = DownloadManager._internal();
  factory DownloadManager() => _instance;
  DownloadManager._internal();

  // Map to store original task IDs to their new file paths
  final Map<String, String> _movedFilePaths = {};

  Future<void> initialize() async {
    // Configure notifications
    FileDownloader().configureNotification(
      running: const TaskNotification(
        'Downloading',
        'Downloading {filename}',
      ),
      complete: const TaskNotification(
        'Download Complete',
        '{filename} has been downloaded',
      ),
      error: const TaskNotification(
        'Download Failed',
        'Failed to download {filename}',
      ),
      progressBar: true,
      tapOpensFile: true,
    );

    // Register notification tap callback
    FileDownloader().registerCallbacks(
      taskNotificationTapCallback: _notificationTapCallback,
    );
  }

  Future<bool> checkAndRequestPermissions() async {
    // Check notification permission
    var status =
        await FileDownloader().permissions.status(PermissionType.notifications);
    if (status != PermissionStatus.granted) {
      if (await FileDownloader()
          .permissions
          .shouldShowRationale(PermissionType.notifications)) {
        // Here you might want to show a dialog explaining why notifications are needed
      }
      status = await FileDownloader()
          .permissions
          .request(PermissionType.notifications);
      if (status != PermissionStatus.granted) {
        return false;
      }
    }

    // Check storage permissions for iOS photo library
    if (Platform.isIOS) {
      status = await FileDownloader()
          .permissions
          .status(PermissionType.iosChangePhotoLibrary);
      if (status != PermissionStatus.granted) {
        if (await FileDownloader()
            .permissions
            .shouldShowRationale(PermissionType.iosChangePhotoLibrary)) {
          // Here you might want to show a dialog explaining why photo library access is needed
        }
        status = await FileDownloader()
            .permissions
            .request(PermissionType.iosChangePhotoLibrary);
        if (status != PermissionStatus.granted) {
          return false;
        }
      }
    }

    // Check storage permissions for Android
    if (Platform.isAndroid) {
      status = await FileDownloader()
          .permissions
          .status(PermissionType.androidSharedStorage);
      if (status != PermissionStatus.granted) {
        if (await FileDownloader()
            .permissions
            .shouldShowRationale(PermissionType.androidSharedStorage)) {
          // Here you might want to show a dialog explaining why storage access is needed
        }
        status = await FileDownloader()
            .permissions
            .request(PermissionType.androidSharedStorage);
        if (status != PermissionStatus.granted) {
          return false;
        }
      }
    }

    return true;
  }

  void _notificationTapCallback(
      Task task, NotificationType notificationType) async {
    if (notificationType == NotificationType.complete) {
      // Try to open the moved file first, if we have its new location
      if (_movedFilePaths.containsKey(task.taskId)) {
        final newPath = _movedFilePaths[task.taskId]!;
        final success = await FileDownloader().openFile(filePath: newPath);
        if (success) return;
      }
      await FileDownloader().openFile(task: task);
    }
  }

  Future<void> moveToDownloads(DownloadTask task) async {
    final extension = task.filename.split('.').last.toLowerCase();
    SharedStorage targetStorage;

    // Determine target storage based on file extension
    switch (extension) {
      case 'png':
        targetStorage = SharedStorage.images;
        break;
      case 'mp4':
        targetStorage = SharedStorage.video;
        break;
      case 'mp3':
        targetStorage = SharedStorage.audio;
        break;
      default:
        targetStorage = SharedStorage.downloads;
    }

    final completer = Completer<void>();
    late StreamSubscription subscription;

    subscription = FileDownloader().updates.listen(
      (taskUpdate) {
        if (taskUpdate.task.taskId == task.taskId) {
          if (taskUpdate is TaskStatusUpdate) {
            if (taskUpdate.status == TaskStatus.complete) {
              subscription.cancel();
              completer.complete();
            } else if (taskUpdate.status == TaskStatus.failed ||
                taskUpdate.status == TaskStatus.canceled) {
              subscription.cancel();
              completer.completeError(
                  'Download failed with status: ${taskUpdate.status}');
            }
          }
        }
      },
      onError: (error) {
        subscription.cancel();
        completer.completeError('Error monitoring download: $error');
      },
    );

    await completer.future;

    // Try to move the file multiple times if needed
    int attempts = 0;
    const maxAttempts = 3;
    bool success = false;

    while (attempts < maxAttempts && !success) {
      try {
        final newFilePath = await FileDownloader().moveToSharedStorage(
          task,
          targetStorage,
        );

        if (newFilePath != null) {
          _movedFilePaths[task.taskId] = newFilePath;
          success = true;
          break;
        }

        await Future.delayed(Duration(seconds: attempts + 1));
        attempts++;
      } catch (e) {
        await Future.delayed(Duration(seconds: attempts + 1));
        attempts++;
      }
    }

    if (!success) {
      // As a fallback, try to move to downloads
      if (targetStorage != SharedStorage.downloads) {
        final newFilePath = await FileDownloader().moveToSharedStorage(
          task,
          SharedStorage.downloads,
        );
        if (newFilePath != null) {
          _movedFilePaths[task.taskId] = newFilePath;
        }
      }
    }

    // Clean up old mappings periodically (keep only last 100 entries)
    if (_movedFilePaths.length > 100) {
      final entriesToRemove = _movedFilePaths.length - 100;
      final keys = _movedFilePaths.keys.take(entriesToRemove).toList();
      for (final key in keys) {
        _movedFilePaths.remove(key);
      }
    }
  }
}
