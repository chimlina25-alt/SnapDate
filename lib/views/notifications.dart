import 'package:flutter/material.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final List<dynamic> notificationsCacheSnapshot = []; // Empty data initialization array

    if (notificationsCacheSnapshot.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.notifications_none_rounded, size: 65, color: Colors.grey[300]),
              const SizedBox(height: 14),
              const Text(
                "No notifications available.",
                style: TextStyle(fontFamily: 'Georgia', color: Colors.black38),
              ),
            ],
          ),
        ),
      );
    }

    return const Scaffold(body: SizedBox.shrink());
  }
}