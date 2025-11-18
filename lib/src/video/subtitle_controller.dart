import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

import '../models/subtitle_track.dart';
import 'subtitle_parser.dart';

class SubtitleController {
  final List<SubtitleTrack> availableTracks;

  SubtitleTrack? _currentTrack;
  List<SubtitleCue> _cues = [];
  final _currentCueController = BehaviorSubject<SubtitleCue?>.seeded(null);
  final _enabledController = BehaviorSubject<bool>.seeded(false);
  final _loadingController = BehaviorSubject<bool>.seeded(false);

  SubtitleController({required this.availableTracks}) {
    // Auto-load default track if available
    final defaultTrack = availableTracks.where((t) => t.isDefault).firstOrNull;
    if (defaultTrack != null) {
      loadTrack(defaultTrack);
    }
  }

  /// Get current subtitle cue stream
  Stream<SubtitleCue?> get currentCueStream => _currentCueController.stream;

  /// Get current subtitle cue
  SubtitleCue? get currentCue => _currentCueController.value;

  /// Get enabled state stream
  Stream<bool> get enabledStream => _enabledController.stream;

  /// Get enabled state
  bool get isEnabled => _enabledController.value;

  /// Get loading state stream
  Stream<bool> get loadingStream => _loadingController.stream;

  /// Get loading state
  bool get isLoading => _loadingController.value;

  /// Get current track
  SubtitleTrack? get currentTrack => _currentTrack;

  /// Load a subtitle track
  Future<void> loadTrack(
    SubtitleTrack track, {
    Map<String, String>? headers,
  }) async {
    _loadingController.add(true);

    try {
      _cues = await SubtitleParser.parseFromUrl(
        track.url,
        track.type,
        headers: headers,
      );

      _currentTrack = track;
      _enabledController.add(true);

      debugPrint('Loaded ${_cues.length} subtitle cues for ${track.label}');
    } catch (e) {
      debugPrint('Failed to load subtitle track: $e');
      _cues = [];
      _currentTrack = null;
      _enabledController.add(false);
    } finally {
      _loadingController.add(false);
    }
  }

  /// Update current position and find active cue
  void updatePosition(Duration position) {
    if (!isEnabled || _cues.isEmpty) {
      if (_currentCueController.value != null) {
        _currentCueController.add(null);
      }
      return;
    }

    // Find active cue at current position
    final activeCue = _cues.firstWhere(
      (cue) => cue.isActive(position),
      orElse: () =>
          const SubtitleCue(start: Duration.zero, end: Duration.zero, text: ''),
    );

    // Only update if cue changed
    if (activeCue.text.isEmpty) {
      if (_currentCueController.value != null) {
        _currentCueController.add(null);
      }
    } else if (_currentCueController.value != activeCue) {
      _currentCueController.add(activeCue);
    }
  }

  /// Enable/disable subtitles
  void setEnabled(bool enabled) {
    _enabledController.add(enabled);
    if (!enabled) {
      _currentCueController.add(null);
    }
  }

  /// Toggle subtitles on/off
  void toggle() {
    setEnabled(!isEnabled);
  }

  /// Clear current track
  void clearTrack() {
    _currentTrack = null;
    _cues = [];
    _currentCueController.add(null);
    _enabledController.add(false);
  }

  /// Dispose resources
  void dispose() {
    _currentCueController.close();
    _enabledController.close();
    _loadingController.close();
  }
}
