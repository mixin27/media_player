# Subtitle/Caption Support - Complete Guide

## 🎬 Overview

The LMS Media Player now supports **subtitles and closed captions** for video content with:
- ✅ **Multiple subtitle tracks** (different languages)
- ✅ **VTT and SRT formats** support
- ✅ **Automatic parsing** from URLs or strings
- ✅ **Real-time synchronization** with video playback
- ✅ **Customizable styling** and positioning
- ✅ **Track selection UI** built-in
- ✅ **Enable/disable toggle**

---

## 📦 New Components

### **1. SubtitleTrack Model**
Represents a subtitle/caption track:
```dart
SubtitleTrack(
  id: 'en',
  label: 'English',
  language: 'en',
  url: 'https://example.com/subtitles/en.vtt',
  type: SubtitleType.vtt,
  isDefault: true,
)
```

### **2. SubtitleCue Model**
Represents a single subtitle entry:
```dart
SubtitleCue(
  start: Duration(seconds: 10),
  end: Duration(seconds: 15),
  text: 'This is the subtitle text',
)
```

### **3. SubtitleParser Service**
Parses VTT and SRT files:
```dart
// From URL
final cues = await SubtitleParser.parseFromUrl(
  'https://example.com/subtitles.vtt',
  SubtitleType.vtt,
);

// From string
final cues = SubtitleParser.parseFromString(
  vttContent,
  SubtitleType.vtt,
);
```

### **4. SubtitleController**
Manages subtitle state and synchronization:
```dart
final subtitleController = SubtitleController(
  availableTracks: subtitleTracks,
);

// Load a track
await subtitleController.loadTrack(track);

// Enable/disable
subtitleController.setEnabled(true);

// Update position (called automatically by video controller)
subtitleController.updatePosition(currentPosition);
```

### **5. SubtitleDisplay Widget**
Displays subtitles over video:
```dart
SubtitleDisplay(
  controller: videoController.subtitleController,
  textStyle: TextStyle(fontSize: 18, color: Colors.white),
  backgroundColor: Colors.black87,
)
```

### **6. SubtitleTrackSelector Widget**
UI for selecting subtitle tracks:
```dart
SubtitleTrackSelector(
  controller: videoController.subtitleController!,
  onTrackChanged: () {
    // Handle track change
  },
)
```

---

## 🚀 Quick Start

### **Basic Usage**

```dart
// 1. Define subtitle tracks
final subtitleTracks = [
  SubtitleTrack(
    id: 'en',
    label: 'English',
    language: 'en',
    url: 'https://example.com/subtitles/en.vtt',
    type: SubtitleType.vtt,
    isDefault: true,
  ),
  SubtitleTrack(
    id: 'es',
    label: 'Spanish',
    language: 'es',
    url: 'https://example.com/subtitles/es.srt',
    type: SubtitleType.srt,
  ),
];

// 2. Create video controller with subtitles
final controller = LMSVideoPlayerController(
  metadata: MediaMetadata(
    id: 'video_1',
    title: 'My Video',
    mediaType: MediaType.video,
    source: NetworkMediaSource(url: videoUrl),
    subtitleConfig: SubtitleConfig(
      subtitleUrl: 'https://example.com/subtitles/en.vtt',
      subtitleLanguage: 'en',
      type: SubtitleType.vtt,
      enabled: true, // Auto-enable default subtitle
    ),
  ),
  config: MediaPlayerConfig(),
  storage: storage,
  subtitleTracks: subtitleTracks, // Pass tracks here
);

// 3. Use video player widget (subtitles included automatically)
LMSVideoPlayerWidget(
  controller: controller,
  showControls: true,
);
```

---

## 📖 Supported Formats

### **WebVTT (.vtt)**
```
WEBVTT

00:00:00.000 --> 00:00:02.000
First subtitle

00:00:02.500 --> 00:00:05.000
Second subtitle with
multiple lines

00:00:05.500 --> 00:00:08.000
<c>Styled</c> subtitle
```

