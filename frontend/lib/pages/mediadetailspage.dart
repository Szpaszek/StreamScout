import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:frontend/appconfig.dart';
import 'package:frontend/models/media.dart';
import 'package:frontend/services/watchlistservice.dart';
import 'package:frontend/widgets/horizontalmediacardrow.dart';
import 'package:http/http.dart' as http;

class MediaDetailsPage extends StatefulWidget {
  final Media media;
  final VoidCallback onBack;

  const MediaDetailsPage({
    super.key,
    required this.media,
    required this.onBack,
  });

  @override
  State<MediaDetailsPage> createState() => _MediaDetailsPageState();
}

class _MediaDetailsPageState extends State<MediaDetailsPage> {
  late Future<Map<String, dynamic>> detailsFuture;
  late Future<List<Media>> similarContent;

  @override
  void initState() {
    super.initState();

    detailsFuture = _fetchDetails();
    similarContent = _fetchSimilarContent();
  }

  Future<Map<String, dynamic>> _fetchDetails() async {
    final uri = Uri.parse(
      '${AppConfig.apiBaseUrl}${AppConfig.mediaDetailsEndpoint}/${widget.media.mediaType}/${widget.media.id}',
    );

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final rawdata = jsonDecode(response.body);

        final details = widget.media.mediaType == 'movie'
            ? rawdata['movie']
            : rawdata['tv'];

        return details;
      } else {
        throw Exception("Server error: ${response.statusCode}");
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Media>> _fetchSimilarContent() async {
    final uri = Uri.parse(
      '${AppConfig.apiBaseUrl}${AppConfig.mediaDetailsEndpoint}/${widget.media.mediaType}/${widget.media.id}/similar',
    );

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final rawdata = jsonDecode(response.body);

        final List<dynamic> results =
            rawdata['media'] ?? rawdata['movies'] ?? rawdata['tvs'];

        return results.map((movieJson) => Media.fromJson(movieJson)).toList();
      } else {
        throw Exception("Server error: ${response.statusCode}");
      }
    } catch (e) {
      rethrow;
    }
  }

  // TODO: add watch provider (seperate api), and more details (runtime etc.) using details api and similar (own api), thrailer (own api)
  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Intercept back button press to close the details view instead of navigating back
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        // if the page already popped do nothing, otherwise call the onBack callback
        if (didPop) return;

        // trigger custom close logic
        widget.onBack();
      },

      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, //left aligned
              children: [
                // Back button
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextButton.icon(
                    onPressed: widget.onBack,
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
                      widget.media.backdropPath ?? '',
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
                        widget.media.title,
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
                            widget.media.rating.toStringAsFixed(1),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 15),
                          // madia type tag
                          _buildInfoTag(widget.media.mediaType.toUpperCase()),
                          const SizedBox(width: 15),
                          // FutureBuilder for the Runtime or number of seasons
                          FutureBuilder<Map<String, dynamic>>(
                            future: detailsFuture,
                            builder: (context, snapshot) {
                              // While loading, we show nothing or a tiny space
                              if (snapshot.connectionState ==
                                      ConnectionState.waiting ||
                                  snapshot.hasError) {
                                return const SizedBox.shrink();
                              }

                              final data = snapshot.data!;

                              final isMovie = widget.media.mediaType == 'movie';
                              // Movies use 'runtime', TV might not have a single value (can use first episode)
                              final String runtime = isMovie
                                  ? "${data['runtime'] ?? 0} min"
                                  : "${data['number_of_seasons'] ?? 0} S • ${data['number_of_episodes'] ?? 0} Ep";

                              return _buildInfoLine(
                                Icons.timer_outlined,
                                runtime,
                              );
                            },
                          ),
                          const SizedBox(width: 15),
                          Text(
                            widget.media.releaseDate,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onTertiary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 15),
                          ValueListenableBuilder<List<Media>>(
                            valueListenable: WatchlistService.watchlistNotifier,
                            builder: (context, list, _) {
                              final isSaved = WatchlistService.isBookmarked(
                                widget.media.id,
                              );

                              return IconButton(
                                onPressed: () =>
                                    WatchlistService.toggleWatchlist(
                                      widget.media,
                                    ),
                                icon: Icon(
                                  isSaved
                                      ? Icons.bookmark
                                      : Icons.bookmark_add_outlined,
                                  color: isSaved
                                      ? Theme.of(context).colorScheme.secondary
                                      : Theme.of(
                                          context,
                                        ).colorScheme.onTertiary,
                                  size: 28,
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      FutureBuilder<Map<String, dynamic>>(
                        future: detailsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsetsGeometry.symmetric(
                                vertical: 20,
                              ),
                              child: LinearProgressIndicator(minHeight: 2),
                            );
                          }

                          if (snapshot.hasError || !snapshot.hasData)
                            return const SizedBox.shrink();

                          final data = snapshot.data!;
                          final isMovie = widget.media.mediaType == 'movie';

                          return Padding(
                            padding: const EdgeInsets.only(top: 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Genres Display
                                Text(
                                  (data['genres'] as List)
                                      .map((g) => g['name'])
                                      .join(' • '),
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onTertiary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                if (!isMovie) ...[
                                  const SizedBox(height: 5),
                                  _buildInfoLine(
                                    Icons.info_outline,
                                    "Status: ${data['status']}",
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),

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
                        widget.media.overview,
                        style: TextStyle(
                          fontSize: 15,
                          color: Theme.of(context).colorScheme.onTertiary,
                          height: 1.6, // adds breathing room between lines
                        ),
                      ),

                      const SizedBox(height: 20),

                      Text(
                        "Similar",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),

                      const SizedBox(height: 10),

                      FutureBuilder<List<Media>>(
                        future: similarContent, 
                        builder: (context, snapshot) {
                          // show a loader while waiting
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const SizedBox(
                              height: 300, // Match your Row height
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          // handle errors or empty results
                          if (snapshot.hasError ||
                              !snapshot.hasData ||
                              snapshot.data!.isEmpty) {
                            return const SizedBox.shrink(); // hide the section if nothing found
                          }

                          // data has arrived, pass the real List<Media>
                          return HorizontalMediaCardRow(
                            mediaList: snapshot.data!,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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

  Widget _buildInfoLine(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.secondary),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
