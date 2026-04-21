import 'package:flutter/material.dart';

class ControlButtons extends StatelessWidget {
  final bool isWorkoutActive;
  final bool isPaused;
  final VoidCallback onToggleWorkout;
  final VoidCallback onStopWorkout;

  const ControlButtons({
    super.key,
    required this.isWorkoutActive,
    required this.isPaused,
    required this.onToggleWorkout,
    required this.onStopWorkout,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Start | Stop | Pause button
          FloatingActionButton.extended(
            onPressed: onToggleWorkout,
            label: Text(
              !isWorkoutActive ? "START" : (isPaused ? "RESUME" : "PAUSE"),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            icon: Icon(!isWorkoutActive || isPaused ? Icons.play_arrow : Icons.pause),
            backgroundColor: isPaused ? Colors.green.shade900 : Colors.green.shade600,
            foregroundColor: Colors.white,
          ),
          
          const SizedBox(width: 20),
          
          // Stop button (appears only if the workout is started)
          // TODO: Center in a better place
          if (isWorkoutActive)
            GestureDetector(
              onLongPress: onStopWorkout,
              child: const Tooltip(
                message: "Hold to stop",
                triggerMode: TooltipTriggerMode.tap,
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.red,
                  child: Icon(Icons.stop, color: Colors.white, size: 30),
                ),
              ),
            ),
        ],
      ),
    );
  }
}