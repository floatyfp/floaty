import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:math' as math;

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
}
