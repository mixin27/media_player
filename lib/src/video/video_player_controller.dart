import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart' hide SubtitleTrack;
import 'package:media_kit_video/media_kit_video.dart';
import 'package:rxdart/rxdart.dart';

import '../core/callbacks.dart';
import '../core/media_config.dart';
import '../core/media_player_state.dart';
import '../models/media_event.dart';
import '../models/media_metadata.dart';
import '../models/media_progress.dart';
import '../models/media_type.dart';
import '../models/subtitle_track.dart';
import '../storage/media_storage_interface.dart';
import 'subtitle_controller.dart';

class LMSVideoPlayerController {
  final MediaMetadata metadata;
  final MediaPlayerConfig config;
  final IMediaStorage storage;
  final List<SubtitleTrack>? subtitleTracks;

  // Callbacks
  final MediaProgressCallback? onProgressUpdate;
  final MediaCompletionCallback? onCompletion;
  final MediaErrorCallback? onError;
  final MediaAnalyticsCallback? onAnalyticsEvent;
  final MediaStateChangeCallback? onStateChange;

  // Media Kit player
  late final Player _player;
  late final VideoController _videoController;

  // Subtitle controller
  SubtitleController? _subtitleController;

  // State streams
  final _stateController = BehaviorSubject<MediaPlayerState>.seeded(
    const MediaPlayerState(),
  );

  // Stream subscriptions for cleanup
  final List<StreamSubscription> _subscriptions = [];

  Timer? _progressTimer;
  Duration _lastSavedPosition = Duration.zero;
  bool _hasResumed = false;
  DateTime? _lastSaveTime;
  bool _isResuming = false;

  LMSVideoPlayerController({
    required this.metadata,
    required this.config,
    required this.storage,
    this.subtitleTracks,
    this.onProgressUpdate,
    this.onCompletion,
    this.onError,
    this.onAnalyticsEvent,
    this.onStateChange,
  }) {
    _initialize();
  }

  /// Get the video controller for UI
  VideoController get videoController => _videoController;

  /// Get subtitle controller
  SubtitleController? get subtitleController => _subtitleController;

  /// Get current state stream
  Stream<MediaPlayerState> get stateStream => _stateController.stream;

  /// Get current state value
  MediaPlayerState get state => _stateController.value;

  void _initialize() async {
    try {
      // Create player with configuration
      _player = Player(
        configuration: const PlayerConfiguration(title: 'LMS Media Player'),
      );
      _videoController = VideoController(_player);

      // Initialize subtitle controller if tracks provided
      if (subtitleTracks != null && subtitleTracks!.isNotEmpty) {
        _subtitleController = SubtitleController(
          availableTracks: subtitleTracks!,
        );

        // Load default subtitle if configured
        if (metadata.subtitleConfig?.enabled == true &&
            metadata.subtitleConfig?.subtitleUrl != null) {
          final defaultTrack = subtitleTracks!.firstWhere(
            (t) => t.url == metadata.subtitleConfig!.subtitleUrl,
            orElse: () => subtitleTracks!.first,
          );

          await _subtitleController!.loadTrack(
            defaultTrack,
            headers: metadata.source.headers,
          );
        }
      }

      // Load saved progress if auto-resume is enabled BEFORE setting up listeners
      if (config.autoResume) {
        await _loadAndResumeProgress();
      }

      // Set up listeners
      _setupListeners();

      // Load media
      await _loadMedia();

      // Auto-play if configured
      if (config.autoPlay) {
        await play();
      }
    } catch (e) {
      _handleError('Initialization failed', e);
    }
  }

