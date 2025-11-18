import 'package:flutter/material.dart';
import 'package:media_player/media_player.dart';

// Example: Creating subtitle files programmatically
class SubtitleFileExample {
  /// Example VTT file content
  static const String exampleVTT = '''
WEBVTT

00:00:00.000 --> 00:00:02.000
Welcome to our video

00:00:02.500 --> 00:00:05.000
This is the first subtitle

00:00:05.500 --> 00:00:08.000
And this is the second one

00:00:09.000 --> 00:00:12.000
Subtitles make videos
more accessible
''';

  /// Example SRT file content
  static const String exampleSRT = '''
1
00:00:00,000 --> 00:00:02,000
Welcome to our video

2
00:00:02,500 --> 00:00:05,000
This is the first subtitle

3
00:00:05,500 --> 00:00:08,000
And this is the second one

4
00:00:09,000 --> 00:00:12,000
Subtitles make videos
more accessible
''';
}

class LocalSubtitleExample extends StatelessWidget {
  const LocalSubtitleExample({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: DefaultAssetBundle.of(
        context,
      ).loadString('assets/subtitles/en.vtt'),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        // Parse subtitle content
        final cues = SubtitleParser.parseFromString(
          snapshot.data!,
          SubtitleType.vtt,
        );

        return ListView.builder(
          itemCount: cues.length,
          itemBuilder: (context, index) {
            final cue = cues[index];
            return ListTile(
              title: Text(cue.text),
              subtitle: Text(
                '${_formatDuration(cue.start)} -> ${_formatDuration(cue.end)}',
              ),
            );
          },
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
