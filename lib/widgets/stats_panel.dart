import 'package:flutter/material.dart';

class StatsPanel extends StatelessWidget {
  final String elapsedTime;
  final double totalDistance;
  final String pace;
  final String lastKmPace;
  final double altitude;

  const StatsPanel({
    super.key,
    required this.elapsedTime,
    required this.totalDistance,
    required this.pace,
    required this.lastKmPace,
    required this.altitude,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: Colors.white.withOpacity(0.95),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem("Time", elapsedTime),
            _buildStatItem("Dist. (km)", (totalDistance / 1000).toStringAsFixed(2)),
            _buildStatItem("Avg", pace),
            _buildStatItem("Lap", lastKmPace),
            _buildStatItem("Alt", altitude.toStringAsFixed(0)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ],
    );
  }
}