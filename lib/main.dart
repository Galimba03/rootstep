import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'screens/home_screen.dart';

import 'models/activity.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Hive.initFlutter(); // initialize Hive
  Hive.registerAdapter(ActivityAdapter()); // register the adapter
  await Hive.openBox<Activity>('activities'); // open the box for our runs

  runApp(const FitnessApp());
}

class FitnessApp extends StatelessWidget {
  const FitnessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Root Step',
      debugShowCheckedModeBanner: false, // Removes the 'debug' badge in the top-right corner
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const HomeScreen(), // The first screen
    );
  }
}