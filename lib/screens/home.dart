import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'dart:async';

import 'package:webfeed/webfeed.dart';

import '../popup/error.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String nextMatchCountdown = 'Fetching match data...';
  int currentMatchday = 1;
  List<dynamic> matchesData = [];
  int currentSlideIndex = 0;
  List<RssItem> topNews = [];
  late Timer timer;
  bool _isLoading = true;
  bool _newsLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchCurrentMatchday();

    if (!_newsLoading) {
      _fetchTopNews().then((topNews) {
        setState(() {
          this.topNews = topNews;
          _newsLoading = true;
        });
      });
    }
  }

  @override
  void dispose() {
    timer.cancel(); // Cancel the timer in the dispose method
    super.dispose();
  }

  Future<List<RssItem>> _fetchTopNews() async {
    final rssUrl =
        'https://sportbild.bild.de/rss/vw-bundesliga-artikel/vw-bundesliga-artikel-45028194,view=rss2.sport.xml';

    final response = await http.get(Uri.parse(rssUrl));

    if (response.statusCode == 200) {
      final feed = RssFeed.parse(response.body);

      // Get the 5 newest items
      final topNews = feed.items?.take(10).toList() ?? [];
      return topNews;
    } else {
      ErrorPopup.show(context,
          'Bitte überprüfe deine Internetverbindung und versuche es erneut.');
      return [];
    }
  }

  void _fetchCurrentMatchday() async {
    const url = 'https://api.openligadb.de/getcurrentgroup/bl1';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        currentMatchday = data['groupOrderID'];
        _fetchMatchesData(currentMatchday);
      });
    } else {
      ErrorPopup.show(context,
          'Bitte überprüfe deine Internetverbindung und versuche es erneut.');
    }
  }

  void _fetchMatchesData(int matchday) async {
    final seasonYear = DateTime.now().year.toString();
    final url =
        'https://api.openligadb.de/getmatchdata/bl1/$seasonYear/$matchday';
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        List<dynamic> matches = jsonDecode(response.body);
        // Sort matches by their time
        matches
            .sort((a, b) => a['matchDateTime'].compareTo(b['matchDateTime']));

        if (matches.isNotEmpty) {
          final nextMatchDateTime =
              DateTime.parse(matches.first['matchDateTime']);
          final currentTime = DateTime.now();
          final timeDifference = nextMatchDateTime.difference(currentTime);

          if (timeDifference < Duration.zero) {
            setState(() {
              nextMatchCountdown = '...';
            });
            _fetchMatchesData(currentMatchday + 1);
            return;
          }
          setState(() {
            nextMatchCountdown =
                '${timeDifference.inDays} days, ${timeDifference.inHours % 24} hours, ${timeDifference.inMinutes % 60} minutes, ${timeDifference.inSeconds % 60} seconds';
            matchesData = matches;
            _isLoading = false;
            _startCountdownTimer();
          });
        }
      } else {
        ErrorPopup.show(context,
            'Bitte überprüfe deine Internetverbindung und versuche es erneut.');
      }
    } catch (e) {
      ErrorPopup.show(context,
          'Bitte überprüfe deine Internetverbindung und versuche es erneut.');
    }
  }

  void _startCountdownTimer() {
    if (matchesData.isEmpty) return;
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        for (var match in matchesData) {
          final matchDateTime = DateTime.parse(match['matchDateTime']);
          final currentTime = DateTime.now();
          final timeDifference = matchDateTime.difference(currentTime);

          if (timeDifference < Duration(seconds: 1) &&
              timeDifference > Duration(seconds: -105 * 60)) {
            // Game is currently running, update standings and slide index
            currentSlideIndex = matchesData.indexOf(match);
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? Center(
            child: CircularProgressIndicator(),
          )
        : Scaffold(
            body: SingleChildScrollView(
              // Wrap the Column with SingleChildScrollView
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(height: 20),
                    Center(
                      child: _buildMatchInfo(matchesData[currentSlideIndex]),
                    ),
                    SizedBox(height: 20),
                    _buildTopNewsSection(),
                    // ... (previous code)
                  ],
                ),
              ),
            ),
          );
  }

  Widget _buildTopNewsSection() {
    if (topNews.isEmpty) {
      return SizedBox(); // Return an empty SizedBox if no top news available
    }

    return Container(
      padding: EdgeInsets.all(8),
      margin: EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 3,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            alignment:
                Alignment.topLeft, // Align the text to the top-left corner
            child: Text(
              'Top News',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          GestureDetector(
            onTap: () {
              _openInAppBrowser(topNews[0].link ?? '', topNews[0].title ?? '');
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(12)),
                    child: Image.network(
                      topNews[0].media?.contents?.first.url ?? '',
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      topNews[0].title ?? '',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          Divider(thickness: 1, color: Colors.grey.withOpacity(0.5)),
          Column(
            children: topNews.sublist(1, 10).map((item) {
              return Column(
                children: [
                  SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      _openInAppBrowser(item.link ?? '', item.title ?? '');
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(8),
                              bottomLeft: Radius.circular(8),
                            ),
                            child: Image.network(
                              item.media?.thumbnails?.first.url ?? '',
                              width: 120,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                item.title ?? '',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                ],
              );
            }).toList(),
          ),
        ],
      ),
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

  Widget _buildMatchInfo(Map<String, dynamic> matchData) {
    final homeTeam = matchData['team1']['teamName'];
    final awayTeam = matchData['team2']['teamName'];
    final dateTime = DateTime.parse(matchData['matchDateTime']);
    final matchResult = matchData['matchResults'].isEmpty
        ? '${DateTime.parse(matchData['matchDateTime']).day.toString() + '.' + DateTime.parse(matchData['matchDateTime']).month.toString() + '.' + DateTime.parse(matchData['matchDateTime']).year.toString() + ' - ' + DateTime.parse(matchData['matchDateTime']).hour.toString() + ':' + DateTime.parse(matchData['matchDateTime']).minute.toString() + ' Uhr'}'
        : '${matchData['matchResults'][1]['pointsTeam1']} : ${matchData['matchResults'][1]['pointsTeam2']}';

    final homeTeamIconUrl = matchData['team1']['teamIconUrl'];
    final awayTeamIconUrl = matchData['team2']['teamIconUrl'];

    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 3,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Nächste Bundesliga-Spiel',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          SizedBox(width: 26),
          if (matchData['matchResults'].isEmpty ||
              matchData['matchResults'][1]['pointsTeam1'] == null ||
              matchData['matchResults'][1]['pointsTeam2'] == null)
            CountdownClock(
              matchesData: matchesData,
              currentSlideIndex: currentSlideIndex,
            ),
          SizedBox(width: 26),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.network(homeTeamIconUrl, width: 48, height: 48),
              SizedBox(width: 8),
              Text(
                homeTeam,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 8),
              Text(
                'gegen',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 8),
              Text(
                awayTeam,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Image.network(awayTeamIconUrl, width: 48, height: 48),
              SizedBox(width: 8),
            ],
          ),
          Text(
            matchResult,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          // Add the standings slideshow here
        ],
      ),
    );
  }
}

