import '../models/media_type.dart';

/// Status of a download
enum DownloadStatus {
  pending,
  downloading,
  paused,
  completed,
  failed,
  cancelled,
}

/// Download progress information
class DownloadProgress {
  final String downloadId;
  final String mediaId;
  final DownloadStatus status;
  final int downloaded;
  final int total;
  final double progress; // 0.0 to 1.0
  final String? error;
  final String? localPath;

  const DownloadProgress({
    required this.downloadId,
    required this.mediaId,
    required this.status,
    required this.downloaded,
    required this.total,
    required this.progress,
    this.error,
    this.localPath,
  });

  DownloadProgress copyWith({
    String? downloadId,
    String? mediaId,
    DownloadStatus? status,
    int? downloaded,
    int? total,
    double? progress,
    String? error,
    String? localPath,
  }) {
    return DownloadProgress(
      downloadId: downloadId ?? this.downloadId,
      mediaId: mediaId ?? this.mediaId,
      status: status ?? this.status,
      downloaded: downloaded ?? this.downloaded,
      total: total ?? this.total,
      progress: progress ?? this.progress,
      error: error ?? this.error,
      localPath: localPath ?? this.localPath,
    );
  }

  bool get isCompleted => status == DownloadStatus.completed;
  bool get isDownloading => status == DownloadStatus.downloading;
  bool get isFailed => status == DownloadStatus.failed;
}

/// Abstract interface for download managers
/// Your downloader package should implement this interface
abstract class IDownloadManager {
  /// Start downloading a media file
  Future<String> startDownload({
    required String mediaId,
    required String url,
    required String fileName,
    Map<String, String>? headers,
    MediaType? mediaType,
  });

  /// Pause a download
  Future<void> pauseDownload(String downloadId);

  /// Resume a paused download
  Future<void> resumeDownload(String downloadId);

  /// Cancel a download
  Future<void> cancelDownload(String downloadId);

  /// Delete a downloaded file
  Future<void> deleteDownload(String downloadId);

  /// Get download progress stream
  Stream<DownloadProgress> getDownloadProgress(String downloadId);

  /// Get all downloads for a specific media ID
  Future<List<DownloadProgress>> getDownloadsForMedia(String mediaId);

  /// Check if media is downloaded
  Future<bool> isMediaDownloaded(String mediaId);

  /// Get local file path for downloaded media
  Future<String?> getLocalPath(String mediaId);

  /// Get all downloads
  Future<List<DownloadProgress>> getAllDownloads();

  /// Clear completed downloads history
  Future<void> clearCompletedDownloads();
}
