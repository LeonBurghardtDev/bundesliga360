import 'package:flutter/material.dart'; // Import the flutter_svg package
import 'package:german_football_app/screens/home.dart';
import 'layout.dart';

void main() {
  runApp(BundesligaApp());
}

class BundesligaApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light, // Use system theme mode (light/dark)
      theme: ThemeData.light(), // Light theme
      darkTheme: ThemeData.light(), // Dark theme
      home: Layout(),
    );
  }
}
