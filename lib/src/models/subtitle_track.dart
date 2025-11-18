import 'package:equatable/equatable.dart';

import '../core/subtitle_config.dart';

/// Represents a subtitle/caption track
class SubtitleTrack extends Equatable {
  final String id;
  final String label;
  final String language;
  final String url;
  final SubtitleType type;
  final bool isDefault;

  const SubtitleTrack({
    required this.id,
    required this.label,
    required this.language,
    required this.url,
    required this.type,
    this.isDefault = false,
  });

  factory SubtitleTrack.empty() => SubtitleTrack(
    id: '',
    label: '',
    language: '',
    url: '',
    type: SubtitleType.none,
  );

  bool get isEmpty => type == SubtitleType.none;

  @override
  List<Object?> get props => [id, label, language, url, type, isDefault];
}

/// Represents a parsed subtitle cue
class SubtitleCue extends Equatable {
  final Duration start;
  final Duration end;
  final String text;

  const SubtitleCue({
    required this.start,
    required this.end,
    required this.text,
  });

  bool isActive(Duration position) {
    return position >= start && position <= end;
  }

  @override
  List<Object?> get props => [start, end, text];
}
