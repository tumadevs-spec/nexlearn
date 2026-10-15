import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Use local Firebase emulators only in debug builds.
  if (kDebugMode) {
    final String emulatorHost = kIsWeb
        ? '127.0.0.1'
        : defaultTargetPlatform == TargetPlatform.android
            ? '10.0.2.2'
            : '127.0.0.1';

    await FirebaseAuth.instance.useAuthEmulator(
      emulatorHost,
      9099,
    );

    FirebaseFunctions.instanceFor(
      region: 'asia-south1',
    ).useFunctionsEmulator(
      emulatorHost,
      5001,
    );

    debugPrint('Firebase Auth emulator: $emulatorHost:9099');
    debugPrint('Firebase Functions emulator: $emulatorHost:5001');
  }

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