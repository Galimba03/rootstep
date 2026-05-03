import 'package:flutter/services.dart';

class LiveActivityService {
  static const MethodChannel _channel = MethodChannel('com.galimba.rootstep/live_activity');

  static Future<void> startActivity({
    required String time,
    required double distance,
    required String pace,
  }) async {
    try {
      await _channel.invokeMethod('startActivity', {
        'time': time,
        'distance': distance,
        'pace': pace,
      });
    } on PlatformException catch (e) {
      print("Failed to start Live Activity: ${e.message}");
    }
  }

  static Future<void> updateActivity({
    required String time,
    required double distance,
    required String pace,
  }) async {
    await _channel.invokeMethod('updateActivity', {
      'time': time,
      'distance': distance,
      'pace': pace,
    });
  }

  static Future<void> stopActivity() async {
    await _channel.invokeMethod('stopActivity');
  }
}