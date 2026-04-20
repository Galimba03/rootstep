import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const FitnessApp());
}

class FitnessApp extends StatelessWidget {
  const FitnessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Open Tracker',
      debugShowCheckedModeBanner: false, // Removes the 'debug' badge in the top-right corner
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home: const HomeScreen(), // The first screen
    );
  }
}