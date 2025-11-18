# LMS Media Player - Complete Integration Guide

## 📦 Package Structure

```
lms_media_player/
├── lib/
│   ├── lms_media_player.dart           # Main export file
│   └── src/
│       ├── core/                        # Core functionality
│       │   ├── callbacks.dart
│       │   ├── media_config.dart
│       │   ├── media_player_state.dart
│       │   └── subtitle_config.dart
│       ├── models/                      # Data models
│       │   ├── media_event.dart
│       │   ├── media_metadata.dart
│       │   ├── media_progress.dart
│       │   ├── media_source.dart
│       │   └── media_type.dart
│       ├── storage/                     # Progress storage
│       │   ├── media_storage_interface.dart
│       │   ├── media_storage_factory.dart
│       │   ├── sqflite_media_storage.dart
│       │   └── in_memory_media_storage.dart
│       ├── video/                       # Video player
│       │   ├── video_player_controller.dart
│       │   └── widgets/
│       │       ├── lms_video_player_widget.dart
│       │       └── minimal_video_player.dart
│       ├── audio/                       # Audio player
│       │   ├── audio_player_controller.dart
│       │   └── widgets/
│       │       ├── lms_audio_player_widget.dart
│       │       └── compact_audio_player.dart
│       ├── document/                    # Document viewer
│       │   ├── document_viewer_controller.dart
│       │   └── widgets/
│       │       ├── lms_document_viewer_page.dart
│       │       ├── document_list_tile.dart
│       │       └── document_thumbnail.dart
│       ├── downloader/                  # Downloader integration
│       │   ├── download_manager_interface.dart
│       │   ├── media_download_adapter.dart
│       │   ├── download_aware_media_metadata.dart
│       │   └── widgets/
│       │       ├── download_button.dart
│       │       └── download_list_tile.dart
│       └── lms_media_manager.dart       # Main manager
└── example/                             # Example apps
```

---

## 🚀 Quick Start for Your LMS Platform

### Step 1: Add Dependencies

```yaml
# pubspec.yaml for your Admin/Teacher/Student apps
dependencies:
  lms_media_player: ^0.1.0
  # Your other dependencies...
```

### Step 2: Initialize Once at App Startup

```dart
// main.dart
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_player/media_player.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Required for video playback
  MediaKit.ensureInitialized();

  // Initialize media player storage
  await LMSMediaManager.initialize(
    storageType: StorageType.sqflite,
  );

  runApp(MyLMSApp());
}
```

### Step 3: Use in Your Apps

---

## 🎓 Student App Integration

### Video Learning Page

```dart
// student_app/lib/pages/video_lesson_page.dart
import 'package:flutter/material.dart';
import 'package:media_player/media_player.dart';

class VideoLessonPage extends StatefulWidget {
  final String lessonId;
  final String videoUrl;
  final String videoTitle;

  const VideoLessonPage({
    required this.lessonId,
    required this.videoUrl,
    required this.videoTitle,
  });

  @override
  State<VideoLessonPage> createState() => _VideoLessonPageState();
}

class _VideoLessonPageState extends State<VideoLessonPage> {
  late LMSVideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _controller = LMSVideoPlayerController(
      metadata: MediaMetadata(
        id: widget.lessonId,
        title: widget.videoTitle,
        mediaType: MediaType.video,
        source: NetworkMediaSource(
          url: widget.videoUrl,
          authHeaders: {
            'Authorization': 'Bearer ${await getAuthToken()}',
          },
        ),
      ),
      config: const MediaPlayerConfig(
        autoResume: true,
        autoPlay: true,
        completionThreshold: 0.9,
        progressSaveInterval: 5,
      ),
      storage: LMSMediaManager.instance.storage,
      onProgressUpdate: (progress) async {
        // Sync progress to your LMS backend
        await syncProgressToBackend(
          lessonId: widget.lessonId,
          progress: progress,
        );
      },
      onCompletion: (mediaId) async {
        // Mark lesson as completed in LMS
        await markLessonComplete(widget.lessonId);

        // Show completion dialog
        if (mounted) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Lesson Complete!'),
              content: const Text('You have completed this lesson.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context); // Go back to course
                  },
                  child: const Text('Continue'),
                ),
              ],
            ),
          );
        }
      },
      onAnalyticsEvent: (event) {
        // Send to your analytics service
        analyticsService.track(event.toAnalyticsJson());
      },
    );

    setState(() => _isInitialized = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Video player
            LMSVideoPlayerWidget(
              controller: _controller,
              showControls: true,
              allowFullscreen: true,
            ),

            // Lesson content below
            Expanded(
              child: LessonContentTab(lessonId: widget.lessonId),
            ),
          ],
        ),
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

### Audio Podcast Player

```dart
// student_app/lib/pages/audio_lesson_page.dart
class AudioLessonPage extends StatefulWidget {
  final String lessonId;
  final String audioUrl;
  final String title;
  final String? coverImage;

