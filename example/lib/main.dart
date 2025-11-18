import 'package:flutter/material.dart';
import 'package:media_player/media_player.dart';

import 'screens/home_screen.dart';
import 'services/analytics_service.dart';
import 'services/download_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Required for video playback
  MediaKit.ensureInitialized();

  // Initialize media player storage
  await LMSMediaManager.initialize(storageType: StorageType.sqflite);

  // Initialize services
  await DownloadService.instance.initialize();
  await AnalyticsService.instance.initialize();

  runApp(const LMSMediaExampleApp());
}

class LMSMediaExampleApp extends StatelessWidget {
  const LMSMediaExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LMS Media Player Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      ),
      home: const HomeScreen(),
    );
  }
}
