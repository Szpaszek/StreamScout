import 'package:flutter/material.dart';
import 'package:frontend/models/media.dart';
import 'package:frontend/services/watchlistservice.dart';

class MediaDetailsPage extends StatelessWidget {
  final Media media;
  final VoidCallback onBack;

  const MediaDetailsPage({
    super.key,
    required this.media,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, //left aligned
        children: [
          // Back button
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextButton.icon(
              onPressed: onBack,
              icon: Icon(
                Icons.arrow_back,
                color: Theme.of(context).colorScheme.secondary,
              ),
              label: Text(
                "Back",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),

          // 2. Movie Poster
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 0, 2, 5),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                media.backdropPath ?? '',
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,

                // fallback if image fails to load
                errorBuilder: (context, error, s) => SizedBox(
                  height: 220,
                  child: Center(
                    child: const Icon(
                      Icons.movie,
                      color: Colors.grey,
                      size: 50,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 3. title and info section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  media.title,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),

                // meta info row
                Row(
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: Theme.of(context).colorScheme.secondary,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      media.rating.toStringAsFixed(1),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 15),
                    _buildInfoTag(media.mediaType.toUpperCase()),
                    const SizedBox(width: 15),
                    Text(
                      media.releaseDate,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onTertiary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 15),
                    ValueListenableBuilder<List<Media>>(
                      valueListenable: WatchlistService.watchlistNotifier,
                      builder: (context, list, _) {
                        final isSaved = WatchlistService.isBookmarked(media.id);

                        return IconButton(
                          onPressed: () =>
                              WatchlistService.toggleWatchlist(media),
                          icon: Icon(
                            isSaved
                                ? Icons.bookmark
                                : Icons.bookmark_add_outlined,
                            color: isSaved
                                ? Theme.of(context).colorScheme.secondary
                                : Theme.of(context).colorScheme.onTertiary,
                            size: 28,
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                // 4. overview
                Text(
                  "Overview",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  media.overview,
                  style: TextStyle(
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.onTertiary,
                    height: 1.6, // adds breathing room between lines
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for the small "Type" tag (Movie/TV)
  Widget _buildInfoTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.cyanAccent.withAlpha(125)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.cyanAccent, fontSize: 11),
      ),
    );
  }
}
