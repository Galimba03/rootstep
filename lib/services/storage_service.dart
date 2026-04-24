import 'package:hive/hive.dart';
import 'package:latlong2/latlong.dart';

import '../models/activity.dart';

class StorageService {
  static const String _boxName = 'activities';

  // Save a new activity to Hive
  static Future<void> saveActivity({
    required double distance,
    required String elapsedTime,
    required String pace,
    required List<List<LatLng>> route,
    required List<String> splits,
  }) async {
    final box = Hive.box<Activity>(_boxName);

    // Convert List<List<LatLng>> to List<List<List<double>>> for Hive storage
    final List<List<List<double>>> encodedRoute = route.map((segment) {
      return segment.map((point) => [point.latitude, point.longitude]).toList();
    }).toList();

    final newActivity = Activity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      dateTime: DateTime.now(),
      distance: distance,
      durationInSeconds: 0, // We could parse the string if needed later
      pace: pace,
      altitude: 0.0, // To be implemented with GPS data
      route: encodedRoute,
      splits: splits,
    );

    await box.add(newActivity);
  }

  // Retrieve all activities sorted by date (newest first)
  static List<Activity> getAllActivities() {
    final box = Hive.box<Activity>(_boxName);
    final activities = box.values.toList();
    activities.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return activities;
  }

  // Delete the single activity trough index
  static Future<void> deleteActivity(int index) async {
    final box = Hive.box<Activity>(_boxName);
    await box.deleteAt(index);
  }

  // Empty all the cronology
  static Future<void> deleteAllActivities() async {
    final box = Hive.box<Activity>(_boxName);
    await box.clear();
  }
}