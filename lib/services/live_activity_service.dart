import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class LiveActivityService {
  static const MethodChannel _channel = MethodChannel('com.galimba.rootstep/live_activity');

  static Future<void> startActivity({
    required String time,
    required double distance,
    required String pace,
    required int startTimeMs,
    required bool isPaused,
  }) async {
    try {
      await _channel.invokeMethod('startActivity', {
        'time': time,
        'distance': distance,
        'pace': pace,
        'startTimeMs': startTimeMs,
        'isPaused': isPaused,
      });
    } on PlatformException catch (e) {
      if (e.code != 'NO_ACTIVITY') debugPrint("Start error: ${e.message}");
    }
  }

  static Future<void> updateActivity({
    required String time,
    required double distance,
    required String pace,
    required int startTimeMs,
    required bool isPaused,
  }) async {
    try {
      await _channel.invokeMethod('updateActivity', {
        'time': time,
        'distance': distance,
        'pace': pace,
        'startTimeMs': startTimeMs,
        'isPaused': isPaused,
      });
    } on PlatformException catch (e) {
      if (e.code != 'NO_ACTIVITY') debugPrint("Update error: ${e.message}");
    }
  }

  static Future<void> stopActivity() async {
    try {
      await _channel.invokeMethod('stopActivity');
    } on PlatformException catch (e) {
      if (e.code != 'NO_ACTIVITY') {
        debugPrint("Stop error: ${e.message}");
      }
    }
  }
}