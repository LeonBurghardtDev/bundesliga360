import 'package:flutter/material.dart'; // Import the flutter_svg package
import 'layout.dart';

void main() {
  runApp(BundesligaApp());
}

class BundesligaApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system, // Use system theme mode (light/dark)
      theme: ThemeData.light(), // Light theme
      darkTheme: ThemeData.dark(), // Dark theme
      home: HomeScreen(),
    );
  }
}
