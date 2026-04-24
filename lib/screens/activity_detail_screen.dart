import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/activity.dart';

class ActivityDetailScreen extends StatelessWidget {
  final Activity activity;

  const ActivityDetailScreen({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    // Convert List<List<List<double>>> back to List<LatLng> for Polyline
    final List<LatLng> points = activity.route.expand((segment) {
      return segment.map((p) => LatLng(p[0], p[1]));
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Run Detail')),
      body: Column(
        children: [
          SizedBox(
            height: 300,
            child: FlutterMap(
              options: MapOptions(
                initialCameraFit: (points.length > 1) 
                  ? CameraFit.bounds(
                      bounds: LatLngBounds.fromPoints(points),
                      padding: const EdgeInsets.all(40),
                    )
                  : null, // If there's only one point we don't use automatic fit
                
                // If fit cannot be done (only one point), center point manually
                initialCenter: (points.length == 1) ? points.first : const LatLng(0, 0),
                initialZoom: (points.length == 1) ? 15.0 : 1.0,
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
                if (points.length == 1)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: points.first,
                        width: 20,
                        height: 20,
                        child: const Icon(Icons.location_on, color: Colors.red),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // TODO: Add stats cards here similar to SummaryScreen
          Expanded(
            child: Center(child: Text("Details for run on ${activity.dateTime}")),
          )
        ],
      ),
    );
  }
}