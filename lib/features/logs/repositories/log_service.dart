import 'dart:async';
import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:hive_ce/hive.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class RemoteLogUploadResult {
  const RemoteLogUploadResult({
    required this.success,
    required this.message,
  });

  final bool success;
  final String message;
}

class LogService {
  static final Logger _logger = Logger();
  static const String _boxName = 'app_logs';
  static const String _logKey = 'persisted_logs';
  static const String _remoteLogEndpoint =
      String.fromEnvironment('FLOATY_REMOTE_LOG_ENDPOINT');
  static const String _remoteLogToken =
      String.fromEnvironment('FLOATY_REMOTE_LOG_TOKEN');
  static final String _sessionId = DateTime.now().toUtc().toIso8601String();
  static List<String> _logs = [];
  static bool _remoteEndpointRejectionLogged = false;

  static bool get remoteLoggingConfigured => _validatedRemoteLogUri != null;
  static String get remoteLogEndpoint => _remoteLogEndpoint;

  static Future<void> init() async {
    final box = await Hive.openBox(_boxName);
    final logs = box.get(_logKey, defaultValue: <String>[]);
    if (logs is List) {
      _logs = List<String>.from(logs);
    } else {
      _logs = [];
    }
  }

  static void logInfo(String message) async {
    _logger.i(message);
    await _saveLog('[INFO] $message', level: 'INFO');
  }

  static void logError(String message) async {
    _logger.e(message);
    await _saveLog('[ERROR] $message', level: 'ERROR');
  }

  static void logDebug(String message) async {
    _logger.d(message);
    await _saveLog('[DEBUG] $message', level: 'DEBUG');
  }

  static void logFlutterError(FlutterErrorDetails details) {
    logError('Flutter error: ${details.exceptionAsString()}\n${details.stack}');
  }

  static void logUncaughtError(Object error, StackTrace stackTrace,
      {String source = 'dart'}) {
    logError('Uncaught $source error: $error\n$stackTrace');
  }

  static Future<void> _saveLog(String log, {String level = 'INFO'}) async {
    final sanitizedLog = redactSensitiveLogData(log);
    final box = await Hive.openBox(_boxName);
    _logs.add('${DateTime.now().toIso8601String()} $sanitizedLog');
    // Keep only the latest 500 logs
    if (_logs.length > 500) {
      _logs = _logs.sublist(_logs.length - 500);
    }
    await box.put(_logKey, _logs);
    _sendRemoteLog(level: level, message: sanitizedLog);
  }

  static Future<List<String>> getLogs() async {
    final box = await Hive.openBox(_boxName);
    final logs = box.get(_logKey, defaultValue: <String>[]);
    if (logs is List) {
      return List<String>.from(logs);
    }
    return [];
  }

  static Future<void> clearLogs() async {
    final box = await Hive.openBox(_boxName);
    _logs.clear();
    await box.delete(_logKey);
  }

  /// Add a log directly (used by logging framework listener)
  static Future<void> addLog(String log, {String level = 'INFO'}) async {
    final sanitizedLog = redactSensitiveLogData(log);
    final box = await Hive.openBox(_boxName);
    _logs.add(
        '${DateTime.now().toIso8601String().split('T').join(' ').substring(0, 19)} $sanitizedLog');
    // Keep only the latest 1000 logs
    if (_logs.length > 1000) {
      _logs = _logs.sublist(_logs.length - 1000);
    }
    await box.put(_logKey, _logs);
    _sendRemoteLog(level: level, message: sanitizedLog);
  }

  static Future<RemoteLogUploadResult> uploadLogSnapshot(
      {required String source, required List<String> logs}) async {
    if (!remoteLoggingConfigured) {
      _logInvalidRemoteLogEndpointIfNeeded();
      return const RemoteLogUploadResult(
        success: false,
        message:
            'Remote logging is not configured. Set FLOATY_REMOTE_LOG_ENDPOINT.',
      );
    }

    final response = await _postRemotePayload({
      'type': 'log_snapshot',
      'source': source,
      'sessionId': _sessionId,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'platform': _platformName,
      'logs': logs.map(redactSensitiveLogData).toList(growable: false),
    });

    if (response == null) {
      return const RemoteLogUploadResult(
        success: false,
        message: 'Failed to send logs to remote endpoint.',
      );
    }

    final success = response.statusCode >= 200 && response.statusCode < 300;
    return RemoteLogUploadResult(
      success: success,
      message: success
          ? 'Sent ${logs.length} log lines to the remote endpoint.'
          : 'Remote endpoint returned HTTP ${response.statusCode}.',
    );
  }

