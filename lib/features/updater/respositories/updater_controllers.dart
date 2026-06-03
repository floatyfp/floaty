import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:get_it/get_it.dart';

UpdaterController get updatercontroller => GetIt.I<UpdaterController>();

class UpdaterController {
  static const _updateTimeout = Duration(seconds: 5);

  final Dio dio = Dio(
    BaseOptions(
      connectTimeout: _updateTimeout,
      receiveTimeout: _updateTimeout,
    ),
  );
  late String flavor;
  bool updateReady = false;
  final StreamController<bool> updateStream =
      StreamController<bool>.broadcast();

  @override
  UpdaterController() {
    const flavorenv =
        String.fromEnvironment('FLUTTER_FLAVOR', defaultValue: 'release');
    if (flavorenv == 'dev') {
      flavor = 'nightly';
    } else {
      flavor = flavorenv;
    }
    initialCheck();
  }

  Future<bool> updateAvailable() async {
    final response =
        await dio.get('https://floaty.fyi/api/latest-update?flavor=$flavor');
    final packageInfo = await PackageInfo.fromPlatform();
    if (response.data != null &&
        response.data['deployment'] != null &&
        response.data['deployment']['version'] == packageInfo.version) {
      return true;
    }
    return false;
  }

  Future<void> initialCheck() async {
    try {
      final response =
          await dio.get('https://floaty.fyi/api/latest-update?flavor=$flavor');
      final packageInfo = await PackageInfo.fromPlatform();
      if (response.data != null &&
          response.data['deployment'] != null &&
          response.data['deployment']['version'] != packageInfo.version) {
        updateReady = true;
        updateStream.add(true);
      }
    } catch (e) {
      debugPrint('Update check failed: $e');
    }
  }

  Future<dynamic> getUpdate() async {
    final response =
        await dio.get('https://floaty.fyi/api/latest-update?flavor=$flavor');
    return response.data;
  }

  /// Returns `/update` when a required update is available; otherwise null.
  Future<String?> redirectPathIfUpdateRequired() async {
    try {
      final data = await getUpdate().timeout(_updateTimeout);
      final packageInfo = await PackageInfo.fromPlatform();
      if (data != null &&
          data['deployment'] != null &&
          data['deployment']['version'] != packageInfo.version &&
          data['deployment']['required'] == 1) {
        return '/update';
      }
    } catch (e) {
      debugPrint('Update redirect check skipped: $e');
    }
    return null;
  }
}
