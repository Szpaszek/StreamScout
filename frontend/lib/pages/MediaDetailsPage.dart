import 'package:flutter/material.dart';
import 'package:frontend/models/media.dart';

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
    return SafeArea(
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Expanded(
              flex: 1,
              child: Image.network(media.backdropPath!, fit: BoxFit.cover),
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 8.0),
                  child: Text(
                    media.title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    "Rating ${media.rating}  Mediatyp: ${media.mediaType}  Release date: ${media.releaseDate}"
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Container(
                    color: Theme.of(context).cardColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Overview",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(media.overview)
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // return const Center(
    //   child: Text(
    //     'Media Details Page',
    //     style: TextStyle(fontSize: 24),
    //   ),
    // );
  }
}
