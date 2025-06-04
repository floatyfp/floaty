import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:floaty/features/player/controllers/media_player_service.dart';
import 'package:floaty/features/api/repositories/fpapi.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:text_scroll/text_scroll.dart';

// Provider for play state
final playingStateProvider = StreamProvider.autoDispose<bool>((ref) {
  final mediaService = ref.watch(mediaPlayerServiceProvider.notifier);
  return mediaService.player.stream.playing;
});

class MiniPlayerWidget extends ConsumerWidget {
  final String title;
  final String artist;
  final String postId;
  final String? thumbnailUrl;
  final bool live;
  final VideoController? videoController;

  const MiniPlayerWidget({
    super.key,
    required this.title,
    required this.artist,
    required this.postId,
    required this.live,
    this.thumbnailUrl,
    this.videoController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final mediaService = ref.read(mediaPlayerServiceProvider.notifier);
    final isPlaying = ref.watch(playingStateProvider);

    return Material(
      elevation: 8,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          mediaService.changeState(MediaPlayerState.main);
          if (!live) {
            fpApiRequests.iprogress(
              mediaService.currentAttachmentId ?? '',
              mediaService.currentPosition.inSeconds,
              mediaService.selectedMediaName ?? '',
            );
          }
          if (live) {
            context.go('/live/$postId');
          } else {
            context.go('/post/$postId');
          }
        },
        child: Container(
          height: 72,
          color: theme.cardColor,
          child: Row(
            children: [
              if (videoController != null)
                SizedBox(
                  width: 128,
                  height: 72,
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Video(
                      controller: videoController!,
                      controls: NoVideoControls,
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else if (thumbnailUrl != null)
                Image.network(
                  thumbnailUrl!,
                  width: 128,
                  height: 72,
                  fit: BoxFit.cover,
                )
              else
                Container(
                  width: 128,
                  height: 72,
                  color: Colors.grey[800],
                  child: const Icon(Icons.music_note, size: 32),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextScroll(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        fadedBorder: true,
                        fadedBorderWidth: 0.1,
                        pauseBetween: const Duration(seconds: 5),
                        intervalSpaces: 6,
                        velocity:
                            const Velocity(pixelsPerSecond: Offset(20, 0)),
                      ),
                      AutoSizeText(
                        artist,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodySmall?.color,
                        ),
                        minFontSize: 6,
                        maxFontSize: 16,
                        textScaleFactor: 0.85,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            child: const Icon(
                              Icons.fast_rewind,
                              size: 18,
                            ),
                            onTap: () {
                              mediaService.seek(mediaService.currentPosition -
                                  const Duration(seconds: 10));
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              child: Icon(
                                isPlaying.when(
                                  data: (playing) =>
                                      playing ? Icons.pause : Icons.play_arrow,
                                  loading: () => Icons.pause,
                                  error: (_, __) => Icons.pause,
                                ),
                                size: 18,
                              ),
                              onTap: () {
                                mediaService.playpause();
                              },
                            ),
                          ),
                          InkWell(
                            child: const Icon(
                              Icons.fast_forward,
                              size: 18,
                            ),
                            onTap: () {
                              mediaService.seek(mediaService.currentPosition +
                                  const Duration(seconds: 10));
                            },
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  child: const Icon(
                    Icons.close,
                    size: 16,
                  ),
                  onTap: () {
                    mediaService.changeState(MediaPlayerState.none);
                    mediaService.stop();
                    mediaService.changeState(MediaPlayerState.none);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
