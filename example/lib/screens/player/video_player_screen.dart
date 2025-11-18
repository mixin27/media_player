import 'package:flutter/material.dart';
import 'package:media_player/media_player.dart';

import '../../services/analytics_service.dart';

class VideoPlayerScreen extends StatefulWidget {
  final MediaMetadata metadata;

  const VideoPlayerScreen({super.key, required this.metadata});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late LMSVideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _controller = LMSVideoPlayerController(
      metadata: widget.metadata,
      config: const MediaPlayerConfig(
        autoResume: true,
        autoPlay: true,
        completionThreshold: 0.9,
        progressSaveInterval: 5,
        enablePiP: true,
      ),
      storage: LMSMediaManager.instance.storage,
      onProgressUpdate: (progress) {
        debugPrint(
          '📹 Progress: ${progress.completionPercentage.toStringAsFixed(1)}%',
        );
      },
      onCompletion: (mediaId) {
        debugPrint('✅ Video completed: $mediaId');

        if (mounted) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Video Completed!'),
              content: const Text('You have finished watching this video.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: const Text('Done'),
                ),
              ],
            ),
          );
        }
      },
      onAnalyticsEvent: AnalyticsService.instance.trackMediaEvent,
      onError: (mediaId, error) {
        debugPrint('❌ Error: $error');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $error')));
        }
      },
    );

    setState(() => _isInitialized = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: !_isInitialized
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  LMSVideoPlayerWidget(
                    controller: _controller,
                    showControls: true,
                    allowFullscreen: true,
                  ),
                  Expanded(
                    child: _VideoDetails(
                      metadata: widget.metadata,
                      controller: _controller,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _VideoDetails extends StatelessWidget {
  final MediaMetadata metadata;
  final LMSVideoPlayerController controller;

  const _VideoDetails({required this.metadata, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              if (metadata.source.isLocal)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.offline_pin, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Offline',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            metadata.title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (metadata.description != null)
            Text(
              metadata.description!,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          const SizedBox(height: 24),
          StreamBuilder<MediaPlayerState>(
            stream: controller.stateStream,
            builder: (context, snapshot) {
              final state = snapshot.data ?? const MediaPlayerState();

              return Column(
                children: [
                  _StatCard(
                    icon: Icons.play_circle_outline,
                    label: 'Status',
                    value: state.isPlaying ? 'Playing' : 'Paused',
                  ),
                  _StatCard(
                    icon: Icons.speed,
                    label: 'Speed',
                    value: '${state.speed}x',
                  ),
                  _StatCard(
                    icon: Icons.access_time,
                    label: 'Position',
                    value: _formatDuration(state.position),
                  ),
                  _StatCard(
                    icon: Icons.timer,
                    label: 'Duration',
                    value: _formatDuration(state.duration),
                  ),
                ],
              );
            },
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
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(label),
        trailing: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}
