import 'package:flutter/material.dart';

import '../examples/video_with_subtitle_example.dart';
import 'tabs/audios_tab.dart';
import 'tabs/documents_tab.dart';
import 'tabs/downloads_tab.dart';
import 'tabs/progress_tab.dart';
import 'tabs/videos_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const VideosTab(),
    const AudiosTab(),
    const DocumentsTab(),
    const DownloadsTab(),
    const ProgressTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LMS Media Player'),
        elevation: 2,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => VideoWithSubtitlesExample(),
                ),
              );
            },
            icon: const Icon(Icons.subtitles_outlined),
          ),
        ],
      ),
      body: _tabs[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.video_library_outlined),
            selectedIcon: Icon(Icons.video_library),
            label: 'Videos',
          ),
          NavigationDestination(
            icon: Icon(Icons.audiotrack_outlined),
            selectedIcon: Icon(Icons.audiotrack),
            label: 'Audio',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description),
            label: 'Documents',
          ),
          NavigationDestination(
            icon: Icon(Icons.download_outlined),
            selectedIcon: Icon(Icons.download),
            label: 'Downloads',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Progress',
          ),
        ],
      ),
    );
  }
}
