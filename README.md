# LMS Media Player

A comprehensive, state-management agnostic Flutter package for playing videos, audio, and viewing documents in Learning Management Systems (LMS). Features offline playback, automatic progress tracking, and seamless integration with any state management solution.

## Features

### 🎥 Video Player
- **Streaming & Offline**: Supports both network URLs and local files
- **Progress Tracking**: Auto-save watch progress every 5 seconds (configurable)
- **Auto-Resume**: Resume from last watched position
- **Playback Controls**: Speed control (0.5x - 2x), seek, volume
- **Subtitle Support**: VTT/SRT subtitle files
- **Picture-in-Picture**: Mobile PiP support (optional)
- **Adaptive Streaming**: HLS/DASH support

### 🎵 Audio Player
- **Background Playback**: Continue playing when app is in background
- **Lock Screen Controls**: Play/pause/seek from lock screen
- **Notification Controls**: Media notification with artwork
- **Progress Tracking**: Same auto-save progress as video
- **Queue Management**: Built on `just_audio` for playlist support

### 📄 Document Viewer
- **Multiple Formats**: PDF, DOCX, PPTX, XLSX, TXT
- **In-App PDF Viewer**: Built-in PDF viewing widget
- **System App Opening**: Open documents with system default apps
- **View Tracking**: Mark documents as viewed/completed

### 💾 Progress Management
- **SQLite Storage**: Persistent local storage with `sqflite`
- **Watch History**: Track viewing history with timestamps
- **Completion Detection**: Auto-mark as complete at 90% (configurable)
- **Export/Import**: Easy data sync with backend

### 📊 Analytics Ready
- **Event System**: Comprehensive media events (play, pause, seek, complete, error)
- **State Management Agnostic**: Use with any analytics package
- **JSON Export**: Events easily serializable for backend sync

## Installation

```yaml
dependencies:
  lms_media_player: ^0.1.0
```

## Quick Start

### 1. Initialize the Package

```dart
import 'package:media_player/media_player.dart';
import 'package:media_kit/media_kit.dart'; // Required for video

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Required for video playback
  MediaKit.ensureInitialized();

  runApp(MyApp());
}
```

### 2. Initialize Storage

```dart
// Initialize once at app startup
final manager = await LMSMediaManager.initialize(
  storageType: StorageType.sqflite, // or StorageType.inMemory for testing
);
```

### 3. Play a Video

```dart
class VideoPlayerPage extends StatefulWidget {
  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late LMSVideoPlayerController _controller;

  @override
  void initState() {
    super.initState();

    _controller = LMSVideoPlayerController(
      metadata: MediaMetadata(
        id: 'lesson_123',
        title: 'Introduction to Flutter',
        mediaType: MediaType.video,
        source: NetworkMediaSource(
          url: 'https://example.com/video.mp4',
          authHeaders: {'Authorization': 'Bearer token'},
        ),
      ),
      config: MediaPlayerConfig(
        autoResume: true,
        autoPlay: false,
      ),
      storage: LMSMediaManager.instance.storage,
      onProgressUpdate: (progress) {
        print('Progress: ${progress.completionPercentage}%');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Video(controller: _controller.videoController),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

## State Management Integration

### With Flutter setState (No External Package)

```dart
class VideoPlayerWithSetState extends StatefulWidget {
  @override
  State<VideoPlayerWithSetState> createState() => _VideoPlayerWithSetStateState();
}

class _VideoPlayerWithSetStateState extends State<VideoPlayerWithSetState> {
  late LMSVideoPlayerController _controller;
  MediaPlayerState _state = const MediaPlayerState();

