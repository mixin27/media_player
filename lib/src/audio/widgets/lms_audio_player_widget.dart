import 'package:flutter/material.dart';

import '../../core/media_player_state.dart';
import '../audio_player_controller.dart';

/// Full-featured audio player widget with album art and controls
class LMSAudioPlayerWidget extends StatelessWidget {
  final LMSAudioPlayerController controller;
  final bool showAlbumArt;
  final bool showPlaylist;
  final Widget? customAlbumArt;

  const LMSAudioPlayerWidget({
    super.key,
    required this.controller,
    this.showAlbumArt = true,
    this.showPlaylist = false,
    this.customAlbumArt,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MediaPlayerState>(
      stream: controller.stateStream,
      builder: (context, snapshot) {
        final state = snapshot.data ?? const MediaPlayerState();

        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showAlbumArt) ...[
                _AudioAlbumArt(
                  imageUrl: controller.metadata.thumbnailUrl,
                  customWidget: customAlbumArt,
                  isPlaying: state.isPlaying,
                ),
                const SizedBox(height: 24),
              ],

              _AudioInfo(
                title: controller.metadata.title,
                subtitle: controller.metadata.description,
              ),

              const SizedBox(height: 16),

              _AudioProgressBar(
                position: state.position,
                duration: state.duration,
                onSeek: controller.seek,
              ),

              const SizedBox(height: 8),

              _AudioTimeDisplay(
                position: state.position,
                duration: state.duration,
              ),

              const SizedBox(height: 24),

              _AudioControls(controller: controller, state: state),

              const SizedBox(height: 16),

              _AudioSecondaryControls(controller: controller, state: state),
            ],
          ),
        );
      },
    );
  }
}

class _AudioAlbumArt extends StatelessWidget {
  final String? imageUrl;
  final Widget? customWidget;
  final bool isPlaying;

  const _AudioAlbumArt({
    this.imageUrl,
    this.customWidget,
    required this.isPlaying,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (customWidget != null)
              customWidget!
            else if (imageUrl != null && imageUrl!.isNotEmpty)
              Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _defaultAlbumArt(),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey[300],
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
              )
            else
              _defaultAlbumArt(),

            // Animated playing indicator
            if (isPlaying)
              Positioned(
                bottom: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _AnimatedBar(delay: 0),
                      SizedBox(width: 3),
                      _AnimatedBar(delay: 200),
                      SizedBox(width: 3),
                      _AnimatedBar(delay: 400),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _defaultAlbumArt() {
    return Container(
      color: Colors.grey[300],
      child: Icon(Icons.audiotrack, size: 120, color: Colors.grey[600]),
    );
  }
}

class _AnimatedBar extends StatefulWidget {
  final int delay;

  const _AnimatedBar({required this.delay});

  @override
  State<_AnimatedBar> createState() => _AnimatedBarState();
}

class _AnimatedBarState extends State<_AnimatedBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 4,
      end: 16,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 3,
          height: _animation.value,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      },
    );
  }
}

class _AudioInfo extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _AudioInfo({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

class _AudioProgressBar extends StatefulWidget {
  final Duration position;
  final Duration duration;
  final Function(Duration) onSeek;

  const _AudioProgressBar({
    required this.position,
    required this.duration,
    required this.onSeek,
  });

  @override
  State<_AudioProgressBar> createState() => _AudioProgressBarState();
}

class _AudioProgressBarState extends State<_AudioProgressBar> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final progress = widget.duration.inMilliseconds > 0
        ? widget.position.inMilliseconds / widget.duration.inMilliseconds
        : 0.0;

    return SliderTheme(
      data: SliderThemeData(
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
        activeTrackColor: Theme.of(context).primaryColor,
        inactiveTrackColor: Colors.grey[300],
        thumbColor: Theme.of(context).primaryColor,
        overlayColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
      ),
      child: Slider(
        value: _dragValue ?? progress.clamp(0.0, 1.0),
        onChanged: (value) {
          setState(() => _dragValue = value);
        },
        onChangeEnd: (value) {
          final seekPosition = Duration(
            milliseconds: (value * widget.duration.inMilliseconds).toInt(),
          );
          widget.onSeek(seekPosition);
          setState(() => _dragValue = null);
        },
      ),
    );
  }
}

class _AudioTimeDisplay extends StatelessWidget {
  final Duration position;
  final Duration duration;

  const _AudioTimeDisplay({required this.position, required this.duration});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _formatDuration(position),
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          Text(
            _formatDuration(duration),
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
}

class _AudioControls extends StatelessWidget {
  final LMSAudioPlayerController controller;
  final MediaPlayerState state;

  const _AudioControls({required this.controller, required this.state});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      spacing: 8,
      children: [
        _AudioControlButton(
          icon: Icons.replay_10,
          size: 40,
          onPressed: () =>
              controller.seek(state.position - const Duration(seconds: 10)),
        ),

        _AudioControlButton(
          icon: Icons.skip_previous,
          size: 48,
          onPressed: () {
            // Hook for previous track (if implementing playlist)
          },
        ),

        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              state.isPlaying ? Icons.pause : Icons.play_arrow,
              size: 40,
            ),
            color: Colors.white,
            onPressed: state.isPlaying ? controller.pause : controller.play,
          ),
        ),

        _AudioControlButton(
          icon: Icons.skip_next,
          size: 48,
          onPressed: () {
            // Hook for next track (if implementing playlist)
          },
        ),

        _AudioControlButton(
          icon: Icons.forward_10,
          size: 40,
          onPressed: () =>
              controller.seek(state.position + const Duration(seconds: 10)),
        ),
      ],
    );
  }
}

class _AudioControlButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback? onPressed;

  const _AudioControlButton({
    required this.icon,
    required this.size,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      iconSize: size,
      color: Colors.grey[700],
      onPressed: onPressed,
    );
  }
}

class _AudioSecondaryControls extends StatelessWidget {
  final LMSAudioPlayerController controller;
  final MediaPlayerState state;

  const _AudioSecondaryControls({
    required this.controller,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: const Icon(Icons.shuffle),
          onPressed: () {
            // Hook for shuffle
          },
        ),
        IconButton(
          icon: const Icon(Icons.replay),
          onPressed: controller.replay,
        ),
        PopupMenuButton<double>(
          icon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${state.speed}x', style: const TextStyle(fontSize: 14)),
              const Icon(Icons.arrow_drop_down, size: 20),
            ],
          ),
          itemBuilder: (context) => controller.config.availableSpeeds.map((
            speed,
          ) {
            return PopupMenuItem<double>(
              value: speed,
              child: Row(
                children: [
                  Text('${speed}x'),
                  const Spacer(),
                  if (speed == state.speed) const Icon(Icons.check, size: 20),
                ],
              ),
            );
          }).toList(),
          onSelected: controller.setSpeed,
        ),
        IconButton(
          icon: const Icon(Icons.repeat),
          onPressed: () {
            // Hook for repeat mode
          },
        ),
      ],
    );
  }
}
