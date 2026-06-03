import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// connectivity_plus on Linux talks to NetworkManager over D-Bus. When D-Bus is
/// missing (headless CI, some AppImage/sandbox setups, minimal distros) those
/// calls throw and break GoRouter redirects — resulting in a blank window.
Future<List<ConnectivityResult>> safeCheckConnectivity() async {
  if (kIsWeb) {
    return [ConnectivityResult.wifi];
  }
  try {
    return await Connectivity().checkConnectivity();
  } catch (e) {
    debugPrint('Connectivity check unavailable, assuming online: $e');
    return [ConnectivityResult.wifi];
  }
}

/// Registers [onOnline] when connectivity changes. Returns false if listening
/// could not be started (e.g. no D-Bus on Linux).
bool listenForConnectivity(void Function(List<ConnectivityResult>) onOnline) {
  if (kIsWeb) {
    return false;
  }
  try {
    Connectivity().onConnectivityChanged.listen((result) {
      if (result.contains(ConnectivityResult.mobile) ||
          result.contains(ConnectivityResult.wifi) ||
          result.contains(ConnectivityResult.ethernet)) {
        onOnline(result);
      }
    });
    return true;
  } catch (e) {
    debugPrint('Connectivity listener unavailable: $e');
    return false;
  }
}

bool get connectivityLikelyUnavailableOnLinux =>
    Platform.isLinux &&
    !File('/var/run/dbus/system_bus_socket').existsSync() &&
    !(Platform.environment['DBUS_SESSION_BUS_ADDRESS']?.isNotEmpty ?? false);
