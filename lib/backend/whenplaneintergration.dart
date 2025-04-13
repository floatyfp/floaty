import 'package:floaty/settings.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:math' as math;
import 'package:web_socket_client/web_socket_client.dart';
import 'package:intl/intl.dart';

class WhenPlaneIntegration {
  static String baseUrl = 'https://whenplane.com/api';
  final List<String> alternates = [
    "late",
    "\"late\"",
    "soon™",
    "close enough",
    "punctually impaired",
    "punctually challenged",
    "belated",
    "procrastinated",
    "Linus Late Tips",
    "Late-nus",
    "The Late Show",
    "fashionably late",
    "tardy",
    "diligently delayed",
    "gregariously unpunctual"
  ];

  Future<String> fetchData(String apiUrl) async {
    final url = Uri.parse('$baseUrl/$apiUrl');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'FloatyClient/1.0.0, CFNetwork',
      },
    );
    return response.body;
  }

  getPreviousShowInfo(String date) {
    return fetchData('history/show/$date');
  }

  String newPhrase() {
    return alternates[math.Random().nextInt(alternates.length)];
  }

  Future<String> lateness() async {
    String res = await fetchData('latenesses');
    return res;
  }

  Stream<String> streamWebsocket() async* {
    try {
      final socket = WebSocket(
        Uri.parse('wss://sockets.whenplane.com/socket?events=aggregate'),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'FloatyClient/1.0.0, CFNetwork',
        },
      );

      await for (final message in socket.messages) {
        yield message;
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<String> floatplanestats() async {
    return fetchData(
        'floatplane?fast=false&description=false&d=${DateTime.now().millisecondsSinceEpoch}');
  }

  bool isBefore(DateTime a, DateTime b) {
    return a.isBefore(b);
  }

  DateTime getNextWAN(DateTime now, {bool buffer = true, bool? hasDone}) {
    DateTime wanDate = getLooseWAN(now);

    while (wanDate.weekday != DateTime.friday) {
      wanDate = wanDate.add(Duration(days: 1));
    }

    bool shouldStay;
    if (buffer) {
      if (hasDone != null) {
        shouldStay = !hasDone;
        // print('hasDone: $hasDone, shouldStay: $shouldStay');
      } else {
        shouldStay = now.isAfter(wanDate.add(Duration(hours: 5))) &&
            now.isBefore(wanDate.add(Duration(hours: 6)));
      }
    } else {
      shouldStay = false;
    }

    if (wanDate.isBefore(now) && !shouldStay) {
      wanDate = wanDate.add(Duration(days: 7));
    }

    if (wanDate.isAfter(now.add(Duration(days: 6)))) {
      if (shouldStay) {
        wanDate = wanDate.subtract(Duration(days: 7));
      }
    }

    if (hasDone != null && wanDate.isBefore(now.add(Duration(days: 1)))) {
      wanDate = wanDate.add(Duration(days: 7));
    }

    if (wanDate.year == 2023 && wanDate.month == 7 && wanDate.day == 28 ||
        wanDate.year == 2019 && wanDate.month == 7 && wanDate.day == 26) {
      wanDate = wanDate.add(Duration(days: 1));
    }

    if (wanDate.year == 2024 && wanDate.month == 4 && wanDate.day == 26) {
      wanDate = DateTime(wanDate.year, wanDate.month, wanDate.day, 13, 0);
    }

    if (wanDate.year == 2024 && wanDate.month == 12 && wanDate.day == 27) {
      wanDate = DateTime(wanDate.year, wanDate.month, wanDate.day, 15, 0);
    }

    if (wanDate.year == 2024 && wanDate.month == 11 && wanDate.day == 22) {
      wanDate = DateTime(wanDate.year, wanDate.month, wanDate.day, 8, 30);
    }

    if (wanDate.year == 2024 && wanDate.month == 6 && wanDate.day == 21) {
      wanDate = DateTime(wanDate.year, wanDate.month, wanDate.day, 10, 0);
    }

    if (wanDate.year == 2023 && wanDate.month == 8 && wanDate.day == 18) {
      wanDate = wanDate.add(Duration(days: 7));
    }

    return wanDate;
  }

  DateTime getLooseWAN(DateTime now) {
    int year = now.year;
    int month = now.month;
    int day = now.hour <= 3 ? now.day - 1 : now.day;

    if (day <= 0) {
      month -= 1;
      day = DateTime(year, month + 1, 0).day + day;
    }

    if (month <= 0) {
      year -= 1;
      month += 12;
      day = DateTime(year, month + 1, 0).day;
    }

    //return utc instead of vancouver time so .toLocal() works
    return DateTime.utc(year, month, day, 23, 30);
  }

  String getUTCDate(DateTime date) {
    if (date.hour < 2) {
      date = date.subtract(Duration(days: 1));
    }
    return DateFormat('yyyy/MM/dd').format(date);
  }

  int dateToNumber(String date) {
    return int.parse(date.replaceAll("/", ""));
  }

  String addZero(int n) {
    return n > 9 ? "$n" : "0$n";
  }

  Map<String, dynamic> getTimeUntil(DateTime date, {DateTime? now}) {
    now ??= DateTime.now();
    int distance = date.difference(now).inMilliseconds;
    bool late = false;
    if (distance < 0) {
      late = true;
      distance = distance.abs();
    }

    String string = timeString(distance);

    return {'string': string, 'late': late, 'distance': distance};
  }

  String timeString(int distance,
      {bool long = false, bool showSeconds = true}) {
    int days = (distance / (1000 * 60 * 60 * 24)).floor();
    int hours = ((distance % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60)).floor();
    int minutes = ((distance % (1000 * 60 * 60)) / (1000 * 60)).floor();
    int seconds = ((distance % (1000 * 60)) / 1000).floor();

    String d = long ? (days != 1 ? " days " : " day ") : "d ";
    String h = long ? (hours != 1 ? " hours " : " hour ") : "h ";
    String m = long ? (minutes != 1 ? " minutes " : " minute ") : "m ";
    String s = long ? (seconds != 1 ? " seconds " : " second ") : "s ";

    String daysS = days > 0 ? "$days$d" : "";
    String hoursS = hours > 0 ? "$hours$h" : "";
    String minutesS = minutes > 0 ? "$minutes$m" : "";
    String and =
        long && (daysS.isNotEmpty || hoursS.isNotEmpty || minutesS.isNotEmpty)
            ? "and "
            : "";
    String secondsS = "$seconds$s";

    return "$daysS$hoursS$minutesS${showSeconds ? "$and$secondsS" : minutes > 0 ? "" : "<1 minute"}";
  }

  String timeStringHours(int distance, {bool long = false}) {
    int hours = (distance / (1000 * 60 * 60)).floor();
    int minutes = ((distance % (1000 * 60 * 60)) / (1000 * 60)).floor();
    int seconds = ((distance % (1000 * 60)) / 1000).floor();

    String h = long ? (hours != 1 ? " hours " : " hour ") : "h ";
    String m = long ? (minutes != 1 ? " minutes " : " minute ") : "m ";
    String s = long ? (seconds != 1 ? " seconds " : " second ") : "s ";

    String hoursS = hours > 0 ? "$hours$h" : "";
    String minutesS = minutes > 0 ? "$minutes$m" : "";
    String and =
        long && (hoursS.isNotEmpty || minutesS.isNotEmpty) ? "and " : "";
    String secondsS = "$seconds$s";

    return "$hoursS$minutesS$and$secondsS";
  }

  DateTime getPreviousWAN(DateTime now) {
    DateTime wanDate = getLooseWAN(now);

    while (wanDate.weekday != DateTime.friday) {
      wanDate = wanDate.subtract(Duration(days: 1));
    }

    if (wanDate.year == 2024 && wanDate.month == 4 && wanDate.day == 26) {
      wanDate = DateTime(wanDate.year, wanDate.month, wanDate.day, 13, 0);
    }

    if (wanDate.year == 2024 && wanDate.month == 12 && wanDate.day == 27) {
      wanDate = DateTime(wanDate.year, wanDate.month, wanDate.day, 15, 0);
    }

    if (wanDate.year == 2024 && wanDate.month == 11 && wanDate.day == 22) {
      wanDate = DateTime(wanDate.year, wanDate.month, wanDate.day, 8, 30);
    }

    if (wanDate.year == 2024 && wanDate.month == 6 && wanDate.day == 21) {
      wanDate = DateTime(wanDate.year, wanDate.month, wanDate.day, 10, 0);
    }

    if (isBefore(now, wanDate)) {
      wanDate = wanDate.subtract(Duration(days: 7));
    }

    if (wanDate.year == 2023 && wanDate.month == 7 && wanDate.day == 28 ||
        wanDate.year == 2019 && wanDate.month == 7 && wanDate.day == 26) {
      wanDate = wanDate.add(Duration(days: 1));
    }

    return wanDate;
  }

  DateTime getClosestWan(DateTime now) {
    DateTime next = getNextWAN(now, buffer: false);
    DateTime previous = getPreviousWAN(now);

    int distanceToNext = next.difference(now).inMilliseconds.abs();
    int distanceToPrevious = previous.difference(now).inMilliseconds.abs();

    return distanceToNext > distanceToPrevious ? previous : next;
  }

  bool isNearWan(DateTime? now) {
    now ??= DateTime.now();
    if (now.weekday == DateTime.friday) {
      return now.hour > 20;
    } else if (now.weekday == DateTime.saturday) {
      return now.hour <= 11;
    } else {
      return false;
    }
  }

  List<String> shortMonths = [
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "Jun",
    "Jul",
    "Aug",
    "Sep",
    "Oct",
    "Nov",
    "Dec"
  ];

  bool isSameDay(DateTime a, DateTime b) {
    return a.day == b.day && a.month == b.month && a.year == b.year;
  }

  DateTime yesterday() {
    DateTime date = DateTime.now();
    return DateTime(date.year, date.month, date.day - 1);
  }

  String dateTimeToString(DateTime date) {
    return DateFormat('yyyy/MM/dd').format(date);
  }

  Future<String> aggregate() async {
    String res = await fetchData('aggregate');
    return res;
  }

  Future<String> sendVote(String vote, String k) async {
    final response = await http.post(
        Uri.parse(
            'https://whenplane.com/?/vote=&for=${Uri.encodeComponent(vote)}&k=$k'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Origin': 'https://whenplane.com',
          'Cookie':
              Settings().getKey('whenplaneid').toString().split(';').first,
          'User-Agent': 'FloatyClient/1.0.0, CFNetwork'
        });

    if (response.headers.containsKey('set-cookie')) {
      Settings().setKey('whenplaneid', response.headers['set-cookie'] ?? '');
    }

    return response.body;
  }
}
