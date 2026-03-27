import 'package:flutter/material.dart';
import 'package:frontend/appconfig.dart';
import 'package:frontend/models/media.dart';
import 'package:frontend/widgets/featuredBanner.dart';
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
  Media? featuredMovie;
  bool _isLoading = true;
  String? _errorMessage;

  // Initial state setup which fetches movies only once when the widget is created
  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    // Only show the big center loader if we don't have data yet
    if (_popularContent.isEmpty) {
      setState(() => _isLoading = true);
    }

    _errorMessage = null;

    try {
      final results = await Future.wait([
        _fetchContent(AppConfig.popularContentEndpoint),
        _fetchContent(AppConfig.latestContentEndpoint),
        _fetchContent(AppConfig.upcomingMoviesEndpoint),
      ]);

      if (mounted) {
        setState(() {
          List<Media> fullPopularList = results[0];

          if (fullPopularList.isNotEmpty) {
          // .removeAt(0) removes the item and RETURNS it to the variable
          featuredMovie = fullPopularList.removeAt(0); 
        }

          _popularContent = fullPopularList;
          _latestContent = results[1];
          _upcomingMovies = results[2];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error: $e';
        });
      }
    }
  }

  // Function to fetch popular content from the backend server
  Future<List<Media>> _fetchContent(String apiEndpoint) async {
    List<Media> content = [];

    final uri = Uri.parse('${AppConfig.apiBaseUrl}$apiEndpoint');

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        // Decode the JSON response to a Dart object
        final data = jsonDecode(response.body);

        final List<dynamic> results =
            data['media'] ?? data['movies'] ?? data['tvs'];

        content = results
            .map((movieJson) => Media.fromJson(movieJson))
            .toList();
        return content;
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
      return RefreshIndicator(
        color: const Color(0xFF4EEAD7),
        onRefresh: _loadAllData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
        // We set the height to the screen height so the 
        // "Center" actually looks centered.
        height: MediaQuery.of(context).size.height * 0.7, 
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.tealAccent, size: 40),
              const SizedBox(height: 10),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Color(0xFFBCCAD9)),
              ),
            ],
          ),
        ),
      ),
        ),
      );
    }

    if (_popularContent.isEmpty) {
      return Center(
        child: Text('No popular content found', style: TextStyle(fontSize: 18)),
      );
    }
    // to refresh content when swept down
    return RefreshIndicator(
      color: const Color(0xFF4EEAD7),
      onRefresh: _loadAllData,
      child: CustomScrollView(
        // CRITICAL: This allows pull-to-refresh to work even when the list is short
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // 1. movie banner
          if (featuredMovie != null)
          SliverToBoxAdapter(
            child: FeaturedBanner(
              media: featuredMovie!)
              ),

          // Title
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "Popular Now",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
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
              child: Text(
                "Recent Releases",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
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
              child: Text(
                "Upcoming Movies",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // 2. Horizontal Row
          SliverToBoxAdapter(
            child: _buildHorizontalMediaCardRow(_upcomingMovies),
          ),
        ],
      ),
    );
  }

  // horizontal list of cards
  Widget _buildHorizontalMediaCardRow(List<Media> data) {
    return SizedBox(
      height: 300, // fixed height for the horizontal scrolling row
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: data.length,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
