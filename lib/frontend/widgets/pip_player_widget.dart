import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:simple_pip_mode/pip_widget.dart';
import 'dart:io' show Platform;
import 'package:window_manager/window_manager.dart';
import 'package:floaty/services/media/media_player_service.dart';
import 'package:floaty/backend/fpapi.dart';

class PipPlayerWidget extends ConsumerWidget {
  final VideoController videoController;
  final String postId;
  final bool live;

  const PipPlayerWidget(
      {super.key,
      required this.videoController,
      required this.postId,
      required this.live});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaService = ref.read(mediaPlayerServiceProvider.notifier);
    return Material(
        child: DragToMoveArea(
      child: Platform.isWindows || Platform.isLinux || Platform.isMacOS
          ? MaterialDesktopVideoControlsTheme(
              normal: MaterialDesktopVideoControlsThemeData(
                topButtonBar: [
                  MaterialCustomButton(
                    icon: Icon(Icons.arrow_back),
                    onPressed: () {
                      mediaService.pipfalse();
                      if (!live) {
                        fpApiRequests.iprogress(
                          mediaService.currentAttachmentId ?? '',
                          mediaService.currentPosition.inSeconds,
                          mediaService.selectedMediaName ?? '',
                        );
                      }
                      mediaService.changeState(MediaPlayerState.main);
                      if (live) {
                        context.go('/live/$postId');
                      } else {
                        context.go('/post/$postId');
                      }
                    },
                  ),
                  const Spacer(),
                  MaterialCustomButton(
                    icon: Icon(Icons.close),
                    onPressed: () {
                      windowManager.close();
                    },
                  ),
                ],
                buttonBarButtonSize: 24.0,
                buttonBarButtonColor: Colors.white,
                seekBarThumbColor: Colors.white,
                seekBarPositionColor: Theme.of(context).colorScheme.primary,
                modifyVolumeOnScroll: false,
                bottomButtonBar: [
                  MaterialDesktopSkipPreviousButton(),
                  MaterialDesktopPlayOrPauseButton(),
                  MaterialDesktopSkipNextButton(),
                  MaterialDesktopVolumeButton(),
                  MaterialDesktopPositionIndicator(),
                  const Spacer(),
                  if (mediaService.textTracks?.isNotEmpty == true)
                    MaterialDesktopCustomButton(
                      icon: Icon(
                        Icons.closed_caption,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        mediaService.toggleSubtitles();
                      },
                    ),
                  MaterialDesktopFullscreenButton(),
                ],
              ),
              fullscreen: MaterialDesktopVideoControlsThemeData(
                topButtonBar: [
                  MaterialCustomButton(
                    icon: Icon(Icons.arrow_back),
                    onPressed: () {
                      mediaService.pipfalse();
                      if (!live) {
                        fpApiRequests.iprogress(
                          mediaService.currentAttachmentId ?? '',
                          mediaService.currentPosition.inSeconds,
                          mediaService.selectedMediaName ?? '',
                        );
                      }
                      mediaService.changeState(MediaPlayerState.main);
                      if (live) {
                        context.go('/live/$postId');
                      } else {
                        context.go('/post/$postId');
                      }
                    },
                  ),
                  const Spacer(),
                  MaterialCustomButton(
                    icon: Icon(Icons.close),
                    onPressed: () {
                      windowManager.close();
                    },
                  ),
                ],
                buttonBarButtonSize: 24.0,
                buttonBarButtonColor: Colors.white,
                seekBarThumbColor: Colors.white,
                seekBarPositionColor: Theme.of(context).colorScheme.primary,
                modifyVolumeOnScroll: false,
                bottomButtonBar: [
                  MaterialDesktopSkipPreviousButton(),
                  MaterialDesktopPlayOrPauseButton(),
                  MaterialDesktopSkipNextButton(),
                  MaterialDesktopVolumeButton(),
                  MaterialDesktopPositionIndicator(),
                  const Spacer(),
                  if (mediaService.textTracks?.isNotEmpty == true)
                    MaterialDesktopCustomButton(
                      icon: Icon(
                        Icons.closed_caption,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        mediaService.toggleSubtitles();
                      },
                    ),
                  MaterialDesktopFullscreenButton(),
                ],
              ),
              child: Video(
                controller: videoController,
                pauseUponEnteringBackgroundMode: false,
              ),
            )
          : PipWidget(
              onPipExited: () {
                fpApiRequests.iprogress(
                  mediaService.currentAttachmentId ?? '',
                  mediaService.currentPosition.inSeconds,
                  mediaService.selectedMediaName ?? '',
                );
                context.go('/post/$postId');
              },
              pipChild: Video(
                controller: videoController,
                controls: NoVideoControls,
                pauseUponEnteringBackgroundMode: false,
              ),
              child: const Center(child: CircularProgressIndicator()),
            ),
    ));
  }
}
