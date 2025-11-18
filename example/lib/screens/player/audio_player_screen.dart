import 'package:flutter/material.dart';
import 'package:media_player/media_player.dart';

import '../../services/analytics_service.dart';

class AudioPlayerScreen extends StatefulWidget {
  final MediaMetadata metadata;

  const AudioPlayerScreen({super.key, required this.metadata});

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  late LMSAudioPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _controller = LMSAudioPlayerController(
      metadata: widget.metadata,
      config: const MediaPlayerConfig(
        autoResume: true,
        autoPlay: true,
        enableBackgroundAudio: true,
        showNotificationControls: true,
      ),
      storage: LMSMediaManager.instance.storage,
      onProgressUpdate: (progress) {
        debugPrint(
          '🎵 Progress: ${progress.completionPercentage.toStringAsFixed(1)}%',
        );
      },
      onCompletion: (mediaId) {
        debugPrint('✅ Audio completed: $mediaId');
      },
      onAnalyticsEvent: AnalyticsService.instance.trackMediaEvent,
    );

    // Small delay to ensure player is ready
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() => _isInitialized = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Player'),
        actions: [
          if (widget.metadata.source.isLocal)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Chip(
                avatar: Icon(Icons.offline_pin, size: 16),
                label: Text('Offline'),
                backgroundColor: Colors.green,
                labelStyle: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: !_isInitialized
          ? const Center(child: CircularProgressIndicator())
          : LMSAudioPlayerWidget(controller: _controller, showAlbumArt: true),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
