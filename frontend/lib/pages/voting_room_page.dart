import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/models/media.dart';
import 'package:frontend/pages/search_page.dart';
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
  final _socket = SocketService().socket;

  @override
  void initState() {
    super.initState();
    _setupSocketListeners();
    _socket.emit('join_room', {'room': widget.roomCode});
  }

  void _setupSocketListeners() {
    

    // Listen for vote updates from server
    _socket.on('update_votes', (data) {
      if (mounted) {
        setState(() {
          // Sync key with your Flask 'emit' (movie_id)
          String id = data['media_id'].toString();
          _votesMap[id] = data['votes'];
        });
        _updateAndSortMedia();
      }
    });

    // Listen for new media being added to the room
    _socket.on('media_added', (data) {
      if (mounted) {
        setState(() {
          _roomMedia.add(Media.fromJson(data));
          _votesMap[data['id'].toString()] = 0;
        });
      }
    });

    _socket.on('room_state', (data) {
      if (mounted) {
        setState(() {
          final List<dynamic> mediaJsonList = data['media_list'] ?? [];
          final Map<String, dynamic> votesJson = data['votes'] ?? {};

          // Parse and populate the existing media
          _roomMedia = mediaJsonList.map((item) => Media.fromJson(item)).toList();

          // Parse and populate the existing votes
          _votesMap = votesJson.map((key, value) => MapEntry(key, value as int)); 
        });
        _updateAndSortMedia();
      }
    });

    _socket.on('error', (data) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['msg']), backgroundColor: Colors.red),
        );
      }
    });
  }

  void _updateAndSortMedia() {
    if (!mounted) return;
    setState(() {
      // Sort media by vote count (highest first)
      _roomMedia.sort((a, b) {
        int votesA = _votesMap[a.id.toString()] ?? 0;
        int votesB = _votesMap[b.id.toString()] ?? 0;
        return votesB.compareTo(votesA);
      });
    });
  }

  void _castVote(String mediaId) {
    HapticFeedback.lightImpact();
    SocketService().socket.emit('vote', {
      'room': widget.roomCode,
      'media_id': mediaId,
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
              style: const TextStyle(fontSize: 12, color: Colors.tealAccent),
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
    return GridView.builder(
      //gridDelegate: gridDelegate, itemBuilder: itemBuilder
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _roomMedia.length,
      itemBuilder: (context, index) {
        final item = _roomMedia[index];
        final currentVotes = _votesMap[item.id.toString()] ?? 0;

        return Column(
          children: [
            Expanded(
              child: Mediacard(
                media: item,
                onTap: () => _castVote(item.id.toString()),
              )
            ),
            const SizedBox(height: 8),
            Text(
            "$currentVotes Votes",
            style: const TextStyle(
              fontSize: 14, 
              fontWeight: FontWeight.bold,
              color: Colors.tealAccent
            ),
          ),
          ],
        );
      },
    );
  }

  void _openAddMediaDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => SearchPage(roomCode: widget.roomCode),
    );
  }
}
