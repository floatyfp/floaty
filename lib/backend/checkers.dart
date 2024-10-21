import 'package:floaty/settings.dart';

class Checkers {
  bool isAuthenticated() {
    var cookie = Settings().getKey('token').toString();
    if (cookie.isEmpty) {
      return false;
    }
    var cookieParts = cookie.split('; ');
    // check if expired
    for (var part in cookieParts) {
      if (part.startsWith('Expires=')) {
        var expirationString = part.substring('Expires='.length);
        DateTime expirationDate = DateTime.parse(expirationString);
        DateTime now = DateTime.now().toUtc();
        return !now.isAfter(expirationDate);
      }
    }
    return false;
  }
  bool twoFAAuthenticated() {
    var cookie = Settings().getKey('2faHeader').toString();
    if (cookie.isEmpty) {
      return false;
    } else {
      return true;
    }
  }
}