  void _setupListeners() {
    // Listen to playback state
    _subscriptions.add(
      _player.stream.playing.listen((isPlaying) {
        _updateState(isPlaying: isPlaying);

        if (isPlaying) {
          _startProgressTracking();
          _emitAnalyticsEvent(
            MediaPlayEvent(
              mediaId: metadata.id,
              timestamp: DateTime.now(),
              mediaType: MediaType.video,
              position: state.position,
            ),
          );
        } else {
          _stopProgressTracking();
          _emitAnalyticsEvent(
            MediaPauseEvent(
              mediaId: metadata.id,
              timestamp: DateTime.now(),
              mediaType: MediaType.video,
              position: state.position,
            ),
          );
        }
      }),
    );

    // Listen to position
    _subscriptions.add(
      _player.stream.position.listen((position) {
        // Don't update state while resuming to avoid conflicts
        if (!_isResuming) {
          _updateState(position: position);
          _checkCompletion();

          // Update subtitle position
          _subtitleController?.updatePosition(position);
        }
      }),
    );

    // Listen to duration
    _subscriptions.add(
      _player.stream.duration.listen((duration) {
        _updateState(duration: duration);
      }),
    );

    // Listen to buffering
    _subscriptions.add(
      _player.stream.buffering.listen((isBuffering) {
        _updateState(isBuffering: isBuffering);
      }),
    );

    // Listen to errors
    _subscriptions.add(
      _player.stream.error.listen((error) {
        _handleError('Playback error', error);
      }),
    );

    // Listen to completed
    _subscriptions.add(
      _player.stream.completed.listen((completed) {
        if (completed) {
          _handleCompletion();
        }
      }),
    );
  }

