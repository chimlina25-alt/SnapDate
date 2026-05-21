import 'package:flutter/material.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFE8F1F2),
      body: Center(
        child: Text(
          'Profile Page View Container',
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
      ),
    );
  }
}