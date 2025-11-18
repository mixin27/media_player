import 'package:equatable/equatable.dart';

import '../core/subtitle_config.dart';
import 'media_source.dart';
import 'media_type.dart';

/// Metadata for a media item
class MediaMetadata extends Equatable {
  final String id;
  final String title;
  final String? description;
  final String? thumbnailUrl;
  final MediaType mediaType;
  final MediaSource source;
  final SubtitleConfig? subtitleConfig;
  final Map<String, dynamic>? customData;

  const MediaMetadata({
    required this.id,
    required this.title,
    this.description,
    this.thumbnailUrl,
    required this.mediaType,
    required this.source,
    this.subtitleConfig,
    this.customData,
  });

  MediaMetadata copyWith({
    String? id,
    String? title,
    String? description,
    String? thumbnailUrl,
    MediaType? mediaType,
    MediaSource? source,
    SubtitleConfig? subtitleConfig,
    Map<String, dynamic>? customData,
  }) {
    return MediaMetadata(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      mediaType: mediaType ?? this.mediaType,
      source: source ?? this.source,
      subtitleConfig: subtitleConfig ?? this.subtitleConfig,
      customData: customData ?? this.customData,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    thumbnailUrl,
    mediaType,
    source,
    subtitleConfig,
    customData,
  ];
}
