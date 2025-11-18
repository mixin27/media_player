import '../models/media_progress.dart';
import '../models/media_type.dart';

/// Abstract storage interface for testability and flexibility
abstract class IMediaStorage {
  Future<void> initialize();
  Future<void> saveProgress(MediaProgress progress);
  Future<MediaProgress?> getProgress(String mediaId);
  Future<List<MediaProgress>> getAllProgress();
  Future<List<MediaProgress>> getProgressByType(MediaType mediaType);
  Future<void> deleteProgress(String mediaId);
  Future<void> clearAllProgress();
  Future<List<MediaProgress>> getWatchHistory({int limit = 50});
  Future<void> close();
}
