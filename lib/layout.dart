import 'package:flutter/material.dart';
import "screens/table.dart";
import "screens/matches.dart";
import "screens/news.dart";
import "screens/scorer.dart";

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Bundesliga",
              style: TextStyle(fontSize: 20),
            ),
            Text(
              "Powerd by openligadb.de",
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        backgroundColor: Color.fromRGBO(235, 28, 45, 300),
        actions: [
          IconButton(
            icon: Icon(Icons.dark_mode_outlined),
            onPressed: () {
              setState(() {
                // Toggle theme mode manually
                ThemeMode currentThemeMode =
                    Theme.of(context).brightness == Brightness.light
                        ? ThemeMode.dark
                        : ThemeMode.light;
                // Set the new theme mode
                if (currentThemeMode == ThemeMode.dark) {
                  // Switch to dark theme
                  ThemeManager.changeTheme(ThemeMode.dark);
                } else {
                  // Switch to light theme
                  ThemeManager.changeTheme(ThemeMode.light);
                }
              });
            },
          ),
        ],
      ),
      body: _buildSelectedScreen(),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: Color.fromRGBO(235, 28, 45, 300),
        showSelectedLabels: false,
        unselectedItemColor: Colors.grey,
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.table_chart),
            label: 'Tabelle',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_soccer),
            label: 'Spieltag',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.newspaper),
            label: 'News',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events),
            label: 'Torschützen',
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedScreen() {
    switch (currentIndex) {
      case 0:
        return TableScreen();
      case 1:
        return MatchesScreen();
      case 2:
        return NewsScreen();
      case 3:
        return ScorerScreen();
      default:
        return Container();
    }
  }
}

class ThemeManager {
  static void changeTheme(ThemeMode themeMode) {
    final MaterialApp app = MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: HomeScreen(),
    );

    runApp(app);
  }
}
