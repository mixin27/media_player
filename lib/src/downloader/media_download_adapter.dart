import 'dart:async';

import '../models/media_metadata.dart';
import '../models/media_source.dart';
import '../models/media_type.dart';
import 'download_manager_interface.dart';

/// Adapter to connect download manager with media player
class MediaDownloadAdapter {
  final IDownloadManager downloadManager;
  final Map<String, StreamSubscription> _progressSubscriptions = {};

  MediaDownloadAdapter({required this.downloadManager});

  /// Download media and get progress updates
  Future<String> downloadMedia({
    required MediaMetadata metadata,
    required Function(DownloadProgress) onProgress,
    Function(String localPath)? onComplete,
    Function(String error)? onError,
  }) async {
    if (metadata.source is! NetworkMediaSource) {
      throw Exception('Can only download network sources');
    }

    final networkSource = metadata.source as NetworkMediaSource;
    final fileName = _generateFileName(metadata);

    try {
      final downloadId = await downloadManager.startDownload(
        mediaId: metadata.id,
        url: networkSource.url,
        fileName: fileName,
        headers: networkSource.headers,
        mediaType: metadata.mediaType,
      );

      // Subscribe to progress updates
      _progressSubscriptions[downloadId]?.cancel();
      _progressSubscriptions[downloadId] = downloadManager
          .getDownloadProgress(downloadId)
          .listen(
            (progress) {
              onProgress(progress);

              if (progress.isCompleted && progress.localPath != null) {
                onComplete?.call(progress.localPath!);
                _progressSubscriptions[downloadId]?.cancel();
                _progressSubscriptions.remove(downloadId);
              } else if (progress.isFailed) {
                onError?.call(progress.error ?? 'Download failed');
                _progressSubscriptions[downloadId]?.cancel();
                _progressSubscriptions.remove(downloadId);
              }
            },
            onError: (error) {
              onError?.call(error.toString());
            },
          );

      return downloadId;
    } catch (e) {
      onError?.call(e.toString());
      rethrow;
    }
  }

  /// Convert network media to local media after download
  Future<MediaMetadata?> getOfflineMetadata(String mediaId) async {
    final localPath = await downloadManager.getLocalPath(mediaId);
    if (localPath == null) return null;

    // Get original metadata (you should cache this somewhere)
    // For now, return null and let the caller handle it
    return null;
  }

  /// Create local source from downloaded file
  MediaSource? createLocalSource(String localPath) {
    if (localPath.isEmpty) return null;
    return LocalMediaSource(filePath: localPath);
  }

  /// Check if media can be played offline
  Future<bool> canPlayOffline(String mediaId) async {
    return await downloadManager.isMediaDownloaded(mediaId);
  }

  /// Get appropriate media source (local if downloaded, network otherwise)
  Future<MediaSource> getPlaybackSource(MediaMetadata metadata) async {
    final localPath = await downloadManager.getLocalPath(metadata.id);

    if (localPath != null) {
      return LocalMediaSource(filePath: localPath);
    }

    return metadata.source;
  }

  String _generateFileName(MediaMetadata metadata) {
    final extension = _getFileExtension(metadata);
    final sanitizedTitle = metadata.title
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_');

    return '${metadata.id}_$sanitizedTitle$extension';
  }

  String _getFileExtension(MediaMetadata metadata) {
    switch (metadata.mediaType) {
      case MediaType.video:
        return '.mp4';
      case MediaType.audio:
        return '.mp3';
      case MediaType.document:
        if (metadata.source.uri.contains('.pdf')) return '.pdf';
        if (metadata.source.uri.contains('.docx')) return '.docx';
        if (metadata.source.uri.contains('.pptx')) return '.pptx';
        return '.pdf';
    }
  }

  /// Dispose resources
  void dispose() {
    for (var subscription in _progressSubscriptions.values) {
      subscription.cancel();
    }
    _progressSubscriptions.clear();
  }
}
