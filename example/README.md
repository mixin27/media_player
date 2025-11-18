# LMS Media Player - Complete Example App

A fully functional example application demonstrating all features of the LMS Media Player package.

## 🎯 Features Demonstrated

### ✅ Video Player
- Stream videos from network URLs
- Download videos for offline viewing
- Auto-resume from last position
- Playback controls (play, pause, seek, speed)
- Fullscreen support
- Progress tracking and analytics

### ✅ Audio Player
- Stream audio files
- Background audio playback
- Lock screen controls with notification
- Download for offline listening
- Beautiful album art display
- Animated visualizer

### ✅ Document Viewer
- View PDF documents in-app
- Support for multiple formats (PDF, DOCX, PPTX, XLSX, TXT)
- Page navigation
- Search functionality (PDF only)
- Open non-PDF documents with system apps

### ✅ Download Manager
- Real downloads with Dio
- Progress tracking with percentage and bytes
- Pause/resume functionality
- Cancel downloads
- Delete downloaded files
- SQLite storage for download state

### ✅ Progress Tracking
- Auto-save watch progress every 5 seconds
- SQLite storage for persistence
- Watch history with timestamps
- Completion detection (90% threshold)
- Progress sync ready for backend integration

## 🚀 Running the Example

### Prerequisites

1. **Flutter SDK** (3.0.0 or higher)
2. **Android Studio** or **Xcode** (for iOS)
3. **Device or Emulator** running Android 5.0+ or iOS 12.0+

### Setup

1. Clone the repository:
```bash
git clone https://github.com/yourorg/lms_media_player.git
cd lms_media_player/example
```

2. Install dependencies:
```bash
flutter pub get
```

3. Configure Android (if targeting Android):

Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<manifest>
    <!-- Add these permissions -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
    <uses-permission android:name="android.permission.WAKE_LOCK"/>
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>

    <application>
        <!-- Your existing application config -->
    </application>
</manifest>
```

4. Configure iOS (if targeting iOS):

Add to `ios/Runner/Info.plist`:
```xml
<dict>
    <!-- Add these keys -->
    <key>UIBackgroundModes</key>
    <array>
        <string>audio</string>
    </array>

    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <true/>
    </dict>