  @override
  void initState() {
    super.initState();

    _controller = LMSVideoPlayerController(
      // ... metadata, config, storage
      onStateChange: (newState) {
        setState(() {
          _state = newState;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Video(controller: _controller.videoController),
        Text('${_state.position} / ${_state.duration}'),
        IconButton(
          icon: Icon(_state.isPlaying ? Icons.pause : Icons.play_arrow),
          onPressed: _state.isPlaying ? _controller.pause : _controller.play,
        ),
      ],
    );
  }
}
```

### With Riverpod

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

final videoControllerProvider = StateNotifierProvider.autoDispose<
    VideoControllerNotifier, MediaPlayerState>(
  (ref) => VideoControllerNotifier(),
);

class VideoControllerNotifier extends StateNotifier<MediaPlayerState> {
  LMSVideoPlayerController? _controller;

  VideoControllerNotifier() : super(const MediaPlayerState());

  Future<void> initialize(MediaMetadata metadata) async {
    _controller = LMSVideoPlayerController(
      metadata: metadata,
      config: const MediaPlayerConfig(autoResume: true),
      storage: LMSMediaManager.instance.storage,
      onStateChange: (newState) => state = newState,
    );
  }

  Future<void> play() => _controller?.play() ?? Future.value();
  Future<void> pause() => _controller?.pause() ?? Future.value();
  Future<void> seek(Duration position) => _controller?.seek(position) ?? Future.value();

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}

// Usage in widget
class VideoPlayerWithRiverpod extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(videoControllerProvider);
    final controller = ref.read(videoControllerProvider.notifier);

    return IconButton(
      icon: Icon(state.isPlaying ? Icons.pause : Icons.play_arrow),
      onPressed: state.isPlaying ? controller.pause : controller.play,
    );
  }
}
```

### With BLoC

```dart
import 'package:flutter_bloc/flutter_bloc.dart';

// Events
abstract class VideoPlayerEvent {}
class PlayVideo extends VideoPlayerEvent {}
class PauseVideo extends VideoPlayerEvent {}
class SeekVideo extends VideoPlayerEvent {
  final Duration position;
  SeekVideo(this.position);
}

// Bloc
class VideoPlayerBloc extends Bloc<VideoPlayerEvent, MediaPlayerState> {
  final LMSVideoPlayerController _controller;

  VideoPlayerBloc(this._controller) : super(const MediaPlayerState()) {
    // Listen to controller state changes
    _controller.stateStream.listen((newState) {
      emit(newState);
    });

    on<PlayVideo>((event, emit) => _controller.play());
    on<PauseVideo>((event, emit) => _controller.pause());
    on<SeekVideo>((event, emit) => _controller.seek(event.position));
  }

  @override
  Future<void> close() {
    _controller.dispose();
    return super.close();
  }
}

// Usage
BlocProvider(
  create: (context) => VideoPlayerBloc(/* controller */),
  child: BlocBuilder<VideoPlayerBloc, MediaPlayerState>(
    builder: (context, state) {
      return IconButton(
        icon: Icon(state.isPlaying ? Icons.pause : Icons.play_arrow),
        onPressed: () => context.read<VideoPlayerBloc>().add(
          state.isPlaying ? PauseVideo() : PlayVideo()
        ),
      );
    },
  ),
)
```

### With GetX

```dart
import 'package:get/get.dart';

class VideoPlayerController extends GetxController {
  late LMSVideoPlayerController _lmsController;
  final state = const MediaPlayerState().obs;

  @override
  void onInit() {
    super.onInit();

    _lmsController = LMSVideoPlayerController(
      // ... metadata, config, storage
      onStateChange: (newState) => state.value = newState,
    );
  }

  void play() => _lmsController.play();
  void pause() => _lmsController.pause();
  void seek(Duration position) => _lmsController.seek(position);

  @override
  void onClose() {
    _lmsController.dispose();
    super.onClose();
  }
}

// Usage
class VideoPlayerView extends GetView<VideoPlayerController> {
  @override
  Widget build(BuildContext context) {
    return Obx(() => IconButton(
      icon: Icon(controller.state.value.isPlaying
          ? Icons.pause
          : Icons.play_arrow),
      onPressed: controller.state.value.isPlaying
          ? controller.pause
          : controller.play,
    ));
  }
}
```

## Audio Player Example

```dart
class AudioPlayerPage extends StatefulWidget {
  @override
  State<AudioPlayerPage> createState() => _AudioPlayerPageState();
}

class _AudioPlayerPageState extends State<AudioPlayerPage> {
  late LMSAudioPlayerController _controller;

  @override
  void initState() {
    super.initState();

    _controller = LMSAudioPlayerController(
      metadata: MediaMetadata(
        id: 'audio_123',
        title: 'Podcast Episode 1',
        description: 'Introduction to LMS',
        thumbnailUrl: 'https://example.com/cover.jpg',
        mediaType: MediaType.audio,
        source: LocalMediaSource(
          filePath: '/storage/emulated/0/audio.mp3',
        ),
      ),
      config: MediaPlayerConfig(
        autoResume: true,
        enableBackgroundAudio: true,
        showNotificationControls: true,
      ),
      storage: LMSMediaManager.instance.storage,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<MediaPlayerState>(
        stream: _controller.stateStream,
        builder: (context, snapshot) {
          final state = snapshot.data ?? const MediaPlayerState();

          return Column(
            children: [
              Text('Now Playing: ${_controller.metadata.title}'),
              Text('${state.position} / ${state.duration}'),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.replay_10),
                    onPressed: () => _controller.seek(
                      state.position - Duration(seconds: 10),
                    ),
                  ),
                  IconButton(
                    icon: Icon(state.isPlaying
                        ? Icons.pause_circle
                        : Icons.play_circle),
                    iconSize: 64,
                    onPressed: state.isPlaying
                        ? _controller.pause
                        : _controller.play,
                  ),
                  IconButton(
                    icon: const Icon(Icons.forward_10),
                    onPressed: () => _controller.seek(
                      state.position + Duration(seconds: 10),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

## Document Viewer Example

```dart
// Open PDF in-app
class PdfViewerPage extends StatelessWidget {
  final MediaMetadata metadata;

  const PdfViewerPage({required this.metadata});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(metadata.title)),
      body: LMSPdfViewerWidget(
        source: metadata.source,
        onPageChanged: (page, total) {
          print('Page $page of $total');
        },
        onDocumentLoaded: () async {
          final controller = LMSDocumentViewerController(
            metadata: metadata,
            storage: LMSMediaManager.instance.storage,
          );
          await controller.markAsViewed();
        },
      ),
    );
  }
}

