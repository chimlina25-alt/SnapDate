import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../main_layout.dart';
import '../views/welcome_view.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFFFFB6C1)),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return const MainLayout();
        }

        return const WelcomeView();
      },
    );
  }
}
