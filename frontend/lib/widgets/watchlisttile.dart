import 'package:flutter/material.dart';
import 'package:frontend/models/media.dart';
import 'package:frontend/services/navcontroller.dart';
import 'package:frontend/services/watchlistservice.dart';

class WatchlistTile extends StatelessWidget {
  final Media media;

  const WatchlistTile({super.key, required this.media});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => NavController.showDetails(media),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            // Poster Image
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: AspectRatio(
                aspectRatio: 1.7,
                child: Image.network(
                  media.backdropPath ?? '',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(color: Colors.black26),
                ),
              ),
            ),

            // Info Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      media.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      media.releaseDate,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onTertiary,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          media.rating.toStringAsFixed(1),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onTertiary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // delete icon
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => WatchlistService.toggleWatchlist(media),
            ),
          ],
        ),
      ),
    );
  }
}
