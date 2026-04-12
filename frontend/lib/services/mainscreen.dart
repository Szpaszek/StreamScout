import 'package:flutter/material.dart';
import 'package:frontend/models/media.dart';
import 'package:frontend/pages/mediadetailspage.dart';
import 'package:frontend/pages/homepage.dart';
import 'package:frontend/pages/watchlistpage.dart';
import 'package:frontend/pages/searchpage.dart';
import 'package:frontend/pages/settingspage.dart';
import 'package:frontend/services/navcontroller.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Keep track of the currently selected page index
  int _selectedIndex = 0;

  // List of pages to display
  final List<Widget> _pages = <Widget>[
    HomePage(),
    SearchPage(),
    WatchlistPage(),
    SettingsPage(),
  ];

  // Function to update the index when a new item is tapped
  void _onItemTapped(int index) {
    NavController.closeDetails();
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stream Scout')),

      // Display the currently selected page
      body: Stack(
        children: [
          // indexedStack do the BottomNav pages don't get reseted
          IndexedStack(index: _selectedIndex, children: _pages),

          // show the details page on top of the current page if a media is selected
          ValueListenableBuilder<Media?>(
            valueListenable: NavController.selectedMedia,
            builder: (context, media, _) {
              if (media == null) return const SizedBox.shrink();

              return MediaDetailsPage(
                media: media,
                onBack: () => NavController.closeDetails(),
              );
            },
          ),
        ],
      ),

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
