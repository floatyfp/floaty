import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:floaty/settings.dart';
import 'package:floaty/backend/definitions.dart';
import 'dart:convert';

class FPApiRequests {
  late final Settings settings = Settings();
  static const String baseUrl = 'https://www.floatplane.com/api';
  static const String userAgent = 'FloatyClient/1.0.0, CFNetwork';

  Future<String> postDataWithEtag(String apiUrl, Map<String, dynamic>? body,
      [Map<String, dynamic>? queryParams]) async {
    final url = Uri.parse('$baseUrl/$apiUrl').replace(
      queryParameters: queryParams != null && queryParams.isNotEmpty
          ? {
              ...queryParams
                  .map((key, value) => MapEntry(key, value.toString()))
            }
          : null,
    );

    final prefs = await SharedPreferences.getInstance();
    final currentTime = DateTime.now().millisecondsSinceEpoch;

    // Create a unique key based on the request body
    final bodyKey = body != null ? jsonEncode(body) : '';
    final cachedEtag = prefs.getString('etag_$url:$bodyKey');
    final cachedData = prefs.getString('data_$url:$bodyKey');

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'User-Agent': userAgent,
      'Cookie': await settings.getKey('token'),
    };

    // Include the ETag in the headers if it exists
    if (cachedEtag != null) {
      headers['If-None-Match'] = cachedEtag;
    }

    // Make the POST request
    final response = await http.post(
      url,
      headers: headers,
      body: body != null ? jsonEncode(body) : null, // Encode the body as JSON
    );

    if (response.statusCode == 200) {
      await prefs.setString(
          'etag_$url:$bodyKey', response.headers['etag'] ?? '');
      await prefs.setInt('etag_time_$url:$bodyKey', currentTime);
      await prefs.setString('data_$url:$bodyKey', response.body);
      return response.body;
    } else if (response.statusCode == 304 && cachedData != null) {
      return cachedData; // Return cached data if not modified
    } else {
      // Handle other status codes accordingly
      return 'ded';
    }
  }

  Future fetchDataWithEtag(String apiUrl,
      [Map<String, dynamic>? queryParams]) async {
    final url = Uri.parse('$baseUrl/$apiUrl').replace(
      queryParameters: queryParams != null && queryParams.isNotEmpty
          ? {
              ...queryParams
                  .map((key, value) => MapEntry(key, value.toString()))
            }
          : null,
    );

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

  Future<List<CreatorModelV3>> getSubscribedCreators() async {
    try {
      final subres = await FPApiRequests()
          .fetchDataWithEtag('v3/user/subscriptions?active=true');
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
      List<CreatorModelV3> creators = [];
      for (String id in creatorIds) {
        try {
          final creatorInfo =
              await FPApiRequests().fetchDataWithEtag('v3/creator/info?id=$id');
          if (creatorInfo != null && creatorInfo.isNotEmpty) {
            Map<String, dynamic> creatorJson = jsonDecode(creatorInfo);
            creators.add(CreatorModelV3.fromJson(creatorJson));
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

  Future<UserSelfV3Response> getUser() async {
    try {
      final user = await FPApiRequests().fetchDataWithEtag('v3/user/self');
      return UserSelfV3Response.fromJson(jsonDecode(user));
    } catch (e) {
      rethrow;
    }
  }

  Future<List<String>> getSubscribedCreatorsIds() async {
    try {
      final subres = await FPApiRequests()
          .fetchDataWithEtag('v3/user/subscriptions?active=true');
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
            subscription['creator'] is String) {
          creatorIds.add(subscription['creator']);
        }
      }

      return creatorIds;
    } catch (e) {
      return [];
    }
  }

  Future<ContentCreatorListV3Response> getHomeFeed(
      List<String> creatorIds, int limit,
      [List<ContentCreatorListLastItems>? lastElements]) async {
    try {
      if (creatorIds.isEmpty) {
        return ContentCreatorListV3Response(blogPosts: [], lastElements: []);
      }

      final Map<String, dynamic> queryParams = {
        for (int i = 0; i < creatorIds.length; i++) 'ids[$i]': creatorIds[i],
        'limit': limit.toString(),
      };

      if (lastElements != null && lastElements.isNotEmpty) {
        for (int i = 0; i < lastElements.length; i++) {
          queryParams['fetchAfter[$i][creatorId]'] = lastElements[i].creatorId;
          queryParams['fetchAfter[$i][blogPostId]'] =
              lastElements[i].blogPostId;
          queryParams['fetchAfter[$i][moreFetchable]'] =
              lastElements[i].moreFetchable.toString();
        }
      }

      final response = await fetchDataWithEtag(
        'v3/content/creator/list',
        queryParams,
      );

      if (response == 'ded' || response.isEmpty) {
        return ContentCreatorListV3Response(blogPosts: [], lastElements: []);
      }

      Map<String, dynamic>? decodedResponse;
      try {
        final decoded = json.decode(response);
        if (decoded is Map<String, dynamic>) {
          decodedResponse = decoded;
        } else {
          throw const FormatException('Unexpected response format');
        }
      } catch (e) {
        return ContentCreatorListV3Response(blogPosts: [], lastElements: []);
      }

      return ContentCreatorListV3Response.fromJson(decodedResponse);
    } catch (error) {
      return ContentCreatorListV3Response(blogPosts: [], lastElements: []);
    }
  }

  Future<List<GetProgressResponse>> getVideoProgress(
      List<String> blogPostIds) async {
    final Map<String, dynamic> requestBody = {
      "ids": blogPostIds,
      "contentType": "blogPost"
    };

    try {
      final response = await postDataWithEtag(
        'v3/content/get/progress',
        requestBody,
      );

      if (response == 'ded' || response.isEmpty) {
        return [];
      }
      print(response);
      final List<dynamic> jsonResponse = jsonDecode(response);
      final List<GetProgressResponse> progressResponses = jsonResponse
          .map((data) =>
              GetProgressResponse.fromJson(data as Map<String, dynamic>))
          .toList();
      print(progressResponses);
      return progressResponses;
    } catch (e) {
      print('Error fetching video progress: $e');
      return [];
    }
  }
}