  const AudioLessonPage({
    required this.lessonId,
    required this.audioUrl,
    required this.title,
    this.coverImage,
  });

  @override
  State<AudioLessonPage> createState() => _AudioLessonPageState();
}

class _AudioLessonPageState extends State<AudioLessonPage> {
  late LMSAudioPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _controller = LMSAudioPlayerController(
      metadata: MediaMetadata(
        id: widget.lessonId,
        title: widget.title,
        thumbnailUrl: widget.coverImage,
        mediaType: MediaType.audio,
        source: NetworkMediaSource(
          url: widget.audioUrl,
          authHeaders: {
            'Authorization': 'Bearer ${await getAuthToken()}',
          },
        ),
      ),
      config: const MediaPlayerConfig(
        autoResume: true,
        enableBackgroundAudio: true,
        showNotificationControls: true,
      ),
      storage: LMSMediaManager.instance.storage,
      onProgressUpdate: (progress) => syncProgressToBackend(
        lessonId: widget.lessonId,
        progress: progress,
      ),
      onCompletion: (mediaId) => markLessonComplete(widget.lessonId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audio Lesson')),
      body: LMSAudioPlayerWidget(
        controller: _controller,
        showAlbumArt: true,
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

### Document Viewer

```dart
// student_app/lib/pages/document_lesson_page.dart
class DocumentLessonPage extends StatelessWidget {
  final String lessonId;
  final String documentUrl;
  final String title;

  const DocumentLessonPage({
    required this.lessonId,
    required this.documentUrl,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final controller = LMSDocumentViewerController(
      metadata: MediaMetadata(
        id: lessonId,
        title: title,
        mediaType: MediaType.document,
        source: NetworkMediaSource(url: documentUrl),
      ),
      storage: LMSMediaManager.instance.storage,
      onCompletion: (mediaId) => markLessonComplete(lessonId),
    );

    return LMSDocumentViewerPage(
      controller: controller,
      showToolbar: true,
      markAsViewedOnLoad: true,
    );
  }
}
```

---

## 👨‍🏫 Teacher App Integration

### Upload & Preview Video

```dart
// teacher_app/lib/pages/upload_video_page.dart
class UploadVideoPage extends StatefulWidget {
  @override
  State<UploadVideoPage> createState() => _UploadVideoPageState();
}

class _UploadVideoPageState extends State<UploadVideoPage> {
  String? _uploadedVideoUrl;
  LMSVideoPlayerController? _previewController;

  Future<void> _uploadVideo() async {
    // Pick video file
    final file = await pickVideoFile();

    // Upload to your backend
    _uploadedVideoUrl = await uploadToBackend(file);

    // Create preview controller
    _previewController = LMSVideoPlayerController(
      metadata: MediaMetadata(
        id: 'preview_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Video Preview',
        mediaType: MediaType.video,
        source: NetworkMediaSource(url: _uploadedVideoUrl!),
      ),
      config: const MediaPlayerConfig(autoPlay: false),
      storage: LMSMediaManager.instance.storage,
    );

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Video')),
      body: Column(
        children: [
          if (_previewController != null)
            LMSVideoPlayerWidget(controller: _previewController!),

          ElevatedButton(
            onPressed: _uploadVideo,
            child: const Text('Upload Video'),
          ),

          if (_uploadedVideoUrl != null)
            ElevatedButton(
              onPressed: _publishToLMS,
              child: const Text('Publish to Course'),
            ),
        ],
      ),
    );
  }

  Future<void> _publishToLMS() async {
    // Save to your LMS backend
  }
}
```

### View Student Progress

```dart
// teacher_app/lib/pages/student_progress_page.dart
class StudentProgressPage extends StatelessWidget {
  final String studentId;

  const StudentProgressPage({required this.studentId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Progress')),
      body: FutureBuilder<List<MediaProgress>>(
        future: getStudentProgress(studentId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final progress = snapshot.data!;

          return ListView.builder(
            itemCount: progress.length,
            itemBuilder: (context, index) {
              final item = progress[index];
              return ListTile(
                title: Text('Lesson ${item.mediaId}'),
                subtitle: LinearProgressIndicator(
                  value: item.completionPercentage / 100,
                ),
                trailing: Text('${item.completionPercentage.toInt()}%'),
              );
            },
          );
        },
      ),
    );
  }
}
```

---

## 👨‍💼 Admin App Integration

### Analytics Dashboard

```dart
// admin_app/lib/pages/analytics_dashboard.dart
class AnalyticsDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Media Analytics')),
      body: FutureBuilder<MediaAnalytics>(
        future: getMediaAnalytics(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final analytics = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _AnalyticsCard(
                title: 'Total Videos Watched',
                value: analytics.totalVideosWatched.toString(),
                icon: Icons.video_library,
              ),
              _AnalyticsCard(
                title: 'Average Completion Rate',
                value: '${analytics.avgCompletionRate.toInt()}%',
                icon: Icons.trending_up,
              ),
              _AnalyticsCard(
                title: 'Total Watch Time',
                value: formatDuration(analytics.totalWatchTime),
                icon: Icons.access_time,
              ),
              const SizedBox(height: 24),
              const Text(
                'Most Watched Content',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              ...analytics.topContent.map((content) => ListTile(
                leading: Icon(_getMediaIcon(content.type)),
                title: Text(content.title),
                trailing: Text('${content.views} views'),
              )),
            ],
          );
        },
      ),
    );
  }
}
```

---

## 📥 Downloader Integration

### Your Downloader Package Implementation

```dart
// your_downloader_package/lib/lms_download_manager.dart
import 'package:media_player/media_player.dart';
import 'package:dio/dio.dart';

class LMSDownloadManager implements IDownloadManager {
  final Dio _dio = Dio();

  @override
  Future<String> startDownload({
    required String mediaId,
    required String url,
    required String fileName,
    Map<String, String>? headers,
    MediaType? mediaType,
  }) async {
    final downloadId = 'dl_${DateTime.now().millisecondsSinceEpoch}';
    final savePath = await _getSavePath(fileName);

    // Use Dio to download with progress
    await _dio.download(
      url,
      savePath,
      options: Options(headers: headers),
      onReceiveProgress: (received, total) {
        final progress = DownloadProgress(
          downloadId: downloadId,
          mediaId: mediaId,
          status: DownloadStatus.downloading,
          downloaded: received,
          total: total,
          progress: received / total,
        );

        _progressController.add(progress);
      },
    );

    // Store in local database
    await _saveDownloadRecord(downloadId, mediaId, savePath);

    return downloadId;
  }

  // Implement other methods...
}
```

### Using Downloaded Files

```dart
// In your app
class OfflineCoursePage extends StatelessWidget {
  final String courseId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Offline Course')),
      body: FutureBuilder<MediaMetadata>(
        future: _getOfflineMetadata(courseId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final metadata = snapshot.data!;

          // Check if downloaded
          return FutureBuilder<bool>(
            future: downloadManager.isMediaDownloaded(courseId),
            builder: (context, downloadSnapshot) {
              final isDownloaded = downloadSnapshot.data ?? false;

              if (!isDownloaded) {
                return DownloadPrompt(
                  metadata: metadata,
                  onDownload: () => _startDownload(metadata),
                );
              }

              // Play from local file
              return VideoPlayerPage(
                metadata: metadata.copyWith(
                  source: LocalMediaSource(
                    filePath: await downloadManager.getLocalPath(courseId),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
```

---

## 🔄 Backend Sync Pattern

### Progress Sync Service

```dart
// lib/services/progress_sync_service.dart
class ProgressSyncService {
  final IMediaStorage localStorage;
  final ApiClient apiClient;

  ProgressSyncService({
    required this.localStorage,
    required this.apiClient,
  });

  /// Sync local progress to backend
  Future<void> syncToBackend() async {
    final allProgress = await localStorage.getAllProgress();

    for (var progress in allProgress) {
      try {
        await apiClient.post(
          '/api/student/progress',
          data: {
            'mediaId': progress.mediaId,
            'currentPosition': progress.currentPosition.inSeconds,
            'totalDuration': progress.totalDuration.inSeconds,
            'completionPercentage': progress.completionPercentage,
            'isCompleted': progress.isCompleted,
            'lastWatched': progress.lastWatched.toIso8601String(),
          },
        );
      } catch (e) {
        print('Failed to sync progress for ${progress.mediaId}: $e');
      }
    }
  }

  /// Pull progress from backend
  Future<void> syncFromBackend() async {
    final response = await apiClient.get('/api/student/progress');
    final progressList = response.data as List;

    for (var item in progressList) {
      final progress = MediaProgress(
        mediaId: item['mediaId'],
        currentPosition: Duration(seconds: item['currentPosition']),
        totalDuration: Duration(seconds: item['totalDuration']),
        lastWatched: DateTime.parse(item['lastWatched']),
        isCompleted: item['isCompleted'],
        mediaType: MediaType.values.firstWhere(
          (e) => e.toString() == item['mediaType'],
        ),
      );

      await localStorage.saveProgress(progress);
    }
  }

  /// Setup periodic sync
  void setupPeriodicSync() {
    Timer.periodic(const Duration(minutes: 5), (_) {
      syncToBackend();
    });
  }
}
```

---

## 🎨 Custom UI Themes

### Branded Video Player

```dart
LMSVideoPlayerWidget(
  controller: controller,
  controlsBackgroundColor: myBrandColor,
  // Custom loading widget
  loadingWidget: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      CircularProgressIndicator(color: myBrandColor),
      const SizedBox(height: 16),
      Text('Loading...', style: TextStyle(color: myBrandColor)),
    ],
  ),
  // Custom error widget
  errorWidget: ErrorDisplay(error: 'Failed to load video'),
)
```

---

## 📊 Analytics Integration

### Firebase Analytics Example

```dart
// lib/services/analytics_service.dart
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:media_player/media_player.dart';

class FirebaseAnalyticsService {
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  void trackMediaEvent(MediaEvent event) {
    final json = event.toAnalyticsJson();

    analytics.logEvent(
      name: json['event'] as String,
      parameters: {
        'media_id': json['mediaId'],
        'media_type': json['mediaType'],
        'timestamp': json['timestamp'],
        ...json,
      },
    );
  }
}

// Usage in player
LMSVideoPlayerController(
  // ... other params
  onAnalyticsEvent: analyticsService.trackMediaEvent,
);
```

---

## 🧪 Testing

### Unit Tests

```dart
// test/video_player_test.dart
void main() {
  late LMSVideoPlayerController controller;
  late InMemoryMediaStorage storage;

  setUp(() async {
    storage = InMemoryMediaStorage();
    await storage.initialize();

    controller = LMSVideoPlayerController(
      metadata: testMetadata,
      config: testConfig,
      storage: storage,
    );
  });

  test('saves progress correctly', () async {
    // Simulate watching
    await controller.play();
    await Future.delayed(const Duration(seconds: 6));

    final progress = await storage.getProgress(testMetadata.id);
    expect(progress, isNotNull);
    expect(progress!.currentPosition.inSeconds, greaterThan(0));
  });

  tearDown(() => controller.dispose());
}
```

---

## 📱 Platform Permissions

### Android (android/app/src/main/AndroidManifest.xml)

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
```

### iOS (ios/Runner/Info.plist)

```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
<key>NSMicrophoneUsageDescription</key>
<string>For audio recording features</string>
```

---

## 🎯 Best Practices

1. **Always dispose controllers** when leaving the page
2. **Sync progress regularly** to backend (every 5-10 seconds during playback)
3. **Handle network errors** gracefully with retry logic
4. **Cache metadata** for offline access
5. **Use analytics events** to understand user behavior
6. **Test offline scenarios** thoroughly
7. **Implement proper authentication** for protected content

---

## 🔧 Troubleshooting

**Video not playing?**
- Check MediaKit.ensureInitialized() is called
- Verify network permissions
- Check video URL is accessible

**Progress not saving?**
- Ensure LMSMediaManager.initialize() is called
- Check storage permissions
- Verify SQLite database creation

**Background audio not working?**
- Check iOS Info.plist configuration
- Verify Android FOREGROUND_SERVICE permission
- Ensure audio_service is initialized

---

Need help? Check the example apps or create an issue!
