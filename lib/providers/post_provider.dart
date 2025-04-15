// ignore_for_file: unnecessary_cast, unnecessary_type_check

import 'package:floaty/backend/fpapi.dart';
import 'package:floaty/backend/definitions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:floaty/services/media/video_quality.dart';
import 'dart:convert';
import 'package:floaty/backend/whenplaneintergration.dart';
import 'package:intl/intl.dart';
import 'package:floaty/frontend/root.dart';
import 'package:flutter/material.dart';
import 'dart:async';

// Post State
class PostState {
  final ContentPostV3Response? post;
  final bool isLoading;
  final String? error;
  final bool isLiked;
  final bool isDisliked;
  final int likeCount;
  final int dislikeCount;
  final bool isExpanded;
  final String? selectedAttachmentId;
  final List<BlogPostModelV3> recommendedPosts;
  final Map<String, GetProgressResponse> progressMap;

  // Add new fields for show timing
  final DateTime? showDate;
  final String? preShowRange;
  final String? preShowDuration;
  final String? mainShowDuration;
  final String? mainShowRange;
  final String? letsBeHonestItsLateTime;
  final bool hundredpercentlate;
  final bool isWan;
  final String latenessString;

  PostState({
    this.post,
    this.isLoading = true,
    this.error,
    this.isLiked = false,
    this.isDisliked = false,
    this.likeCount = 0,
    this.dislikeCount = 0,
    this.isExpanded = false,
    this.selectedAttachmentId,
    this.recommendedPosts = const [],
    this.progressMap = const {},
    // Initialize new fields
    this.showDate,
    this.preShowRange,
    this.preShowDuration,
    this.mainShowDuration,
    this.mainShowRange,
    this.letsBeHonestItsLateTime,
    this.hundredpercentlate = false,
    this.isWan = false,
    this.latenessString = '',
  });

  PostState copyWith({
    ContentPostV3Response? post,
    bool? isLoading,
    String? error,
    bool? isLiked,
    bool? isDisliked,
    int? likeCount,
    int? dislikeCount,
    bool? isExpanded,
    String? selectedAttachmentId,
    List<BlogPostModelV3>? recommendedPosts,
    Map<String, GetProgressResponse>? progressMap,
    // Add new fields to copyWith
    DateTime? showDate,
    String? preShowRange,
    String? preShowDuration,
    String? mainShowDuration,
    String? mainShowRange,
    String? letsBeHonestItsLateTime,
    bool? hundredpercentlate,
    bool? isWan,
    String? latenessString,
  }) {
    return PostState(
      post: post ?? this.post,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isLiked: isLiked ?? this.isLiked,
      isDisliked: isDisliked ?? this.isDisliked,
      likeCount: likeCount ?? this.likeCount,
      dislikeCount: dislikeCount ?? this.dislikeCount,
      isExpanded: isExpanded ?? this.isExpanded,
      selectedAttachmentId: selectedAttachmentId ?? this.selectedAttachmentId,
      recommendedPosts: recommendedPosts ?? this.recommendedPosts,
      progressMap: progressMap ?? this.progressMap,
      showDate: showDate ?? this.showDate,
      preShowRange: preShowRange ?? this.preShowRange,
      preShowDuration: preShowDuration ?? this.preShowDuration,
      mainShowDuration: mainShowDuration ?? this.mainShowDuration,
      mainShowRange: mainShowRange ?? this.mainShowRange,
      letsBeHonestItsLateTime:
          letsBeHonestItsLateTime ?? this.letsBeHonestItsLateTime,
      hundredpercentlate: hundredpercentlate ?? this.hundredpercentlate,
      isWan: isWan ?? this.isWan,
      latenessString: latenessString ?? this.latenessString,
    );
  }
}

// Post Provider
class PostNotifier extends StateNotifier<PostState> {
  PostNotifier() : super(PostState());

