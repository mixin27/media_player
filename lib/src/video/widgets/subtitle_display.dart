import 'package:flutter/material.dart';

import '../../models/subtitle_track.dart';
import '../subtitle_controller.dart';

/// Widget to display subtitles overlay on video
class SubtitleDisplay extends StatelessWidget {
  final SubtitleController? controller;
  final TextStyle? textStyle;
  final EdgeInsets padding;
  final Color backgroundColor;
  final BorderRadius? borderRadius;

  const SubtitleDisplay({
    super.key,
    required this.controller,
    this.textStyle,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    this.backgroundColor = Colors.black38,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    if (controller == null) return const SizedBox.shrink();

    return StreamBuilder<SubtitleCue?>(
      stream: controller!.currentCueStream,
      builder: (context, snapshot) {
        final cue = snapshot.data;

        if (cue == null || cue.text.isEmpty) {
          return const SizedBox.shrink();
        }

        return Positioned(
          bottom: 10,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: borderRadius ?? BorderRadius.circular(4),
              ),
              child: Text(
                cue.text,
                textAlign: TextAlign.center,
                style:
                    textStyle ??
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          offset: Offset(1, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Widget for subtitle track selection menu
class SubtitleTrackSelector extends StatelessWidget {
  final SubtitleController controller;
  final VoidCallback? onTrackChanged;

  const SubtitleTrackSelector({
    super.key,
    required this.controller,
    this.onTrackChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<SubtitleTrack?>(
      icon: const Icon(Icons.closed_caption, color: Colors.white),
      tooltip: 'Subtitles',
      onSelected: (track) async {
        if (track == null) {
          controller.clearTrack();
        } else {
          await controller.loadTrack(track);
        }
        onTrackChanged?.call();
      },
      itemBuilder: (context) {
        return [
          PopupMenuItem<SubtitleTrack?>(
            value: null,
            child: Row(
              children: [
                if (controller.currentTrack == null)
                  const Icon(Icons.check, size: 20)
                else
                  const SizedBox(width: 20),
                const SizedBox(width: 8),
                const Text('Off'),
              ],
            ),
          ),
          const PopupMenuDivider(),
          ...controller.availableTracks.map((track) {
            final isSelected = controller.currentTrack?.id == track.id;

            return PopupMenuItem<SubtitleTrack?>(
              value: track,
              child: Row(
                children: [
                  if (isSelected)
                    const Icon(Icons.check, size: 20)
                  else
                    const SizedBox(width: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(track.label),
                        Text(
                          track.language,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ];
      },
    );
  }
}

/// Widget for subtitle toggle button
class SubtitleToggleButton extends StatelessWidget {
  final SubtitleController? controller;

  const SubtitleToggleButton({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    if (controller == null || controller!.availableTracks.isEmpty) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<bool>(
      stream: controller!.enabledStream,
      builder: (context, snapshot) {
        final isEnabled = snapshot.data ?? false;

        return IconButton(
          icon: Icon(
            isEnabled ? Icons.closed_caption : Icons.closed_caption_disabled,
            color: Colors.white,
          ),
          tooltip: isEnabled ? 'Disable Subtitles' : 'Enable Subtitles',
          onPressed: controller!.toggle,
        );
      },
    );
  }
}
