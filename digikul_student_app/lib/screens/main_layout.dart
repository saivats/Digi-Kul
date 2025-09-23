import 'package:flutter/material.dart';

// Import the screens that the layout will manage
import 'package:digikul_student_app/screens/home_screen.dart';
import 'package:digikul_student_app/screens/my_courses_screen.dart';
import 'package:digikul_student_app/screens/profile_screen.dart';
import 'package:digikul_student_app/screens/settings_screen.dart';

// --- THEME COLORS ---
const Color primaryColor = Color(0xFF5247eb);

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  // List of the pages to be displayed.
  final List<Widget> _pages = [
    const HomePage(), // Corrected from HomeScreen
    const MyCoursesScreen(),
    const ProfileScreen(),
    const SettingsScreen(),
  ];

  void _onTabTapped(int index) {
    // Now we have all 4 screens available
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey.shade600,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined),
            activeIcon: Icon(Icons.school),
            label: 'My Courses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}