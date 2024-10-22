import 'package:floaty/settings.dart';
import 'package:intl/intl.dart';

class Checkers {
  Future<bool> isAuthenticated() async {
    var cookie = await Settings().getKey('token');
    if (cookie.isEmpty) {
      return false;
    }
    try {
      var cookieParts = cookie.split(';').map((s) => s.trim()).toList();
      String expiresPart = '';
      for (var part in cookieParts) {
        if (part.startsWith('Expires=')) {
          expiresPart = part.substring('Expires='.length);
        }
      }
      if (expiresPart.isEmpty) {
        if (cookieParts.length > 1) {
          expiresPart = cookieParts[1];
        } else {
          return false; //failsafe i guess 
        }
      }
      DateTime parsedDate;
      try {
        DateFormat dateFormat = DateFormat("dd MMM yyyy HH:mm:ss 'GMT'", "en_US");
        parsedDate = dateFormat.parse(expiresPart, true);
      } catch (e) {
        DateFormat dateFormat = DateFormat("dd MMM yyyy HH:mm:ss Z", "en_US"); //handle timezones maybe idk
        parsedDate = dateFormat.parse(expiresPart);
      }
      DateTime now = DateTime.now().toUtc();
      const bufferMinutes = 1;
      var adjustedNow = now.add(const Duration(minutes: bufferMinutes));
      bool isValid = !adjustedNow.isAfter(parsedDate);
      if (!isValid) {
        await Settings().removeKey('token');
      }
      return isValid;
    } catch (e) {
      return false;
    }
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
