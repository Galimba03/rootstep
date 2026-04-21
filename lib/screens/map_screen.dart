import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio_cache_interceptor_hive_store/dio_cache_interceptor_hive_store.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? _currentPosition;
  final MapController _mapController = MapController();
  HiveCacheStore? _cacheStore;
  bool _isFirstLocationUpdate = true;

  final List<LatLng> _routePoints = []; // Route points

  @override
  void initState() {
    super.initState();
    _initCache();
    _determinePosition();
  }

  Future<void> _initCache() async {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/map_tiles';
    setState(() {
      _cacheStore = HiveCacheStore(path);
    });
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    // Listen to the GPS input flow
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Update every 5 meters
      ),
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);

          // Updating route. Add a new point to the list '_routePoints'
          _routePoints.add(_currentPosition!);
          
          // If it is the first signal, move the pointer to the real point
          if (_isFirstLocationUpdate) {
            _mapController.move(_currentPosition!, 16.0);
            _isFirstLocationUpdate = false;
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_cacheStore == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Tracciamento Corsa')),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          // Default value: Milano center
          initialCenter: _currentPosition ?? const LatLng(45.4642, 9.1900),
          initialZoom: 15.0,
        ),
        children: [
          // LAYER 1: The map
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.galimba.rootstep_app',
            tileProvider: CachedTileProvider(store: _cacheStore!),
          ),

          // LAYER 2: the line of the path (Polyline)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _routePoints,
                color: Colors.orange,
                strokeWidth: 5.0, // line weigth
              ),
            ],
          ),

          // LAYER 3: the point with the current position
          if (_currentPosition != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: _currentPosition!,
                  width: 30,
                  height: 30,
                  child: const Icon(
                    Icons.my_location,
                    color: Colors.blue,
                    size: 30,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}