  Future<ContentPostV3Response> getPost(String postId) async {
    state = state.copyWith(isLoading: true);

    try {
      ContentPostV3Response? loadedPost;
      final postStream = fpApiRequests.getBlogPost(postId);
      await for (final post in postStream) {
        loadedPost = post;
        state = state.copyWith(
          post: post,
          isLoading: false,
          isLiked: post.userInteraction.contains("like"),
          isDisliked: post.userInteraction.contains("dislike"),
          likeCount: post.likes ?? 0,
          dislikeCount: post.dislikes ?? 0,
          selectedAttachmentId: post.attachmentOrder.isNotEmpty
              ? post.attachmentOrder.first
              : null,
        );
        rootLayoutKey.currentState?.setAppBar(Text(post.title ?? ''));
        await _loadRecommendedPosts(postId);
        break;
      }

      if (loadedPost == null) {
        throw Exception('Failed to load post');
      }

      //whenplane intergration
      //100% not converted from the browser extension
      String addZero(int n) => n > 9 ? "$n" : "0$n";

      String formatDuration(Duration duration) {
        return [
          if (duration.inHours > 0) "${duration.inHours}h",
          if (duration.inMinutes.remainder(60) > 0)
            "${duration.inMinutes.remainder(60)}m",
          if (duration.inSeconds.remainder(60) > 0)
            "${duration.inSeconds.remainder(60)}s"
        ].join(" ");
      }

      String formatTime(DateTime date) {
        return "${addZero(date.hour)}:${addZero(date.minute)}";
      }

      String? extractShowDate(String title) {
        final titleRegex = RegExp(
            r" - WAN Show ((January|February|March|April|May|June|July|August|September|October|November|December) \d{1,2}, \d{4})");
        final match = titleRegex.firstMatch(title);

        if (match != null) {
          String dateString = match.group(1)!;
          DateTime parsedDate = DateFormat("MMMM d, yyyy").parse(dateString);
          return DateFormat("yyyy/MM/dd").format(parsedDate);
        }

        return null;
      }

      String convertTimeFormat(String date1, String date2, bool length) {
        DateTime start = DateTime.parse(date1).toUtc();
        DateTime end = DateTime.parse(date2).toUtc();

        if (length) {
          return formatDuration(end.difference(start));
        } else {
          return "${formatTime(start)} - ${formatTime(end)}";
        }
      }

      String compareWithFixedTime(String dateStr) {
        DateTime date = DateTime.parse(dateStr).toUtc();
        DateTime fixedTime =
            DateTime.utc(date.year, date.month, date.day, 23, 30, 0);

        // Handle case where show is on next day (after midnight)
        if (date.hour < 12 && fixedTime.hour > 12) {
          // Assume this is after midnight, so date is actually on the next day
          fixedTime = fixedTime.subtract(Duration(days: 1));
        }

        Duration diff = date.difference(fixedTime);

        if (diff.inSeconds.abs() <= 300) {
          return "on time";
        }

        return formatDuration(diff.abs());
      }

      bool compareWithFixedTimeBool(String dateStr) {
        DateTime date = DateTime.parse(dateStr).toUtc();

        // Create fixed time (11:30 PM UTC) for the same date
        DateTime fixedTime =
            DateTime.utc(date.year, date.month, date.day, 23, 30, 0);

        // Handle case where show is on next day (after midnight)
        if (date.hour < 12 && fixedTime.hour > 12) {
          // Assume this is after midnight, so date is actually on the next day
          fixedTime = fixedTime.subtract(Duration(days: 1));
        }

        Duration diff = date.difference(fixedTime);

        if (diff.inSeconds.abs() <= 300) {
          return true; // On time
        }

        // If you want the function to return true for "late" shows:
        return !diff.isNegative; // True if late, false if early

        // Or if you want the function to return true for "early" shows:
        // return diff.isNegative; // True if early, false if late
      }

      if (loadedPost.title != null) {
        final showDate = extractShowDate(loadedPost.title!);
        final latenessString = whenPlaneIntegration.newPhrase();

        if (showDate != null) {
          final res = await whenPlaneIntegration.getPreviousShowInfo(showDate);
          final jsonRes = jsonDecode(res);
          final preShowStart = jsonRes['metadata']['preShowStart'];
          final mainShowStart = jsonRes['metadata']['mainShowStart'];
          final showEnd = jsonRes['metadata']['showEnd'];

          state = state.copyWith(
            preShowRange: convertTimeFormat(preShowStart, mainShowStart, false),
            preShowDuration:
                convertTimeFormat(preShowStart, mainShowStart, true),
            mainShowDuration: convertTimeFormat(mainShowStart, showEnd, true),
            mainShowRange: convertTimeFormat(mainShowStart, showEnd, false),
            letsBeHonestItsLateTime: compareWithFixedTime(mainShowStart),
            hundredpercentlate: compareWithFixedTimeBool(mainShowStart),
            isWan: true,
            latenessString: latenessString,
          );
        }
      }

      return loadedPost;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> _loadRecommendedPosts(String postId) async {
    try {
      final recommended = await fpApiRequests.getRecommended(postId);
      final List<String> postIds = (recommended as List<BlogPostModelV3>)
          .where((post) => post.id != null)
          .map((post) => post.id!)
          .toList();

      final progress = await fpApiRequests.getVideoProgress(postIds);
      final progressMap = <String, GetProgressResponse>{};

      if (progress is List) {
        for (var item in progress) {
          if (item is GetProgressResponse && item.id != null) {
            progressMap[item.id!] = item;
          }
        }
      }

      state = state.copyWith(
        recommendedPosts: recommended,
        progressMap: progressMap,
      );
    } catch (e) {
      // Handle error if needed
    }
  }

  Future<void> toggleLike() async {
    if (state.post?.id == null) return;

    final res = await fpApiRequests.likeBlogPost(state.post!.id!);
    if (res == 'success') {
      state = state.copyWith(
        isLiked: !state.isLiked,
        likeCount: state.isLiked ? state.likeCount - 1 : state.likeCount + 1,
        isDisliked: state.isDisliked ? false : state.isDisliked,
        dislikeCount:
            state.isDisliked ? state.dislikeCount - 1 : state.dislikeCount,
      );
    }
  }

  Future<void> toggleDislike() async {
    if (state.post?.id == null) return;

    final res = await fpApiRequests.dislikeBlogPost(state.post!.id!);
    if (res == 'success') {
      state = state.copyWith(
        isDisliked: !state.isDisliked,
        dislikeCount:
            state.isDisliked ? state.dislikeCount - 1 : state.dislikeCount + 1,
        isLiked: state.isLiked ? false : state.isLiked,
        likeCount: state.isLiked ? state.likeCount - 1 : state.likeCount,
      );
    }
  }

  void toggleExpanded() {
    state = state.copyWith(isExpanded: !state.isExpanded);
  }

  void setSelectedAttachment(String attachmentId) {
    state = state.copyWith(selectedAttachmentId: attachmentId);
  }
}

// Providers
final postProvider =
    StateNotifierProvider.family<PostNotifier, PostState, String>(
  (ref, postId) => PostNotifier()..getPost(postId),
);

class MenuItemsNotifier extends StateNotifier<List<PopupMenuEntry<String>>> {
  MenuItemsNotifier() : super([]);

  void updateMenuItems(List<PopupMenuEntry<String>> items) {
    // Create a new list to ensure state change is detected
    state = List<PopupMenuEntry<String>>.from(items);
  }

  void clearMenuItems() {
    state = [];
  }
}

final menuItemsProvider =
    StateNotifierProvider<MenuItemsNotifier, List<PopupMenuEntry<String>>>(
        (ref) => MenuItemsNotifier());

class RatelimitState {
  final bool ratelimited;
  final String? ratelimitTimer;

  RatelimitState({
    this.ratelimitTimer,
    this.ratelimited = false,
  });

  RatelimitState copyWith({
    bool? ratelimited,
    String? ratelimitTimer,
  }) {
    return RatelimitState(
      ratelimitTimer: ratelimitTimer,
      ratelimited: ratelimited ?? this.ratelimited,
    );
  }
}

class RateLimitNotifier extends StateNotifier<RatelimitState> {
  Timer? _timer;

  RateLimitNotifier() : super(RatelimitState());

  void startRateLimit() {
    state = state.copyWith(
      ratelimited: true,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final elapsedSeconds = timer.tick;
      final remainingSeconds = 300 - elapsedSeconds;

      if (remainingSeconds <= 0) {
        _timer?.cancel();
        state = state.copyWith(ratelimited: false);
      } else {
        state = state.copyWith(
            ratelimitTimer:
                formatDuration(Duration(seconds: remainingSeconds)));
      }
    });
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '$twoDigitMinutes:$twoDigitSeconds';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final ratelimitProvider =
    StateNotifierProvider<RateLimitNotifier, RatelimitState>((ref) {
  return RateLimitNotifier();
});

class DownloadOption {
  final String url;
  final String label;

  DownloadOption({required this.url, required this.label});
}

class DownloadOptionsState {
  final List<DownloadOption> options;
  final bool isLoading;
  final String? error;

  DownloadOptionsState({
    this.options = const [],
    this.isLoading = false,
    this.error,
  });

  DownloadOptionsState copyWith({
    List<DownloadOption>? options,
    bool? isLoading,
    String? error,
  }) {
    return DownloadOptionsState(
      options: options ?? this.options,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class DownloadOptionsNotifier extends StateNotifier<DownloadOptionsState> {
  DownloadOptionsNotifier() : super(DownloadOptionsState());

  void setLoading() {
    state = state.copyWith(
      isLoading: true,
      error: null,
      options: [],
    );
  }

  void setOptions(List<DownloadOption> options) {
    state = state.copyWith(
      options: options,
      isLoading: false,
      error: null,
    );
  }

  void setError(String error) {
    state = state.copyWith(
      error: error,
      isLoading: false,
      options: [],
    );
  }

  void reset() {
    state = DownloadOptionsState();
  }
}

final downloadOptionsProvider =
    StateNotifierProvider<DownloadOptionsNotifier, DownloadOptionsState>(
        (ref) => DownloadOptionsNotifier());

// Media Quality Provider
final mediaQualityProvider = FutureProvider.family<List<VideoQuality>, String>(
    (ref, attachmentId) async {
  final res = await fpApiRequests.getDelivery('onDemand', attachmentId);
  final decoded = jsonDecode(res);

  List<VideoQuality> qualities = [];
  String baseUrl = decoded['groups'][0]['origins'][0]['url'];

  for (var group in decoded['groups']) {
    for (var variant in group['variants']) {
      if (variant['enabled']) {
        qualities.add(VideoQuality(
          url: '$baseUrl${variant["url"]}',
          label: variant['label'],
        ));
      }
    }
  }

  return qualities;
});
