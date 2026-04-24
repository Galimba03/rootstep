import 'dart:async';
import 'package:flutter/material.dart';

class ControlButtons extends StatefulWidget {
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
  State<ControlButtons> createState() => _ControlButtonsState();
}


class _ControlButtonsState extends State<ControlButtons> {
  bool _showHint = false;
  Timer? _hintTimer;

  void _triggerHint() {
    _hintTimer?.cancel();
    setState(() => _showHint = true);
    
    // The message disappears after 2 seconds
    _hintTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showHint = false);
    });
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min, // Occupy only the necessary space
        children: [
          AnimatedOpacity(
            opacity: _showHint ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Padding(
              padding: EdgeInsets.only(bottom: 16.0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200, 
                  borderRadius: BorderRadius.circular(20), 
                ),
                child: Text(
                  "Hold for 3 seconds to finish",
                  style: TextStyle(
                    color: Colors.grey.shade600, 
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Button START / PAUSE / RESUME
              FloatingActionButton.extended(
                onPressed: widget.onToggleWorkout,
                label: Text(
                  !widget.isWorkoutActive ? "START" : (widget.isPaused ? "RESUME" : "PAUSE"),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                icon: Icon(!widget.isWorkoutActive || widget.isPaused ? Icons.play_arrow : Icons.pause),
                backgroundColor: widget.isPaused ? Colors.green.shade700 : Colors.green.shade900,
                foregroundColor: Colors.white,
              ),
              
              // Button STOP
              if (widget.isWorkoutActive && widget.isPaused) ...[
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: _triggerHint, 
                  onLongPress: widget.onStopWorkout,
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.red,
                    child: const Icon(Icons.stop, color: Colors.white, size: 30),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}