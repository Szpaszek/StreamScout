import 'dart:async';
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
  String _roomStatus = 'suggesting';
  bool _isHost = false;
  int _userCount = 1;
  Media? _winnerMedia;
  int _secondsRemaining = 30; // 300 in release
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _setupSocketListeners();
    _socket.emit('join_room', {'room': widget.roomCode});
  }

  void _setupSocketListeners() {
    _socket.on('user_count_update', (data) {
      if (mounted) {
        setState(() => _userCount = data['count']);
      }
    });

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
          _roomStatus = data['status'] ?? 'suggesting';
          _isHost = data['is_host'] ?? false;
          _userCount = data['user_count'] ?? 1;
        });
        if (_roomStatus == 'voting' && data['timer_end'] != null) {
          _startLocalTimer(data['timer_end']);
        }
      }
    });

    _socket.on('phase_changed', (data) {
      if (mounted) {
        setState(() {
          _roomStatus = data['status'];
          if (data['winner'] != null) {
            _winnerMedia = Media.fromJson(data['winner']);
          }
        });

        if (_roomStatus == 'voting' && data['timer_end'] != null) {
          _startLocalTimer(data['timer_end']);
        }
      }
    });

    _socket.on('room_expired', (data) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                data['msg'],
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
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

  void _startLocalTimer(dynamic serverTimerEnd) {
    _countdownTimer?.cancel();

    double endTime = (serverTimerEnd is num) ? serverTimerEnd.toDouble() : 0.0;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now().millisecondsSinceEpoch / 1000;
      final remaining = (endTime - now).round();

      if (remaining <= 0) {
        timer.cancel();
        setState(() {
          _secondsRemaining = 0;
        });
      } else {
        setState(() {
          _secondsRemaining = remaining;
        });
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
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
              "Room: ${widget.roomCode} ($_userCount Online)",
              style: const TextStyle(fontSize: 12, color: Colors.tealAccent),
            ),
          ],
        ),
      ),
      body: _buildPhaseBody(),
    );
  }

  Widget _buildPhaseBody() {
    switch (_roomStatus) {
      case 'suggesting':
        return _buildSuggestingPhase();
      case 'voting':
        return _buildVotingPhase();
      case 'results':
        return _buildResultsPhase();
      default:
        return const Center(child: CircularProgressIndicator());
    }
  }

  Widget _buildSuggestingPhase() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "Suggested Movies (${_roomMedia.length})",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
            icon: const Icon(Icons.add, color: Colors.tealAccent),
            onPressed: () => _openAddMediaDialog(),
          ),
        Expanded(
          child: _roomMedia.isEmpty
              ? const Center(child: Text("Waiting for movie suggestions..."))
              : _buildMediaGrid(enableVoting: false),
        ),
        if (_isHost)
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: () =>
                  _socket.emit('start_voting', {'room': widget.roomCode}),
              child: const Text("START VOTING NOW"),
            ),
          ),
      ],
    );
  }

  Widget _buildVotingPhase() {
    int minutes = _secondsRemaining ~/ 60;
    int seconds = _secondsRemaining % 60;
    String timeStr = "$minutes:${seconds.toString().padLeft(2, '0')}";

    return Column(
      children: [
        Container(
          color: Colors.redAccent.withOpacity(0.1),
          padding: const EdgeInsets.all(12),
          width: double.infinity,
          child: Text(
            "VOTE! Time Remaining: $timeStr",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(child: _buildMediaGrid(enableVoting: true)),
      ],
    );
  }

  Widget _buildResultsPhase() {
    if (_winnerMedia == null) {
      return const Center(child: Text("No winner. No movies were voted on!"));
    }

    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 1200),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "🎉 THE WINNER IS 🎉",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.amber,
              ),
            ),
            const SizedBox(height: 24),
            // Using a larger display for the winner
            SizedBox(
              height: 350,
              width: 240,
              child: Card(
                elevation: 10,
                clipBehavior: Clip.antiAlias,
                child: Image.network(
                  _winnerMedia?.posterPath ?? '',
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => const Icon(Icons.movie, size: 100),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _winnerMedia!.title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaGrid({required bool enableVoting}) {
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
                onTap: () =>
                    enableVoting ? _castVote(item.id.toString()) : null,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "$currentVotes Votes",
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.tealAccent,
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
