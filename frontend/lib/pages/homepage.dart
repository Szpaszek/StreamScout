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
  String _jsonResponse = 'Awaiting response...'; // test only
  bool _isLoading = true;
  String? _errorMessage;

  // Use a Json encoder to format the JSON response for better readability
  static const JsonEncoder _jsonEncoder = JsonEncoder.withIndent('  '); // test only

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
      _jsonResponse = 'Awaiting response...'; // test only
    });

    final uri = Uri.parse('${AppConfig.apiBaseUrl}${AppConfig.popularMoviesEndpoint}');

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {

        // Decode the JSON response to a Dart object
        final data = jsonDecode(response.body);

        final formattedJson = _jsonEncoder.convert(data); // test only

        // Ensure data is a dictionary and has the 'movies' key
        if (data is Map<String, dynamic> && data.containsKey('movies')) {
          final List<dynamic> results = data['movies'];

          setState(() {
            _movies = results.map((movieJson) => Movie.fromJson(movieJson)).toList();
            _isLoading = false;
            _jsonResponse = formattedJson; // test only
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
    } 
    on FormatException  {
      // Handle JSON format exceptions
      setState(() {
        _isLoading = false;
        _errorMessage = 'Invalid data received from server. Expected JSON format.';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPopularMovies,
          )
        ],
      ),
        body: _buildBody(),
    );
  }
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.amber,));
    }

    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        _jsonResponse,
        style: const TextStyle(fontFamily: 'Courier', fontSize: 14),
      ),
    );
  }
}