import 'in_memory_media_storage.dart';
import 'media_storage_interface.dart';
import 'sqflite_media_storage.dart';

enum StorageType { sqflite, inMemory }

class MediaStorageFactory {
  static IMediaStorage create(StorageType type) {
    switch (type) {
      case StorageType.sqflite:
        return SqfliteMediaStorage();
      case StorageType.inMemory:
        return InMemoryMediaStorage();
    }
  }
}
