import 'package:flutter/material.dart';

import '../../core/media_player_state.dart';
import '../audio_player_controller.dart';

/// Compact audio player for mini player / bottom sheet
class CompactAudioPlayer extends StatelessWidget {
  final LMSAudioPlayerController controller;
  final VoidCallback? onTap;

  const CompactAudioPlayer({super.key, required this.controller, this.onTap});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MediaPlayerState>(
      stream: controller.stateStream,
      builder: (context, snapshot) {
        final state = snapshot.data ?? const MediaPlayerState();

        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Thumbnail
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[300],
                  ),
                  child: controller.metadata.thumbnailUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            controller.metadata.thumbnailUrl!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(Icons.audiotrack),
                ),

                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        controller.metadata.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: state.duration.inMilliseconds > 0
                            ? state.position.inMilliseconds /
                                  state.duration.inMilliseconds
                            : 0.0,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation(
                          Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Controls
                IconButton(
                  icon: Icon(state.isPlaying ? Icons.pause : Icons.play_arrow),
                  onPressed: state.isPlaying
                      ? controller.pause
                      : controller.play,
                ),

                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    controller.pause();
                    // Hook to close mini player
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
