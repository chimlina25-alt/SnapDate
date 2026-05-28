import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:path_provider/path_provider.dart';
import 'utils/app_image.dart';
import 'screens/auth_wrapper.dart';
import 'service/notification_service.dart';

void main() async {
  // Ensures Flutter framework widgets are bound before initializing the backend
  WidgetsFlutterBinding.ensureInitialized();

  // Initializing connection to your Firebase Android app
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService().initialize();

  if (!kIsWeb) {
    final docDir = await getApplicationDocumentsDirectory();
    appDocumentsDirectoryPath = docDir.path;
  }

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
      home: const AuthWrapper(),
    );
  }
}
