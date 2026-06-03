import 'dart:io';

import 'package:floaty/features/download/controllers/fp_download_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('selectOfflineStorageDirectory', () {
    test('uses external storage when requested and available', () {
      final appSupportDirectory = Directory('/app-support');
      final externalStorageDirectory = Directory('/external-storage');

      final directory = selectOfflineStorageDirectory(
        applicationSupportDirectory: appSupportDirectory,
        externalStorageDirectory: externalStorageDirectory,
        useExternalStorage: true,
      );

      expect(directory.path, externalStorageDirectory.path);
    });

    test('uses app support storage when external storage is unavailable', () {
      final appSupportDirectory = Directory('/app-support');

      final directory = selectOfflineStorageDirectory(
        applicationSupportDirectory: appSupportDirectory,
        useExternalStorage: true,
      );

      expect(directory.path, appSupportDirectory.path);
    });

    test('uses app support storage when external storage is not requested', () {
      final appSupportDirectory = Directory('/app-support');
      final externalStorageDirectory = Directory('/external-storage');

      final directory = selectOfflineStorageDirectory(
        applicationSupportDirectory: appSupportDirectory,
        externalStorageDirectory: externalStorageDirectory,
        useExternalStorage: false,
      );

      expect(directory.path, appSupportDirectory.path);
    });
  });
}
