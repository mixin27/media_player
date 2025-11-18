import 'package:equatable/equatable.dart';

/// Generic player state that can be consumed by any state management solution
class MediaPlayerState extends Equatable {
  final bool isPlaying;
  final bool isBuffering;
  final bool isCompleted;
  final Duration position;
  final Duration duration;
  final double speed;
  final String? error;
  final double volume;

  const MediaPlayerState({
    this.isPlaying = false,
    this.isBuffering = false,
    this.isCompleted = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.speed = 1.0,
    this.error,
    this.volume = 1.0,
  });

  MediaPlayerState copyWith({
    bool? isPlaying,
    bool? isBuffering,
    bool? isCompleted,
    Duration? position,
    Duration? duration,
    double? speed,
    String? error,
    double? volume,
  }) {
    return MediaPlayerState(
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      isCompleted: isCompleted ?? this.isCompleted,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      speed: speed ?? this.speed,
      error: error ?? this.error,
      volume: volume ?? this.volume,
    );
  }

  @override
  List<Object?> get props => [
    isPlaying,
    isBuffering,
    isCompleted,
    position,
    duration,
    speed,
    error,
    volume,
  ];
}
