import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'views/home_view.dart';
import 'views/calendar_view.dart';
import 'views/favorites.dart';
import 'views/chat.dart';
import 'views/profile_view.dart';
import 'views/notifications.dart';
import 'views/camera_view.dart';
import 'views/gallery.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  String _currentScreen = 'home';

  void _navigateTo(String screenName) {
    setState(() {
      _currentScreen = screenName;
    });
  }

  void _resetToHome() {
    setState(() {
      _currentScreen = 'home';
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isHome = _currentScreen == 'home';

    return WillPopScope(
      onWillPop: () async {
        if (!isHome) {
          _resetToHome();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFA3D2CA),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Global Header Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    !isHome
                        ? IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 22),
                            onPressed: _resetToHome, // Clicking always takes the user back to the Home Screen
                          )
                        : Expanded(
                            child: Container(
                              height: 45,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF5F5),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: const TextField(
                                decoration: InputDecoration(
                                  hintText: 'Search Profile...',
                                  hintStyle: TextStyle(color: Colors.black38, fontSize: 14),
                                  prefixIcon: Icon(Icons.search, color: Colors.black38, size: 20),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                              ),
                            ),
                          ),
                    if (isHome) const SizedBox(width: 15),
                    GestureDetector(
                      onTap: () => _navigateTo('profile'),
                      child: Container(
                        width: 45, height: 45,
                        decoration: const BoxDecoration(color: Color(0xFFFFF5F5), shape: BoxShape.circle),
                        child: const Center(
                          child: Text('pf', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Core Screen Content Window
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(45), topRight: Radius.circular(45)),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(45), topRight: Radius.circular(45)),
                    child: _getActiveView(),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  Widget _getActiveView() {
  switch (_currentScreen) {
    case 'home': 
      // CHANGED: Added the required onNavigate parameter here
      return HomeView(onNavigate: _navigateTo); 
    case 'calendar': 
      return CalendarView(onBackToHome: _resetToHome);
    case 'favorites': 
      return FavoritesView(onBackToHome: _resetToHome);
    case 'chat': 
      return const ChatView();
    case 'profile': 
      return ProfileView(onBackToHome: _resetToHome);
    case 'notifications': 
      return const NotificationsView();
    case 'camera': 
      return const CameraMainView();
    case 'gallery': 
      return GalleryView(onBackToHome: _resetToHome);
    default: 
      // CHANGED: Added the required onNavigate parameter here as well
      return HomeView(onNavigate: _navigateTo);
  }
}

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 80,
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            onPressed: () => _navigateTo('notifications'),
            icon: Icon(Icons.notifications_none_rounded, size: 30, color: _currentScreen == 'notifications' ? const Color(0xFFD6A2A8) : Colors.black26),
          ),
          GestureDetector(
            onTap: () => _navigateTo('camera'),
            child: Container(
              width: 55, height: 55,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5F5), shape: BoxShape.circle,
                border: Border.all(color: _currentScreen == 'camera' ? const Color(0xFFD6A2A8) : const Color(0xFFEBEBEB), width: 2.5),
              ),
              child: const Icon(Icons.camera_alt_outlined, size: 26, color: Colors.black87),
            ),
          ),
          IconButton(
            onPressed: () => _navigateTo('gallery'),
            icon: Icon(Icons.image_outlined, size: 30, color: _currentScreen == 'gallery' ? const Color(0xFFD6A2A8) : Colors.black26),
          ),
        ],
      ),
    );
  }
}