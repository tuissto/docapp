// lib/screens/main_layout.dart

import 'package:doctor_appointment_app/models/auth_model.dart';
import 'package:doctor_appointment_app/screens/appointment_page.dart';
import 'package:doctor_appointment_app/screens/fav_page.dart';
import 'package:doctor_appointment_app/screens/home_page.dart';
import 'package:doctor_appointment_app/screens/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils/config.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({Key? key}) : super(key: key);

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  // List of screens corresponding to each tab
  final List<Widget> _screens = [
    const HomePage(),
    const AppointmentPage(),
    const FavPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthModel>(
      builder: (context, auth, child) {
        return Scaffold(
          appBar: AppBar(
            title: _buildAppBarTitle(_currentIndex),
            backgroundColor: Config.primaryColor,
            centerTitle: _currentIndex == 0, // Center title only for "Bookit"
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.logout,
                  size: 28.0, // Increased icon size for consistency
                ),
                onPressed: () async {
                  await auth.logout();
                  // Navigate back to AuthPage after logout
                  Navigator.pushReplacementNamed(context, '/');
                },
              ),
            ],
          ),
          body: _screens[_currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            iconSize: 30.0, // Ensures all icons are uniformly sized
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.black,
            backgroundColor: Config.primaryColor,
            type: BottomNavigationBarType.fixed,
            showSelectedLabels: false, // Hide labels for selected items
            showUnselectedLabels: true, // Show labels for unselected items
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.home_outlined),
                activeIcon: const Icon(Icons.home),
                label: '', // Removes the "Bookit" label
                tooltip: 'Bookit', // Provides accessibility label
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today_outlined),
                activeIcon: Icon(Icons.calendar_today),
                label: 'Mes rendez-vous',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.favorite_border),
                activeIcon: Icon(Icons.favorite),
                label: 'Favoris',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }

  // Custom method to build the AppBar title with conditional styling
  Widget _buildAppBarTitle(int index) {
    String title = _getTitle(index);
    TextStyle? titleStyle;

    if (title == 'Bookit') {
      titleStyle = const TextStyle(
        fontFamily: 'DreamAvenue', // Apply the custom font
        fontSize: 60, // Adjusted font size for balance
        fontWeight: FontWeight.w500,
        color: Colors.black87 , // Custom color for visibility
      );
    } else {
      titleStyle = const TextStyle(
        fontSize: 20, // Default font size for other titles
        fontWeight: FontWeight.w400,
        color: Colors.black87, // Default AppBar text color
      );
    }

    return Text(
      title,
      style: titleStyle,
      textAlign: _currentIndex == 0 ? TextAlign.center : TextAlign.start, // Centers "Bookit" title
    );
  }

  String _getTitle(int index) {
    switch (index) {
      case 0:
        return 'Bookit';
      case 1:
        return 'Mes rendez-vous';
      case 2:
        return 'Favoris';
      case 3:
        return 'Profile';
      default:
        return 'Doctor App';
    }
  }
}
