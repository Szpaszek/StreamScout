import 'dart:math';

import 'package:flutter/material.dart';
import 'package:frontend/appconfig.dart';
import 'package:frontend/models/media.dart';
import 'package:frontend/services/socketservice.dart';
import 'package:frontend/widgets/featuredbanner.dart';
import 'package:frontend/widgets/horizontalmediacardrow.dart';
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: Expanded(child: _buildBody()));
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
                  const Icon(
                    Icons.error_outline,
                    color: Colors.tealAccent,
                    size: 40,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFFBCCAD9),
                    ),
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
            SliverToBoxAdapter(child: FeaturedBanner(media: featuredMovie!)),

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
            child: HorizontalMediaCardRow(mediaList: _popularContent),
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
            child: HorizontalMediaCardRow(mediaList: _latestContent),
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
            child: HorizontalMediaCardRow(mediaList: _upcomingMovies),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsetsGeometry.fromLTRB(20, 20, 20, 40),
              child: ElevatedButton(
                onPressed: () {
                  _showVoteOptionsDialog();
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  minimumSize: const Size(100, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "MOVIE VOTE",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showVoteOptionsDialog() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: const Color(0xFF1A1D1F), // Match your dark theme
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Movie Vote Party", 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Option 1: HOST
            _buildDialogOption(
              icon: Icons.add_to_queue,
              title: "Host a Room",
              subtitle: "Start a room and invite friends",
              onTap: () {
                Navigator.pop(context);
                _handleHostRoom();
              },
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white10),
            const SizedBox(height: 16),
            // Option 2: JOIN
            _buildDialogOption(
              icon: Icons.group_add_outlined,
              title: "Join a Room",
              subtitle: "Enter a code to join friends",
              onTap: () {
                Navigator.pop(context);
                _showJoinInputDialog();
              },
            ),
          ],
        ),
      );
    },
  );
}

// Helper for the list items in the dialog
Widget _buildDialogOption({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.tealAccent, size: 30),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

// 1. Logic for Hosting
void _handleHostRoom() {
  // Generate a random 6-digit code
  String roomCode = (Random().nextInt(900000) + 100000).toString();
  
  // Tell the server we are hosting
  SocketService().hostRoom(roomCode);

  // TODO: Navigate to your VotingRoomScreen (we will build this next)
  print("Hosting Room: $roomCode");
}

// 2. Logic for Joining
void _showJoinInputDialog() {
  final TextEditingController _codeController = TextEditingController();
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Enter Room Code"),
      content: TextField(
        controller: _codeController,
        keyboardType: TextInputType.number,
        maxLength: 6,
        decoration: const InputDecoration(hintText: "123456"),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          onPressed: () {
            SocketService().joinRoom(_codeController.text);
            Navigator.pop(context);
            // TODO: Navigate to VotingRoomScreen
          }, 
          child: const Text("Join")
        ),
      ],
    ),
  );
}
}
