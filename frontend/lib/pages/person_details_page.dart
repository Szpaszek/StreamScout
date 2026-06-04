import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/Utilities.dart';
import 'package:frontend/app_config.dart';
import 'package:frontend/models/media.dart';
import 'package:frontend/models/person.dart';
import 'package:frontend/widgets/horizontal_media_card_row.dart';
import 'package:http/http.dart' as http;
import 'package:readmore/readmore.dart';

class PersonDetailsPage extends StatefulWidget {
  final Person person;
  final VoidCallback onBack;

  const PersonDetailsPage({
    super.key,
    required this.person,
    required this.onBack,
  });

  @override
  State<PersonDetailsPage> createState() => _PersonDetailsPage();
}

class _PersonDetailsPage extends State<PersonDetailsPage> {
  
  late Future<(Map<String, dynamic>, List<Media>)> _pageDataFuture;

  @override
  void initState() {
    super.initState();

    _pageDataFuture = _loadAllData();
  }

  Future<(Map<String, dynamic>, List<Media>)> _loadAllData() async {
    final results = await Future.wait([_fetchDetails(), _fetchCredits()]);

    return (results[0] as Map<String, dynamic>, results[1] as List<Media>);
  }

  Future<Map<String, dynamic>> _fetchDetails() async {
    final uri = Uri.parse(
      '${AppConfig.apiBaseUrl}${AppConfig.personEndpoint}/details/${widget.person.id}',
    );

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final rawdata = jsonDecode(response.body);

        return rawdata['details'];
      } else {
        throw Exception("Server error: ${response.statusCode}");
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Media>> _fetchCredits() async {
    final uri = Uri.parse(
      '${AppConfig.apiBaseUrl}${AppConfig.personEndpoint}/credits/${widget.person.id}',
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // intercept back button press to close the details view instead of navigating back
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
          child: FutureBuilder<(Map<String, dynamic>, List<Media>)>(
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

              // Data is safely here! Unpack it once at the top:
              final (details, mediaList) = snapshot.data!;

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, //left aligned
                  children: [
                    // back button
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

                    // profile header (image left, info right)
                    Padding(
                      padding: const EdgeInsetsGeometry.symmetric(
                        horizontal: 16.0,
                        vertical: 10,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // actor image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              widget.person.profilePath ?? '',
                              width: 140,
                              height: 200,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, s) => Container(
                                width: 140,
                                height: 200,
                                color: Colors.white10,
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.grey,
                                  size: 50,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),

                          // actor info
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),

                              child: Padding(
                                padding: EdgeInsetsGeometry.all(10),

                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.person.name,
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 10),

                                    // role tag
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withValues(alpha: 0.5),
                                        ),
                                      ),
                                      child: Text(
                                        details['known_for_department'],
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 8),
                                    ReadMoreText(
                                      "Also known as: ${(details['also_known_as'] ?? 'N/A' as List).join(', ')}",
                                      trimLines:
                                          2, // Number of lines to show before cutting off
                                      colorClickableText: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      trimMode: TrimMode.Line,
                                      trimCollapsedText: ' Show more',
                                      trimExpandedText: ' Show less',
                                      moreStyle: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                      lessStyle: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onTertiary,
                                        height: 1.6,
                                      ),
                                    ),
                                    const SizedBox(height: 8),

                                    Text(
                                      "Birthday: ${Utilities.formatDate(details['birthday'] ?? 'Unknown')}",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onTertiary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Place of birth: ${details['place_of_birth'] ?? 'Unknown'}",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onTertiary,
                                      ),
                                    ),

                                    if (details['Deathday'] != null) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        "Deathday: ${Utilities.formatDate(details['Deathday'] ?? 'Unknown')}",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onTertiary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    Padding(
                      padding: EdgeInsetsGeometry.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          Text(
                            "Biography",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ReadMoreText(
                            details['biography'] ?? 'Biography not available.',
                            trimLines:
                                4, // Number of lines to show before cutting off
                            colorClickableText: Theme.of(
                              context,
                            ).colorScheme.primary,
                            trimMode: TrimMode.Line,
                            trimCollapsedText: ' Show more',
                            trimExpandedText: ' Show less',
                            moreStyle: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            lessStyle: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onTertiary,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // "Known For" section
                    Padding(
                      padding: EdgeInsetsGeometry.symmetric(horizontal: 16.0),
                      child: Center(
                        child: Text(
                          "Played in",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // data has arrived, pass the real List<Media>
                    HorizontalMediaCardRow(mediaList: mediaList),

                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
