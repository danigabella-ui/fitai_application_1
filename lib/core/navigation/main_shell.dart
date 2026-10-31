import 'package:flutter/material.dart';

import '../../features/calendar/presentation/calendar_screen.dart';
import '../../features/chat/presentation/chat_screen.dart';
import '../../features/checkin/presentation/checkin_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';

/// A fő keret: alul a navigációs sáv a négy füllel, felette az aktív képernyő.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  /// A fülek sorrendje itt és a navigációs sávban is ugyanaz kell legyen.
  static const List<Widget> _screens = [
    ChatScreen(),
    CalendarScreen(),
    CheckInScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Az IndexedStack megőrzi a fülek állapotát váltáskor
      // (pl. a chat nem ürül ki, ha átnézel a naptárba).
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Naptár',
          ),
          NavigationDestination(
            icon: Icon(Icons.wb_sunny_outlined),
            selectedIcon: Icon(Icons.wb_sunny),
            label: 'Check-In',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
