/// Configuration for media playback behavior
class MediaPlayerConfig {
  /// Auto-resume from last watched position
  final bool autoResume;

  /// Completion threshold (0.0 to 1.0). Default 0.9 means 90% watched = completed
  final double completionThreshold;

  /// Auto-save progress interval in seconds
  final int progressSaveInterval;

  /// Enable Picture-in-Picture (mobile only)
  final bool enablePiP;

  /// Auto-play when media loads
  final bool autoPlay;

  /// Default playback speed
  final double defaultSpeed;

  /// Available playback speeds
  final List<double> availableSpeeds;

  /// Enable background audio (audio only)
  final bool enableBackgroundAudio;

  /// Show notification controls (audio only)
  final bool showNotificationControls;

  const MediaPlayerConfig({
    this.autoResume = true,
    this.completionThreshold = 0.9,
    this.progressSaveInterval = 5,
    this.enablePiP = false,
    this.autoPlay = false,
    this.defaultSpeed = 1.0,
    this.availableSpeeds = const [0.5, 0.75, 1.0, 1.25, 1.5, 2.0],
    this.enableBackgroundAudio = true,
    this.showNotificationControls = true,
  });

  MediaPlayerConfig copyWith({
    bool? autoResume,
    double? completionThreshold,
    int? progressSaveInterval,
    bool? enablePiP,
    bool? autoPlay,
    double? defaultSpeed,
    List<double>? availableSpeeds,
    bool? enableBackgroundAudio,
    bool? showNotificationControls,
  }) {
    return MediaPlayerConfig(
      autoResume: autoResume ?? this.autoResume,
      completionThreshold: completionThreshold ?? this.completionThreshold,
      progressSaveInterval: progressSaveInterval ?? this.progressSaveInterval,
      enablePiP: enablePiP ?? this.enablePiP,
      autoPlay: autoPlay ?? this.autoPlay,
      defaultSpeed: defaultSpeed ?? this.defaultSpeed,
      availableSpeeds: availableSpeeds ?? this.availableSpeeds,
      enableBackgroundAudio:
          enableBackgroundAudio ?? this.enableBackgroundAudio,
      showNotificationControls:
          showNotificationControls ?? this.showNotificationControls,
    );
  }
}
