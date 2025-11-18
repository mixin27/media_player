import 'package:equatable/equatable.dart';

import 'media_type.dart';

/// Analytics events that can be consumed by external analytics packages
abstract class MediaEvent extends Equatable {
  final String mediaId;
  final DateTime timestamp;
  final MediaType mediaType;

  const MediaEvent({
    required this.mediaId,
    required this.timestamp,
    required this.mediaType,
  });

  Map<String, dynamic> toAnalyticsJson();

  @override
  List<Object?> get props => [mediaId, timestamp, mediaType];
}

class MediaPlayEvent extends MediaEvent {
  final Duration position;

  const MediaPlayEvent({
    required super.mediaId,
    required super.timestamp,
    required super.mediaType,
    required this.position,
  });

  @override
  Map<String, dynamic> toAnalyticsJson() {
    return {
      'event': 'media_play',
      'mediaId': mediaId,
      'timestamp': timestamp.toIso8601String(),
      'mediaType': mediaType.toString(),
      'position': position.inSeconds,
    };
  }

  @override
  List<Object?> get props => [...super.props, position];
}

class MediaPauseEvent extends MediaEvent {
  final Duration position;

  const MediaPauseEvent({
    required super.mediaId,
    required super.timestamp,
    required super.mediaType,
    required this.position,
  });

  @override
  Map<String, dynamic> toAnalyticsJson() {
    return {
      'event': 'media_pause',
      'mediaId': mediaId,
      'timestamp': timestamp.toIso8601String(),
      'mediaType': mediaType.toString(),
      'position': position.inSeconds,
    };
  }

  @override
  List<Object?> get props => [...super.props, position];
}

class MediaSeekEvent extends MediaEvent {
  final Duration fromPosition;
  final Duration toPosition;

  const MediaSeekEvent({
    required super.mediaId,
    required super.timestamp,
    required super.mediaType,
    required this.fromPosition,
    required this.toPosition,
  });

  @override
  Map<String, dynamic> toAnalyticsJson() {
    return {
      'event': 'media_seek',
      'mediaId': mediaId,
      'timestamp': timestamp.toIso8601String(),
      'mediaType': mediaType.toString(),
      'fromPosition': fromPosition.inSeconds,
      'toPosition': toPosition.inSeconds,
    };
  }

  @override
  List<Object?> get props => [...super.props, fromPosition, toPosition];
}

class MediaCompleteEvent extends MediaEvent {
  final Duration watchedDuration;

  const MediaCompleteEvent({
    required super.mediaId,
    required super.timestamp,
    required super.mediaType,
    required this.watchedDuration,
  });

  @override
  Map<String, dynamic> toAnalyticsJson() {
    return {
      'event': 'media_complete',
      'mediaId': mediaId,
      'timestamp': timestamp.toIso8601String(),
      'mediaType': mediaType.toString(),
      'watchedDuration': watchedDuration.inSeconds,
    };
  }

  @override
  List<Object?> get props => [...super.props, watchedDuration];
}

class MediaSpeedChangeEvent extends MediaEvent {
  final double speed;

  const MediaSpeedChangeEvent({
    required super.mediaId,
    required super.timestamp,
    required super.mediaType,
    required this.speed,
  });

  @override
  Map<String, dynamic> toAnalyticsJson() {
    return {
      'event': 'media_speed_change',
      'mediaId': mediaId,
      'timestamp': timestamp.toIso8601String(),
      'mediaType': mediaType.toString(),
      'speed': speed,
    };
  }

  @override
  List<Object?> get props => [...super.props, speed];
}

class MediaErrorEvent extends MediaEvent {
  final String errorMessage;
  final String? errorCode;

  const MediaErrorEvent({
    required super.mediaId,
    required super.timestamp,
    required super.mediaType,
    required this.errorMessage,
    this.errorCode,
  });

  @override
  Map<String, dynamic> toAnalyticsJson() {
    return {
      'event': 'media_error',
      'mediaId': mediaId,
      'timestamp': timestamp.toIso8601String(),
      'mediaType': mediaType.toString(),
      'errorMessage': errorMessage,
      'errorCode': errorCode,
    };
  }

  @override
  List<Object?> get props => [...super.props, errorMessage, errorCode];
}
