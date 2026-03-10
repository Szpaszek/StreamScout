import 'package:flutter/material.dart';
import 'package:frontend/models/media.dart';


class NavController {
  // ValueNotifier holds the current movie to show in detail view
  static final ValueNotifier<Media?> selectedMedia = ValueNotifier(null);

  static void showDetails(Media media) {
    selectedMedia.value = media;
  }

  static void closeDetails() {
    selectedMedia.value = null;
  }
}