  @visibleForTesting
  static bool isRemoteLogEndpointAllowed(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    if (!uri.hasScheme || !uri.hasAuthority || uri.host.isEmpty) {
      return false;
    }
    if (scheme == 'https') {
      return true;
    }
    if (scheme == 'http' && _isLoopbackHost(uri.host)) {
      return true;
    }
    return false;
  }

  @visibleForTesting
  static String redactSensitiveLogData(String value) {
    var redacted = value;
    final patterns = <RegExp>[
      RegExp(r'authorization\s*[:=]\s*bearer\s+[^\s,;]+', caseSensitive: false),
      RegExp(r'cookie\s*[:=]\s*[^,\n]+', caseSensitive: false),
      RegExp(r'(token|accessToken|refreshToken|idToken)\s*[:=]\s*[^\s,;]+',
          caseSensitive: false),
      RegExp(r'(sails\.sid|__Host-sp-sess)\s*=\s*[^;\s]+',
          caseSensitive: false),
    ];

    for (final pattern in patterns) {
      redacted = redacted.replaceAllMapped(pattern, (match) {
        final text = match.group(0) ?? '';
        final separatorIndex = text.indexOf(RegExp(r'[:=]'));
        if (separatorIndex == -1) return '[REDACTED]';
        return '${text.substring(0, separatorIndex + 1)} [REDACTED]';
      });
    }
    return redacted;
  }

  static void _sendRemoteLog({
    required String level,
    required String message,
  }) {
    if (!remoteLoggingConfigured) return;

    unawaited(_postRemotePayload({
      'type': 'log',
      'level': level,
      'message': message,
      'sessionId': _sessionId,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'platform': _platformName,
    }));
  }

  static Future<http.Response?> _postRemotePayload(
      Map<String, dynamic> payload) async {
    try {
      final uri = _validatedRemoteLogUri;
      if (uri == null) {
        _logInvalidRemoteLogEndpointIfNeeded();
        return null;
      }

      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (_remoteLogToken.isNotEmpty)
          'Authorization': 'Bearer $_remoteLogToken',
      };

      return await http
          .post(uri, headers: headers, body: jsonEncode(payload))
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      return null;
    }
  }

  static Uri? get _validatedRemoteLogUri {
    if (_remoteLogEndpoint.isEmpty) return null;

    final uri = Uri.tryParse(_remoteLogEndpoint);
    if (uri == null || !isRemoteLogEndpointAllowed(uri)) {
      return null;
    }
    return uri;
  }

  static void _logInvalidRemoteLogEndpointIfNeeded() {
    if (_remoteLogEndpoint.isEmpty ||
        _validatedRemoteLogUri != null ||
        _remoteEndpointRejectionLogged) {
      return;
    }

    _remoteEndpointRejectionLogged = true;
    _logger.w(
        'Remote logging endpoint rejected; use HTTPS or HTTP loopback only: $_remoteLogEndpoint');
  }

  static bool _isLoopbackHost(String host) {
    final normalizedHost = host.toLowerCase();
    return normalizedHost == 'localhost' ||
        normalizedHost == '127.0.0.1' ||
        normalizedHost == '::1';
  }

  static String get _platformName {
    if (kIsWeb) return 'web';
    return Platform.operatingSystem;
  }

  /// Get download logs from file
  static Future<List<String>> getDownloadLogs() async {
    try {
      final directory = await getApplicationSupportDirectory();
      final logFile = File('${directory.path}/download.log');

      if (!await logFile.exists()) {
        return [];
      }

      final contents = await logFile.readAsString();
      final lines =
          contents.split('\n').where((line) => line.isNotEmpty).toList();

      // Return the last 1000 lines
      if (lines.length > 1000) {
        return lines.sublist(lines.length - 1000);
      }

      return lines;
    } catch (e) {
      return ['Error reading download logs: $e'];
    }
  }

  /// Clear download logs
  static Future<void> clearDownloadLogs() async {
    try {
      final directory = await getApplicationSupportDirectory();
      final logFile = File('${directory.path}/download.log');

      if (await logFile.exists()) {
        await logFile.delete();
      }
    } catch (e) {
      _logger.e('Error clearing download logs: $e');
    }
  }
}
