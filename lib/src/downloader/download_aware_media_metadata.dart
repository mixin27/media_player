import '../core/subtitle_config.dart';
import '../models/media_metadata.dart';
import '../models/media_source.dart';
import '../models/media_type.dart';
import 'download_manager_interface.dart';

/// Extended metadata with download information
class DownloadAwareMediaMetadata extends MediaMetadata {
  final bool isDownloaded;
  final String? localPath;
  final DownloadProgress? downloadProgress;

  const DownloadAwareMediaMetadata({
    required super.id,
    required super.title,
    super.description,
    super.thumbnailUrl,
    required super.mediaType,
    required super.source,
    super.subtitleConfig,
    super.customData,
    this.isDownloaded = false,
    this.localPath,
    this.downloadProgress,
  });

  /// Create from regular metadata with download info
  factory DownloadAwareMediaMetadata.fromMetadata(
    MediaMetadata metadata, {
    bool isDownloaded = false,
    String? localPath,
    DownloadProgress? downloadProgress,
  }) {
    return DownloadAwareMediaMetadata(
      id: metadata.id,
      title: metadata.title,
      description: metadata.description,
      thumbnailUrl: metadata.thumbnailUrl,
      mediaType: metadata.mediaType,
      source: metadata.source,
      subtitleConfig: metadata.subtitleConfig,
      customData: metadata.customData,
      isDownloaded: isDownloaded,
      localPath: localPath,
      downloadProgress: downloadProgress,
    );
  }

  /// Get the appropriate source (local if downloaded, original otherwise)
  MediaSource get playbackSource {
    if (isDownloaded && localPath != null) {
      return LocalMediaSource(filePath: localPath!);
    }
    return source;
  }

  @override
  DownloadAwareMediaMetadata copyWith({
    String? id,
    String? title,
    String? description,
    String? thumbnailUrl,
    MediaType? mediaType,
    MediaSource? source,
    SubtitleConfig? subtitleConfig,
    Map<String, dynamic>? customData,
    bool? isDownloaded,
    String? localPath,
    DownloadProgress? downloadProgress,
  }) {
    return DownloadAwareMediaMetadata(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      mediaType: mediaType ?? this.mediaType,
      source: source ?? this.source,
      subtitleConfig: subtitleConfig ?? this.subtitleConfig,
      customData: customData ?? this.customData,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      localPath: localPath ?? this.localPath,
      downloadProgress: downloadProgress ?? this.downloadProgress,
    );
  }
}
