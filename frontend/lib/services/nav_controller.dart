import 'package:flutter/material.dart';
import 'package:frontend/models/actor.dart';
import 'package:frontend/models/media.dart';
import 'package:frontend/pages/media_details_page.dart';
import 'package:frontend/pages/search_page.dart';

class NavController {
  // Media Navigation
  // ValueNotifier holds the current movie to show in detail view
  static final ValueNotifier<Media?> selectedMedia = ValueNotifier(null);

  static void showDetails(Media media) {
    selectedMedia.value = media;
  }

  static void showDetailsForVoting(
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

  static void closeDetails() {
    selectedMedia.value = null;
  }

  // Actor Navigation
  static final ValueNotifier<Actor?> selectedActor = ValueNotifier(null);

  static void showActorDetails(Actor actor) {
    selectedActor.value = actor;
  }

  static void closeActorDetails() {
    selectedActor.value = null;
  }

  // helper to clear everything at once
  static void clearAll() {
    selectedMedia.value = null;
    selectedActor.value = null;
  }
}
