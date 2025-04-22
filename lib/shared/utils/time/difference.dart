extension TimeDifference on DateTime {
  String get relativeTime {
    final diff = DateTime.now().difference(this);
    const thresholds = {
      365 * 24 * 60: 'year',
      30 * 24 * 60: 'month',
      7 * 24 * 60: 'week',
      24 * 60: 'day',
      60: 'hour',
      1: 'minute'
    };

    final minutes = diff.inMinutes;
    final entry = thresholds.entries.firstWhere((e) => minutes >= e.key,
        orElse: () => const MapEntry(0, 'just now'));

    return entry.key == 0
        ? 'Just now'
        : '${(minutes / entry.key).floor()} ${entry.value}${(minutes ~/ entry.key) > 1 ? 's' : ''} ago';
  }
}
