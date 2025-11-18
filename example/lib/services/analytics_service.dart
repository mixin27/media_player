// ignore_for_file: avoid_print

import 'package:media_player/media_player.dart';

class AnalyticsService {
  static final AnalyticsService instance = AnalyticsService._();
  AnalyticsService._();

  Future<void> initialize() async {
    // Initialize your analytics service (Firebase, Mixpanel, etc.)
  }

  void trackMediaEvent(MediaEvent event) {
    final json = event.toAnalyticsJson();

    // Log to console for demo
    print('📊 Analytics: ${json['event']}');
    print('   Media: ${json['mediaId']}');
    print('   Type: ${json['mediaType']}');

    // In production, send to your analytics service:
    // FirebaseAnalytics.instance.logEvent(
    //   name: json['event'],
    //   parameters: json,
    // );
  }
}
