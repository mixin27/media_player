import 'package:media_player/media_player.dart';

class SampleMedia {
  static List<MediaMetadata> get videos => [
    MediaMetadata(
      id: 'video_1',
      title: 'Big Buck Bunny',
      description: 'Blender Foundation - Open movie project',
      thumbnailUrl:
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/BigBuckBunny.jpg',
      mediaType: MediaType.video,
      source: NetworkMediaSource(
        url:
            'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
      ),
    ),
    MediaMetadata(
      id: 'video_2',
      title: 'Elephant Dream',
      description: 'Blender Foundation - First open movie',
      thumbnailUrl:
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/ElephantsDream.jpg',
      mediaType: MediaType.video,
      source: NetworkMediaSource(
        url:
            'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
      ),
    ),
    MediaMetadata(
      id: 'video_3',
      title: 'For Bigger Blazes',
      description: 'Google sample video',
      thumbnailUrl:
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/ForBiggerBlazes.jpg',
      mediaType: MediaType.video,
      source: NetworkMediaSource(
        url:
            'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
      ),
    ),
    MediaMetadata(
      id: 'video_4',
      title: 'Sintel',
      description: 'Blender Foundation - Fantasy short film',
      thumbnailUrl:
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/Sintel.jpg',
      mediaType: MediaType.video,
      source: NetworkMediaSource(
        url:
            'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4',
      ),
    ),
  ];

  static List<MediaMetadata> get audios => [
    MediaMetadata(
      id: 'audio_1',
      title: 'Acoustic Breeze',
      description: 'Calm acoustic guitar melody',
      thumbnailUrl: 'https://picsum.photos/seed/audio1/400/400',
      mediaType: MediaType.audio,
      source: NetworkMediaSource(
        url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
      ),
    ),
    MediaMetadata(
      id: 'audio_2',
      title: 'Electronic Sunrise',
      description: 'Uplifting electronic music',
      thumbnailUrl: 'https://picsum.photos/seed/audio2/400/400',
      mediaType: MediaType.audio,
      source: NetworkMediaSource(
        url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
      ),
    ),
    MediaMetadata(
      id: 'audio_3',
      title: 'Piano Dreams',
      description: 'Peaceful piano composition',
      thumbnailUrl: 'https://picsum.photos/seed/audio3/400/400',
      mediaType: MediaType.audio,
      source: NetworkMediaSource(
        url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
      ),
    ),
  ];

  static List<MediaMetadata> get documents => [
    MediaMetadata(
      id: 'doc_1',
      title: 'Sample PDF Document',
      description: 'PDF format example',
      mediaType: MediaType.document,
      source: NetworkMediaSource(
        url:
            'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
      ),
    ),
    MediaMetadata(
      id: 'doc_2',
      title: 'Flutter Documentation',
      description: 'Official Flutter PDF guide',
      mediaType: MediaType.document,
      source: NetworkMediaSource(
        url: 'https://flutter.dev/assets/brand/Flutter_Brand_Guidelines.pdf',
      ),
    ),
    MediaMetadata(
      id: 'doc_3',
      title: 'Course Material',
      description: 'Lecture notes and slides',
      mediaType: MediaType.document,
      source: NetworkMediaSource(
        url:
            'https://www.adobe.com/support/products/enterprise/knowledgecenter/media/c4611_sample_explain.pdf',
      ),
    ),
  ];

  static List<MediaMetadata> get all => [...videos, ...audios, ...documents];
}
