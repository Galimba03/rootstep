import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class SummaryScreen extends StatelessWidget {
  final double distance;
  final String time;
  final String pace;
  final List<List<LatLng>> route;
  final List<String> splits;

  const SummaryScreen({
    super.key,
    required this.distance,
    required this.time,
    required this.pace,
    required this.route,
    required this.splits,
  });

  LatLngBounds? _getBounds() {
    if (route.isEmpty || route.first.isEmpty) return null;
    
    double minLat = 90.0;
    double maxLat = -90.0;
    double minLng = 180.0;
    double maxLng = -180.0;

    for (var segment in route) {
      for (var point in segment) {
        if (point.latitude < minLat) minLat = point.latitude;
        if (point.latitude > maxLat) maxLat = point.latitude;
        if (point.longitude < minLng) minLng = point.longitude;
        if (point.longitude > maxLng) maxLng = point.longitude;
      }
    }
    
    return LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));
  }

  @override
  Widget build(BuildContext context) {
    final bounds = _getBounds();
    bool hasValidBounds = false;
    
    if (bounds != null) {
      // Check if the bounds actually represent an area and not just a single dot
      if (bounds.southWest.latitude != bounds.northEast.latitude || 
          bounds.southWest.longitude != bounds.northEast.longitude) {
        hasValidBounds = true;
      }
    }

    // Get the first point to use as a fallback center
    LatLng? firstPoint;
    if (route.isNotEmpty && route.first.isNotEmpty) {
      firstPoint = route.first.first;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Summary'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 250,
            child: firstPoint == null
                ? const Center(child: Text('No route data'))
                : FlutterMap(
                    options: MapOptions(
                      initialCameraFit: hasValidBounds
                          ? CameraFit.bounds(
                              bounds: bounds!,
                              padding: const EdgeInsets.all(32.0),
                            )
                          : null,
                      initialCenter: firstPoint,
                      initialZoom: 15.0, // Default zoom for single-point runs
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.none, 
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.galimba.rootstep_app',
                      ),
                      PolylineLayer(
                        polylines: route
                            .where((segment) => segment.isNotEmpty)
                            .map((segment) => Polyline(
                                  points: segment,
                                  color: Colors.green.shade700,
                                  strokeWidth: 5,
                                ))
                            .toList(),
                      ),
                      if (!hasValidBounds)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: firstPoint,
                              width: 16,
                              height: 16,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.green.shade700,
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

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem('Distance', '${(distance / 1000).toStringAsFixed(2)} km'),
                _buildStatItem('Time', time),
                _buildStatItem('Avg Pace', pace),
              ],
            ),
          ),

          const Divider(),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Splits',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          Expanded(
            child: ListView.builder(
              itemCount: splits.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.shade100,
                    foregroundColor: Colors.green.shade900,
                    child: Text('${index + 1}'),
                  ),
                  title: Text('Kilometer ${index + 1}'),
                  trailing: Text(
                    splits[index],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      ],
    );
  }
}