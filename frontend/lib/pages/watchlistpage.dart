import 'package:flutter/material.dart';

class WatchlistPage extends StatelessWidget {
  const WatchlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Your Watchlist is empty!',
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}