import 'package:flutter/material.dart';
import 'package:frontend/pages/home_page.dart';
import 'package:frontend/pages/watchlist_page.dart';
import 'package:frontend/pages/search_page.dart';
import 'package:frontend/pages/settings_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // keep track of the currently selected page index
  int _selectedIndex = 0;

  // list of pages to display
  static const List<Widget> _pages = <Widget>[
    HomePage(),
    SearchPage(),
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
      appBar: AppBar(title: Text('Stream Scout', style: TextStyle(color: Theme.of(context).colorScheme.primary))),

      // Display the currently selected page
      body: Center(child: _pages.elementAt(_selectedIndex)),

      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Watchlist'),
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
