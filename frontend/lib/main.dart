import 'package:flutter/material.dart';
import 'package:frontend/services/mainscreen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key}); // super.key is a standard pattern to unique identify widgets

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stream Scout',
      theme: ThemeData.dark(),
      home: const MainScreen()
    );
  }
}
