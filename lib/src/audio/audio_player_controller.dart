import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

import '../core/callbacks.dart';
import '../core/media_config.dart';
import '../core/media_player_state.dart';
import '../models/media_event.dart';
import '../models/media_metadata.dart';
import '../models/media_progress.dart';
import '../models/media_type.dart';
import '../storage/media_storage_interface.dart';

/// LMS audio player controller
class LMSAudioPlayerController {
  final MediaMetadata metadata;
  final MediaPlayerConfig config;
  final IMediaStorage storage;

  // Callbacks
  final MediaProgressCallback? onProgressUpdate;
  final MediaCompletionCallback? onCompletion;
  final MediaErrorCallback? onError;
  final MediaAnalyticsCallback? onAnalyticsEvent;
  final MediaStateChangeCallback? onStateChange;

  // Just Audio player
  late final AudioPlayer _player;

  // Static audio handler (singleton across all audio players)
  static AudioHandler? _sharedAudioHandler;

  // State streams
  final _stateController = BehaviorSubject<MediaPlayerState>.seeded(
    const MediaPlayerState(),
  );

  // Stream subscriptions for cleanup
  final List<StreamSubscription> _subscriptions = [];

  Timer? _progressTimer;
  Duration _lastSavedPosition = Duration.zero;
  bool _hasResumed = false;
  bool _isInitialized = false;
  DateTime? _lastSaveTime;

  LMSAudioPlayerController({
    required this.metadata,
    required this.config,
    required this.storage,
    this.onProgressUpdate,
    this.onCompletion,
    this.onError,
    this.onAnalyticsEvent,
    this.onStateChange,
  }) {
    _initialize();
  }

  /// Get the audio player instance
  AudioPlayer get player => _player;

  /// Get current state stream
  Stream<MediaPlayerState> get stateStream => _stateController.stream;

  /// Get current state value
  MediaPlayerState get state => _stateController.value;

  Future<void> _initialize() async {
    try {
      _player = AudioPlayer();

      // Initialize audio service if background audio is enabled
      if (config.enableBackgroundAudio) {
        await _initializeAudioService();
      }

      // Set up listeners
      _setupListeners();

      // Load saved progress if auto-resume is enabled
      if (config.autoResume) {
        await _loadAndResumeProgress();
      }

      // Load media
      await _loadMedia();

      _isInitialized = true;

      // Auto-play if configured
      if (config.autoPlay) {
        await play();
      }
    } catch (e) {
      _handleError('Initialization failed', e);
    }
  }

  Future<void> _initializeAudioService() async {
    if (!config.showNotificationControls) return;

    try {
      // Use shared audio handler (singleton)
      _sharedAudioHandler ??= await AudioService.init(
        builder: () => _LMSAudioHandler(),
        config: const AudioServiceConfig(
          androidNotificationChannelId:
              'dev.mixin27.lms_media_player_example.channel.audio',
          androidNotificationChannelName: 'LMS Audio Player',
          androidNotificationOngoing: true,
          androidStopForegroundOnPause: true,
        ),
      );

      // Update handler with current player
      if (_sharedAudioHandler != null) {
        (_sharedAudioHandler as _LMSAudioHandler).updatePlayer(_player);

        // Set media item for notification
        (_sharedAudioHandler!.mediaItem as dynamic).add(
          MediaItem(
            id: metadata.id,
            title: metadata.title,
            artist: metadata.description ?? '',
            artUri: metadata.thumbnailUrl != null
                ? Uri.parse(metadata.thumbnailUrl!)
                : null,
            duration: Duration.zero,
          ),
        );
      }
    } catch (e) {
      debugPrint('Failed to initialize audio service: $e');
    }
  }

  void _setupListeners() {
    // Listen to player state
    _subscriptions.add(
      _player.playerStateStream.listen((playerState) {
        final isPlaying = playerState.playing;
        final isBuffering =
            playerState.processingState == ProcessingState.buffering ||
            playerState.processingState == ProcessingState.loading;

        _updateState(isPlaying: isPlaying, isBuffering: isBuffering);

        if (isPlaying) {
          _startProgressTracking();
          _emitAnalyticsEvent(
            MediaPlayEvent(
              mediaId: metadata.id,
              timestamp: DateTime.now(),
              mediaType: MediaType.audio,
              position: state.position,
            ),
          );
        } else {
          _stopProgressTracking();
          if (_isInitialized) {
            _emitAnalyticsEvent(
              MediaPauseEvent(
                mediaId: metadata.id,
                timestamp: DateTime.now(),
                mediaType: MediaType.audio,
                position: state.position,
              ),
            );
          }
        }

        // Handle completion
        if (playerState.processingState == ProcessingState.completed) {
          _handleCompletion();
        }
      }),
    );

    // Listen to position
    _subscriptions.add(
      _player.positionStream.listen((position) {
        _updateState(position: position);
        _checkCompletion();
        // Audio handler updates are handled internally by _LMSAudioHandler
      }),
    );

    // Listen to duration
    _subscriptions.add(
      _player.durationStream.listen((duration) {
        if (duration != null) {
          _updateState(duration: duration);
          // Update media item with duration
          if (_sharedAudioHandler != null) {
            (_sharedAudioHandler!.mediaItem as dynamic).add(
              MediaItem(
                id: metadata.id,
                title: metadata.title,
                artist: metadata.description ?? '',
                artUri: metadata.thumbnailUrl != null
                    ? Uri.parse(metadata.thumbnailUrl!)
                    : null,
                duration: duration,
              ),
            );
          }
        }
      }),
    );

    // Listen to volume
    _subscriptions.add(
      _player.volumeStream.listen((volume) {
        _updateState(volume: volume);
      }),
    );

    // Listen to speed
    _subscriptions.add(
      _player.speedStream.listen((speed) {
        _updateState(speed: speed);
        // Audio handler speed is handled internally by _LMSAudioHandler
      }),
    );
  }

