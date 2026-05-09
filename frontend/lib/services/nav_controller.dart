import 'package:flutter/material.dart';
import 'package:frontend/models/actor.dart';
import 'package:frontend/models/media.dart';

class NavController {
  // Media Navigation
  // ValueNotifier holds the current movie to show in detail view
  static final ValueNotifier<Media?> selectedMedia = ValueNotifier(null);

  static void showDetails(Media media) {
    selectedMedia.value = media;
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
