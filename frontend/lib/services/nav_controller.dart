import 'package:flutter/material.dart';
import 'package:frontend/models/person.dart';
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

  // Person Navigation
  static final ValueNotifier<Person?> selectedPerson = ValueNotifier(null);

  static void showPersonDetails(Person person) {
    selectedPerson.value = person;
  }

  static void closePersonDetails() {
    selectedPerson.value = null;
  }

  // helper to clear everything at once
  static void clearAll() {
    selectedMedia.value = null;
    selectedPerson.value = null;
  }
}
