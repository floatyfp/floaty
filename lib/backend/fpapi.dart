import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:floaty/settings.dart';
import 'package:floaty/backend/definitions.dart';
import 'dart:convert';

class FPApiRequests{
  late final Settings settings = Settings();
  static const String baseUrl = 'https://www.floatplane.com/api';
  static const String userAgent = 'FloatyClient/1.0.0, CFNetwork';

  Future _fetchDataWithEtag(String apiUrl) async {
    final url = Uri.parse('$baseUrl/$apiUrl');
    final prefs = await SharedPreferences.getInstance();
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final cachedEtag = prefs.getString('etag_$url');
    final cachedData = prefs.getString('data_$url');

    // Create headers map with the correct types
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'User-Agent': userAgent,
      'Cookie': await settings.getKey('token'),
    };
    if (cachedEtag != null) {
      headers['If-None-Match'] = cachedEtag;
    }

    // Send request with the ETag header if it exists and is not expired
    final response = await http.get(url, headers: headers);
    print(response.body);

    if (response.statusCode == 200) {
      // Store new ETag, data, and update timestamp
      await prefs.setString('etag_$url', response.headers['etag'] ?? '');
      await prefs.setInt('etag_time_$url', currentTime);
      await prefs.setString('data_$url', response.body); // Store response body
      print("New data received: $response.body");
      return response.body;
    } else if (response.statusCode == 304 && cachedData != null) {
      print("Using cached data: $cachedData");
      return cachedData;
    } else {
      return 'ded';
    }
  }


  Future<void> purgeOldEtags() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    const expiryTime = 30 * 24 * 60 * 60 * 1000; // 30 days

    for (var key in keys) {
      if (key.startsWith('etag_time_')) {
        final lastUpdated = prefs.getInt(key) ?? 0;
        if (currentTime - lastUpdated > expiryTime) {
          final etagKey = key.replaceFirst('etag_time_', 'etag_');
          final dataKey = key.replaceFirst('etag_time_', 'data_');
          await prefs.remove(key);       // Remove timestamp
          await prefs.remove(etagKey);   // Remove ETag
          await prefs.remove(dataKey);   // Remove cached data
        }
      }
    }
  }

  Future <List<CreatorResponse>> getSubscribedCreators() async {
    final subres = await FPApiRequests()._fetchDataWithEtag('v3/user/subscriptions?active=true');
    if (subres.isEmpty) {
      throw Exception('No subscribed creators found');
    }
    List<dynamic> createids = jsonDecode(subres);
    List<String> creatorIds = createids
      .map((subscription) => subscription['creator'] as String)
      .toList();
    String url = 'v2/creator/info?creatorGUID=${creatorIds.first}';
    for (int i = 1; i < creatorIds.length; i++) {
      url += '&creatorGUID=${creatorIds[i]}';
    }
    print(url);
    final creatorres = await  FPApiRequests()._fetchDataWithEtag(url);
    final creatorress = jsonDecode(creatorres);
    List<CreatorResponse> creatorResponses = creatorress.map((creatorJson) {
      if (creatorJson is Map<String, dynamic>) {
        return CreatorResponse.fromJson(creatorJson);
      } else {
        throw Exception('Invalid creator response format.');
      }
    }).toList();
    print(creatorResponses);
    return creatorResponses;
  }
}