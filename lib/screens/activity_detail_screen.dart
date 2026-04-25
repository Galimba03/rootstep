// lib/screens/activity_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';

import '../models/activity.dart';

class ActivityDetailScreen extends StatelessWidget {
  final Activity activity;

  const ActivityDetailScreen({super.key, required this.activity});

  String _formatDuration(int totalSeconds) {
    final int hours = totalSeconds ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;
    final int seconds = totalSeconds % 60;

    if (hours > 0) {
      return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
    }
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final List<LatLng> points = [];
    
    for (var segment in activity.route) {
      for (var pt in segment) {
        if (pt.length >= 2) {
          points.add(LatLng(pt[0], pt[1]));
        }
      }
    }

    bool hasValidBounds = false;
    LatLngBounds? mapBounds;
    
    if (points.isNotEmpty) {
      mapBounds = LatLngBounds.fromPoints(points);
      if (mapBounds.southWest.latitude != mapBounds.northEast.latitude || 
          mapBounds.southWest.longitude != mapBounds.northEast.longitude) {
        hasValidBounds = true;
      }
    }

    final String formattedDate = DateFormat('EEEE, MMM d, yyyy • HH:mm').format(activity.dateTime);
    final String distanceKm = (activity.distance / 1000).toStringAsFixed(2);
    final String displayTime = _formatDuration(activity.durationInSeconds);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Run Detail'),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 300,
            child: FlutterMap(
              options: MapOptions(
                initialCameraFit: hasValidBounds 
                    ? CameraFit.bounds(
                        bounds: mapBounds!,
                        padding: const EdgeInsets.all(40),
                      )
                    : null,
                initialCenter: points.isNotEmpty ? points.first : const LatLng(45.46, 9.19),
                initialZoom: points.isNotEmpty ? 15.0 : 2.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.galimba.rootstep_app',
                ),
                if (points.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: points,
                        color: const Color(0xFF2D5A27),
                        strokeWidth: 4,
                      ),
                    ],
                  ),
                if (points.isNotEmpty)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: points.first,
                        width: 16,
                        height: 16,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D1B11),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildDetailItem("Distance", "$distanceKm km"),
                      _buildDetailItem("Time", displayTime),
                      _buildDetailItem("Pace", activity.pace),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ],
    );
  }
}