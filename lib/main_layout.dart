import 'package:flutter/material.dart';
import 'views/calendar_view.dart';
import 'views/camera_view.dart';
import 'views/profile_view.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _views = [
    const CalendarView(),
    const CameraView(),
    const ProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _views,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: const Color(0xFFFFB7B2), 
        unselectedItemColor: Colors.grey,           
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,               
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined, size: 28),
            activeIcon: Icon(Icons.calendar_month, size: 28),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt_outlined, size: 28),
            activeIcon: Icon(Icons.camera_alt, size: 28),
            label: 'Camera',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline, size: 28),
            activeIcon: Icon(Icons.person, size: 28),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}