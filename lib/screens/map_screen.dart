import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio_cache_interceptor_hive_store/dio_cache_interceptor_hive_store.dart';

import '../services/storage_service.dart';
import '../widgets/stats_panel.dart';
import '../widgets/control_buttons.dart';
import 'summary_screen.dart';

// TODO: make the bottom nav-bar disappear when the workout starts

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  // Map logic and cache
  LatLng? _currentPosition;
  final MapController _mapController = MapController();
  HiveCacheStore? _cacheStore;

  // Workout logic
  bool _isWorkoutActive = false;
  bool _isPaused = false;
  final List<List<LatLng>> _trackSegments = [];
  double _totalDistance = 0.0;
  double _altitude = 0.0;

  double _last50mDistance = 0.0;
  double _lastKmDistance = 0.0;
  Duration _lastKmDuration = Duration.zero;
  List<String> _kmSplits = []; // Times every km
  String _displayPace = "0'00\"";
  String _lastKmPace = "-'--\"";

  // Timer
  late Stopwatch _stopwatch;
  late Timer _timer;
  String _elapsedTime = "00:00";

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch();
    _initCache();
    _setupLocation();
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_stopwatch.isRunning) {
        setState(() {
          _elapsedTime = _formatDuration(_stopwatch.elapsed);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _initCache() async {
    final dir = await getTemporaryDirectory();
    setState(() {
      _cacheStore = HiveCacheStore('${dir.path}/map_tiles');
    });
  }

  // Function for the zoom/de-zoom animation when the workout start/pause
  void _animatedMapMove(LatLng destLocation, double destZoom) {
    final latTween = Tween<double>(
        begin: _mapController.camera.center.latitude,
        end: destLocation.latitude);
    final lngTween = Tween<double>(
        begin: _mapController.camera.center.longitude,
        end: destLocation.longitude);
    final zoomTween = Tween<double>(
        begin: _mapController.camera.zoom, 
        end: destZoom);

    final controller = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
    
    final Animation<double> animation = CurvedAnimation(
        parent: controller, curve: Curves.fastOutSlowIn);

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controller.dispose();
      } else if (status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(duration.inMinutes)}:${twoDigits(duration.inSeconds.remainder(60))}";
  }

  String _calculatePace() {
    if (_totalDistance == 0) return "0'00\"";
    double distanceKm = _totalDistance / 1000;
    double totalMinutes = _stopwatch.elapsed.inSeconds / 60;
    double paceDecimal = totalMinutes / distanceKm;
    
    int minutes = paceDecimal.toInt();
    int seconds = ((paceDecimal - minutes) * 60).toInt();
    return "$minutes'${seconds.toString().padLeft(2, "0")}\"";
  }

  void _setupLocation() async {
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5),
    ).listen((Position position) {
      if (!mounted) return;

      setState(() {
        LatLng newPoint = LatLng(position.latitude, position.longitude);
        _altitude = position.altitude;

        if (_isWorkoutActive && !_isPaused) {
          if (_trackSegments.isNotEmpty && _trackSegments.last.isNotEmpty) {
            double d = Geolocator.distanceBetween(
              _trackSegments.last.last.latitude, _trackSegments.last.last.longitude,
              newPoint.latitude, newPoint.longitude,
            );
            _totalDistance += d;

            // 1. Update of the Pace every 50m
            if (_totalDistance - _last50mDistance >= 50) {
              _displayPace = _calculateAveragePace();
              _last50mDistance = _totalDistance;
            }

            // 2. Chilometers logic (Splits)
            if (_totalDistance - _lastKmDistance >= 1000) {
              _saveKmSplit();
            }
          }
          _trackSegments.last.add(newPoint);
        }
        _currentPosition = newPoint;

        try {
          _mapController.move(_currentPosition!, _mapController.camera.zoom);
        } catch (e) {
          debugPrint("Map not ready");
        }
      });
    });
  }

  void _saveKmSplit() {
    Duration totalElapsed = _stopwatch.elapsed;
    Duration lapDuration = totalElapsed - _lastKmDuration;
    
    String splitTime = _formatDuration(lapDuration);
    _kmSplits.add(splitTime);
    _lastKmPace = splitTime; // Il passo dell'ultimo km
    
    _lastKmDistance = _totalDistance;
    _lastKmDuration = totalElapsed;
  }

  String _calculateAveragePace() {
    if (_totalDistance < 10) return "0'00\"";
    double distanceKm = _totalDistance / 1000;
    double totalMinutes = _stopwatch.elapsed.inSeconds / 60;
    double paceDecimal = totalMinutes / distanceKm;
    
    int min = paceDecimal.toInt();
    int sec = ((paceDecimal - min) * 60).toInt();
    return "$min'${sec.toString().padLeft(2, "0")}\"";
  }

  void _toggleWorkout() {
    setState(() {
      if (!_isWorkoutActive) {
        _isWorkoutActive = true;
        _isPaused = false;

        List<LatLng> initialSegment = [];
        if (_currentPosition != null) {
          initialSegment.add(_currentPosition!);
        }
        _trackSegments.add(initialSegment); // first segment
        _stopwatch.start();

        // Dynamic zoom in on start
        if (_currentPosition != null) {
          _animatedMapMove(_currentPosition!, 17.5);
        }
      } else {
        _isPaused = !_isPaused;
        if (_isPaused) {
          _stopwatch.stop();

          // Dynamic zoom out on pause
          if (_currentPosition != null) {
            _animatedMapMove(_currentPosition!, 14.5);
          }
        } else {
          _trackSegments.add([]); // new segment after the pause
          _stopwatch.start();

          // Back to close zoom on resume
          if (_currentPosition != null) {
            _animatedMapMove(_currentPosition!, 17.5);
          }
        }
      }
    });
  }

  void _resetWorkout() {
    setState(() {
      _isWorkoutActive = false;
      _isPaused = false;
      _totalDistance = 0.0;
      _elapsedTime = "00:00";
      _displayPace = "0'00\"";

      _trackSegments.clear();
      _trackSegments.add([]);

      _kmSplits.clear();
      _stopwatch.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_cacheStore == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      body: Stack(
        children: [
          // 1. The map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(initialCenter: _currentPosition ?? const LatLng(45.46, 9.19), initialZoom: 15),
            children: [
              // FMap LAYER 1: Tile downloaded from openstreetmap
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.galimba.rootstep_app',
                tileProvider: CachedTileProvider(store: _cacheStore!),
              ),
              
              // FMap LAYER 2: Polyline for the tracking of the path
              if (_trackSegments.any((s) => s.isNotEmpty))
                PolylineLayer(
                  polylines: _trackSegments
                    .where((segment) => segment.isNotEmpty)
                    .map((segment) => Polyline(
                          points: segment,
                          color: Colors.green,
                          strokeWidth: 4.0,
                        ))
                    .toList(),
              ),

              // FMap LAYER 3: Point of the GPS
              if (_currentPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentPosition!, 
                      child: const Icon(Icons.my_location, color: Colors.blueAccent, size: 28)
                    )
                  ],
                ),
            ],
          ),
          
          // 2. Statistics panel
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: SafeArea(
              child: StatsPanel(
                elapsedTime: _elapsedTime,
                totalDistance: _totalDistance,
                pace: _displayPace, 
                lastKmPace: _lastKmPace,
                altitude: _altitude,
              ),
            ),
          ),

          // 3. Control buttons
          Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: ControlButtons(
              isWorkoutActive: _isWorkoutActive,
              isPaused: _isPaused,
              onToggleWorkout: _toggleWorkout,
              onStopWorkout: () async {
                _stopwatch.stop();
                // _timer.cancel();

                final distanceSaved = _totalDistance;
                final timeSaved = _elapsedTime;
                final paceSaved = _displayPace;
                final routeSaved = List<List<LatLng>>.from(_trackSegments);
                final splitsSaved = List<String>.from(_kmSplits);

                await StorageService.saveActivity(
                  distance: distanceSaved,
                  elapsedTime: timeSaved,
                  pace: paceSaved,
                  route: routeSaved,
                  splits: splitsSaved,
                );

                if (!mounted) return;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SummaryScreen(
                      distance: distanceSaved,
                      time: timeSaved,
                      pace: paceSaved,
                      route: routeSaved,
                      splits: splitsSaved,
                    ),
                  ),
                );

                _resetWorkout();
              },
            ),
          ),
        ],
      ),
    );
  }
}