### **SubRip (.srt)**
```
1
00:00:00,000 --> 00:00:02,000
First subtitle

2
00:00:02,500 --> 00:00:05,000
Second subtitle with
multiple lines

3
00:00:05,500 --> 00:00:08,000
Third subtitle
```

---

## 🎨 Customization

### **Custom Subtitle Styling**

```dart
SubtitleDisplay(
  controller: controller.subtitleController,
  textStyle: TextStyle(
    color: Colors.yellow,
    fontSize: 20,
    fontWeight: FontWeight.bold,
    shadows: [
      Shadow(
        color: Colors.black,
        offset: Offset(2, 2),
        blurRadius: 3,
      ),
    ],
  ),
  backgroundColor: Colors.black.withOpacity(0.8),
  borderRadius: BorderRadius.circular(8),
  padding: EdgeInsets.all(12),
)
```

### **Custom Subtitle Position**

```dart
// Positioned at top instead of bottom
Positioned(
  top: 80,  // Instead of bottom: 80
  left: 0,
  right: 0,
  child: SubtitleDisplay(
    controller: controller.subtitleController,
  ),
)
```

---

## 🔧 Advanced Features

### **Programmatic Track Control**

```dart
// Get subtitle controller
final subController = videoController.subtitleController;

// Load specific track
await subController!.loadTrack(
  subtitleTracks.firstWhere((t) => t.language == 'es'),
);

// Toggle subtitles
subController.toggle();

// Check current state
if (subController.isEnabled) {
  print('Subtitles are on');
  print('Current track: ${subController.currentTrack?.label}');
}

// Listen to subtitle changes
subController.currentCueStream.listen((cue) {
  if (cue != null) {
    print('Current subtitle: ${cue.text}');
  }
});
```

### **Loading Subtitles from Assets**

```dart
// 1. Add subtitle file to assets
// assets/subtitles/en.vtt

// 2. Load from assets
final subtitleContent = await rootBundle.loadString(
  'assets/subtitles/en.vtt',
);

// 3. Parse subtitle content
final cues = SubtitleParser.parseFromString(
  subtitleContent,
  SubtitleType.vtt,
);

// 4. Use with custom subtitle display
```

### **Multiple Subtitle Tracks with Language Detection**

```dart
// Auto-select subtitle based on device language
final deviceLanguage = Platform.localeName.split('_')[0]; // e.g., 'en'

final defaultTrack = subtitleTracks.firstWhere(
  (track) => track.language == deviceLanguage,
  orElse: () => subtitleTracks.first,
);

final metadata = MediaMetadata(
  // ... other fields
  subtitleConfig: SubtitleConfig(
    subtitleUrl: defaultTrack.url,
    subtitleLanguage: defaultTrack.language,
    type: defaultTrack.type,
    enabled: true,
  ),
);
```

---

## 🎯 UI Components

### **1. Subtitle Toggle Button**

```dart
SubtitleToggleButton(
  controller: controller.subtitleController,
)
```

### **2. Subtitle Track Selector Menu**

```dart
SubtitleTrackSelector(
  controller: controller.subtitleController!,
  onTrackChanged: () {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Subtitle track changed'),
      ),
    );
  },
)
```

### **3. Custom Track List**

```dart
ListView.builder(
  itemCount: subtitleTracks.length,
  itemBuilder: (context, index) {
    final track = subtitleTracks[index];
    final isActive = controller.subtitleController?.currentTrack?.id == track.id;

    return ListTile(
      leading: Icon(
        isActive ? Icons.check_circle : Icons.language,
        color: isActive ? Colors.blue : null,
      ),
      title: Text(track.label),
      subtitle: Text(track.language),
      onTap: () async {
        await controller.subtitleController?.loadTrack(track);
      },
    );
  },
)
```

---

## 📝 Creating Subtitle Files

### **VTT Format Template**

```
WEBVTT

NOTE This is a comment

00:00:00.000 --> 00:00:02.000
First line of subtitle

00:00:02.500 --> 00:00:05.000
Second line can have
multiple lines

00:00:05.500 --> 00:00:08.000 position:50% align:middle
Positioned subtitle

00:00:09.000 --> 00:00:12.000
<c.yellow>Colored text</c>

00:00:13.000 --> 00:00:16.000
<b>Bold text</b>
<i>Italic text</i>
```

