import 'package:http/http.dart' as http;

import '../core/subtitle_config.dart';
import '../models/subtitle_track.dart';

class SubtitleParser {
  /// Parse subtitle file from URL
  static Future<List<SubtitleCue>> parseFromUrl(
    String url,
    SubtitleType type, {
    Map<String, String>? headers,
  }) async {
    try {
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode != 200) {
        throw Exception('Failed to load subtitle: ${response.statusCode}');
      }

      return parseFromString(response.body, type);
    } catch (e) {
      throw Exception('Error loading subtitle: $e');
    }
  }

  /// Parse subtitle from string content
  static List<SubtitleCue> parseFromString(String content, SubtitleType type) {
    switch (type) {
      case SubtitleType.vtt:
        return _parseVTT(content);
      case SubtitleType.srt:
        return _parseSRT(content);
      case SubtitleType.none:
        return [];
    }
  }

  /// Parse WebVTT format
  static List<SubtitleCue> _parseVTT(String content) {
    final cues = <SubtitleCue>[];
    final lines = content.split('\n');

    // Skip WEBVTT header
    int i = 0;
    while (i < lines.length && !lines[i].contains('-->')) {
      i++;
    }

    while (i < lines.length) {
      final line = lines[i].trim();

      // Look for timestamp line
      if (line.contains('-->')) {
        final parts = line.split('-->');
        if (parts.length == 2) {
          final start = _parseVTTTimestamp(parts[0].trim());
          final end = _parseVTTTimestamp(parts[1].trim().split(' ')[0]);

          // Collect text lines
          final textLines = <String>[];
          i++;
          while (i < lines.length && lines[i].trim().isNotEmpty) {
            textLines.add(lines[i].trim());
            i++;
          }

          if (textLines.isNotEmpty) {
            cues.add(
              SubtitleCue(start: start, end: end, text: textLines.join('\n')),
            );
          }
        }
      }
      i++;
    }

    return cues;
  }

  /// Parse SRT format
  static List<SubtitleCue> _parseSRT(String content) {
    final cues = <SubtitleCue>[];
    final blocks = content.split('\n\n');

    for (var block in blocks) {
      final lines = block
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .toList();

      if (lines.length < 3) continue;

      // Line 0: Index (skip)
      // Line 1: Timestamp
      final timestampLine = lines[1];
      if (timestampLine.contains('-->')) {
        final parts = timestampLine.split('-->');
        if (parts.length == 2) {
          final start = _parseSRTTimestamp(parts[0].trim());
          final end = _parseSRTTimestamp(parts[1].trim());

          // Remaining lines: Text
          final text = lines.sublist(2).join('\n');

          cues.add(SubtitleCue(start: start, end: end, text: text));
        }
      }
    }

    return cues;
  }

  /// Parse VTT timestamp (00:00:00.000 or 00:00.000)
  static Duration _parseVTTTimestamp(String timestamp) {
    final parts = timestamp.split(':');

    if (parts.length == 3) {
      // HH:MM:SS.mmm
      final hours = int.parse(parts[0]);
      final minutes = int.parse(parts[1]);
      final secondsParts = parts[2].split('.');
      final seconds = int.parse(secondsParts[0]);
      final milliseconds = secondsParts.length > 1
          ? int.parse(secondsParts[1].padRight(3, '0').substring(0, 3))
          : 0;

      return Duration(
        hours: hours,
        minutes: minutes,
        seconds: seconds,
        milliseconds: milliseconds,
      );
    } else if (parts.length == 2) {
      // MM:SS.mmm
      final minutes = int.parse(parts[0]);
      final secondsParts = parts[1].split('.');
      final seconds = int.parse(secondsParts[0]);
      final milliseconds = secondsParts.length > 1
          ? int.parse(secondsParts[1].padRight(3, '0').substring(0, 3))
          : 0;

      return Duration(
        minutes: minutes,
        seconds: seconds,
        milliseconds: milliseconds,
      );
    }

    return Duration.zero;
  }

  /// Parse SRT timestamp (00:00:00,000)
  static Duration _parseSRTTimestamp(String timestamp) {
    final parts = timestamp.split(':');

    if (parts.length == 3) {
      final hours = int.parse(parts[0]);
      final minutes = int.parse(parts[1]);
      final secondsParts = parts[2].split(',');
      final seconds = int.parse(secondsParts[0]);
      final milliseconds = secondsParts.length > 1
          ? int.parse(secondsParts[1].padRight(3, '0').substring(0, 3))
          : 0;

      return Duration(
        hours: hours,
        minutes: minutes,
        seconds: seconds,
        milliseconds: milliseconds,
      );
    }

    return Duration.zero;
  }
}
