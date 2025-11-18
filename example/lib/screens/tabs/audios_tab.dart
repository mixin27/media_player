import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_player/media_player.dart';

import '../../models/sample_media.dart';
import '../../services/download_service.dart';
import '../../widgets/media_card.dart';
import '../player/audio_player_screen.dart';

class AudiosTab extends StatefulWidget {
  const AudiosTab({super.key});

  @override
  State<AudiosTab> createState() => _AudiosTabState();
}

class _AudiosTabState extends State<AudiosTab> {
  final Map<String, DownloadProgress?> _downloadStates = {};
  final Map<String, StreamSubscription?> _downloadSubscriptions = {};

  @override
  void initState() {
    super.initState();
    _loadDownloadStates();
  }

  Future<void> _loadDownloadStates() async {
    for (var audio in SampleMedia.audios) {
      final downloads = await DownloadService.instance.getDownloadsForMedia(
        audio.id,
      );

      if (downloads.isNotEmpty) {
        final download = downloads.first;
        setState(() {
          _downloadStates[audio.id] = download;
        });

        if (download.isDownloading ||
            download.status == DownloadStatus.paused) {
          _subscribeToDownload(audio.id, download.downloadId);
        }
      }
    }
  }

  void _subscribeToDownload(String mediaId, String downloadId) {
    _downloadSubscriptions[mediaId]?.cancel();

    _downloadSubscriptions[mediaId] = DownloadService.instance
        .getDownloadProgress(downloadId)
        .listen((progress) {
          if (mounted) {
            setState(() {
              _downloadStates[mediaId] = progress;
            });

            if (progress.isCompleted ||
                progress.isFailed ||
                progress.status == DownloadStatus.cancelled) {
              _downloadSubscriptions[mediaId]?.cancel();
              _downloadSubscriptions[mediaId] = null;
            }
          }
        });
  }

  @override
  void dispose() {
    for (var subscription in _downloadSubscriptions.values) {
      subscription?.cancel();
    }
    _downloadSubscriptions.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadDownloadStates,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: SampleMedia.audios.length,
        itemBuilder: (context, index) {
          final audio = SampleMedia.audios[index];
          final downloadState = _downloadStates[audio.id];

          return MediaCard(
            metadata: audio,
            downloadProgress: downloadState,
            onTap: () => _playAudio(audio),
            onDownload: () => _startDownload(audio),
            onPause: downloadState != null && downloadState.isDownloading
                ? () => _pauseDownload(downloadState)
                : null,
            onCancel: downloadState?.isDownloading == true
                ? () => _cancelDownload(downloadState!)
                : null,
            onDelete: downloadState?.isCompleted == true
                ? () => _deleteDownload(downloadState!)
                : null,
          );
        },
      ),
    );
  }

  Future<void> _playAudio(MediaMetadata metadata) async {
    final localPath = await DownloadService.instance.getLocalPath(metadata.id);

    final playbackMetadata = localPath != null
        ? metadata.copyWith(source: LocalMediaSource(filePath: localPath))
        : metadata;

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AudioPlayerScreen(metadata: playbackMetadata),
      ),
    );
  }

  Future<void> _startDownload(MediaMetadata metadata) async {
    final adapter = MediaDownloadAdapter(
      downloadManager: DownloadService.instance,
    );

    final downloadId = await adapter.downloadMedia(
      metadata: metadata,
      onProgress: (progress) {
        if (mounted) {
          setState(() {
            _downloadStates[metadata.id] = progress;
          });
        }
      },
      onComplete: (localPath) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Downloaded: ${metadata.title}')),
          );
        }
      },
    );

    _subscribeToDownload(metadata.id, downloadId);
  }

  Future<void> _pauseDownload(DownloadProgress progress) async {
    await DownloadService.instance.pauseDownload(progress.downloadId);
    await _loadDownloadStates();
  }

  Future<void> _cancelDownload(DownloadProgress progress) async {
    await DownloadService.instance.cancelDownload(progress.downloadId);
    await _loadDownloadStates();
  }

  Future<void> _deleteDownload(DownloadProgress progress) async {
    await DownloadService.instance.deleteDownload(progress.downloadId);
    await _loadDownloadStates();
  }
}