class CountdownClock extends StatefulWidget {
  final List<dynamic> matchesData;
  final int currentSlideIndex;

  CountdownClock({required this.matchesData, required this.currentSlideIndex});

  @override
  _CountdownClockState createState() => _CountdownClockState();
}

class _CountdownClockState extends State<CountdownClock> {
  String countdown = '00:00:00:00';
  late final Timer timer;

  @override
  void initState() {
    super.initState();
    _startCountdownTimer();
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  void _startCountdownTimer() {
    if (widget.matchesData.isEmpty) return;
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      final currentTime = DateTime.now();
      final nextMatchTime = DateTime.parse(
          widget.matchesData[widget.currentSlideIndex]['matchDateTime']);
      final timeDifference = nextMatchTime.difference(currentTime);

      if (timeDifference.isNegative) {
        setState(() {
          countdown = '00:00:00';
        });
        timer.cancel();
      } else {
        final days = timeDifference.inDays.toString().padLeft(2, '0');
        final hours = (timeDifference.inHours % 24).toString().padLeft(2, '0');
        final minutes =
            (timeDifference.inMinutes % 60).toString().padLeft(2, '0');
        final seconds =
            (timeDifference.inSeconds % 60).toString().padLeft(2, '0');
        setState(() {
          countdown = '$days:$hours:$minutes:$seconds';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      countdown,
      style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
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
