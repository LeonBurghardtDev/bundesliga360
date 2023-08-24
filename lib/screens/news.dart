import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:webfeed/webfeed.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../popup/error.dart';

class NewsScreen extends StatefulWidget {
  @override
  _NewsScreenState createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  RssFeed? _feed;
  bool _isLoading = true;
  String _selectedTeam =
      'Bundesliga'; // Selected Bundesliga team or empty for all news

  // List of Bundesliga teams and their logos fetched from openligadb
  List<BundesligaTeam> _bundesligaTeams = [];

  @override
  void initState() {
    super.initState();
    _fetchFeed("https://newsfeed.kicker.de/news/bundesliga");
    _fetchBundesligaTeams(); // Fetch Bundesliga team data
  }

  void _fetchBundesligaTeams() async {
    final seasonYear = DateTime.now().year.toString();
    try {
      final response = await http.get(
        Uri.parse('https://api.openligadb.de/getbltable/bl1/$seasonYear'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> teamsData = jsonDecode(response.body);

        final List<BundesligaTeam> teams = [];

        teamsData.sort((a, b) => b['points'].compareTo(a['points']));
        teams.add(BundesligaTeam(
            teamName: "Bundesliga",
            logoUrl:
                "https://seeklogo.com/images/B/bundesliga-logo-CA4C5CF312-seeklogo.com.png"));
        for (final teamData in teamsData) {
          final teamName = teamData['teamName'];
          final logoUrl = teamData['teamIconUrl'];

          teams.add(BundesligaTeam(teamName: teamName, logoUrl: logoUrl));
        }

        setState(() {
          _bundesligaTeams = teams;
          _isLoading = false;
        });
      } else {
        print('Failed to fetch Bundesliga teams: ${response.statusCode}');
      }
    } catch (e) {
      // Handle error
      print('Error fetching Bundesliga teams: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _fetchFeed(String url) async {
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final responseBody = response.body
            .replaceAll("Ã¼", "ü")
            .replaceAll("Ã¤", "ä")
            .replaceAll("Ã¶", "ö")
            .replaceAll("Ã", "ß");
        setState(() {
          _feed = RssFeed.parse(responseBody);
          _isLoading = false;
        });
      } else {
        print('Failed to fetch news feed: ${response.statusCode}');
      }
    } catch (e) {
      ErrorPopup.show(context,
          'Die Nachrichten konnte nicht geladen werden. \nBitte überprüfe deine Internetverbindung und versuche es erneut.');
    }
  }

  Widget _buildImageWidget(String imageUrl) {
    final lowerImageUrl = imageUrl.toLowerCase();
    const size = 27.0;
    if (lowerImageUrl.endsWith('.svg')) {
      return SvgPicture.network(
        imageUrl,
        placeholderBuilder: (context) => const CircularProgressIndicator(),
        height: size,
        width: size,
        alignment: Alignment.topCenter,
      );
    } else if (lowerImageUrl.endsWith('.jpg') ||
        lowerImageUrl.endsWith('.jpeg') ||
        lowerImageUrl.endsWith('.png')) {
      return Image.network(
        imageUrl,
        height: size,
        width: size,
        alignment: Alignment.topCenter,
      );
    } else {
      // Fallback widget, you can replace it with any custom widget for unsupported image types
      return const Icon(Icons.error);
    }
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

  void _onTeamSelected(String teamName) async {
    setState(() {
      _selectedTeam = teamName;
      _isLoading = true;
    });

    switch (teamName.toLowerCase()) {
      case 'bundesliga':
        _fetchFeed("https://newsfeed.kicker.de/news/bundesliga");
        break;
      case '1. fc köln':
        _fetchFeed("https://newsfeed.kicker.de/team/1-fc-koeln");
        break;
      case '1. fc union berlin':
        _fetchFeed("https://newsfeed.kicker.de/team/1-fc-union-berlin");
        break;
      case '1. fsv mainz 05':
        _fetchFeed("https://newsfeed.kicker.de/team/1-fsv-mainz-05");
        break;
      case 'tsg 1899 hoffenheim':
        _fetchFeed("https://newsfeed.kicker.de/team/1899-hoffenheim");
        break;
      case 'fc augsburg':
        _fetchFeed("https://newsfeed.kicker.de/team/fc-augsburg");
        break;
      case 'fc bayern münchen':
        _fetchFeed("https://newsfeed.kicker.de/team/fc-bayern-muenchen");
        break;
      case 'borussia dortmund':
        _fetchFeed("https://newsfeed.kicker.de/team/borussia-dortmund");
        break;
      case 'borussia mönchengladbach':
        _fetchFeed("https://newsfeed.kicker.de/team/bor-moenchengladbach");
        break;
      case 'eintracht frankfurt':
        _fetchFeed("https://newsfeed.kicker.de/team/eintracht-frankfurt");
        break;
      case 'sv damstadt 98':
        _fetchFeed("https://newsfeed.kicker.de/team/darmstadt-98");
        break;
      case '1. fc heidenheim 1846':
        _fetchFeed("https://newsfeed.kicker.de/team/1-fc-heidenheim");
        break;
      case 'vfl wolfsburg':
        _fetchFeed("https://newsfeed.kicker.de/team/vfl-wolfsburg");
        break;
      case 'vfb stuttgart':
        _fetchFeed("https://newsfeed.kicker.de/team/vfb-stuttgart");
        break;
      case 'vfl bochum':
        _fetchFeed("https://newsfeed.kicker.de/team/vfl-bochum");
        break;
      case 'werder bremen':
        _fetchFeed("https://newsfeed.kicker.de/team/werder-bremen");
        break;
      case 'sc freiburg':
        _fetchFeed("https://newsfeed.kicker.de/team/sc-freiburg");
        break;
      case 'rb leipzig':
        _fetchFeed("https://newsfeed.kicker.de/team/rb-leipzig");
        break;
      case 'bayer leverkusen':
        _fetchFeed("https://newsfeed.kicker.de/team/bayer-04-leverkusen");
        break;
      default:
        _fetchFeed("https://newsfeed.kicker.de/news/bundesliga");
    }

    setState(() {
      _isLoading = false; // Hide loading indicator after news is fetched
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final team in _bundesligaTeams)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: () => _onTeamSelected(team.teamName),
                    style: ElevatedButton.styleFrom(
                      primary: _selectedTeam == team.teamName
                          ? Color.fromRGBO(
                              235, 28, 45, 300) // Selected team's color
                          : Colors.white,
                      shadowColor: Colors.grey.withOpacity(0.5),
                      elevation: 7,
                    ),
                    child: _buildImageWidget(team.logoUrl),
                  ),
                ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Color.fromARGB(255, 255, 255, 255).withOpacity(1.0),
                spreadRadius: 5,
                blurRadius: 7,
                offset: Offset(0, 3),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(),
                )
              : ListView.separated(
                  itemCount: _feed?.items?.length ?? 0,
                  separatorBuilder: (context, index) => SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final item = _feed!.items![index];
                    final category = item.categories?.first.value ??
                        'Bundesliga'; // Default category
                    final title = item.title ?? ''; // Decode HTML entities

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Card(
                        elevation: 3,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            category.toString(),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          onTap: () {
                            if (item.link != null && item.link!.isNotEmpty) {
                              _openInAppBrowser(item.link!, item.title!);
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
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

class BundesligaTeam {
  final String teamName;
  final String logoUrl;
  BundesligaTeam({required this.teamName, required this.logoUrl});
}
