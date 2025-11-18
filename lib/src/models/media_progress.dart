import 'package:equatable/equatable.dart';

import 'media_type.dart';

/// Represents playback progress for any media type
class MediaProgress extends Equatable {
  final String mediaId;
  final Duration currentPosition;
  final Duration totalDuration;
  final DateTime lastWatched;
  final bool isCompleted;
  final MediaType mediaType;

  const MediaProgress({
    required this.mediaId,
    required this.currentPosition,
    required this.totalDuration,
    required this.lastWatched,
    required this.isCompleted,
    required this.mediaType,
  });

  double get completionPercentage {
    if (totalDuration.inMilliseconds == 0) return 0.0;
    return (currentPosition.inMilliseconds / totalDuration.inMilliseconds * 100)
        .clamp(0.0, 100.0);
  }

  MediaProgress copyWith({
    String? mediaId,
    Duration? currentPosition,
    Duration? totalDuration,
    DateTime? lastWatched,
    bool? isCompleted,
    MediaType? mediaType,
  }) {
    return MediaProgress(
      mediaId: mediaId ?? this.mediaId,
      currentPosition: currentPosition ?? this.currentPosition,
      totalDuration: totalDuration ?? this.totalDuration,
      lastWatched: lastWatched ?? this.lastWatched,
      isCompleted: isCompleted ?? this.isCompleted,
      mediaType: mediaType ?? this.mediaType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mediaId': mediaId,
      'currentPosition': currentPosition.inMilliseconds,
      'totalDuration': totalDuration.inMilliseconds,
      'lastWatched': lastWatched.toIso8601String(),
      'isCompleted': isCompleted ? 1 : 0,
      'mediaType': mediaType.toString(),
    };
  }

  factory MediaProgress.fromJson(Map<String, dynamic> json) {
    return MediaProgress(
      mediaId: json['mediaId'] as String,
      currentPosition: Duration(milliseconds: json['currentPosition'] as int),
      totalDuration: Duration(milliseconds: json['totalDuration'] as int),
      lastWatched: DateTime.parse(json['lastWatched'] as String),
      isCompleted: json['isCompleted'] == 1,
      mediaType: MediaType.values.firstWhere(
        (e) => e.toString() == json['mediaType'],
        orElse: () => MediaType.video,
      ),
    );
  }

  @override
  List<Object?> get props => [
    mediaId,
    currentPosition,
    totalDuration,
    lastWatched,
    isCompleted,
    mediaType,
  ];
}
