import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:rxdart/rxdart.dart';

import '../core/callbacks.dart';
import '../models/media_event.dart';
import '../models/media_metadata.dart';
import '../models/media_progress.dart';
import '../models/media_type.dart';
import '../storage/media_storage_interface.dart';

enum DocumentType { pdf, docx, pptx, xlsx, txt, other }

class LMSDocumentViewerController {
  final MediaMetadata metadata;
  final IMediaStorage storage;

  // Callbacks
  final MediaProgressCallback? onProgressUpdate;
  final MediaCompletionCallback? onCompletion;
  final MediaErrorCallback? onError;
  final MediaAnalyticsCallback? onAnalyticsEvent;

  // State
  final _isOpenController = BehaviorSubject<bool>.seeded(false);
  DateTime? _openedAt;

  LMSDocumentViewerController({
    required this.metadata,
    required this.storage,
    this.onProgressUpdate,
    this.onCompletion,
    this.onError,
    this.onAnalyticsEvent,
  });

  /// Get document open state stream
  Stream<bool> get isOpenStream => _isOpenController.stream;

  /// Get current open state
  bool get isOpen => _isOpenController.value;

  /// Get document type
  DocumentType get documentType => _getDocumentType();

  /// Get file path (local files only)
  String? get localFilePath {
    if (!metadata.source.isLocal) return null;
    return metadata.source.uri;
  }

  DocumentType _getDocumentType() {
    final uri = metadata.source.uri.toLowerCase();

    if (uri.endsWith('.pdf')) return DocumentType.pdf;
    if (uri.endsWith('.docx') || uri.endsWith('.doc')) return DocumentType.docx;
    if (uri.endsWith('.pptx') || uri.endsWith('.ppt')) return DocumentType.pptx;
    if (uri.endsWith('.xlsx') || uri.endsWith('.xls')) return DocumentType.xlsx;
    if (uri.endsWith('.txt')) return DocumentType.txt;

    return DocumentType.other;
  }

  /// Open document with system default app
  Future<void> openWithSystemApp() async {
    if (!metadata.source.isLocal) {
      _handleError('Cannot open remote documents with system app', null);
      return;
    }

    try {
      final result = await OpenFilex.open(metadata.source.uri);

      if (result.type == ResultType.done) {
        _markAsOpened();
        _emitAnalyticsEvent(
          MediaPlayEvent(
            mediaId: metadata.id,
            timestamp: DateTime.now(),
            mediaType: MediaType.document,
            position: Duration.zero,
          ),
        );
      } else {
        _handleError('Failed to open document: ${result.message}', null);
      }
    } catch (e) {
      _handleError('Error opening document', e);
    }
  }

  /// Mark document as opened/viewed
  Future<void> markAsViewed() async {
    _markAsOpened();
    await _markAsCompleted();
  }

  /// Mark document as completed
  Future<void> _markAsCompleted() async {
    final progress = MediaProgress(
      mediaId: metadata.id,
      currentPosition: Duration.zero,
      totalDuration: Duration.zero,
      lastWatched: DateTime.now(),
      isCompleted: true,
      mediaType: MediaType.document,
    );

    try {
      await storage.saveProgress(progress);
      onProgressUpdate?.call(progress);
      onCompletion?.call(metadata.id);

      _emitAnalyticsEvent(
        MediaCompleteEvent(
          mediaId: metadata.id,
          timestamp: DateTime.now(),
          mediaType: MediaType.document,
          watchedDuration: Duration.zero,
        ),
      );
    } catch (e) {
      debugPrint('Failed to mark document as completed: $e');
    }
  }

  void _markAsOpened() {
    _openedAt = DateTime.now();
    _isOpenController.add(true);
  }

  /// Check if document is already completed
  Future<bool> isCompleted() async {
    try {
      final progress = await storage.getProgress(metadata.id);
      return progress?.isCompleted ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Get viewing duration (time since opened)
  Duration? getViewingDuration() {
    if (_openedAt == null) return null;
    return DateTime.now().difference(_openedAt!);
  }

  void _handleError(String message, dynamic error) {
    onError?.call(metadata.id, error);

    _emitAnalyticsEvent(
      MediaErrorEvent(
        mediaId: metadata.id,
        timestamp: DateTime.now(),
        mediaType: MediaType.document,
        errorMessage: message,
        errorCode: error?.toString(),
      ),
    );
  }

  void _emitAnalyticsEvent(MediaEvent event) {
    onAnalyticsEvent?.call(event);
  }

  Future<void> dispose() async {
    await _isOpenController.close();
  }
}
