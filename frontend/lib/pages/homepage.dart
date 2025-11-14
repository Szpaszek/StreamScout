import 'package:flutter/material.dart';
import 'package:frontend/appconfig.dart';
import 'package:frontend/models/movie.dart';
import 'package:frontend/widgets/moviecard.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

// State class for HomePage
class _HomePageState extends State<HomePage> {
  List<Movie> _movies = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Initial state setup which fetches movies only once when the widget is created
  @override
  void initState() {
    super.initState();
    _fetchPopularMovies();
  }

  // Function to fetch movies from the backend server
  Future<void> _fetchPopularMovies() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final uri = Uri.parse(
      '${AppConfig.apiBaseUrl}${AppConfig.popularMoviesEndpoint}',
    );

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        // Decode the JSON response to a Dart object
        final data = jsonDecode(response.body);

        // Ensure data is a dictionary and has the 'movies' key
        if (data is Map<String, dynamic> && data.containsKey('movies')) {
          final List<dynamic> results = data['movies'];

          // if homepage is displayed
          if (mounted) {
            setState(() {
            _movies = results
                .map((movieJson) => Movie.fromJson(movieJson))
                .toList();
            _isLoading = false;
          });
          }
        } 

        else 
        {
          throw const FormatException("Invalid JSON format from server.");
        }
      } else {
        // Handle non-200 responses
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Failed to load movies: ${response.statusCode}: ${response.body}';
        });
      }
    } on FormatException {
      // Handle JSON format exceptions
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Invalid data received from server. Expected JSON format.';
      });
    } catch (e) {
      // Handle exceptions during the HTTP request
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to connect to the server';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 8.0,
              top: 8.0,
              bottom: 8.0,
            ),
            child: Text(
              'Popular Movies',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  // body of the screen
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.tealAccent),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(_errorMessage!, style: TextStyle(fontSize: 18)),
      );
    }

    if (_movies.isEmpty) {
      return Center(
        child: Text('No popular movies found', style: TextStyle(fontSize: 18)),
      );
    }

    return ListView(
      children: [
        // horizontal list of cards
        SizedBox(
          height: 300, // fixed height for the horizontal scrolling row
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _movies.length,
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
            ), // padding for the list
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(
                  right: 12.0,
                ), // padding for each movie
                child: SizedBox(
                  width: 130, // fixed width for each card
                  child: Moviecard(movie: _movies[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
