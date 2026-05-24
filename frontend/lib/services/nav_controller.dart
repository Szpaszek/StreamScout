import 'package:flutter/material.dart';
import 'package:frontend/models/person.dart';
import 'package:frontend/models/media.dart';
import 'package:frontend/pages/media_details_page.dart';
import 'package:frontend/pages/person_details_page.dart';
import 'package:frontend/pages/search_page.dart';
import 'package:frontend/pages/voting_room_page.dart';

class NavController {

  static void showMediaDetails(BuildContext context, Media media) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MediaDetailsPage(
          media: media,
          onBack: () => Navigator.pop(context),
        ),
      ),
    );
  }

  static void showMediaDetailsForVoting(
    BuildContext context,
    Media media,
    String? roomCode,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MediaDetailsPage(
          media: media,
          onBack: () => Navigator.pop(context),
          roomCode: roomCode, // Passing it down the line
        ),
      ),
    );
  }

  static void openSearchPage(BuildContext context, String roomCode) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SearchPage(roomCode: roomCode)),
    );
  }

  static void showPersonDetails(BuildContext context, Person person) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PersonDetailsPage(
          person: person,
          onBack: () => Navigator.pop(context),
        ),
      ),
    );
  }

  static void joinVotingRoom(BuildContext context, String roomCode) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VotingRoomPage(
          roomCode: roomCode,
        ),
      ),
    );
  }

}
