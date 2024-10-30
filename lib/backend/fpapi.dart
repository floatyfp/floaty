import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:floaty/settings.dart';
import 'package:floaty/backend/definitions.dart';
import 'dart:convert';

class FPApiRequests {
  late final Settings settings = Settings();
  static const String baseUrl = 'https://www.floatplane.com/api';
  static const String userAgent = 'FloatyClient/1.0.0, CFNetwork';

  Future _fetchDataWithEtag(String apiUrl) async {
    final url = Uri.parse('$baseUrl/$apiUrl');
    final prefs = await SharedPreferences.getInstance();
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final cachedEtag = prefs.getString('etag_$url');
    final cachedData = prefs.getString('data_$url');

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'User-Agent': userAgent,
      'Cookie': await settings.getKey('token'),
    };
    if (cachedEtag != null) {
      headers['If-None-Match'] = cachedEtag;
    }

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      await prefs.setString('etag_$url', response.headers['etag'] ?? '');
      await prefs.setInt('etag_time_$url', currentTime);
      await prefs.setString('data_$url', response.body);
      return response.body;
    } else if (response.statusCode == 304 && cachedData != null) {
      return cachedData;
    } else {
      return 'ded';
    }
  }

  Future<void> purgeOldEtags() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    const expiryTime = 30 * 24 * 60 * 60 * 1000;

    for (var key in keys) {
      if (key.startsWith('etag_time_')) {
        final lastUpdated = prefs.getInt(key) ?? 0;
        if (currentTime - lastUpdated > expiryTime) {
          final etagKey = key.replaceFirst('etag_time_', 'etag_');
          final dataKey = key.replaceFirst('etag_time_', 'data_');
          await prefs.remove(key);
          await prefs.remove(etagKey);
          await prefs.remove(dataKey);
        }
      }
    }
  }

  Future<List<CreatorResponse>> getSubscribedCreators() async {
    try {
      final subres = await FPApiRequests()
          ._fetchDataWithEtag('v3/user/subscriptions?active=true');
      if (subres == null || subres.isEmpty) {
        return [];
      }
      List<dynamic> subscriptions;
      try {
        subscriptions = jsonDecode(subres) as List<dynamic>;
      } catch (e) {
        return [];
      }
      List<String> creatorIds = [];
      for (var subscription in subscriptions) {
        if (subscription is Map<String, dynamic> &&
            subscription.containsKey('creator') &&
            subscription['creator'] != null) {
          creatorIds.add(subscription['creator'].toString());
        }
      }
      if (creatorIds.isEmpty) {
        return [];
      }
      List<CreatorResponse> creators = [];
      for (String id in creatorIds) {
        try {
          final creatorInfo = await FPApiRequests()
              ._fetchDataWithEtag('v3/creator/info?id=$id');
          if (creatorInfo != null && creatorInfo.isNotEmpty) {
            Map<String, dynamic> creatorJson = jsonDecode(creatorInfo);
            creators.add(CreatorResponse.fromJson(creatorJson));
          }
        } catch (e) {
          continue;
        }
      }
      return creators;
    } catch (e) {
      rethrow;
    }
  }

  Future<User> getUser() async {
    try {
      final user = await FPApiRequests()._fetchDataWithEtag('v3/user/self');
      return User.fromJson(jsonDecode(user));
    } catch (e) {
      rethrow;
    }
  }
}