  Future<void> _loadMedia() async {
    try {
      final source = metadata.source.uri;

      if (metadata.source.isLocal) {
        await _player.setFilePath(source);
      } else {
        await _player.setUrl(source, headers: metadata.source.headers);
      }

      await _player.setSpeed(config.defaultSpeed);

      // Resume from saved position after media is loaded
      if (_hasResumed && _lastSavedPosition > Duration.zero) {
        await _player.seek(_lastSavedPosition);
      }
    } catch (e) {
      _handleError('Failed to load media', e);
    }
  }

  Future<void> _loadAndResumeProgress() async {
    try {
      final progress = await storage.getProgress(metadata.id);
      if (progress != null && !progress.isCompleted) {
        _lastSavedPosition = progress.currentPosition;
        _hasResumed = true;
      }
    } catch (e) {
      debugPrint('Failed to load progress: $e');
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

    if ((currentState.position - _lastSavedPosition).abs().inSeconds < 2) {
      return;
    }

    final progress = MediaProgress(
      mediaId: metadata.id,
      currentPosition: currentState.position,
      totalDuration: currentState.duration,
      lastWatched: DateTime.now(),
      isCompleted: currentState.isCompleted,
      mediaType: MediaType.audio,
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
      mediaType: MediaType.audio,
    );

    storage.saveProgress(progress);
    onProgressUpdate?.call(progress);
    onCompletion?.call(metadata.id);

    _emitAnalyticsEvent(
      MediaCompleteEvent(
        mediaId: metadata.id,
        timestamp: DateTime.now(),
        mediaType: MediaType.audio,
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
        mediaType: MediaType.audio,
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
    if (!_hasResumed && _lastSavedPosition > Duration.zero) {
      await _player.seek(_lastSavedPosition);
      _hasResumed = true;
    }

    await _player.play();

    // Update audio handler if it exists
    if (_sharedAudioHandler != null) {
      await _sharedAudioHandler!.play();
    }
  }

  Future<void> pause() async {
    await _player.pause();
    await _saveProgress();

    // Update audio handler if it exists
    if (_sharedAudioHandler != null) {
      await _sharedAudioHandler!.pause();
    }
  }

  Future<void> seek(Duration position) async {
    final fromPosition = state.position;
    await _player.seek(position);

    _emitAnalyticsEvent(
      MediaSeekEvent(
        mediaId: metadata.id,
        timestamp: DateTime.now(),
        mediaType: MediaType.audio,
        fromPosition: fromPosition,
        toPosition: position,
      ),
    );

    await _saveProgress();

    // Update audio handler if it exists
    if (_sharedAudioHandler != null) {
      await _sharedAudioHandler!.seek(position);
    }
  }

  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);

    _emitAnalyticsEvent(
      MediaSpeedChangeEvent(
        mediaId: metadata.id,
        timestamp: DateTime.now(),
        mediaType: MediaType.audio,
        speed: speed,
      ),
    );
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume);
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

    // Dispose player
    if (_player.playerState.playing) {
      await _player.stop();
    }
    await _player.dispose();

    // Don't stop the audio handler - keep it alive for notifications
    // It will be reused by the next audio player instance
  }
}

// Audio handler for background audio
class _LMSAudioHandler extends BaseAudioHandler {
  AudioPlayer? _player;
  final List<StreamSubscription> _subscriptions = [];

  _LMSAudioHandler();

  void _setupListeners() {
    if (_player == null) return;

    // Cancel old subscriptions
    for (var sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();

    // Listen to player state and update playback state
    _subscriptions.add(
      _player!.playingStream.listen((playing) {
        playbackState.add(
          playbackState.value.copyWith(
            playing: playing,
            controls: [
              MediaControl.skipToPrevious,
              if (playing) MediaControl.pause else MediaControl.play,
              MediaControl.skipToNext,
              MediaControl.stop,
            ],
            processingState: AudioProcessingState.ready,
          ),
        );
      }),
    );

    // Listen to position changes
    _subscriptions.add(
      _player!.positionStream.listen((position) {
        playbackState.add(
          playbackState.value.copyWith(updatePosition: position),
        );
      }),
    );

    // Listen to speed changes
    _subscriptions.add(
      _player!.speedStream.listen((speed) {
        playbackState.add(playbackState.value.copyWith(speed: speed));
      }),
    );
  }

  /// Update to use a new player instance
  void updatePlayer(AudioPlayer newPlayer) {
    _player = newPlayer;
    _setupListeners();
  }

  @override
  Future<void> play() async {
    if (_player != null) {
      await _player!.play();
    }
  }

  @override
  Future<void> pause() async {
    if (_player != null) {
      await _player!.pause();
    }
  }

  @override
  Future<void> seek(Duration position) async {
    if (_player != null) {
      await _player!.seek(position);
    }
  }

  @override
  Future<void> stop() async {
    if (_player != null) {
      await _player!.stop();
    }

    // Clear playback state
    playbackState.add(
      playbackState.value.copyWith(
        playing: false,
        processingState: AudioProcessingState.idle,
      ),
    );

    // Cancel subscriptions
    for (var sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
  }

  @override
  Future<void> setSpeed(double speed) async {
    if (_player != null) {
      await _player!.setSpeed(speed);
    }
  }
}
