import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../core/media_player_state.dart';
import '../video_player_controller.dart';

/// Minimal video player without controls (for previews, thumbnails)
class MinimalVideoPlayer extends StatelessWidget {
  final LMSVideoPlayerController controller;
  final bool showLoadingIndicator;

  const MinimalVideoPlayer({
    super.key,
    required this.controller,
    this.showLoadingIndicator = true,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MediaPlayerState>(
      stream: controller.stateStream,
      builder: (context, snapshot) {
        final state = snapshot.data ?? const MediaPlayerState();

        return Stack(
          fit: StackFit.expand,
          children: [
            Video(
              controller: controller.videoController,
              controls: NoVideoControls,
            ),
            if (showLoadingIndicator && state.isBuffering)
              const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
          ],
        );
      },
    );
  }
}
