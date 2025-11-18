import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../core/media_player_state.dart';
import '../video_player_controller.dart';
import 'subtitle_display.dart';

/// Complete video player widget with built-in controls
class LMSVideoPlayerWidget extends StatefulWidget {
  final LMSVideoPlayerController controller;
  final bool showControls;
  final Duration controlsTimeout;
  final Color? controlsBackgroundColor;
  final bool allowFullscreen;
  final Widget? loadingWidget;
  final Widget? errorWidget;

  const LMSVideoPlayerWidget({
    super.key,
    required this.controller,
    this.showControls = true,
    this.controlsTimeout = const Duration(seconds: 3),
    this.controlsBackgroundColor,
    this.allowFullscreen = true,
    this.loadingWidget,
    this.errorWidget,
  });

  @override
  State<LMSVideoPlayerWidget> createState() => _LMSVideoPlayerWidgetState();
}

class _LMSVideoPlayerWidgetState extends State<LMSVideoPlayerWidget> {
  bool _showControls = true;
  bool _isFullscreen = false;
  OverlayEntry? _fullscreenOverlay;

  @override
  void initState() {
    super.initState();
    _hideControlsAfterTimeout();
  }

  void _hideControlsAfterTimeout() {
    if (!widget.showControls) return;

    Future.delayed(widget.controlsTimeout, () {
      if (mounted && _showControls) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      _hideControlsAfterTimeout();
    }
  }

  void _toggleFullscreen() {
    if (_isFullscreen) {
      _exitFullscreen();
    } else {
      _enterFullscreen();
    }
  }

  void _enterFullscreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _fullscreenOverlay = OverlayEntry(
      builder: (context) => Material(
        color: Colors.black,
        child: LMSVideoPlayerWidget(
          controller: widget.controller,
          showControls: widget.showControls,
          controlsTimeout: widget.controlsTimeout,
          allowFullscreen: false,
        ),
      ),
    );

    Overlay.of(context).insert(_fullscreenOverlay!);
    setState(() => _isFullscreen = true);
  }

  void _exitFullscreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    _fullscreenOverlay?.remove();
    _fullscreenOverlay = null;
    setState(() => _isFullscreen = false);
  }

  @override
  void dispose() {
    if (_isFullscreen) {
      _exitFullscreen();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MediaPlayerState>(
      stream: widget.controller.stateStream,
      builder: (context, snapshot) {
        final state = snapshot.data ?? const MediaPlayerState();

        return AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            color: Colors.black,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Video surface
                Video(
                  controller: widget.controller.videoController,
                  controls: NoVideoControls,
                ),

                // Loading indicator
                if (state.isBuffering)
                  widget.loadingWidget ??
                      const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),

                // Error widget
                if (state.error != null)
                  widget.errorWidget ??
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.white,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              state.error!,
                              style: const TextStyle(color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                // Controls overlay
                if (widget.showControls)
                  GestureDetector(
                    onTap: _toggleControls,
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedOpacity(
                      opacity: _showControls ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: _VideoControls(
                        controller: widget.controller,
                        state: state,
                        isFullscreen: _isFullscreen,
                        allowFullscreen: widget.allowFullscreen,
                        onFullscreenToggle: widget.allowFullscreen
                            ? _toggleFullscreen
                            : null,
                        backgroundColor: widget.controlsBackgroundColor,
                      ),
                    ),
                  ),

                // Subtitle display
                SubtitleDisplay(
                  controller: widget.controller.subtitleController,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _VideoControls extends StatelessWidget {
  final LMSVideoPlayerController controller;
  final MediaPlayerState state;
  final bool isFullscreen;
  final bool allowFullscreen;
  final VoidCallback? onFullscreenToggle;
  final Color? backgroundColor;

  const _VideoControls({
    required this.controller,
    required this.state,
    required this.isFullscreen,
    required this.allowFullscreen,
    this.onFullscreenToggle,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            backgroundColor?.withValues(alpha: 0.7) ?? Colors.black54,
            Colors.transparent,
            Colors.transparent,
            backgroundColor?.withValues(alpha: 0.7) ?? Colors.black54,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildTopBar(context),
          _buildCenterControls(),
          _buildBottomBar(context),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            if (isFullscreen)
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: onFullscreenToggle,
              ),
            Expanded(
              child: Text(
                controller.metadata.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Subtitle selector
            if (controller.subtitleController != null)
              SubtitleTrackSelector(controller: controller.subtitleController!),
            // Speed selector
            _SpeedSelector(
              currentSpeed: state.speed,
              availableSpeeds: controller.config.availableSpeeds,
              onSpeedChanged: controller.setSpeed,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ControlButton(
          icon: Icons.replay_10,
          onPressed: () =>
              controller.seek(state.position - const Duration(seconds: 10)),
        ),
        const SizedBox(width: 32),
        _ControlButton(
          icon: state.isPlaying ? Icons.pause : Icons.play_arrow,
          size: 64,
          onPressed: state.isPlaying ? controller.pause : controller.play,
        ),
        const SizedBox(width: 32),
        _ControlButton(
          icon: Icons.forward_10,
          onPressed: () =>
              controller.seek(state.position + const Duration(seconds: 10)),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar
          _VideoProgressBar(
            position: state.position,
            duration: state.duration,
            onSeek: controller.seek,
          ),

          // Bottom controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Text(
                  _formatDuration(state.position),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                const Text(
                  ' / ',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  _formatDuration(state.duration),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                const Spacer(),
                if (allowFullscreen && onFullscreenToggle != null)
                  IconButton(
                    icon: Icon(
                      isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                      color: Colors.white,
                    ),
                    onPressed: onFullscreenToggle,
                  ),
              ],
            ),
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

// lib/src/video/widgets/control_button.dart
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final double size;

  const _ControlButton({
    required this.icon,
    required this.onPressed,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.black38, shape: BoxShape.circle),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        iconSize: size,
        onPressed: onPressed,
      ),
    );
  }
}

// lib/src/video/widgets/video_progress_bar.dart
class _VideoProgressBar extends StatefulWidget {
  final Duration position;
  final Duration duration;
  final Function(Duration) onSeek;

  const _VideoProgressBar({
    required this.position,
    required this.duration,
    required this.onSeek,
  });

  @override
  State<_VideoProgressBar> createState() => _VideoProgressBarState();
}

class _VideoProgressBarState extends State<_VideoProgressBar> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final progress = widget.duration.inMilliseconds > 0
        ? widget.position.inMilliseconds / widget.duration.inMilliseconds
        : 0.0;

    return SliderTheme(
      data: SliderThemeData(
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
        activeTrackColor: Theme.of(context).primaryColor,
        inactiveTrackColor: Colors.white24,
        thumbColor: Colors.white,
        overlayColor: Theme.of(context).primaryColor.withValues(alpha: 0.3),
      ),
      child: Slider(
        value: _dragValue ?? progress,
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

// lib/src/video/widgets/speed_selector.dart
class _SpeedSelector extends StatelessWidget {
  final double currentSpeed;
  final List<double> availableSpeeds;
  final Function(double) onSpeedChanged;

  const _SpeedSelector({
    required this.currentSpeed,
    required this.availableSpeeds,
    required this.onSpeedChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<double>(
      itemBuilder: (context) => availableSpeeds.map((speed) {
        return PopupMenuItem<double>(
          value: speed,
          child: Row(
            children: [
              Text('${speed}x'),
              const Spacer(),
              if (speed == currentSpeed) const Icon(Icons.check, size: 20),
            ],
          ),
        );
      }).toList(),
      onSelected: onSpeedChanged,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black38,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${currentSpeed}x',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}
