import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/appconfig.dart';
import 'package:frontend/models/actor.dart';
import 'package:frontend/models/media.dart';
import 'package:frontend/widgets/actorcard.dart';
import 'package:frontend/widgets/mediacard.dart';
import 'package:http/http.dart' as http;

class SearchPage extends StatefulWidget{
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

// state class for SearchPage
class _SearchPageState extends State<SearchPage> {

  // dynamic list to contain diffrent objects
  List<dynamic> _searchResults = [];
  bool _isLoading = false;
  String? _errorMessage;
  // to read the currect text and detect changes
  final TextEditingController _searchController = TextEditingController();
  // a cooldown between api calls when user types a search query 
  Timer? _debounce;

  // function to performe a multi search
  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final uri = Uri.parse(
      '${AppConfig.apiBaseUrl}${AppConfig.multiSearchEndpoint}?query=$query',
    );

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> resultsJson = data['results'];

        final List<dynamic> parsedResults = [];

        for (var item in resultsJson) {
          final mediaType = item['media_type'];

          if (mediaType == 'person') {
            parsedResults.add(Actor.fromJson(item));
          } else if (mediaType == 'movie' || mediaType == 'tv') {
            parsedResults.add(Media.fromJson(item));
          }
        }

        if (mounted) {
          setState(() {
            _searchResults = parsedResults;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to search. Please try again.';
          print("Search error: $e");
        });
      }
    }
  }

  // debounce to prevent api calls on every keystroke
  void _onSearchChanged(String query) {
    // is there a timer existing and is it currently ticking? if so cancell and start new one
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(seconds: 1), () {
      _performSearch(query);
    });
  }

  @override
  void dispose() {
    // destroy all dangerous objects 
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

@override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Search Bar Area
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search movies, shows, people...',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.tealAccent),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
            ),
          ),

          // result area
          Expanded(
            child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.tealAccent))
            : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _searchResults.isEmpty
                ? _buildEmptyState()
                : _buildResultsGrid(),
          ),
        ],
      ) 
    );
  }

Widget _buildEmptyState() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.movie_creation_outlined, size: 80, color: Colors.white24),
        SizedBox(height: 16),
        Text(
          "Find your next favorite",
          style: TextStyle(color: Colors.white54, fontSize: 16),
        )
      ],
    ),
  );
}

Widget _buildResultsGrid() {
  return GridView.builder(
    //gridDelegate: gridDelegate, itemBuilder: itemBuilder
    padding: const EdgeInsets.all(16),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      childAspectRatio: 0.65,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      ),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final item = _searchResults[index];

        if (item is Media) {
          return Mediacard(media: item);
        }
        else if (item is Actor) {
          return Actorcard(actor: item);
        }
        return const SizedBox.shrink();
      },
    );
}

// TODO: decorate

  // @override
  // Widget build(BuildContext context) {
  //   return SafeArea(
  //     child: Center(
  //       child: 
  //       Text('Search Page')
  //     )
  //   );
  // }
}