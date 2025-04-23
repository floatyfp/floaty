import 'package:logger/logger.dart';
import 'package:hive_ce/hive.dart';

class LogService {
  static final Logger _logger = Logger();
  static const String _boxName = 'app_logs';
  static const String _logKey = 'persisted_logs';
  static List<String> _logs = [];

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
    await _saveLog('[INFO] $message');
  }

  static void logError(String message) async {
    _logger.e(message);
    await _saveLog('[ERROR] $message');
  }

  static void logDebug(String message) async {
    _logger.d(message);
    await _saveLog('[DEBUG] $message');
  }

  static Future<void> _saveLog(String log) async {
    final box = await Hive.openBox(_boxName);
    _logs.add('${DateTime.now().toIso8601String()} $log');
    // Keep only the latest 500 logs
    if (_logs.length > 500) {
      _logs = _logs.sublist(_logs.length - 500);
    }
    await box.put(_logKey, _logs);
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
}
