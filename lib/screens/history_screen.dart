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
              padding: const EdgeInsets.only(top: 8),
              itemCount: _activities.length,
              itemBuilder: (context, index) {
                final activity = _activities[index];
                
                // Widget per eliminare con lo swipe
                return Dismissible(
                  key: Key(activity.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (direction) async {
                    return await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Delete Activity"),
                        content: const Text("Are you sure you want to delete this run permanently?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false), // Non cancella
                            child: const Text("CANCEL"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true), // Procede con la cancellazione
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text("DELETE"),
                          ),
                        ],
                      ),
                    );
                  },
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) async {
                    // Eliminiamo dal database Hive
                    await StorageService.deleteActivity(index);
                    
                    // Rimuoviamo dalla lista locale e aggiorniamo la UI
                    setState(() {
                      _activities.removeAt(index);
                    });

                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Activity deleted')),
                    );
                  },
                  child: _ActivityCard(activity: activity),
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