import 'dart:convert';
import 'package:http/http.dart' as http;

class fpApi {
  static const String baseUrl = 'https://www.floatplane.com/api';
  static const String userAgent = 'FloatyClient/1.0.0, CFNetwork';
  String cookies = '';

  Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': userAgent,
      },
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to login: ${response.body}');
    }
  }
  Future<Map<String, dynamic>> twofa(String code) async {
    final url = Uri.parse('$baseUrl/auth/checkFor2faLogin'); 
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': userAgent,
      },
      body: jsonEncode({
        'token': code,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to send 2fa: ${response.body}');
    }
  }
}