import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_svg/flutter_svg.dart';
import '../popup/error.dart';

class MatchesScreen extends StatefulWidget {
  @override
  _MatchesScreenState createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  List<dynamic> matchesData = [];
  int currentMatchday = 1;

  @override
  void initState() {
    super.initState();
    _fetchCurrentMatchday();
    _fetchMatchesData(currentMatchday);
  }

  String getDayOfWeek(DateTime dateTime) {
    switch (dateTime.weekday) {
      case 1:
        return 'Montag';
      case 2:
        return 'Dienstag';
      case 3:
        return 'Mittwoch';
      case 4:
        return 'Donnerstag';
      case 5:
        return 'Freitag';
      case 6:
        return 'Samstag';
      case 7:
        return 'Sonntag';
      default:
        return ''; // Return an empty string or any default value for invalid cases
    }
  }

  String _formatTime(DateTime dateTime) {
    // Format time as per your requirement, e.g., 'HH:mm'
    return '${getDayOfWeek(dateTime)}, ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _fetchCurrentMatchday() async {
    final url = 'https://api.openligadb.de/getcurrentgroup/bl1';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        currentMatchday = data['groupOrderID'];
      });
    } else {
      print('Failed to fetch current matchday: ${response.statusCode}');
    }
  }

  void _fetchMatchesData(int matchday) async {
    final seasonYear = DateTime.now().year.toString();
    // final seasonYear = '2021';
    final url =
        'https://api.openligadb.de/getmatchdata/bl1/$seasonYear/$matchday';
    print(url);
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        List<dynamic> matches = jsonDecode(response.body);
        // Sort matches by their time
        matches
            .sort((a, b) => a['matchDateTime'].compareTo(b['matchDateTime']));

        setState(() {
          matchesData = matches;
        });
      } else {
        print('Failed to fetch matches data: ${response.statusCode}');
      }
    } catch (e) {
      ErrorPopup.show(context,
          'Der Spieltag konnte nicht geladen werden. \nBitte überprüfe deine Internetverbindung und versuche es erneut.');
    }
  }

  Widget _buildImageWidget(String imageUrl) {
    final lowerImageUrl = imageUrl.toLowerCase();
    const size = 27.0;
    if (lowerImageUrl.endsWith('.svg')) {
      return SvgPicture.network(
        imageUrl,
        placeholderBuilder: (context) => CircularProgressIndicator(),
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
      return Icon(Icons.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildMatchdaySelector(),
        Expanded(
          child: ListView.builder(
            itemCount: matchesData.length,
            itemBuilder: (context, index) {
              final matchData = matchesData[index];
              final date = matchData['matchDateTime'];
              final homeTeam = matchData['team1']['teamName'];
              final awayTeam = matchData['team2']['teamName'];
              final matchResult = matchData['matchResults'].isEmpty
                  ? ':'
                  : '${matchData['matchResults'][0]['pointsTeam1']} - ${matchData['matchResults'][0]['pointsTeam2']}';

              final homeTeamIconUrl = matchData['team1']['teamIconUrl'];
              final awayTeamIconUrl = matchData['team2']['teamIconUrl'];

              // Check if the time separator should be displayed
              bool showTimeSeparator = false;
              if (index == 0) {
                showTimeSeparator = true;
              } else {
                final prevMatchData = matchesData[index - 1];
                final prevDate = prevMatchData['matchDateTime'];
                if (date != prevDate) {
                  showTimeSeparator = true;
                }
              }

              return Column(
                children: [
                  if (showTimeSeparator)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Text(
                            _formatTime(DateTime.parse(date)),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Divider(
                            thickness: 1, // Adjust thickness as needed

                            color: Colors.grey, // Adjust color as needed
                          ),
                        ],
                      ),
                    ),
                  SizedBox(height: 8), // Add spacing between rows
                  Row(
                    mainAxisAlignment: MainAxisAlignment
                        .center, // Align the teams and "vs" in the center
                    children: [
                      Column(
                        children: [
                          _buildImageWidget(homeTeamIconUrl),
                          SizedBox(height: 4),
                        ],
                      ),
                      // Spacer between the team name and the separator ":"

                      // Separator ":" aligned under each other
                      Row(
                        children: [
                          Text(
                            '$homeTeam ',
                            style: TextStyle(fontSize: 14),
                          ),
                          Text(
                            matchResult,
                            style: matchData['matchResults'].isEmpty
                                ? TextStyle(fontSize: 14, color: Colors.black)
                                : TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black),
                          ),
                          Text(
                            ' $awayTeam',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),

                      Column(
                        children: [
                          _buildImageWidget(awayTeamIconUrl),
                          SizedBox(height: 4),
                        ],
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMatchdaySelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            if (currentMatchday > 1) {
              setState(() {
                currentMatchday--;
                _fetchMatchesData(currentMatchday);
              });
            }
          },
        ),
        Text(
          '$currentMatchday. Spieltag',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: Icon(Icons.arrow_forward),
          onPressed: () {
            // You can replace the 'totalMatchdays' with the actual total number of matchdays
            int totalMatchdays = 34;
            if (currentMatchday < totalMatchdays) {
              setState(() {
                currentMatchday++;
                _fetchMatchesData(currentMatchday);
              });
            }
          },
        ),
      ],
    );
  }
}
