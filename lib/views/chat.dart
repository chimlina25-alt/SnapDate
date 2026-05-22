import 'package:flutter/material.dart';

class ChatView extends StatelessWidget {
  const ChatView({super.key});

  @override
  Widget build(BuildContext context) {
    // Hardcoded empty checker representing empty database lookup return collections
    final List<dynamic> databaseFriendsList = []; 

    if (databaseFriendsList.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat_bubble_outline_rounded, size: 65, color: Colors.grey[300]),
              const SizedBox(height: 14),
              const Text(
                "Your chat inbox is empty.\nUse search to add friends!",
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Georgia', color: Colors.black38, height: 1.4),
              ),
            ],
          ),
        ),
      );
    }

    return const Scaffold(body: SizedBox.shrink()); // Fallback placeholder line
  }
}