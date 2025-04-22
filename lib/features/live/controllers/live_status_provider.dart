import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LiveStatusNotifier extends StateNotifier<String> {
  Timer? _timer;
  final String? lastLiveTime;

  LiveStatusNotifier(this.lastLiveTime) : super('') {
    _updateOfflineTime();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      _updateOfflineTime();
    });
  }

  void _updateOfflineTime() {
    if (lastLiveTime == null || lastLiveTime!.isEmpty) {
      state = '';
      return;
    }

    final lastLive = DateTime.tryParse(lastLiveTime!);
    if (lastLive == null) {
      state = '';
      return;
    }

    DateTime unixTime = DateTime.now();
    DateTime isoTime = DateTime.parse(lastLiveTime!);

    Duration diff = unixTime.difference(isoTime).abs();

    int days = diff.inDays;
    int hours = diff.inHours.remainder(24);
    int minutes = diff.inMinutes.remainder(60);

    List<String> parts = [];
    if (days > 0) parts.add("$days day${days > 1 ? 's' : ''}");
    if (hours > 0) parts.add("$hours hour${hours > 1 ? 's' : ''}");
    if (minutes > 0) parts.add("$minutes minute${minutes > 1 ? 's' : ''}");

    state = parts.isNotEmpty ? parts.join(" ") : "just now";
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final liveStatusProvider =
    StateNotifierProvider.family<LiveStatusNotifier, String, String?>(
        (ref, lastLiveTime) {
  return LiveStatusNotifier(lastLiveTime);
});
