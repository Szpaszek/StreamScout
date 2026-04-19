import 'package:flutter/material.dart';
import 'package:frontend/services/watchlistservice.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Data & Privacy",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.delete_sweep_outlined,
              color: Colors.redAccent,
            ),
            title: const Text("Clear Watchlist"),
            subtitle: const Text("Remove all saved movies and shows"),
            onTap: () => _showDeleteConfirmation(context),
          ),
          // add more settings at a later date
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text("Clear Watchlist?"),
        content: const Text(
          "This will permanently remove all items from your watchlist.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () async {
              await WatchlistService.clearWatchlist();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Watchlist cleared successfully"),
                  ),
                );
              }
            },
            child: const Text(
              "Clear All",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}
