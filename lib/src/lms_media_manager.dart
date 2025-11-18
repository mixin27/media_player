import 'storage/media_storage_factory.dart';
import 'storage/media_storage_interface.dart';

/// Main entry point for LMS Media Player
/// Manages storage and provides factory methods
class LMSMediaManager {
  static LMSMediaManager? _instance;
  late final IMediaStorage _storage;

  LMSMediaManager._({required IMediaStorage storage}) : _storage = storage;

  /// Initialize the media manager
  static Future<LMSMediaManager> initialize({
    StorageType storageType = StorageType.sqflite,
  }) async {
    if (_instance != null) {
      return _instance!;
    }

    final storage = MediaStorageFactory.create(storageType);
    await storage.initialize();

    _instance = LMSMediaManager._(storage: storage);
    return _instance!;
  }

  /// Get the current instance
  static LMSMediaManager get instance {
    if (_instance == null) {
      throw StateError(
        'LMSMediaManager not initialized. Call initialize() first.',
      );
    }
    return _instance!;
  }

  /// Get the storage instance
  IMediaStorage get storage => _storage;

  /// Dispose the manager
  static Future<void> dispose() async {
    await _instance?._storage.close();
    _instance = null;
  }
}
