import 'package:floaty/settings.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cookie_jar/cookie_jar.dart';

class Checkers {
  Future<bool> isAuthenticated() async {
    final dir = await getApplicationSupportDirectory();
    final cookieJar = PersistCookieJar(
      storage: FileStorage('${dir.path}/.cookies/'),
    );
    final cookies =
        await cookieJar.loadForRequest(Uri.parse('https://floatplane.com'));
    Cookie? authCookie;
    try {
      authCookie = cookies.firstWhere(
        (c) => c.name == 'sails.sid',
      );
    } catch (_) {
      authCookie = null;
    }

    return authCookie != null &&
        authCookie.expires != null &&
        authCookie.expires!.isAfter(DateTime.now());
  }

  Future<bool> twoFAAuthenticated() async {
    var cookie = await Settings().getKey('2faHeader');
    if (cookie.isEmpty) {
      return false;
    } else {
      return true;
    }
  }
}
