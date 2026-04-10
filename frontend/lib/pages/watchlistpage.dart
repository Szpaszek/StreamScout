import 'package:flutter/material.dart';
import 'package:frontend/models/media.dart';
import 'package:frontend/services/watchlistservice.dart';
import 'package:frontend/widgets/watchlisttile.dart';

class WatchlistPage extends StatelessWidget {
  const WatchlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ValueListenableBuilder<List<Media>>(
        valueListenable: WatchlistService.watchlistNotifier,
        builder: (context, watchlist, _) {
          if (watchlist.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: watchlist.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final media = watchlist[index];
              return WatchlistTile(media: media);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        "Your list is empty",
        style: TextStyle(color: Colors.black54),
      ),
    );
  }
}
