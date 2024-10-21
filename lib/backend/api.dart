import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:Floaty/settings.dart';

class fpApi {
  late final Settings settings = Settings();
  static const String baseUrl = 'https://www.floatplane.com/api';
  static const String userAgent = 'FloatyClient/1.0.0, CFNetwork';
  String? token;

  fpApi() {
    _initTokens();
  }

  Future<void> _initTokens() async {
    token = await settings.getKey('token');
  }

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
    var res = jsonDecode(response.body);
    final setCookieHeader = response.headers['set-cookie'];
    if (setCookieHeader != null) {
      final cookies = setCookieHeader.split(',').map((cookie) {
        return cookie.split(';').first.trim();
      }).toList();
      final allCookies = cookies.join('; '); 
      if (res['needs2FA'] == true) {
        await settings.setKey('2faHeader', allCookies);
      } else {
        await settings.setKey('cookies', allCookies);
      }
      _initTokens();
    }
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
         'Cookie': await settings.getKey('2faHeader'),
      },
      body: jsonEncode({
        'token': code,
      }),
    );

    if (response.statusCode == 200) {
      var res = jsonDecode(response.body);
      if (res['needs2FA'] == true) {
        await settings.setKey('cookies', await settings.getKey('2faHeader'));
      }
      _initTokens();
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to send 2fa: ${response.body}');
    }
  }
}