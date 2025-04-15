import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:http_cache_hive_store/http_cache_hive_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:floaty/settings.dart';
import 'package:floaty/backend/definitions.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';

final FPApiRequests fpApiRequests = GetIt.I<FPApiRequests>();

class FPApiRequests {
  late final Settings settings = Settings();
  static const String baseUrl = 'https://www.floatplane.com/api';
  static const String userAgent = 'FloatyClient/1.0.0, CFNetwork';
  late final SharedPreferences prefs;

  late final PersistCookieJar cookieJar;
  late final Dio _dio;
  late final CacheOptions _cacheOptions;

  FPApiRequests() {
    _init();
  }

  Future<void> _init() async {
    prefs = await SharedPreferences.getInstance();
    final dir = await getApplicationSupportDirectory();
    cookieJar = PersistCookieJar(
      storage: FileStorage('${dir.path}/.cookies/'),
    );

    _cacheOptions = CacheOptions(
      store: HiveCacheStore('${dir.path}/.dio_cache'),
      policy: CachePolicy
          .request, // Only cache if server provides headers (like ETag)
      hitCacheOnNetworkFailure: true,
      priority: CachePriority.normal,
      maxStale: const Duration(days: 7),
    );

    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      responseType: ResponseType.plain,
      headers: {
        'User-Agent': userAgent,
      },
      validateStatus: (_) => true,
    ));

    _dio.interceptors.add(CookieManager(cookieJar));
    _dio.interceptors.add(DioCacheInterceptor(options: _cacheOptions));
  }

  Future<String> postData(
    String apiUrl,
    Map<String, dynamic>? body, [
    Map<String, dynamic>? queryParams,
  ]) async {
    try {
      final response = await _dio.post(
        '$baseUrl/$apiUrl',
        data: body,
        queryParameters: queryParams,
      );

      return response.data.toString();
    } on DioException catch (e) {
      return 'Error: ${e.response?.statusCode}, ${e.response?.data}';
    }
  }

  Future<dynamic> fetchData(
    String apiUrl, [
    Map<String, dynamic>? queryParams,
  ]) async {
    try {
      final response = await _dio.get(
        '$baseUrl/$apiUrl',
        queryParameters: queryParams,
      );

      return response.data;
    } on DioException catch (e) {
      return {'statusCode': e.response?.statusCode ?? 500, 'body': e.message};
    }
  }

  Future<void> purgeOldEtags() async {
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

  Stream<UserSelfV3Response> getUser() async* {
    try {
      final user = await fetchData('v3/user/self');
      if (user != null && user is String && user.isNotEmpty) {
        yield UserSelfV3Response.fromJson(jsonDecode(user));
      }
    } catch (e) {
      yield UserSelfV3Response();
    }
  }

  Future<List<dynamic>> getNamedUser(String username) async {
    final user = await fetchData('v3/user/named?username[0]=$username');
    if (user != null && user.isNotEmpty) {
      return jsonDecode(user);
    }
    return [];
  }

  Future<dynamic> getActivity(String userId) async {
    final activity = await fetchData('v3/user/activity?id=$userId');
    if (activity != null && activity.isNotEmpty) {
      return activity;
    }
    return [];
  }

  Stream<List<CreatorModelV3>> getSubscribedCreators() async* {
    try {
      final subres = await fetchData('v3/user/subscriptions?active=true');
      if (subres != null && subres is String && subres.isNotEmpty) {
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
            final creatorInfo = await fetchData('v3/creator/info?id=$id');
            if (creatorInfo != null &&
                creatorInfo is String &&
                creatorInfo.isNotEmpty) {
              Map<String, dynamic> creatorJson = jsonDecode(creatorInfo);
              creators.add(CreatorModelV3.fromJson(creatorJson));
            }
          } catch (e) {
            continue;
          }
        }
        yield creators;
      }
    } catch (e) {
      yield [];
    }
  }

  Stream<List<String>> getSubscribedCreatorsIds() async* {
    try {
      final subres = await fetchData('v3/user/subscriptions?active=true');
      if (subres != null && subres.isNotEmpty) {
        List<dynamic> subscriptions = jsonDecode(subres);
        List<String> creatorIds = subscriptions
            .where((subscription) =>
                subscription is Map<String, dynamic> &&
                subscription['creator'] is String)
            .map((subscription) => subscription['creator'] as String)
            .toList();
        yield creatorIds;
      }
    } catch (e) {
      yield [];
    }
  }

  Future<ContentCreatorListV3Response> getMultiCreatorVideoFeed(
      List<String> creatorIds, int limit,
      {List<ContentCreatorListLastItems>? lastElements}) async {
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

      final response = await fetchData('v3/content/creator/list', queryParams);
      if (response != null && response.isNotEmpty) {
        return ContentCreatorListV3Response.fromJson(jsonDecode(response));
      }
      return ContentCreatorListV3Response(blogPosts: [], lastElements: []);
    } catch (error) {
      return ContentCreatorListV3Response(blogPosts: [], lastElements: []);
    }
  }

  Future<List<BlogPostModelV3>> getChannelVideoFeed(
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
  }) async {
    try {
      bool? hasVideo = contentTypes?.contains('Video');
      bool? hasAudio = contentTypes?.contains('Audio');
      bool? hasPicture = contentTypes?.contains('Picture');
      bool? hasText = contentTypes?.contains('Text');

      final Map<String, dynamic> queryParams = {
        'id': creator,
        'limit': limit.toString(),
        'fetchAfter': fetchAfter.toString(),
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

      final response = await fetchData('v3/content/creator', queryParams);
      if (response != null && response.isNotEmpty) {
        List<dynamic> decodedResponse = jsonDecode(response);
        return decodedResponse
            .map((item) => BlogPostModelV3.fromJson(item))
            .toList();
      }
      return [];
    } catch (error) {
      return [];
    }
  }

  Future<List<GetProgressResponse>> getVideoProgress(
      List<String> blogPostIds) async {
    final Map<String, dynamic> requestBody = {
      "ids": blogPostIds,
      "contentType": "blogPost"
    };

    try {
      final response = await postData('v3/content/get/progress', requestBody);
      // ignore: unnecessary_null_comparison
      if (response != null && response.isNotEmpty) {
        final List<dynamic> jsonResponse = jsonDecode(response);
        return jsonResponse
            .map((data) => GetProgressResponse.fromJson(data))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Stream<List<CreatorModelV3>> getCreators({String? query}) async* {
    try {
      final apiUrl =
          query != null ? 'v3/creator/list?search=$query' : 'v3/creator/list';

      final subres = await fetchData(apiUrl);
      if (subres != null && subres.isNotEmpty) {
        List<dynamic> jsonList = jsonDecode(subres);
        yield jsonList.map((json) => CreatorModelV3.fromJson(json)).toList();
      }
    } catch (e) {
      yield [];
    }
  }

  Future<List<HistoryModelV3>> getHistory({int? offset}) async {
    try {
      int offsetInt = offset ?? 0;
      final response = await fetchData('v3/content/history?offset=$offsetInt');
      if (response != null && response.isNotEmpty) {
        List<dynamic> jsonList = jsonDecode(response);
        return jsonList.map((json) => HistoryModelV3.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Stream<CreatorModelV3> getCreator({String? urlname, int? id}) async* {
    try {
      final apiUrl = urlname != null
          ? 'v3/creator/named?creatorURL=$urlname'
          : 'v3/creator/info?id=$id';

      final creatorInfo = await fetchData(apiUrl);

      if (creatorInfo != null && creatorInfo.isNotEmpty) {
        List<dynamic> creatorList = jsonDecode(creatorInfo);
        if (creatorList.isNotEmpty) {
          Map<String, dynamic> creatorJson = creatorList.first;
          final freshCreator = CreatorModelV3.fromJson(creatorJson);
          yield freshCreator;
        }
      }
    } catch (e) {
      yield CreatorModelV3();
    }
  }

  Future<StatsModel> getStats(String creatorId) async {
    try {
      final stats = await fetchData('v2/plan/info?creatorId=$creatorId');
      if (stats != null && stats.isNotEmpty) {
        dynamic statsJson = jsonDecode(stats);
        return StatsModel(
          totalIncome: statsJson['totalIncome'],
          totalSubcriberCount: statsJson['totalSubscriberCount'],
        );
      }
      return StatsModel(totalIncome: 0, totalSubcriberCount: 0);
    } catch (e) {
      return StatsModel(totalIncome: 0, totalSubcriberCount: 0);
    }
  }

  Future<Map<String, dynamic>> getStatsV3(String creatorId) async {
    try {
      final stats = await fetchData('v3/creator/stats?id=$creatorId');
      if (stats != null && stats.isNotEmpty) {
        dynamic statsJson = jsonDecode(stats);
        return statsJson;
      }
      return {"error": true};
    } catch (e) {
      return {"error": true};
    }
  }

  Stream<ContentPostV3Response> getBlogPost(String blogPostId) async* {
    try {
      final apiUrl = 'v3/content/post?id=$blogPostId';
      final response = await fetchData(apiUrl);
      if (response != null && response.isNotEmpty) {
        try {
          final jsonData = jsonDecode(response);
          final parsed = ContentPostV3Response.fromJson(jsonData);
          yield parsed;
        } catch (e) {
          yield ContentPostV3Response();
        }
      } else {
        yield ContentPostV3Response();
      }
    } catch (e) {
      yield ContentPostV3Response();
    }
  }

  Future<String> likeBlogPost(String blogPostId) async {
    final response = await postData(
        'v3/content/like', {'contentType': 'blogPost', 'id': blogPostId});
    final decodedres = jsonDecode(response);
    if (decodedres.contains('like')) {
      return 'success';
    } else if (response.toString() == '[]') {
      return 'removed';
    } else {
      return 'fail';
    }
  }

  Future<String> dislikeBlogPost(String blogPostId) async {
    final response = await postData(
        'v3/content/dislike', {'contentType': 'blogPost', 'id': blogPostId});
    final decodedres = jsonDecode(response);
    if (decodedres.contains('dislike')) {
      return 'success';
    } else if (response.toString() == '[]') {
      return 'removed';
    } else {
      return 'fail';
    }
  }

  Future<String> likeComment(String commentId, String blogPostId) async {
    final response = await postData(
        'v3/comment/like', {'comment': commentId, 'blogPost': blogPostId});
    final decodedres = jsonDecode(response);
    if (decodedres.contains('like')) {
      return 'success';
    } else if (response.toString() == '[]') {
      return 'removed';
    } else {
      return 'fail';
    }
  }

  Future<String> dislikeComment(String commentId, String blogPostId) async {
    final response = await postData(
        'v3/comment/dislike', {'comment': commentId, 'blogPost': blogPostId});
    final decodedres = jsonDecode(response);
    if (decodedres.contains('dislike')) {
      return 'success';
    } else if (response.toString() == '[]') {
      return 'removed';
    } else {
      return 'fail';
    }
  }

  Future<List<BlogPostModelV3>> getRecommended(String blogPostId) async {
    try {
      final response = await fetchData('v3/content/related?id=$blogPostId');
      if (response != null && response.isNotEmpty) {
        List<dynamic> decodedResponse = json.decode(response) as List<dynamic>;
        return decodedResponse
            .map((item) => BlogPostModelV3.fromJson(item))
            .toList();
      }
      return [];
    } catch (error) {
      return [];
    }
  }

  Future<List<CommentModel>> getComments(
      String blogPostId, int limit, String sortBy, String sortOrder,
      {String? fetchAfter}) async {
    try {
      dynamic response;
      if (fetchAfter != null) {
        response = await fetchData(
            'v3/comment?blogPost=$blogPostId&limit=$limit&fetchAfter=$fetchAfter&sortBy=$sortBy&sortDirection=$sortOrder');
      } else {
        response = await fetchData(
            'v3/comment?blogPost=$blogPostId&limit=$limit&sortBy=$sortBy&sortDirection=$sortOrder');
      }

      if (response != null && response.isNotEmpty) {
        final List<dynamic> decodedData =
            json.decode(response) as List<dynamic>;
        return decodedData
            .map((item) => CommentModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (error) {
      return [];
    }
  }

  Future<List<CommentModel>> getReplies(
      String comment, String blogPost, int limit, String rid) async {
    try {
      final response = await fetchData(
          'v3/comment/replies?comment=$comment&blogPost=$blogPost&limit=$limit&rid=$rid');

      if (response != null && response.isNotEmpty) {
        final List<dynamic> decodedData =
            json.decode(response) as List<dynamic>;
        return decodedData
            .map((item) => CommentModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (error) {
      return [];
    }
  }

  Future<CommentModel?> comment(String blogPostId, String comment,
      {String? replyto}) async {
    try {
      final response = await postData('v3/comment', {
        'blogPost': blogPostId,
        if (replyto != null) 'replyTo': replyto,
        'text': comment
      });
      if (response.isNotEmpty) {
        final decodedData = json.decode(response) as Map<String, dynamic>;
        return CommentModel.fromJson(decodedData);
      }
      return null;
    } catch (error) {
      return null;
    }
  }

  Future<String> deleteComment(String commentId) async {
    final response = await postData('v3/comment/delete?comment=$commentId', {});
    return response;
  }

  Future<String> editComment(String commentId, String text) async {
    final response =
        await postData('v3/comment/edit?comment=$commentId&text=$text', {});
    return response;
  }

  Future<String> getDelivery(String scenario, String entityId) async {
    try {
      final res = await fetchData(
          'v3/delivery/info?scenario=$scenario&entityId=$entityId&outputKind=hls.mpegts');
      return res;
    } catch (e) {
      return '';
    }
  }

  Future<String> getDeliveryv2(String type, String guid) async {
    try {
      final res = await fetchData('v2/cdn/delivery?type=$type&guid=$guid');
      return res;
    } catch (e) {
      return '';
    }
  }

  Future<String> getContent(String type, String id) async {
    try {
      final res = await fetchData('v3/content/$type?id=$id');
      return res;
    } catch (e) {
      return '';
    }
  }

  Future<void> submitVote(String id, int vote) async {
    await postData('v3/poll/votePoll', {
      'pollId': id,
      'optionIndex': vote,
    });
  }

  //because of the dumb way i handle progress (i have 3 different things that can call progress) we debounce this to avoid spam and stale data.
  Timer? _progressDebounceTimer;
  final Map<String, Map<String, dynamic>> _pendingProgress = {};

  Future<void> progress(String id, int progress, String contentType) async {
    if (id.isEmpty) return;
    _pendingProgress[id] = {
      'progress': progress,
      'contentType': contentType,
    };
    _progressDebounceTimer?.cancel();
    _progressDebounceTimer = Timer(const Duration(seconds: 5), () async {
      for (final entry in _pendingProgress.entries) {
        final String entryId = entry.key;
        final Map<String, dynamic> params = entry.value;

        await postData('v3/content/progress', {
          'id': entryId,
          'contentType': params['contentType'],
          'progress': params['progress'],
        });
      }
      _pendingProgress.clear();
    });
  }

  Future<void> iprogress(String id, int progress, String contentType) async {
    if (id.isEmpty) return;
    await postData('v3/content/progress', {
      'id': id,
      'contentType': contentType,
      'progress': progress,
    });
  }
}
