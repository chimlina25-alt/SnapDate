import 'package:flutter/material.dart';

class HomeView extends StatelessWidget {
  final Function(String) onNavigate;
  const HomeView({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFCD7D9),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Text('SnapDate', style: TextStyle(fontFamily: 'Georgia', fontSize: 28, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
          ),
          const SizedBox(height: 25),
          const Text(
            'Every photo tells a story. Save your happiest moments and revisit them whenever you want',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Georgia', fontSize: 16, height: 1.4, color: Colors.black87),
          ),
          const SizedBox(height: 35),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 0.95,
            children: [
              _buildFeatureTile(Icons.calendar_month_outlined, 'Calendar', const Color(0xFFE26A97), () => onNavigate('calendar')),
              _buildFeatureTile(Icons.bookmark_border_rounded, 'Favourite', const Color(0xFFE26A97), () => onNavigate('favorites')),
              _buildFeatureTile(Icons.chat_bubble_outline_rounded, 'Chat', const Color(0xFFE26A97), () => onNavigate('chat')),
              _buildFeatureTile(Icons.person_outline_rounded, 'Profile', const Color(0xFFE26A97), () => onNavigate('profile')),
            ],
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildFeatureTile(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(color: const Color(0xFFEDF6F4), borderRadius: BorderRadius.circular(20)),
              child: Icon(icon, size: 100, color: color.withValues(alpha: 0.8)),
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontFamily: 'Georgia', fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
