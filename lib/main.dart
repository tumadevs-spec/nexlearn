import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const NexLearnApp());
}

class NexLearnApp extends StatelessWidget {
  const NexLearnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NexLearn',

      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Poppins',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7567E8),
        ),
      ),

      home: const HomeScreen(),
    );
  }
}