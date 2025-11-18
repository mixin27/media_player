/// Configuration for subtitles/captions
class SubtitleConfig {
  final String? subtitleUrl;
  final String? subtitleLanguage;
  final SubtitleType type;
  final bool enabled;

  const SubtitleConfig({
    this.subtitleUrl,
    this.subtitleLanguage,
    this.type = SubtitleType.vtt,
    this.enabled = false,
  });

  SubtitleConfig copyWith({
    String? subtitleUrl,
    String? subtitleLanguage,
    SubtitleType? type,
    bool? enabled,
  }) {
    return SubtitleConfig(
      subtitleUrl: subtitleUrl ?? this.subtitleUrl,
      subtitleLanguage: subtitleLanguage ?? this.subtitleLanguage,
      type: type ?? this.type,
      enabled: enabled ?? this.enabled,
    );
  }
}

enum SubtitleType {
  vtt, // WebVTT
  srt, // SubRip
  none,
}
