import 'package:flutter/material.dart';

import '../controllers/media_player_service.dart';
import '../models/video_quality.dart';

PopupMenuItem<String> subtitlePopupMenuItem({
  required MediaPlayerService mediaService,
  required List<Map<String, dynamic>> textTracks,
}) {
  // Local state to track selected subtitles
  int selectedSubtitles = mediaService.subtitlesEnabled
      ? (mediaService.currentSubtitleTrackIndex ?? -1)
      : -1;

  return PopupMenuItem<String>(
    value: 'subtitles',
    child: StatefulBuilder(
      builder: (context, setState) {
        String selectedSubtitlesLabel = 'off';
        if (selectedSubtitles >= 0 &&
            textTracks[selectedSubtitles]['language'] != null) {
          selectedSubtitlesLabel =
              '${textTracks[selectedSubtitles]['language']}';
        }

        return PopupMenuButton<int>(
          child: Text('Subtitles ($selectedSubtitlesLabel)'),
          itemBuilder: (context) => [
            PopupMenuItem<int>(
              value: -1,
              child: Row(
                children: [
                  const Text('off'),
                  if (selectedSubtitles == -1)
                    const Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Icon(Icons.check, size: 16),
                    ),
                ],
              ),
            ),
            ...textTracks.asMap().entries.map((entry) {
              final index = entry.key;
              final track = entry.value;
              return PopupMenuItem<int>(
                value: index,
                child: Row(
                  children: [
                    Text(track['language'] ?? 'Unknown'),
                    if (selectedSubtitles == index)
                      const Padding(
                        padding: EdgeInsets.only(left: 8.0),
                        child: Icon(Icons.check, size: 16),
                      ),
                  ],
                ),
              );
            }),
          ],
          onSelected: (index) {
            setState(() {
              selectedSubtitles = index;
            });
            mediaService.setSubtitleTrack(index);
          },
        );
      },
    ),
  );
}

PopupMenuItem<String> qualityPopupMenuItem({
  required MediaPlayerService mediaService,
  required List<VideoQuality> qualities,
}) {
  return PopupMenuItem<String>(
    value: 'quality',
    child: StatefulBuilder(
      builder: (context, setState) {
        // Local state to track selected quality
        VideoQuality? selectedQuality = mediaService.currentQuality;
        String selectedQualityLabel = '';
        if (selectedQuality?.label != null) {
          selectedQualityLabel = ' (${selectedQuality?.label})';
        }

        return PopupMenuButton<VideoQuality>(
          child: Text('Quality$selectedQualityLabel'),
          itemBuilder: (context) => qualities.map((quality) {
            return PopupMenuItem<VideoQuality>(
              value: quality,
              child: Row(
                children: [
                  Text(quality.label),
                  if (selectedQuality == quality)
                    const Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Icon(Icons.check, size: 16),
                    ),
                ],
              ),
            );
          }).toList(),
          onSelected: (quality) {
            setState(() {
              selectedQuality = quality;
            });
            mediaService.changeQuality(quality);
          },
        );
      },
    ),
  );
}

PopupMenuItem<String> playbackSpeedPopupMenuItem({
  required MediaPlayerService mediaService,
}) {
  List<double> playbackSpeeds = [0.5, 1.0, 1.25, 1.5, 1.75, 2.0];

  return PopupMenuItem<String>(
    value: 'playback_speed',
    child: StatefulBuilder(
      builder: (context, setState) {
        // Local state to track selected speed
        double selectedSpeed = mediaService.playbackSpeed;

        return PopupMenuButton<double>(
          child: Text('Playback Speed (${selectedSpeed}x)'),
          itemBuilder: (context) => [
            ...playbackSpeeds.map((speed) {
              return PopupMenuItem(
                  value: speed,
                  child: Row(
                    children: [
                      Text('${speed}x'),
                      if (selectedSpeed == speed)
                        const Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: Icon(Icons.check, size: 16),
                        ),
                    ],
                  ));
            }),
            PopupMenuItem(
              value: selectedSpeed,
              child: Row(
                children: [
                  Text('Custom'),
                  if (!playbackSpeeds.contains(selectedSpeed))
                    const Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Icon(Icons.check, size: 16),
                    ),
                ],
              ),
              onTap: () => _showCustomSpeedDialog(context, mediaService),
            ),
          ],
          onSelected: (speed) {
            setState(() {
              selectedSpeed = speed;
            });
            mediaService.setSpeed(speed);
          },
        );
      },
    ),
  );
}

void _showCustomSpeedDialog(
  BuildContext context,
  MediaPlayerService mediaService,
) {
  double customSpeed = mediaService.playbackSpeed;
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            title: const Text('Select Playback Speed'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Slider(
                  value: customSpeed,
                  min: 0.1,
                  max: 4.0,
                  divisions: 100,
                  label: '${customSpeed.toStringAsFixed(1)}x',
                  onChanged: (value) {
                    setState(() {
                      customSpeed = value;
                    });
                  },
                ),
                Text('${customSpeed.toStringAsFixed(1)}x'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  mediaService.setSpeed(customSpeed);
                },
                child: const Text('Set Speed'),
              ),
            ],
          );
        },
      );
    },
  );
}
