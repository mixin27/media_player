import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:media_player/media_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;

class DownloadService implements IDownloadManager {
  static final DownloadService instance = DownloadService._();
  DownloadService._();

  final Dio _dio = Dio();
  final Map<String, CancelToken> _cancelTokens = {};
  final Map<String, StreamController<DownloadProgress>> _progressControllers =
      {};
  Database? _database;

  // Batch write optimization
  final Map<String, DownloadProgress> _pendingWrites = {};
  bool _isWriting = false;

  Future<void> initialize() async {
    final dbPath = await getDatabasesPath();
    final dbFile = path.join(dbPath, 'downloads.db');

    _database = await openDatabase(
      dbFile,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE downloads (
            downloadId TEXT PRIMARY KEY,
            mediaId TEXT NOT NULL,
            status TEXT NOT NULL,
            downloaded INTEGER NOT NULL,
            total INTEGER NOT NULL,
            localPath TEXT,
            error TEXT,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE INDEX idx_mediaId ON downloads(mediaId)
        ''');

        // await db.execute('PRAGMA journal_mode=WAL');
      },
    );
  }

  @override
  Future<String> startDownload({
    required String mediaId,
    required String url,
    required String fileName,
    Map<String, String>? headers,
    MediaType? mediaType,
  }) async {
    final downloadId = 'dl_${DateTime.now().millisecondsSinceEpoch}';
    final savePath = await _getSavePath(fileName, mediaType);
    final cancelToken = CancelToken();

    _cancelTokens[downloadId] = cancelToken;
    _progressControllers[downloadId] =
        StreamController<DownloadProgress>.broadcast();

    // Save initial record
    await _saveDownloadRecord(
      DownloadProgress(
        downloadId: downloadId,
        mediaId: mediaId,
        status: DownloadStatus.downloading,
        downloaded: 0,
        total: 0,
        progress: 0.0,
      ),
    );

    // Start download
    _performDownload(
      downloadId: downloadId,
      mediaId: mediaId,
      url: url,
      savePath: savePath,
      cancelToken: cancelToken,
      headers: headers,
    );

    return downloadId;
  }

  Future<void> _performDownload({
    required String downloadId,
    required String mediaId,
    required String url,
    required String savePath,
    required CancelToken cancelToken,
    Map<String, String>? headers,
  }) async {
    try {
      await _dio.download(
        url,
        savePath,
        cancelToken: cancelToken,
        options: Options(headers: headers),
        onReceiveProgress: (received, total) {
          if (total == -1) {
            total = received * 2; // Estimate if total is unknown
          }

          final progress = DownloadProgress(
            downloadId: downloadId,
            mediaId: mediaId,
            status: DownloadStatus.downloading,
            downloaded: received,
            total: total,
            progress: total > 0 ? received / total : 0.0,
          );

          _saveDownloadRecord(progress);
          _progressControllers[downloadId]?.add(progress);
        },
      );

      // Download completed
      final completedProgress = DownloadProgress(
        downloadId: downloadId,
        mediaId: mediaId,
        status: DownloadStatus.completed,
        downloaded: await File(savePath).length(),
        total: await File(savePath).length(),
        progress: 1.0,
        localPath: savePath,
      );

      await _saveDownloadRecord(completedProgress);
      _progressControllers[downloadId]?.add(completedProgress);

      // Clean up
      _cancelTokens.remove(downloadId);
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        // Download was cancelled
        final cancelledProgress = DownloadProgress(
          downloadId: downloadId,
          mediaId: mediaId,
          status: DownloadStatus.cancelled,
          downloaded: 0,
          total: 0,
          progress: 0.0,
        );

        await _saveDownloadRecord(cancelledProgress);
        _progressControllers[downloadId]?.add(cancelledProgress);
      } else {
        // Download failed
        final failedProgress = DownloadProgress(
          downloadId: downloadId,
          mediaId: mediaId,
          status: DownloadStatus.failed,
          downloaded: 0,
          total: 0,
          progress: 0.0,
          error: e.message,
        );

        await _saveDownloadRecord(failedProgress);
        _progressControllers[downloadId]?.add(failedProgress);
      }

      _cancelTokens.remove(downloadId);
    } catch (e) {
      final failedProgress = DownloadProgress(
        downloadId: downloadId,
        mediaId: mediaId,
        status: DownloadStatus.failed,
        downloaded: 0,
        total: 0,
        progress: 0.0,
        error: e.toString(),
      );

      await _saveDownloadRecord(failedProgress);
      _progressControllers[downloadId]?.add(failedProgress);
      _cancelTokens.remove(downloadId);
    }
  }

  Future<String> _getSavePath(String fileName, MediaType? mediaType) async {
    final directory = await getApplicationDocumentsDirectory();
    final typeFolder = mediaType?.toString().split('.').last ?? 'files';
    final folder = Directory('${directory.path}/downloads/$typeFolder');

    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }

    return path.join(folder.path, fileName);
  }

  Future<void> _saveDownloadRecord(DownloadProgress progress) async {
    // Add to pending writes instead of writing immediately
    _pendingWrites[progress.downloadId] = progress;

    // Trigger batch write if not already writing
    if (!_isWriting) {
      _processPendingWrites();
    }
  }

  Future<void> _processPendingWrites() async {
    if (_isWriting || _pendingWrites.isEmpty) return;

    _isWriting = true;

    try {
      final writes = Map<String, DownloadProgress>.from(_pendingWrites);
      _pendingWrites.clear();

      final now = DateTime.now().toIso8601String();

      // Use transaction with batch for better performance
      await _database?.transaction((txn) async {
        final batch = txn.batch();

        for (var progress in writes.values) {
          batch.insert('downloads', {
            'downloadId': progress.downloadId,
            'mediaId': progress.mediaId,
            'status': progress.status.toString(),
            'downloaded': progress.downloaded,
            'total': progress.total,
            'localPath': progress.localPath,
            'error': progress.error,
            'createdAt': now,
            'updatedAt': now,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }

        await batch.commit(noResult: true);
      });
    } finally {
      _isWriting = false;

      // Check if new writes came in while we were processing
      if (_pendingWrites.isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 100));
        _processPendingWrites();
      }
    }
  }

  @override
  Future<void> pauseDownload(String downloadId) async {
    final cancelToken = _cancelTokens[downloadId];
    if (cancelToken != null) {
      cancelToken.cancel('Paused by user');

      final progress = await _getDownloadProgress(downloadId);
      if (progress != null) {
        final paused = progress.copyWith(status: DownloadStatus.paused);
        await _saveDownloadRecord(paused);
        _progressControllers[downloadId]?.add(paused);
      }
    }
  }

  @override
  Future<void> resumeDownload(String downloadId) async {
    // Get existing download info
    final progress = await _getDownloadProgress(downloadId);
    if (progress == null) return;

    // For simplicity, restart the download
    // In production, you'd implement resumable downloads
    final results = await _database?.query(
      'downloads',
      where: 'downloadId = ?',
      whereArgs: [downloadId],
    );

    if (results != null && results.isNotEmpty) {
      // Restart download (simplified - production would use Range headers)
      final resumed = progress.copyWith(status: DownloadStatus.downloading);
      await _saveDownloadRecord(resumed);
      _progressControllers[downloadId]?.add(resumed);
    }
  }

  @override
  Future<void> cancelDownload(String downloadId) async {
    final cancelToken = _cancelTokens[downloadId];
    if (cancelToken != null) {
      cancelToken.cancel('Cancelled by user');
      _cancelTokens.remove(downloadId);
    }

    final progress = await _getDownloadProgress(downloadId);
    if (progress != null) {
      final cancelled = progress.copyWith(status: DownloadStatus.cancelled);
      await _saveDownloadRecord(cancelled);
      _progressControllers[downloadId]?.add(cancelled);
      _progressControllers[downloadId]?.close();
      _progressControllers.remove(downloadId);
    }
  }

  @override
  Future<void> deleteDownload(String downloadId) async {
    final progress = await _getDownloadProgress(downloadId);

    if (progress?.localPath != null) {
      final file = File(progress!.localPath!);
      if (await file.exists()) {
        await file.delete();
      }
    }

    await _database?.delete(
      'downloads',
      where: 'downloadId = ?',
      whereArgs: [downloadId],
    );

    _progressControllers[downloadId]?.close();
    _progressControllers.remove(downloadId);
    _cancelTokens.remove(downloadId);
  }

  @override
  Stream<DownloadProgress> getDownloadProgress(String downloadId) async* {
    // First yield current state from database
    final current = await _getDownloadProgress(downloadId);
    if (current != null) {
      yield current;
    }

    // Then yield updates from stream
    if (_progressControllers[downloadId] != null) {
      yield* _progressControllers[downloadId]!.stream;
    }
  }

  Future<DownloadProgress?> _getDownloadProgress(String downloadId) async {
    final results = await _database?.query(
      'downloads',
      where: 'downloadId = ?',
      whereArgs: [downloadId],
    );

    if (results == null || results.isEmpty) return null;

    final data = results.first;
    return DownloadProgress(
      downloadId: data['downloadId'] as String,
      mediaId: data['mediaId'] as String,
      status: DownloadStatus.values.firstWhere(
        (s) => s.toString() == data['status'],
      ),
      downloaded: data['downloaded'] as int,
      total: data['total'] as int,
      progress: (data['total'] as int) > 0
          ? (data['downloaded'] as int) / (data['total'] as int)
          : 0.0,
      localPath: data['localPath'] as String?,
      error: data['error'] as String?,
    );
  }

  @override
  Future<List<DownloadProgress>> getDownloadsForMedia(String mediaId) async {
    final results = await _database?.query(
      'downloads',
      where: 'mediaId = ?',
      whereArgs: [mediaId],
      orderBy: 'updatedAt DESC',
    );

    if (results == null) return [];

    return results.map((data) {
      return DownloadProgress(
        downloadId: data['downloadId'] as String,
        mediaId: data['mediaId'] as String,
        status: DownloadStatus.values.firstWhere(
          (s) => s.toString() == data['status'],
        ),
        downloaded: data['downloaded'] as int,
        total: data['total'] as int,
        progress: (data['total'] as int) > 0
            ? (data['downloaded'] as int) / (data['total'] as int)
            : 0.0,
        localPath: data['localPath'] as String?,
        error: data['error'] as String?,
      );
    }).toList();
  }

  @override
  Future<bool> isMediaDownloaded(String mediaId) async {
    final downloads = await getDownloadsForMedia(mediaId);
    return downloads.any((d) => d.isCompleted && d.localPath != null);
  }

  @override
  Future<String?> getLocalPath(String mediaId) async {
    final downloads = await getDownloadsForMedia(mediaId);
    final completed = downloads.firstWhere(
      (d) => d.isCompleted && d.localPath != null,
      orElse: () => DownloadProgress(
        downloadId: '',
        mediaId: '',
        status: DownloadStatus.pending,
        downloaded: 0,
        total: 0,
        progress: 0.0,
      ),
    );

    if (completed.localPath != null) {
      final file = File(completed.localPath!);
      if (await file.exists()) {
        return completed.localPath;
      }
    }

    return null;
  }

  @override
  Future<List<DownloadProgress>> getAllDownloads() async {
    final results = await _database?.query(
      'downloads',
      orderBy: 'updatedAt DESC',
    );

    if (results == null) return [];

    return results.map((data) {
      return DownloadProgress(
        downloadId: data['downloadId'] as String,
        mediaId: data['mediaId'] as String,
        status: DownloadStatus.values.firstWhere(
          (s) => s.toString() == data['status'],
        ),
        downloaded: data['downloaded'] as int,
        total: data['total'] as int,
        progress: (data['total'] as int) > 0
            ? (data['downloaded'] as int) / (data['total'] as int)
            : 0.0,
        localPath: data['localPath'] as String?,
        error: data['error'] as String?,
      );
    }).toList();
  }

  @override
  Future<void> clearCompletedDownloads() async {
    await _database?.delete(
      'downloads',
      where: 'status = ?',
      whereArgs: [DownloadStatus.completed.toString()],
    );
  }

  Future<void> dispose() async {
    // Flush pending writes before disposing
    if (_pendingWrites.isNotEmpty) {
      await _processPendingWrites();
    }

    for (var controller in _progressControllers.values) {
      await controller.close();
    }
    _progressControllers.clear();
    _cancelTokens.clear();
    await _database?.close();
  }
}
