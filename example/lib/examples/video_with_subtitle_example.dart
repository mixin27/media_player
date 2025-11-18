import 'package:flutter/material.dart';
import 'package:media_player/media_player.dart';

/// Example of video player with multiple subtitle tracks
class VideoWithSubtitlesExample extends StatefulWidget {
  const VideoWithSubtitlesExample({super.key});

  @override
  State<VideoWithSubtitlesExample> createState() =>
      _VideoWithSubtitlesExampleState();
}

class _VideoWithSubtitlesExampleState extends State<VideoWithSubtitlesExample> {
  late LMSVideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    final manager = LMSMediaManager.instance;

    // Define subtitle tracks
    final subtitleTracks = [
      SubtitleTrack(
        id: 'en',
        label: 'English',
        language: 'en',
        url:
            'https://hls.ted.com/project_masters/9916/subtitles/en/full.vtt?intro_master_id=9294',
        type: SubtitleType.vtt,
        isDefault: true,
      ),
      SubtitleTrack(
        id: 'my',
        label: 'Myanmar (Burmese)',
        language: 'my',
        url:
            'https://hls.ted.com/project_masters/9916/subtitles/my/full.vtt?intro_master_id=9294',
        type: SubtitleType.vtt,
      ),
      SubtitleTrack(
        id: 'ar',
        label: 'Arabic',
        language: 'ar',
        url:
            'https://hls.ted.com/project_masters/9916/subtitles/ar/full.vtt?intro_master_id=9294',
        type: SubtitleType.srt,
      ),
    ];

    _controller = LMSVideoPlayerController(
      metadata: MediaMetadata(
        id: 'video_with_subs',
        title: 'Video with Subtitles',
        mediaType: MediaType.video,
        source: NetworkMediaSource(
          url:
              'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
        ),
        // Optional: Enable default subtitle
        subtitleConfig: SubtitleConfig(
          subtitleUrl:
              'https://hls.ted.com/project_masters/9916/subtitles/en/full.vtt?intro_master_id=9294',
          subtitleLanguage: 'en',
          type: SubtitleType.vtt,
          enabled: true,
        ),
      ),
      config: const MediaPlayerConfig(autoPlay: false, autoResume: true),
      storage: manager.storage,
      subtitleTracks: subtitleTracks, // Pass subtitle tracks
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: const Text('Video with Subtitles')),
      body: SafeArea(
        child: Column(
          children: [
            LMSVideoPlayerWidget(controller: _controller, showControls: true),
            const SizedBox(height: 16),
            _SubtitleControls(controller: _controller),
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

class _SubtitleControls extends StatelessWidget {
  final LMSVideoPlayerController controller;

  const _SubtitleControls({required this.controller});

  @override
  Widget build(BuildContext context) {
    if (controller.subtitleController == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Subtitle Controls',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Current subtitle track
          StreamBuilder<bool>(
            stream: controller.subtitleController!.enabledStream,
            builder: (context, snapshot) {
              final isEnabled = snapshot.data ?? false;
              final currentTrack = controller.subtitleController!.currentTrack;

              return Card(
                child: ListTile(
                  leading: Icon(
                    isEnabled
                        ? Icons.closed_caption
                        : Icons.closed_caption_disabled,
                  ),
                  title: Text(
                    currentTrack != null ? currentTrack.label : 'Subtitles Off',
                  ),
                  subtitle: currentTrack != null
                      ? Text('Language: ${currentTrack.language}')
                      : null,
                  trailing: Switch(
                    value: isEnabled,
                    onChanged: (value) {
                      controller.subtitleController!.setEnabled(value);
                    },
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // Available tracks
          const Text(
            'Available Tracks',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),

          ...controller.subtitleController!.availableTracks.map((track) {
            final isSelected =
                controller.subtitleController!.currentTrack?.id == track.id;

            return Card(
              color: isSelected ? Colors.blue[50] : null,
              child: ListTile(
                leading: Icon(
                  isSelected ? Icons.check_circle : Icons.language,
                  color: isSelected ? Colors.blue : null,
                ),
                title: Text(track.label),
                subtitle: Text(
                  '${track.language} • ${track.type.toString().split('.').last.toUpperCase()}',
                ),
                onTap: () async {
                  await controller.subtitleController!.loadTrack(track);
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}
