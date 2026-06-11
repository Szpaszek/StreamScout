import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/app_config.dart';
import 'package:frontend/models/media.dart';
import 'package:frontend/services/socket_service.dart';
import 'package:frontend/services/watchlist_service.dart';
import 'package:frontend/widgets/horizontal_media_card_row.dart';
import 'package:frontend/widgets/streaming_providers_row.dart';
import 'package:http/http.dart' as http;

class MediaDetailsPage extends StatefulWidget {
  final Media media;
  final VoidCallback onBack;
  final String? roomCode;

  const MediaDetailsPage({
    super.key,
    required this.media,
    required this.onBack,
    this.roomCode,
  });

  @override
  State<MediaDetailsPage> createState() => _MediaDetailsPageState();
}

// defining clean alias for file readability
typedef MediaPageData = ({
  Map<String, dynamic> details,
  List<dynamic> providers,
  List<Media> similarContent,
});

class _MediaDetailsPageState extends State<MediaDetailsPage> {
  late Future<MediaPageData> _pageDataFuture;

  @override
  void initState() {
    super.initState();

    _pageDataFuture = _loadAllData();
  }

  Future<MediaPageData> _loadAllData() async {
    final results = await Future.wait([
      _fetchDetails(),
      _fetchSimilarContent(),
    ]);

    final (details, providers) =
        results[0] as (Map<String, dynamic>, List<dynamic>);
    final similarContent = results[1] as List<Media>;

    return (
      details: details,
      providers: providers,
      similarContent: similarContent,
    );
  }

  Future<(Map<String, dynamic>, List<dynamic>)> _fetchDetails() async {
    final uri = Uri.parse(
      '${AppConfig.apiBaseUrl}${AppConfig.mediaDetailsEndpoint}/${widget.media.mediaType}/${widget.media.id}',
    );

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final rawdata = jsonDecode(response.body);

        final Map<String, dynamic> details = widget.media.mediaType == 'movie'
            ? rawdata['movie']
            : rawdata['tv'];

        final rawProviders = rawdata['streaming_services_de'];

        final List<dynamic> streaming_services = (rawProviders is List)
            ? rawProviders
            : [];

        return (details, streaming_services);
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
      final response = await http.get(uri).timeout(const Duration(seconds: 15));

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

  Future<void> _handleRefresh() async {
    setState(() {
      _pageDataFuture = _loadAllData();
    });

    await _pageDataFuture;
  }

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
          child: FutureBuilder<MediaPageData>(
            future: _pageDataFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return Center(
                  child: Text("Error loading page: ${snapshot.error}"),
                );
              }

              // Unpack it once at the top:
              final data = snapshot.data!;
              final details = data.details;
              final providers = data.providers;
              final similarMedia = data.similarContent;

              return RefreshIndicator(
                color: const Color(0xFF4EEAD7),
                onRefresh: _handleRefresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
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
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondary,
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.media.rating.toStringAsFixed(1),
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // madia type tag
                                _buildInfoTag(
                                  widget.media.mediaType.toUpperCase(),
                                ),
                                const SizedBox(width: 10),

                                _buildInfoLine(
                                  Icons.timer_outlined,
                                  widget.media.mediaType == 'movie'
                                      ? "${details['runtime'] ?? 0} min"
                                      : "${details['number_of_seasons'] ?? 0} S • ${details['number_of_episodes'] ?? 0} Ep",
                                ),

                                const SizedBox(width: 10),
                                Text(
                                  widget.media.releaseDate,
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onTertiary,
                                    fontSize: 14,
                                  ),
                                ),
                                ValueListenableBuilder<List<Media>>(
                                  valueListenable:
                                      WatchlistService.watchlistNotifier,
                                  builder: (context, list, _) {
                                    final isSaved =
                                        WatchlistService.isBookmarked(
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
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.secondary
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

                            Padding(
                              padding: const EdgeInsets.only(top: 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Genres Display
                                  Text(
                                    (details['genres'] as List)
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
                                  if (widget.media.mediaType != 'movie') ...[
                                    const SizedBox(height: 5),
                                    _buildInfoLine(
                                      Icons.info_outline,
                                      "Status: ${details['status']}",
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                  StreamingProvidersRow(providers: providers),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            if (widget.roomCode != null) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.tealAccent,
                                    foregroundColor: Colors.black,
                                    minimumSize: const Size(
                                      double.infinity,
                                      50,
                                    ),
                                  ),
                                  icon: const Icon(Icons.add_to_photos),
                                  label: const Text("Suggest for Voting"),
                                  onPressed: () => _suggestMovie(context),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],

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
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onTertiary,
                                height:
                                    1.6, // adds breathing room between lines
                              ),
                            ),

                            const SizedBox(height: 20),
                            Center(
                              child: Text(
                                "Similar",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondary,
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),

                            // data has arrived, pass the real List<Media>
                            HorizontalMediaCardRow(mediaList: similarMedia),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // helper widget for the small "Type" tag (Movie/TV)
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

  void _suggestMovie(BuildContext context) {
    // Emit the socket event
    SocketService().addMedia(widget.roomCode!, widget.media);

    // Feedback to user
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Suggested ${widget.media.title}!")));

    // Pop back to the Voting Room
    // Pop twice: once from Details, once from Search
    Navigator.of(context).pop(); // Closes MediaDetails
    Navigator.of(context).pop(); // Closes SearchPage
  }
}
