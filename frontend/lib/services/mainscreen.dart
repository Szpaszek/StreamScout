import 'package:flutter/material.dart';
import 'package:frontend/Pages/homepage.dart';
import 'package:frontend/Pages/watchlistpage.dart';
import 'package:frontend/pages/settingspage.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

    @override
  State<MainScreen> createState() => _MainScreenState();
}



class _MainScreenState extends State<MainScreen> {
  // Keep track of the currently selected page index
  int _selectedIndex = 0;

  // List of pages to display
  static const List<Widget> _pages = <Widget>[
    HomePage(),
    WatchlistPage(),
    SettingsPage(),
  ];

 // Function to update the index when a new item is tapped
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      
      title: const Text('Stream Scout'),
    ),

    // Display the currently selected page
    body: Center(
      child: _pages.elementAt(_selectedIndex),
    ),
     
    bottomNavigationBar: BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.list),
          label: 'Watchlist',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
      currentIndex: _selectedIndex,
      selectedItemColor: Colors.tealAccent,
      onTap: _onItemTapped,
    ),
  );
}

}

