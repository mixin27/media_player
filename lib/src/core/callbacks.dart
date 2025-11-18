import '../models/media_event.dart';
import '../models/media_progress.dart';
import 'media_player_state.dart';

/// Callback for progress updates
typedef MediaProgressCallback = void Function(MediaProgress progress);

/// Callback for completion events
typedef MediaCompletionCallback = void Function(String mediaId);

/// Callback for error events
typedef MediaErrorCallback = void Function(String mediaId, dynamic error);

/// Callback for analytics events (state management agnostic)
typedef MediaAnalyticsCallback = void Function(MediaEvent event);

/// Callback for state changes (for external state management)
typedef MediaStateChangeCallback = void Function(MediaPlayerState state);
