import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_player/media_player.dart';

import '../../models/sample_media.dart';
import '../../services/download_service.dart';
import '../../widgets/media_card.dart';
import '../player/video_player_screen.dart';

class VideosTab extends StatefulWidget {
  const VideosTab({super.key});

  @override
  State<VideosTab> createState() => _VideosTabState();
}

class _VideosTabState extends State<VideosTab> {
  final Map<String, DownloadProgress?> _downloadStates = {};
  final Map<String, StreamSubscription?> _downloadSubscriptions = {};

  @override
  void initState() {
    super.initState();
    _loadDownloadStates();
  }

  Future<void> _loadDownloadStates() async {
    for (var video in SampleMedia.videos) {
      final downloads = await DownloadService.instance.getDownloadsForMedia(
        video.id,
      );

      if (downloads.isNotEmpty) {
        final download = downloads.first;
        setState(() {
          _downloadStates[video.id] = download;
        });

        // Listen to progress updates for active downloads
        if (download.isDownloading ||
            download.status == DownloadStatus.paused) {
          _subscribeToDownload(video.id, download.downloadId);
        }
      }
    }
  }

  void _subscribeToDownload(String mediaId, String downloadId) {
    // Cancel existing subscription if any
    _downloadSubscriptions[mediaId]?.cancel();

    // Subscribe to download progress
    _downloadSubscriptions[mediaId] = DownloadService.instance
        .getDownloadProgress(downloadId)
        .listen((progress) {
          if (mounted) {
            setState(() {
              _downloadStates[mediaId] = progress;
            });

            // Unsubscribe when download completes or fails
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
    // Cancel all subscriptions
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
        itemCount: SampleMedia.videos.length,
        itemBuilder: (context, index) {
          final video = SampleMedia.videos[index];
          final downloadState = _downloadStates[video.id];

          return MediaCard(
            metadata: video,
            downloadProgress: downloadState,
            onTap: () => _playVideo(video),
            onDownload: () => _startDownload(video),
            onPause: downloadState != null && downloadState.isDownloading
                ? () => _pauseDownload(downloadState)
                : null,
            onResume: downloadState?.status == DownloadStatus.paused
                ? () => _resumeDownload(downloadState!)
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

  Future<void> _playVideo(MediaMetadata metadata) async {
    // Check if downloaded
    final localPath = await DownloadService.instance.getLocalPath(metadata.id);

    final playbackMetadata = localPath != null
        ? metadata.copyWith(source: LocalMediaSource(filePath: localPath))
        : metadata;

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(metadata: playbackMetadata),
      ),
    );
  }

  Future<void> _startDownload(MediaMetadata metadata) async {
    final adapter = MediaDownloadAdapter(
      downloadManager: DownloadService.instance,
    );

    try {
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
              SnackBar(
                content: Text('Downloaded: ${metadata.title}'),
                action: SnackBarAction(
                  label: 'Play',
                  onPressed: () => _playVideo(metadata),
                ),
              ),
            );
          }
        },
        onError: (error) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Download failed: $error')));
          }
        },
      );

      // Subscribe to continuous updates
      _subscribeToDownload(metadata.id, downloadId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _pauseDownload(DownloadProgress progress) async {
    await DownloadService.instance.pauseDownload(progress.downloadId);
    await _loadDownloadStates();
  }

  Future<void> _resumeDownload(DownloadProgress progress) async {
    await DownloadService.instance.resumeDownload(progress.downloadId);
    await _loadDownloadStates();
  }

  Future<void> _cancelDownload(DownloadProgress progress) async {
    await DownloadService.instance.cancelDownload(progress.downloadId);
    await _loadDownloadStates();
  }

  Future<void> _deleteDownload(DownloadProgress progress) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Download'),
        content: const Text('Are you sure you want to delete this download?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DownloadService.instance.deleteDownload(progress.downloadId);
      await _loadDownloadStates();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Download deleted')));
      }
    }
  }
}
