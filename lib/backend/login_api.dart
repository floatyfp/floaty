import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:floaty/settings.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:get_it/get_it.dart';

final LoginApi loginApi = GetIt.I<LoginApi>();

class LoginApi {
  late final Settings settings = settings;
  static const String baseUrl = 'https://www.floatplane.com/api';
  PackageInfo? packageInfo;
  String userAgent = 'FloatyClient/error, CFNetwork';
  String? token;
  late final PersistCookieJar cookieJar;
  late final Dio _dio;

  LoginApi() {
    _init();
  }

  void _init() async {
    packageInfo = await PackageInfo.fromPlatform();
    userAgent = 'FloatyClient/${packageInfo?.version}, CFNetwork';
    final dir = await getApplicationSupportDirectory();
    cookieJar = PersistCookieJar(
      storage: FileStorage('${dir.path}/.cookies/'),
    );

    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      responseType: ResponseType.plain,
      headers: {
        'User-Agent': userAgent,
        'Content-Type': 'application/json',
      },
      validateStatus: (_) => true,
    ));

    _dio.interceptors.add(CookieManager(cookieJar));
  }

  Future<void> addManualCookie(
    CookieJar jar, {
    required String domain,
    required String name,
    required String value,
    String path = '/',
    DateTime? expires,
  }) async {
    final cookie = Cookie(name, value)
      ..domain = domain
      ..path = path
      ..httpOnly = true
      ..expires =
          expires ?? DateTime.now().add(Duration(days: 30)); // default 30 days

    await jar.saveFromResponse(
      Uri.parse('https://$domain'),
      [cookie],
    );
  }

// do not messsage me about this absolute garbage code please - bw86
// back here like 3 months later because well it broke - bw86 - 20/01/2025
// migration to dio and cookiejar because my manual system is ass - bw86 -15/04/2025
  Future<Map<String, dynamic>> login(String username, String password) async {
    final url = '$baseUrl/auth/login';
    final response = await _dio.post(
      url,
      data: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    final resData = jsonDecode(response.data);

    if (response.statusCode == 200) {
      final cookies = await cookieJar.loadForRequest(Uri.parse(baseUrl));
      final cookieString = _cookieHeader(cookies);

      if (resData['needs2FA'] == true) {
        await settings.setKey('2faHeader', cookieString);
        token = cookieString;
      }
    }

    return resData;
  }

  Future<Map<String, dynamic>> twofa(String code) async {
    final twofaCookie = await settings.getKey('2faHeader');
    String? parsedtoken;
    final cookies = twofaCookie.split(';');
    for (final cookie in cookies) {
      final cookieParts = cookie.split('=');
      if (cookieParts.length == 2) {
        final name = cookieParts[0].trim();
        final value = cookieParts[1].trim();
        if (name == 'sails.sid') {
          parsedtoken = value;
        }
      }
    }
    final url = '$baseUrl/auth/checkFor2faLogin';
    final response = await _dio.post(url,
        data: jsonEncode({
          'token': code,
        }),
        options: Options(
          headers: {
            'Cookie': twofaCookie,
          },
        ));

    final resData = jsonDecode(response.data);

    if (response.statusCode == 200 && resData['needs2FA'] == false) {
      await addManualCookie(
        cookieJar,
        domain: 'floatplane.com',
        name: 'sails.sid',
        value: parsedtoken!,
      );
      await settings.setKey('2faHeader', '');
      token = twofaCookie;
    }

    return resData;
  }

  String _cookieHeader(List<Cookie> cookies) {
    return cookies.map((c) => '${c.name}=${c.value}').join('; ');
  }
}
