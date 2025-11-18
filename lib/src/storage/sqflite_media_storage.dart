import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/media_progress.dart';
import '../models/media_type.dart';
import 'media_storage_interface.dart';

class SqfliteMediaStorage implements IMediaStorage {
  static const String _databaseName = 'lms_media_player.db';
  static const int _databaseVersion = 1;
  static const String _tableName = 'media_progress';

  Database? _database;
  final Map<String, MediaProgress> _pendingWrites = {};
  bool _isWriting = false;

  @override
  Future<void> initialize() async {
    if (_database != null) return;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    _database = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        mediaId TEXT PRIMARY KEY,
        currentPosition INTEGER NOT NULL,
        totalDuration INTEGER NOT NULL,
        lastWatched TEXT NOT NULL,
        isCompleted INTEGER NOT NULL,
        mediaType TEXT NOT NULL
      )
    ''');

    // Create index for faster queries
    await db.execute('''
      CREATE INDEX idx_lastWatched ON $_tableName(lastWatched DESC)
    ''');

    await db.execute('''
      CREATE INDEX idx_mediaType ON $_tableName(mediaType)
    ''');

    // Enable Write-Ahead Logging
    // await db.execute('PRAGMA journal_mode=WAL');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle future schema migrations
  }

  Database get _db {
    if (_database == null) {
      throw StateError('Database not initialized. Call initialize() first.');
    }
    return _database!;
  }

  @override
  Future<void> saveProgress(MediaProgress progress) async {
    // Add to pending writes instead of writing immediately
    _pendingWrites[progress.mediaId] = progress;

    // Trigger batch write if not already writing
    if (!_isWriting) {
      _processPendingWrites();
    }
  }

  Future<void> _processPendingWrites() async {
    if (_isWriting || _pendingWrites.isEmpty) return;

    _isWriting = true;

    try {
      // Get all pending writes
      final writes = Map<String, MediaProgress>.from(_pendingWrites);
      _pendingWrites.clear();

      // Use batch operation for multiple writes
      await _db.transaction((txn) async {
        final batch = txn.batch();

        for (var progress in writes.values) {
          batch.insert(
            _tableName,
            progress.toJson(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        await batch.commit(noResult: true);
      });
      debugPrint(
        '[SqfliteMediaStorage]: batch commit complete: Total = ${writes.length}',
      );
    } finally {
      _isWriting = false;

      // Check if new writes came in while we were processing
      if (_pendingWrites.isNotEmpty) {
        // Wait a bit before next batch to avoid constant writing
        await Future.delayed(const Duration(milliseconds: 500));
        _processPendingWrites();
      }
    }
  }

  @override
  Future<MediaProgress?> getProgress(String mediaId) async {
    // Check pending writes first
    if (_pendingWrites.containsKey(mediaId)) {
      return _pendingWrites[mediaId];
    }

    final results = await _db.query(
      _tableName,
      where: 'mediaId = ?',
      whereArgs: [mediaId],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return MediaProgress.fromJson(results.first);
  }

  @override
  Future<List<MediaProgress>> getAllProgress() async {
    final results = await _db.query(_tableName, orderBy: 'lastWatched DESC');

    return results.map((json) => MediaProgress.fromJson(json)).toList();
  }

  @override
  Future<List<MediaProgress>> getProgressByType(MediaType mediaType) async {
    final results = await _db.query(
      _tableName,
      where: 'mediaType = ?',
      whereArgs: [mediaType.toString()],
      orderBy: 'lastWatched DESC',
    );

    return results.map((json) => MediaProgress.fromJson(json)).toList();
  }

  @override
  Future<void> deleteProgress(String mediaId) async {
    // Remove from pending writes if present
    _pendingWrites.remove(mediaId);

    await _db.delete(_tableName, where: 'mediaId = ?', whereArgs: [mediaId]);
  }

  @override
  Future<void> clearAllProgress() async {
    // Clear pending writes
    _pendingWrites.clear();

    await _db.delete(_tableName);
  }

  @override
  Future<List<MediaProgress>> getWatchHistory({int limit = 50}) async {
    final results = await _db.query(
      _tableName,
      orderBy: 'lastWatched DESC',
      limit: limit,
    );

    return results.map((json) => MediaProgress.fromJson(json)).toList();
  }

  @override
  Future<void> close() async {
    // Flush any pending writes before closing
    if (_pendingWrites.isNotEmpty) {
      await _processPendingWrites();
    }

    await _database?.close();
    _database = null;
  }
}
