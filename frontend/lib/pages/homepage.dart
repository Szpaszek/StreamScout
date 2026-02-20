import 'package:flutter/material.dart';
import 'package:frontend/appconfig.dart';
import 'package:frontend/models/media.dart';
import 'package:frontend/widgets/mediacard.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

// State class for HomePage
class _HomePageState extends State<HomePage> {
  
  List<Media> _popularContent = [];
  List<Media> _latestContent = [];
  List<Media> _upcomingMovies = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Initial state setup which fetches movies only once when the widget is created
  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    try {
      final results = await Future.wait([
        _fetchContent(AppConfig.popularContentEndpoint),
        _fetchContent(AppConfig.latestContentEndpoint),
        _fetchContent(AppConfig.upcomingMoviesEndpoint),
      ]);

      if (mounted) {
        setState(() {
          _popularContent = results[0];
          _latestContent = results[1];
          _upcomingMovies = results[2];
          _isLoading = false;
        });
      }

    } on FormatException {
      if (mounted) {
        // Handle JSON format exceptions
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Invalid data received from server. Expected JSON format.';
        });
      }
    } catch (e){
      if (mounted) {
      // Handle non-200 responses
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Failed to load movies: $e';
        });
      }
    }
  }

  // TODO: save the state of the page, so the app does not need to fetch every time 
  // Function to fetch popular content from the backend server
  Future<List<Media>> _fetchContent(String apiEndpoint) async {

    List<Media> content = [];

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final uri = Uri.parse(
      '${AppConfig.apiBaseUrl}$apiEndpoint',
    );

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        // Decode the JSON response to a Dart object
        final data = jsonDecode(response.body);

        // Ensure data is a dictionary 
        if (data is Map<String, dynamic> && data.containsKey('movies') 
        || data is Map<String, dynamic> && data.containsKey('media') 
        || data is Map<String, dynamic> && data.containsKey('tvs')) {

          final List<dynamic> results = data['media'] ?? data['movies'] ?? data['tvs'];

          content = results
              .map((movieJson) => Media.fromJson(movieJson)).toList();
          return content;
          
        } else {
          throw const FormatException("Invalid JSON format from server.");
        }
      } else {
          throw Exception("Server error: ${response.statusCode}");
      }
    } catch (e) {
      rethrow;
    }
  }

// TODO: Create large Banner for a popular movie
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
              'Home Page',
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

    if (_popularContent.isEmpty) {
      return Center(
        child: Text('No popular content found', style: TextStyle(fontSize: 18)),
      );
    }

      return CustomScrollView(
        // physics ensures smooth scrolling on both iOS an Android 
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Title
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("Popular", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), 
            ),
          ),

          // 2. Horizontal Row 
          SliverToBoxAdapter(
            child: _buildHorizontalMediaCardRow(_popularContent),
          ),

          // Title
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("Recent Releases", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), 
            ),
          ),

          // 2. Horizontal Row 
          SliverToBoxAdapter(
            child: _buildHorizontalMediaCardRow(_latestContent),
          ),

          // Title
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("Upcoming Movies", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), 
            ),
          ),

          // 2. Horizontal Row 
          SliverToBoxAdapter(
            child: _buildHorizontalMediaCardRow(_upcomingMovies),
          )
        ]
      );
  }

  // horizontal list of cards
  Widget _buildHorizontalMediaCardRow(List<Media> data) {
    return SizedBox(
      height: 300, // fixed height for the horizontal scrolling row
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: data.length,
        padding: const EdgeInsets.symmetric(
          horizontal: 16.0,
        ),
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(
              right: 12.0, // Padding for each media element
            ),
            child: SizedBox(
              width: 130, //fixed width for each card
              child: Mediacard(media: data[index]),
            ),
          );
        },
      ),
    );
  } 
}
