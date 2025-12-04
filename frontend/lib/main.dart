import 'package:flutter/material.dart';
import 'package:frontend/services/mainscreen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key}); // super.key is a standard pattern to unique identify widgets

  @override
  Widget build(BuildContext context) {

    // theme 
    //colors Color(0xFF0F1117); 
    //Color(0xFF1E222D);
    //Color.fromARGB(255, 22, 27, 39);
    //const Color kBackgroundColor = Color.fromARGB(255, 23, 27, 36); // very dark blue background
    //const Color kBackgroundColor = Color.fromARGB(255, 30, 34, 44); // very dark blue background
    //const Color kBackgroundColor = Color.fromARGB(255, 20, 23, 31); // very dark blue background
    //const Color kBackgroundColor = Color.fromARGB(255, 24, 27, 39); // very dark blue background
    const Color kBackgroundColor = Color.fromARGB(255, 16, 18, 26); // very dark blue background
    const Color kSurfaceColor = Color.fromARGB(255, 34, 39, 51); // lighter blue-grey for cards/nav bar
    const Color kAccentColor = Color(0xFF2CD9C6); // vibrant Teal color
    const Color kTextSecondary = Color(0xFF8F9BB3); // nuted grey for subtitles

    return MaterialApp(
      title: 'Stream Scout',

      // global theme definition
      theme: ThemeData(
        brightness: Brightness.dark,

        // background colors
        scaffoldBackgroundColor: kBackgroundColor,
        canvasColor: kBackgroundColor, // helper for some widgets

        // card Color (default color for card widgets)
        cardColor: kSurfaceColor,

        // the overall color scheme
        colorScheme: const ColorScheme.dark(
          primary: kAccentColor, // used for active states, buttons
          secondary: kAccentColor, // used for floating action buttons, etc
          surface: kSurfaceColor, // background for cards, sheets
          onSurface: Colors.white, // text color on surface
          onTertiary: Colors.white70,
          background: kBackgroundColor,
        ),

        // appbar theme
        appBarTheme: const AppBarTheme(
          backgroundColor: kBackgroundColor, // seamless look with body
          elevation: 0, // flat design (no shadow)
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),

        // bottom navigation bat theme
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: kSurfaceColor,
          selectedItemColor: kAccentColor, // teal for active tab
          unselectedItemColor: kTextSecondary, // grey for inactive tabs
          type: BottomNavigationBarType.fixed
        ),

        // input/search bar
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: kSurfaceColor, // dark box background
          hintStyle: const TextStyle(color: kTextSecondary),
          prefixIconColor: kTextSecondary,
          // Border when not typing
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Colors.transparent), // no border
          ),
          // border when typing
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: kAccentColor, width: 2),
          ),
        ),

        // text selection
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: kAccentColor,
          selectionHandleColor: kAccentColor,
        )
      ),

      home: const MainScreen()
    );
  }
}
