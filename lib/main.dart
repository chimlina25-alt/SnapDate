import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'views/welcome_view.dart'; // Links directly to your onboarding landing screen


void main() async {
  // Ensures Flutter framework widgets are bound before initializing the backend
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initializing connection to your Firebase Android app
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SnapDate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Setting up standard app background and accent colors matching your UI designs
        scaffoldBackgroundColor: const Color(0xFFE8F1F2), 
        primaryColor: const Color(0xFFFFB7B2),
      ),
      home: const WelcomeView(), // Sets the landing page as the entry screen
    );
  }
}