  Future<void> _loadMedia() async {
    final media = Media(
      metadata.source.uri,
      httpHeaders: metadata.source.headers ?? {},
    );

    // Open media without auto-playing
    await _player.open(
      media,
      play: false, // Don't auto-play
    );

    await _player.setRate(config.defaultSpeed);

    // Resume from saved position if needed
    if (_hasResumed && _lastSavedPosition > Duration.zero && !_isResuming) {
      _isResuming = true;

      try {
        // Wait for duration to be available with timeout
        final duration = await _player.stream.duration
            .firstWhere((d) => d > Duration.zero, orElse: () => Duration.zero)
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () => Duration.zero,
            );

        if (duration > Duration.zero) {
          // Wait a bit for player to stabilize
          await Future.delayed(const Duration(milliseconds: 300));

          // Seek to saved position
          await _player.seek(_lastSavedPosition);
          debugPrint(
            '✅ Resumed video at ${_lastSavedPosition.inSeconds}s / ${duration.inSeconds}s',
          );
        }
      } catch (e) {
        debugPrint('❌ Failed to resume: $e');
      } finally {
        _isResuming = false;
      }
    }
  }

  Future<void> _loadAndResumeProgress() async {
    try {
      final progress = await storage.getProgress(metadata.id);
      if (progress != null && !progress.isCompleted) {
        _lastSavedPosition = progress.currentPosition;
        _hasResumed = true;
        debugPrint('📍 Found saved position: ${_lastSavedPosition.inSeconds}s');
      } else {
        debugPrint('📍 No saved position found or video completed');
      }
    } catch (e) {
      debugPrint('📍 Failed to load progress: $e');
    }
  }

  void _startProgressTracking() {
    _stopProgressTracking();

    _progressTimer = Timer.periodic(
      Duration(seconds: config.progressSaveInterval),
      (_) => _saveProgress(),
    );
  }

  void _stopProgressTracking() {
    _progressTimer?.cancel();
    _progressTimer = null;
  }

  Future<void> _saveProgress() async {
    final currentState = state;

    // Throttle saves to at most once per second
    final now = DateTime.now();
    if (_lastSaveTime != null &&
        now.difference(_lastSaveTime!).inMilliseconds < 1000) {
      return;
    }

    // Don't save if position hasn't changed significantly
    if ((currentState.position - _lastSavedPosition).abs().inSeconds < 2) {
      return;
    }

    final progress = MediaProgress(
      mediaId: metadata.id,
      currentPosition: currentState.position,
      totalDuration: currentState.duration,
      lastWatched: DateTime.now(),
      isCompleted: currentState.isCompleted,
      mediaType: MediaType.video,
    );

    try {
      await storage.saveProgress(progress);
      _lastSavedPosition = currentState.position;
      _lastSaveTime = now;
      onProgressUpdate?.call(progress);
    } catch (e) {
      debugPrint('Failed to save progress: $e');
    }
  }

  void _checkCompletion() {
    final currentState = state;

    if (currentState.duration == Duration.zero) return;

    final completionRatio =
        currentState.position.inMilliseconds /
        currentState.duration.inMilliseconds;

    if (completionRatio >= config.completionThreshold &&
        !currentState.isCompleted) {
      _handleCompletion();
    }
  }

  void _handleCompletion() {
    _updateState(isCompleted: true);

    final progress = MediaProgress(
      mediaId: metadata.id,
      currentPosition: state.duration,
      totalDuration: state.duration,
      lastWatched: DateTime.now(),
      isCompleted: true,
      mediaType: MediaType.video,
    );

    storage.saveProgress(progress);
    onProgressUpdate?.call(progress);
    onCompletion?.call(metadata.id);

    _emitAnalyticsEvent(
      MediaCompleteEvent(
        mediaId: metadata.id,
        timestamp: DateTime.now(),
        mediaType: MediaType.video,
        watchedDuration: state.duration,
      ),
    );
  }

  void _handleError(String message, dynamic error) {
    _updateState(error: message);
    onError?.call(metadata.id, error);

    _emitAnalyticsEvent(
      MediaErrorEvent(
        mediaId: metadata.id,
        timestamp: DateTime.now(),
        mediaType: MediaType.video,
        errorMessage: message,
        errorCode: error?.toString(),
      ),
    );
  }

  void _emitAnalyticsEvent(MediaEvent event) {
    onAnalyticsEvent?.call(event);
  }

  void _updateState({
    bool? isPlaying,
    bool? isBuffering,
    bool? isCompleted,
    Duration? position,
    Duration? duration,
    double? speed,
    String? error,
    double? volume,
  }) {
    // Don't update if controller is closed
    if (_stateController.isClosed) {
      return;
    }

    final newState = state.copyWith(
      isPlaying: isPlaying,
      isBuffering: isBuffering,
      isCompleted: isCompleted,
      position: position,
      duration: duration,
      speed: speed,
      error: error,
      volume: volume,
    );

    _stateController.add(newState);
    onStateChange?.call(newState);
  }

  // Public control methods

  Future<void> play() async {
    await _player.play();
  }

  Future<void> pause() async {
    await _player.pause();
    await _saveProgress();
  }

  Future<void> seek(Duration position) async {
    final fromPosition = state.position;
    await _player.seek(position);

    _emitAnalyticsEvent(
      MediaSeekEvent(
        mediaId: metadata.id,
        timestamp: DateTime.now(),
        mediaType: MediaType.video,
        fromPosition: fromPosition,
        toPosition: position,
      ),
    );

    await _saveProgress();
  }

  Future<void> setSpeed(double speed) async {
    await _player.setRate(speed);
    _updateState(speed: speed);

    _emitAnalyticsEvent(
      MediaSpeedChangeEvent(
        mediaId: metadata.id,
        timestamp: DateTime.now(),
        mediaType: MediaType.video,
        speed: speed,
      ),
    );
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume * 100); // Media Kit uses 0-100
    _updateState(volume: volume);
  }

  Future<void> replay() async {
    await seek(Duration.zero);
    await play();
  }

  Future<void> dispose() async {
    await _saveProgress();
    _stopProgressTracking();

    // Cancel all subscriptions first
    for (var subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();

    // Close stream controller
    await _stateController.close();

    // Dispose subtitle controller
    _subtitleController?.dispose();

    // Dispose player
    await _player.dispose();
  }
}
