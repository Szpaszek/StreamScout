import 'package:flutter/material.dart';
import 'package:frontend/services/watchlistservice.dart';
import 'package:frontend/widgets/mediacard.dart';

class WatchlistPage extends StatelessWidget {
  const WatchlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ValueListenableBuilder(
        valueListenable: WatchlistService.watchlistNotifier,
        builder: (context, watchlist, _) {
          // empty state if nothing is saved
          if (watchlist.isEmpty) {
            return Center(
              child: Text(
                "Your watchlist is empty!",
                style: TextStyle(color: Theme.of(context).colorScheme.onTertiary),
              ),
            );
          }

          // displaying saved movies
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 3 posters pre rows
              childAspectRatio: 0.65,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: watchlist.length,
            itemBuilder: (context, index) {
              final media = watchlist[index];
              return Mediacard(media: media);
            },
          );
        },
      ),
    );
  }
}
