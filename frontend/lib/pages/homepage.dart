import 'dart:math';

import 'package:flutter/material.dart';
import 'package:frontend/appconfig.dart';
import 'package:frontend/models/movie.dart';
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

    final uri = Uri.parse('${AppConfig.apiBaseUrl}${AppConfig.popularMoviesEndpoint}');

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {

        // Decode the JSON response to a Dart object
        final data = jsonDecode(response.body);

        // Ensure data is a dictionary and has the 'results' key
        if (data is Map<String, dynamic> && data.containsKey('results')) {
          final List<dynamic> results = data['results'];

          setState(() {
            _movies = results.map((movieJson) => Movie.fromJson(movieJson)).toList();
            _isLoading = false;
          });
        }
        else {
          throw const FormatException("Invalid JSON format from server.");
        }
      } else {
        // Handle non-200 responses
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load movies: ${response.statusCode}: ${response.body}';
        });
      }
    } catch (e) {
      // Handle exceptions during the HTTP request
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to connect to the server';
      });
    }
  }

  // TODO: Implement the build method to display the UI

}