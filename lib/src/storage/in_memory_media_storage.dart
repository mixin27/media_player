import '../models/media_progress.dart';
import '../models/media_type.dart';
import 'media_storage_interface.dart';

/// In-memory storage for testing or temporary use
class InMemoryMediaStorage implements IMediaStorage {
  final Map<String, MediaProgress> _storage = {};

  @override
  Future<void> initialize() async {
    // No initialization needed
  }

  @override
  Future<void> saveProgress(MediaProgress progress) async {
    _storage[progress.mediaId] = progress;
  }

  @override
  Future<MediaProgress?> getProgress(String mediaId) async {
    return _storage[mediaId];
  }

  @override
  Future<List<MediaProgress>> getAllProgress() async {
    final list = _storage.values.toList();
    list.sort((a, b) => b.lastWatched.compareTo(a.lastWatched));
    return list;
  }

  @override
  Future<List<MediaProgress>> getProgressByType(MediaType mediaType) async {
    final list = _storage.values
        .where((p) => p.mediaType == mediaType)
        .toList();
    list.sort((a, b) => b.lastWatched.compareTo(a.lastWatched));
    return list;
  }

  @override
  Future<void> deleteProgress(String mediaId) async {
    _storage.remove(mediaId);
  }

  @override
  Future<void> clearAllProgress() async {
    _storage.clear();
  }

  @override
  Future<List<MediaProgress>> getWatchHistory({int limit = 50}) async {
    final list = await getAllProgress();
    return list.take(limit).toList();
  }

  @override
  Future<void> close() async {
    _storage.clear();
  }
}
