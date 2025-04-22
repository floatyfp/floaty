class VideoQuality {
  final String label; // e.g., "1080p", "720p"
  final String url; // URL for this quality

  const VideoQuality({
    required this.label,
    required this.url,
  });
}
