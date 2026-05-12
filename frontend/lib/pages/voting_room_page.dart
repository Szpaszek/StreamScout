import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/models/media.dart';
import 'package:frontend/services/socket_service.dart';
import 'package:frontend/widgets/media_card.dart';

class VotingRoomPage extends StatefulWidget {
  final String roomCode;
  const VotingRoomPage({super.key, required this.roomCode});

  @override
  State<VotingRoomPage> createState() => _VotingRoomScreenState();
}

class _VotingRoomScreenState extends State<VotingRoomPage> {
  Map<String, int> _votesMap = {};
  List<Media> _roomMedia = [];

  @override
  void initState() {
    super.initState();
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    final socket = SocketService().socket;

    // Listen for vote updates from server
    socket.on('update_votes', (data) {
      if (mounted) {
        setState(() {
          // Sync key with your Flask 'emit' (movie_id)
          String id = data['movie_id'].toString();
          _votesMap[id] = data['votes'];
        });
      }
    });

    // Listen for new media being added to the room
    socket.on('media_added', (data) {
      if (mounted) {
        setState(() {
          _roomMedia.add(Media.fromJson(data));
          _votesMap[data['id'].toString()] = 0;
        });
      }
    });

    socket.on('error', (data) {
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(data['msg']), backgroundColor: Colors.red),
    );
  }
});
  }

  void _castVote(String mediaId) {
    HapticFeedback.lightImpact();
    SocketService().socket.emit('vote', {
      'room': widget.roomCode,
      'movie_id': mediaId
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Voting Room", style: TextStyle(fontSize: 18)),
            Text(
              "Code: ${widget.roomCode}", 
              style: const TextStyle(fontSize: 12, color: Colors.tealAccent)
            ),
          ],
        ),
        actions: [
        IconButton(
          icon: const Icon(Icons.add, color: Colors.tealAccent),
          onPressed: () => _openAddMediaDialog(),
        ),
      ],
      ),
      body: _roomMedia.isEmpty 
          ? const Center(child: Text("No media added yet.")) 
          : _buildMediaList(),
    );
  }

  Widget _buildMediaList() {
    // Sort media by vote count (highest first)
    _roomMedia.sort((a, b) {
      int votesA = _votesMap[a.id.toString()] ?? 0;
      int votesB = _votesMap[b.id.toString()] ?? 0;
      return votesB.compareTo(votesA);
    });

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _roomMedia.length,
      itemBuilder: (context, index) {
        final media = _roomMedia[index];
        final currentVotes = _votesMap[media.id.toString()] ?? 0;

        return Column(
          children: [
            Mediacard(media: media, onTap: () => _castVote(media.id.toString()),),
            SizedBox(height: 5),
            Text("$currentVotes", style: const TextStyle(fontSize: 12, color: Colors.tealAccent))
          ],
        );  
      },
    );
  }

// TODO: implement
  void _openAddMediaDialog() {
  // For now, this is a placeholder. 
  // Ideally, you'd navigate to your Search page and pass the roomCode back.
  // When a movie is selected:
  // SocketService().addMedia(widget.roomCode, selectedMovie);
}
}