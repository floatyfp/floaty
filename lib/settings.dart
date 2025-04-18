import 'package:hive_ce/hive.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:get_it/get_it.dart';

final Settings settings = GetIt.I<Settings>();

class Settings {
  Future<Box> _getBox() async {
    final dir = await getApplicationSupportDirectory();
    Hive.init(dir.path);
    return await Hive.openBox('settings');
  }

  Future<void> setKey(String key, String value) async {
    final box = await _getBox();
    await box.put(key, value);
  }

  Future<String> getKey(String key) async {
    final box = await _getBox();
    return box.get(key, defaultValue: '');
  }

  Future<void> removeKey(String key) async {
    final box = await _getBox();
    await box.delete(key);
  }

  Future<void> setDynamic(String key, dynamic value) async {
    final box = await _getBox();
    await box.put(key, value);
  }

  Future<dynamic> getDynamic(String key) async {
    final box = await _getBox();
    return box.get(key);
  }

  Future<void> setBool(String key, bool value) async {
    final box = await _getBox();
    await box.put(key, value);
  }

  Future<bool> getBool(String key) async {
    final box = await _getBox();
    return box.get(key, defaultValue: false);
  }

  Future<bool> toggleBool(String key) async {
    final box = await _getBox();
    await box.put(key, !box.get(key, defaultValue: false));
    return box.get(key, defaultValue: false);
  }

  Future<void> removeBool(String key) async {
    final box = await _getBox();
    await box.delete(key);
  }

  Future<bool> containsKey(String key) async {
    final box = await _getBox();
    return box.containsKey(key);
  }

  Future<String?> getAuthTokenFromCookieJar() async {
    final dir = await getApplicationSupportDirectory();
    final cookieJar = PersistCookieJar(
      storage: FileStorage('${dir.path}/.cookies/'),
    );

    final uri = Uri.parse('https://www.floatplane.com');
    final cookies = await cookieJar.loadForRequest(uri);

    Cookie? authCookie;
    try {
      authCookie = cookies.firstWhere(
        (c) => c.name == 'sails.sid',
      );
    } catch (_) {
      authCookie = null;
    }
    return '${authCookie?.name}=${authCookie?.value}';
  }
}
