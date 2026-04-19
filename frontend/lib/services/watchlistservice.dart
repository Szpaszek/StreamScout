import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/models/media.dart';

class WatchlistService {
  static const _storageKey = 'user_watchlist';
  static final ValueNotifier<List<Media>> watchlistNotifier = ValueNotifier([]);

  // load from disk on app start
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_storageKey);

    if (jsonString != null) {
      final List<dynamic> decoded = jsonDecode(jsonString);
      watchlistNotifier.value = decoded.map((item) => Media.fromJson(item)).toList();
    }
  }

  // toggle and save
  static Future<void> toggleWatchlist(Media media) async {
    final prefs = await SharedPreferences.getInstance();
    List<Media> currentList = List.from(watchlistNotifier.value);

    final index = currentList.indexWhere((item) => item.id == media.id);

    if (index != -1) {
      currentList.removeAt(index);
    } else {
      currentList.add(media);
    }

    // update ui
    watchlistNotifier.value = currentList;

    // save to disk
    final String encoded = jsonEncode(currentList.map((m) => m.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  static bool isBookmarked(int id) {
    return watchlistNotifier.value.any((item) => item.id == id);
  }

  static Future<void> clearWatchlist() async {
    final prefs = await SharedPreferences.getInstance();

    // remove the specific key from the phone's storage
    await prefs.remove(_storageKey);

    // update the valuenotifier so the ui clears instantly
    watchlistNotifier.value = [];
  }
}