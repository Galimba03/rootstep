import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';
import '../models/activity.dart';
import 'activity_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Activity> _activities = [];

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  void _loadActivities() {
    setState(() {
      _activities = StorageService.getAllActivities();
    });
  }

  void _deleteActivity(int index) async {
    await StorageService.deleteActivity(index);
    setState(() {
      _activities.removeAt(index);
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Activity deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity History'),
        centerTitle: true,
      ),
      body: _activities.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.only(
                top: 8,
                left: 0,
                right: 0,
                bottom: 20, 
              ),
              itemCount: _activities.length,
              itemBuilder: (context, index) {
                final activity = _activities[index];
                
                // Swipable for the elimination of a run
                return _SwipeableActivityCard(
                  key: ValueKey(activity.id),
                  activity: activity,
                  onDeleteConfirm: () => _deleteActivity(index),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_run, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No runs recorded yet.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _SwipeableActivityCard extends StatefulWidget {
  final Activity activity;
  final VoidCallback onDeleteConfirm;

  const _SwipeableActivityCard({
    super.key,
    required this.activity,
    required this.onDeleteConfirm,
  });

  @override
  State<_SwipeableActivityCard> createState() => _SwipeableActivityCardState();
}

class _SwipeableActivityCardState extends State<_SwipeableActivityCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _dragExtent = 0.0;
  final double _maxDragDistance = 90.0; // Space to show the button

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _controller.addListener(() {
      setState(() {
        _dragExtent = _animation.value;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragExtent += details.primaryDelta!;
      // Can't slide right and can't go over the total length on the left.
      if (_dragExtent < -_maxDragDistance) {
        _dragExtent = -_maxDragDistance;
      } else if (_dragExtent > 0) {
        _dragExtent = 0;
      }
    });
  }

  void _onDragEnd(DragEndDetails details) {
    // If it goes over half of the screen, it has done a "quick swipe".
    if (_dragExtent < -_maxDragDistance / 2 || details.primaryVelocity! < -500) {
      _openSwipe();
    } else {
      _closeSwipe();
    }
  }

  void _openSwipe() {
    _animation = Tween<double>(begin: _dragExtent, end: -_maxDragDistance).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward(from: 0.0);
  }

  void _closeSwipe() {
    _animation = Tween<double>(begin: _dragExtent, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      child: Stack(
        children: [
          // 1. The TRASH button (Bottom layer)
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0, top: 6.0, bottom: 6.0),
                child: GestureDetector(
                  onTap: () async {
                    bool? confirm = await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Delete Activity"),
                        content: const Text("Are you sure you want to delete this run permanently?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("CANCEL"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text("DELETE"),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      widget.onDeleteConfirm();
                    } else {
                      _closeSwipe();
                    }
                  },
                  child: Container(
                    width: 70,
                    height: double.infinity, // force the height to be the one of the Activity Card
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                      // Shadow to make it seem like the Activity Card
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.red, size: 28), // Red trash icon
                  ),
                ),
              ),
            ),
          ),
          
          // 2. Card of the activity (Upper layer)
          Transform.translate(
            offset: Offset(_dragExtent, 0),
            child: _ActivityCard(activity: widget.activity),
          ),
        ],
      ),
    );
  }
}

// DESIGN OF THE CARD
class _ActivityCard extends StatelessWidget {
  final Activity activity;

  const _ActivityCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEEE, MMM d • HH:mm').format(activity.dateTime);
    final distanceKm = (activity.distance / 1000).toStringAsFixed(2);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      color: Colors.white, // Assicura che la card non sia trasparente nascondendo il cestino
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.timeline, color: Color(0xFF2D5A27)),
        ),
        title: Text(
          dateStr,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            '$distanceKm km  |  Pace: ${activity.pace}',
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ActivityDetailScreen(activity: activity),
            ),
          );
        },
      ),
    );
  }
}