import 'package:flutter/material.dart';
import 'package:webfeed/webfeed.dart';
import 'package:url_launcher/url_launcher.dart'; // Import for AssetImage
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import "screens/table.dart";
import "screens/matches.dart";
import "screens/news.dart";
import "screens/scorer.dart";
import "screens/home.dart";

class Layout extends StatefulWidget {
  @override
  _LayoutState createState() => _LayoutState();
}

class _LayoutState extends State<Layout> {
  int currentIndex = 2;
  PageController _pageController = PageController(initialPage: 2);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(235, 28, 45, 300),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bundesliga360',
              style: TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              _openSettingsDialog(context); // Open settings dialog
            },
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        clipBehavior: Clip.none,
        onPageChanged: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        children: [
          TableScreen(),
          MatchesScreen(),
          HomeScreen(),
          NewsScreen(),
          ScorerScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white, // Background color
        selectedItemColor: Color(0xFFE51C2D), // Active icon color
        unselectedItemColor: Colors.grey, // Inactive icon color
        currentIndex: currentIndex,
        showSelectedLabels: false,
        onTap: (index) {
          setState(() {
            currentIndex = index;
            _pageController.animateToPage(
              index,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
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
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
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

  void _openSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Einstellungen'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.nightlight_round),
                title: Text('Dark Mode (Experimental)'),
                onTap: () {
                  ThemeManager.changeTheme(ThemeMode.dark);
                },
              ),
              ListTile(
                leading: Icon(Icons.privacy_tip),
                title: Text('Datenschutz'),
                onTap: () {
                  _openInAppBrowser(
                      "https://www.privacypolicies.com/live/42997c92-a7cf-4a0d-a0e2-f1a7996434db",
                      "Datenschutzerklärung");
                },
              ),
              ListTile(
                leading: Icon(Icons.code),
                title: Text('OpenSource'),
                onTap: () {
                  _openInAppBrowser(
                      "https://github.com/tr3xxx/bundesliga360", "OpenSource");
                },
              ),
              ListTile(
                leading: Icon(Icons.money),
                title: Text('Spenden'),
                onTap: () {
                  _openInAppBrowser(
                      "https://www.paypal.me/leontr3x",
                      "Spenden");
                },
              ),
              ListTile(
                leading: Icon(Icons.info),
                title: Text('Fehler melden'),
                onTap: () async {
                  final Uri _emailLaunchUri = Uri(
                    scheme: 'mailto',
                    path: 'leon@tr3x.xyz',
                    query: 'subject=Fehlermeldung%20Bundesliga360',
                  );
                  final String _emailUri = _emailLaunchUri.toString();

                  if (await canLaunch(_emailUri)) {
                    await launch(_emailUri);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Fehler beim Öffnen der E-Mail App!\nBitte manuell eine E-Mail an leon@tr3x.xyz senden!'),
                      ),
                    );
                  }
                },
              ),
              Divider(
                thickness: 1,
              ),
              Text(
                'Entwickelt von Leon Burghardt\nKein offizielles Lizenzprodukt der DFL', // Developer information
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              )
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _openInAppBrowser(String url, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) {
          return InAppWebViewPage(url: url, title: title);
        },
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
        return HomeScreen();
      case 3:
        return NewsScreen();
      case 4:
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

class InAppWebViewPage extends StatelessWidget {
  final String url;
  final String title;

  const InAppWebViewPage({required this.url, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(235, 28, 45, 300),
        title: Text(title),
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: Uri.parse(url)),
        initialOptions: InAppWebViewGroupOptions(
          crossPlatform: InAppWebViewOptions(
            useOnLoadResource: true,
          ),
        ),
      ),
    );
  }
}