</dict>
```

5. Run the app:
```bash
flutter run
```

## 📱 App Structure

```
example/
├── lib/
│   ├── main.dart                      # App entry point
│   ├── models/
│   │   └── sample_media.dart          # Sample video/audio/document data
│   ├── screens/
│   │   ├── home_screen.dart           # Main screen with tabs
│   │   ├── videos_tab.dart            # Videos list
│   │   ├── audios_tab.dart            # Audio list
│   │   ├── documents_tab.dart         # Documents list
│   │   ├── downloads_tab.dart         # Download manager
│   │   ├── progress_tab.dart          # Watch history
│   │   ├── video_player_screen.dart   # Full video player
│   │   ├── audio_player_screen.dart   # Full audio player
│   │   └── document_viewer_screen.dart # Document viewer
│   ├── services/
│   │   ├── download_service.dart      # Real download implementation
│   │   └── analytics_service.dart     # Analytics tracking
│   └── widgets/
│       ├── media_card.dart            # Reusable media card
│       └── document_list_item.dart    # Document list item
└── pubspec.yaml
```

## 🎬 How to Use

### 1. Videos Tab
- Browse available videos
- Tap a video card to play
- Tap the download button to save for offline
- Monitor download progress
- Offline videos show a green "Offline" badge

### 2. Audio Tab
- Browse audio tracks
- Tap to play with full-screen player
- Download for offline listening
- Player works in background
- Lock screen controls available

### 3. Documents Tab
- Browse available documents
- Tap PDF files to view in-app
- Other formats open with system apps
- Navigate pages with bottom controls
- Search within PDFs

### 4. Downloads Tab
- View all active and completed downloads
- Pause/resume active downloads
- Cancel unwanted downloads
- Delete completed downloads
- See real-time progress with bytes transferred

### 5. Progress Tab
- View watch history for all media
- See completion percentage
- Check last watched time
- Delete individual progress items
- Clear all history

## 🧪 Testing Features

### Test Video Downloads
1. Go to Videos tab
2. Tap download icon on any video
3. Watch progress in real-time
4. Once completed, tap the video to play offline
5. Notice the "Offline" badge and faster loading

### Test Progress Tracking
1. Play any video for a few seconds
2. Close the player
3. Go to Progress tab to see saved progress
4. Open the video again - it will resume from where you left off

### Test Background Audio
1. Go to Audio tab
2. Play any audio track
3. Press home button or lock screen
4. Control playback from notification or lock screen

### Test Document Viewing
1. Go to Documents tab
2. Tap any PDF document
3. Use toolbar to navigate, search, or jump to page
4. Try non-PDF documents to see system app integration

## 📊 Sample Data

The app uses real, publicly available media:

**Videos** (from Google's sample content):
- Big Buck Bunny
- Elephant Dream
- For Bigger Blazes
- Sintel

**Audio** (from SoundHelix):
- Acoustic Breeze
- Electronic Sunrise
- Piano Dreams

**Documents** (public PDFs):
- Sample PDF Document
- Flutter Brand Guidelines
- Course Material Sample

## 🔧 Customization

### Add Your Own Media

Edit `lib/models/sample_media.dart`:

```dart
static List<MediaMetadata> get videos => [
  MediaMetadata(
    id: 'your_video_id',
    title: 'Your Video Title',
    description: 'Your description',
    thumbnailUrl: 'https://your-thumbnail.jpg',
    mediaType: MediaType.video,
    source: NetworkMediaSource(
      url: 'https://your-video.mp4',
      authHeaders: {'Authorization': 'Bearer your-token'},
    ),
  ),
  // Add more videos...
];
```

### Connect to Your Backend

Replace mock implementations in `lib/services/`:

```dart
// In video_player_screen.dart
onProgressUpdate: (progress) async {
  // Instead of just printing:
  await yourApiClient.post(
    '/api/progress',
    data: progress.toJson(),
  );
},
```

### Change Theme

Edit `lib/main.dart`:

```dart
theme: ThemeData(
  primarySwatch: Colors.purple,  // Your brand color
  useMaterial3: true,
  // Add more customization...
),
```

## 🐛 Troubleshooting

### Videos Not Playing
- Check internet connection
- Verify video URL is accessible
- Check Android/iOS permissions
- Try different video format (MP4 recommended)

### Downloads Failing
- Check storage permissions
- Verify available disk space
- Check network connection
- Try smaller files first

### Background Audio Not Working
- iOS: Verify Info.plist configuration
- Android: Check FOREGROUND_SERVICE permission
- Ensure audio_service is initialized

### PDF Not Loading
- Check PDF URL is direct download link
- Try downloading the PDF manually to verify
- Check if PDF is password protected

## 📈 Performance Tips

1. **Video Quality**: For mobile, use 720p or lower
2. **Thumbnail Loading**: Use CDN for thumbnails
3. **Database**: Index frequently queried fields
4. **Downloads**: Implement chunked downloads for large files
5. **Memory**: Dispose controllers properly

## 🔐 Security Notes

This example uses public sample media. In production:

1. **Protect Your URLs**: Use signed URLs or tokens
2. **Encrypt Downloads**: Store sensitive media encrypted
3. **Validate Files**: Check file types before downloading
4. **Rate Limiting**: Prevent abuse of download feature
5. **DRM**: Consider DRM for premium content

## 📄 License

This example app is part of the LMS Media Player package.
See LICENSE file for details.

## 🤝 Contributing

Found a bug or want to improve the example?
1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📞 Support

- **Documentation**: Check package README
- **Issues**: GitHub Issues
- **Questions**: Discussions tab

---

Built with ❤️ using Flutter and LMS Media Player
