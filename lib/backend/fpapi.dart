import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:floaty/settings.dart';
import 'package:floaty/backend/definitions.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:async';

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

    final bodyKey = body != null ? jsonEncode(body) : '';
    final cachedEtag = prefs.getString('etag_$url:$bodyKey');
    final cachedData = prefs.getString('data_$url:$bodyKey');

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'User-Agent': userAgent,
      'Cookie': await settings.getKey('token'),
    };

    if (cachedEtag != null) {
      headers['If-None-Match'] = cachedEtag;
    }

    final response = await http.post(
      url,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );

    if (response.statusCode == 200) {
      await prefs.setString(
          'etag_$url:$bodyKey', response.headers['etag'] ?? '');
      await prefs.setInt('etag_time_$url:$bodyKey', currentTime);
      await prefs.setString('data_$url:$bodyKey', response.body);
      return response.body;
    } else if (response.statusCode == 304 && cachedData != null) {
      return cachedData;
    } else {
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

  Stream<UserSelfV3Response> getUserStream() async* {
    try {
      // Fetch cached data first
      final cachedData = await getCachedResponse('v3/user/self');
      if (cachedData != null && cachedData.isNotEmpty) {
        yield UserSelfV3Response.fromJson(
            jsonDecode(cachedData)); // Emit cached data
      }

      // Proceed with the API call
      final user = await fetchDataWithEtag('v3/user/self');
      if (user != null && user.isNotEmpty) {
        yield UserSelfV3Response.fromJson(jsonDecode(user)); // Emit fresh data
      }
    } catch (e) {
      // Handle errors gracefully
    }
  }

  Stream<List<CreatorModelV3>> getSubscribedCreatorsStream() async* {
    try {
      // Fetch cached data first
      final cachedData =
          await getCachedResponse('v3/user/subscriptions?active=true');
      if (cachedData != null && cachedData.isNotEmpty) {
        List<dynamic> subscriptions = jsonDecode(cachedData);
        List<String> creatorIds = subscriptions
            .where((subscription) =>
                subscription is Map<String, dynamic> &&
                subscription['creator'] is String)
            .map((subscription) => subscription['creator'] as String)
            .toList();
        List<CreatorModelV3> creators = [];
        for (String id in creatorIds) {
          try {
            final creatorInfo = await FPApiRequests()
                .fetchDataWithEtag('v3/creator/info?id=$id');
            if (creatorInfo != null && creatorInfo.isNotEmpty) {
              Map<String, dynamic> creatorJson = jsonDecode(creatorInfo);
              creators.add(CreatorModelV3.fromJson(creatorJson));
            }
          } catch (e) {
            continue;
          }
        }
        yield creators; // Emit cached data
      }

      // Proceed with the API call
      final subres =
          await fetchDataWithEtag('v3/user/subscriptions?active=true');
      if (subres != null && subres.isNotEmpty) {
        List<dynamic> subscriptions = jsonDecode(subres);
        List<String> creatorIds = subscriptions
            .where((subscription) =>
                subscription is Map<String, dynamic> &&
                subscription['creator'] is String)
            .map((subscription) => subscription['creator'] as String)
            .toList();
        List<CreatorModelV3> creators = [];
        for (String id in creatorIds) {
          try {
            final creatorInfo = await FPApiRequests()
                .fetchDataWithEtag('v3/creator/info?id=$id');
            if (creatorInfo != null && creatorInfo.isNotEmpty) {
              Map<String, dynamic> creatorJson = jsonDecode(creatorInfo);
              creators.add(CreatorModelV3.fromJson(creatorJson));
            }
          } catch (e) {
            continue;
          }
        }
        yield creators; // Emit fresh data
      }
    } catch (e) {
      yield []; // Emit empty list on error
    }
  }

  Stream<List<String>> getSubscribedCreatorsIdsStream() async* {
    try {
      // Fetch cached data first
      final cachedData =
          await getCachedResponse('v3/user/subscriptions?active=true');
      if (cachedData != null && cachedData.isNotEmpty) {
        List<dynamic> subscriptions = jsonDecode(cachedData);
        List<String> creatorIds = subscriptions
            .where((subscription) =>
                subscription is Map<String, dynamic> &&
                subscription['creator'] is String)
            .map((subscription) => subscription['creator'] as String)
            .toList();
        yield creatorIds; // Emit cached data
      }

      // Proceed with the API call
      final subres =
          await fetchDataWithEtag('v3/user/subscriptions?active=true');
      if (subres != null && subres.isNotEmpty) {
        List<dynamic> subscriptions = jsonDecode(subres);
        List<String> creatorIds = subscriptions
            .where((subscription) =>
                subscription is Map<String, dynamic> &&
                subscription['creator'] is String)
            .map((subscription) => subscription['creator'] as String)
            .toList();
        yield creatorIds; // Emit fresh data
      }
    } catch (e) {
      // Handle errors gracefully
    }
  }

  Stream<ContentCreatorListV3Response> getMultiCreatorVideoFeedStream(
      List<String> creatorIds, int limit,
      {List<ContentCreatorListLastItems>? lastElements}) async* {
    try {
      if (creatorIds.isEmpty) {
        yield ContentCreatorListV3Response(
            blogPosts: [],
            lastElements: []); // Emit empty response for empty input
        return;
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

      // Fetch cached data first
      final cachedData =
          await getCachedResponse('v3/content/creator/list', queryParams);
      if (cachedData != null && cachedData.isNotEmpty) {
        yield ContentCreatorListV3Response.fromJson(
            jsonDecode(cachedData)); // Emit cached data
      }

      // Proceed with the API call
      final response =
          await fetchDataWithEtag('v3/content/creator/list', queryParams);
      if (response != null && response.isNotEmpty) {
        yield ContentCreatorListV3Response.fromJson(
            jsonDecode(response)); // Emit fresh data
      }
    } catch (error) {
      yield ContentCreatorListV3Response(
          blogPosts: [], lastElements: []); // Emit empty response on error
    }
  }

  Stream<List<BlogPostModelV3>> getChannelVideoFeedStream(
    String creator,
    int limit,
    int fetchAfter, {
    String? channel,
    String? searchQuery,
    Set<String>? contentTypes,
    RangeValues? durationRange,
    DateTime? fromDate,
    DateTime? toDate,
    bool? isAscending,
  }) async* {
    try {
      bool? hasVideo = contentTypes?.contains('Video');
      bool? hasAudio = contentTypes?.contains('Audio');
      bool? hasPicture = contentTypes?.contains('Picture');
      bool? hasText = contentTypes?.contains('Text');

      final Map<String, dynamic> queryParams = {
        'id': creator,
        'limit': limit.toString(),
        'fetchAfter': fetchAfter,
        if (channel != null) 'channel': channel,
        if (fromDate != null) 'fromDate': fromDate.toUtc().toIso8601String(),
        if (toDate != null) 'toDate': toDate.toUtc().toIso8601String(),
        if (contentTypes != null) ...{
          'hasVideo': hasVideo.toString(),
          'hasAudio': hasAudio.toString(),
          'hasPicture': hasPicture.toString(),
          'hasText': hasText.toString(),
        },
        if (durationRange != null) ...{
          if ((durationRange.start * 60).round().toString() != '0')
            'fromDuration': (durationRange.start * 60).round().toString(),
          if ((durationRange.end * 60).round().toString() != '10800')
            'toDuration': (durationRange.end * 60).round().toString(),
        },
        if (isAscending != null) 'sort': isAscending ? 'ASC' : 'DESC',
        if (searchQuery != null && searchQuery.isNotEmpty)
          'search': searchQuery,
      };

      // Fetch cached data first
      final cachedData =
          await getCachedResponse('v3/content/creator', queryParams);
      if (cachedData != null && cachedData.isNotEmpty) {
        List<dynamic> decodedResponse =
            json.decode(cachedData) as List<dynamic>;
        yield decodedResponse
            .map((item) => BlogPostModelV3.fromJson(item))
            .toList(); // Emit cached data
      }

      // Proceed with the API call
      final response =
          await fetchDataWithEtag('v3/content/creator', queryParams);
      if (response != null && response.isNotEmpty) {
        List<dynamic> decodedResponse = json.decode(response) as List<dynamic>;
        yield decodedResponse
            .map((item) => BlogPostModelV3.fromJson(item))
            .toList(); // Emit fresh data
      }
    } catch (error) {
      yield []; // Emit empty list on error
    }
  }

  Stream<List<GetProgressResponse>> getVideoProgressStream(
      List<String> blogPostIds) async* {
    final Map<String, dynamic> requestBody = {
      "ids": blogPostIds,
      "contentType": "blogPost"
    };

    try {
      // Fetch cached data first
      final cachedData =
          await getCachedResponse('v3/content/get/progress', requestBody);
      if (cachedData != null && cachedData.isNotEmpty) {
        final List<dynamic> jsonResponse = jsonDecode(cachedData);
        yield jsonResponse
            .map((data) => GetProgressResponse.fromJson(data))
            .toList(); // Emit cached data
      }

      // Proceed with the API call
      final response =
          await postDataWithEtag('v3/content/get/progress', requestBody);
      // ignore: unnecessary_null_comparison
      if (response != null && response.isNotEmpty) {
        final List<dynamic> jsonResponse = jsonDecode(response);
        yield jsonResponse
            .map((data) => GetProgressResponse.fromJson(data))
            .toList(); // Emit fresh data
      }
    } catch (e) {
      yield []; // Emit empty list on error
    }
  }

  Stream<List<CreatorModelV3>> getCreatorsStream({String? query}) async* {
    try {
      // Fetch cached data first
      final apiUrl =
          query != null ? 'v3/creator/list?search=$query' : 'v3/creator/list';
      final cachedData = await getCachedResponse(apiUrl);
      if (cachedData != null && cachedData.isNotEmpty) {
        List<dynamic> jsonList = jsonDecode(cachedData);
        yield jsonList
            .map((json) => CreatorModelV3.fromJson(json))
            .toList(); // Emit cached data
      }

      // Proceed with the API call
      final subres = await fetchDataWithEtag(apiUrl);
      if (subres != null && subres.isNotEmpty) {
        List<dynamic> jsonList = jsonDecode(subres);
        yield jsonList
            .map((json) => CreatorModelV3.fromJson(json))
            .toList(); // Emit fresh data
      }
    } catch (e) {
      yield []; // Emit empty list on error
    }
  }

  Stream<List<HistoryModelV3>> getHistoryStream({int? offset}) async* {
    try {
      int offsetInt = offset ?? 0;
      // Fetch cached data first
      final cachedData =
          await getCachedResponse('v3/content/history?offset=$offsetInt');
      if (cachedData != null && cachedData.isNotEmpty) {
        List<dynamic> jsonList = jsonDecode(cachedData);
        yield jsonList
            .map((json) => HistoryModelV3.fromJson(json))
            .toList(); // Emit cached data
      }

      // Proceed with the API call
      final response =
          await fetchDataWithEtag('v3/content/history?offset=$offsetInt');
      if (response != null && response.isNotEmpty) {
        List<dynamic> jsonList = jsonDecode(response);
        yield jsonList
            .map((json) => HistoryModelV3.fromJson(json))
            .toList(); // Emit fresh data
      }
    } catch (e) {
      yield []; // Emit empty list on error
    }
  }

  Stream<CreatorModelV3> getCreator({String? urlname, int? id}) async* {
    try {
      final apiUrl = urlname != null
          ? 'v3/creator/named?creatorURL=$urlname'
          : 'v3/creator/info?id=$id';

      // Fetch cached data first
      final cachedData = await getCachedResponse(apiUrl);
      CreatorModelV3? cachedCreator;
      if (cachedData != null && cachedData.isNotEmpty) {
        List<dynamic> creatorList = jsonDecode(cachedData);
        if (creatorList.isNotEmpty) {
          Map<String, dynamic> creatorJson = creatorList.first;
          cachedCreator = CreatorModelV3.fromJson(creatorJson);
          yield cachedCreator; // Emit cached data
        }
      }

      // Proceed with the API call
      final creatorInfo = await fetchDataWithEtag(apiUrl);

      // Compare and emit fresh data if different
      if (creatorInfo != null && creatorInfo.isNotEmpty) {
        List<dynamic> creatorList = jsonDecode(creatorInfo);
        if (creatorList.isNotEmpty) {
          Map<String, dynamic> creatorJson = creatorList.first;
          final freshCreator = CreatorModelV3.fromJson(creatorJson);
          if (freshCreator != cachedCreator) {
            yield freshCreator; // Emit fresh data
          }
        }
      }
    } catch (e) {
      yield CreatorModelV3(); // Emit default on error
    }
  }

  Stream<StatsModel> getStatsStream(String creatorId) async* {
    try {
      // Fetch cached data first
      final cachedData =
          await getCachedResponse('v2/plan/info?creatorId=$creatorId');
      if (cachedData != null && cachedData.isNotEmpty) {
        dynamic statsJson = jsonDecode(cachedData);
        yield StatsModel(
          totalIncome: statsJson['totalIncome'],
          totalSubcriberCount: statsJson['totalSubscriberCount'],
        ); // Emit cached data
      }

      // Proceed with the API call
      final stats =
          await fetchDataWithEtag('v2/plan/info?creatorId=$creatorId');
      if (stats != null && stats.isNotEmpty) {
        dynamic statsJson = jsonDecode(stats);
        yield StatsModel(
          totalIncome: statsJson['totalIncome'],
          totalSubcriberCount: statsJson['totalSubscriberCount'],
        ); // Emit fresh data
      }
    } catch (e) {
      // Handle errors gracefully
    }
  }

  Future<String?> getCachedResponse(String apiUrl,
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
    final cachedData = prefs.getString('data_$url');

    return cachedData;
  }
}