// Or open with system app
void openDocumentWithSystemApp(MediaMetadata metadata) async {
  final controller = LMSDocumentViewerController(
    metadata: metadata,
    storage: LMSMediaManager.instance.storage,
    onCompletion: (id) {
      print('Document completed: $id');
    },
  );

  await controller.openWithSystemApp();
}
```

## Analytics Integration

```dart
// Create your analytics service
class AnalyticsService {
  void logEvent(String name, Map<String, dynamic> parameters) {
    // Send to Firebase, Mixpanel, etc.
  }
}

// Use with media player
LMSVideoPlayerController(
  // ... other params
  onAnalyticsEvent: (event) {
    analyticsService.logEvent(
      event.runtimeType.toString(),
      event.toAnalyticsJson(),
    );
  },
);

// Available events:
// - MediaPlayEvent
// - MediaPauseEvent
// - MediaSeekEvent
// - MediaCompleteEvent
// - MediaSpeedChangeEvent
// - MediaErrorEvent
```

## Progress & History Management

```dart
// Get watch progress
final progress = await storage.getProgress('video_123');
print('Last watched: ${progress?.lastWatched}');
print('Completion: ${progress?.completionPercentage}%');

// Get watch history
final history = await storage.getWatchHistory(limit: 20);
for (var item in history) {
  print('${item.mediaId}: ${item.lastWatched}');
}

// Get all videos progress
final videoProgress = await storage.getProgressByType(MediaType.video);

// Clear all progress
await storage.clearAllProgress();

// Export progress for backend sync
final allProgress = await storage.getAllProgress();
final json = allProgress.map((p) => p.toJson()).toList();
// Send to backend
```

## Configuration Options

```dart
MediaPlayerConfig(
  // Resume from last position
  autoResume: true,

  // Mark as complete at 90% watched
  completionThreshold: 0.9,

  // Save progress every 5 seconds
  progressSaveInterval: 5,

  // Enable Picture-in-Picture (mobile)
  enablePiP: false,

  // Auto-play when loaded
  autoPlay: false,

  // Default playback speed
  defaultSpeed: 1.0,

  // Available speed options
  availableSpeeds: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0],

  // Background audio (audio only)
  enableBackgroundAudio: true,

  // Notification controls (audio only)
  showNotificationControls: true,
)
```

## Offline Support

```dart
// After downloading with your downloader package:

// Video
final videoController = LMSVideoPlayerController(
  metadata: MediaMetadata(
    id: 'video_123',
    title: 'Offline Video',
    mediaType: MediaType.video,
    source: LocalMediaSource(
      filePath: '/data/user/0/.../video.mp4',
    ),
  ),
  // ... rest of config
);

// Audio
final audioController = LMSAudioPlayerController(
  metadata: MediaMetadata(
    id: 'audio_123',
    title: 'Offline Audio',
    mediaType: MediaType.audio,
    source: LocalMediaSource(
      filePath: '/data/user/0/.../audio.mp3',
    ),
  ),
  // ... rest of config
);
```

## Testing

```dart
// Use in-memory storage for tests
final storage = InMemoryMediaStorage();
await storage.initialize();

final controller = LMSVideoPlayerController(
  metadata: testMetadata,
  config: testConfig,
  storage: storage,
  onProgressUpdate: (progress) {
    // Test assertions
  },
);
```

## Platform Support

| Feature | Android | iOS | Web | Desktop |
|---------|---------|-----|-----|---------|
| Video Player | ✅ | ✅ | 🚧 | 🚧 |
| Audio Player | ✅ | ✅ | ❌ | ❌ |
| Background Audio | ✅ | ✅ | ❌ | ❌ |
| Notification Controls | ✅ | ✅ | ❌ | ❌ |
| PDF Viewer | ✅ | ✅ | ✅ | ✅ |
| Document Opening | ✅ | ✅ | ❌ | ✅ |
| Progress Storage | ✅ | ✅ | ✅ | ✅ |

✅ Supported | 🚧 Planned | ❌ Not Available

## License

MIT License

## Contributing

Contributions are welcome! Please read our contributing guidelines.