### **SRT Format Template**

```
1
00:00:00,000 --> 00:00:02,000
First line of subtitle

2
00:00:02,500 --> 00:00:05,000
Second line can have
multiple lines

3
00:00:05,500 --> 00:00:08,000
Third subtitle

4
00:00:09,000 --> 00:00:12,000
<b>Bold text</b>
<i>Italic text</i>
```

---

## 🧪 Testing

### **Manual Testing Checklist**

- [ ] Subtitles appear at correct times
- [ ] Multiple tracks can be loaded
- [ ] Switch between tracks works
- [ ] Enable/disable toggle works
- [ ] Subtitles sync with video playback
- [ ] Seeking updates subtitle position
- [ ] Speed changes don't break sync
- [ ] Multi-line subtitles display correctly
- [ ] Long text wraps properly
- [ ] Subtitles clear when not active

### **Testing with Sample VTT**

```dart
final testVTT = '''
WEBVTT

00:00:00.000 --> 00:00:02.000
Test subtitle 1

00:00:02.500 --> 00:00:05.000
Test subtitle 2
with multiple lines

00:00:05.500 --> 00:00:08.000
Test subtitle 3
''';

final cues = SubtitleParser.parseFromString(testVTT, SubtitleType.vtt);
print('Parsed ${cues.length} cues'); // Should print: Parsed 3 cues
```

---

## 🔍 Troubleshooting

### **Subtitles Not Appearing**

1. Check if subtitle controller is initialized:
   ```dart
   if (controller.subtitleController == null) {
     print('No subtitle tracks provided');
   }
   ```

2. Check if subtitles are enabled:
   ```dart
   print('Enabled: ${controller.subtitleController?.isEnabled}');
   ```

3. Check if track is loaded:
   ```dart
   print('Current track: ${controller.subtitleController?.currentTrack}');
   ```

4. Check cue count:
   ```dart
   print('Total cues: ${controller.subtitleController?._cues.length}');
   ```

### **Subtitles Out of Sync**

- Ensure video position is updating correctly
- Check subtitle file timestamps
- Verify format parsing (VTT uses `.` while SRT uses `,`)

### **Subtitle File Won't Load**

- Check URL is accessible
- Verify correct MIME type (text/vtt or text/srt)
- Check CORS headers for web
- Ensure proper authentication headers passed

---

## 📊 Performance Considerations

- Subtitle parsing is done **once** when track loads
- Active cue lookup is **O(n)** but optimized with early returns
- Memory usage: ~1KB per minute of subtitles
- No impact on video playback performance
- Subtitle updates only when position changes significantly

---

## 🌐 Internationalization

### **Multi-Language Support**

```dart
final subtitleTracks = [
  SubtitleTrack(
    id: 'en',
    label: 'English',
    language: 'en',
    url: 'https://cdn.example.com/subtitles/video1_en.vtt',
    type: SubtitleType.vtt,
    isDefault: true,
  ),
  SubtitleTrack(
    id: 'es',
    label: 'Español',
    language: 'es',
    url: 'https://cdn.example.com/subtitles/video1_es.vtt',
    type: SubtitleType.vtt,
  ),
  SubtitleTrack(
    id: 'fr',
    label: 'Français',
    language: 'fr',
    url: 'https://cdn.example.com/subtitles/video1_fr.vtt',
    type: SubtitleType.vtt,
  ),
  SubtitleTrack(
    id: 'de',
    label: 'Deutsch',
    language: 'de',
    url: 'https://cdn.example.com/subtitles/video1_de.vtt',
    type: SubtitleType.vtt,
  ),
  SubtitleTrack(
    id: 'ja',
    label: '日本語',
    language: 'ja',
    url: 'https://cdn.example.com/subtitles/video1_ja.vtt',
    type: SubtitleType.vtt,
  ),
];
```
