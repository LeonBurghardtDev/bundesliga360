import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_svg/flutter_svg.dart';
import '../popup/error.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  _MatchesScreenState createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  List<dynamic> matchesData = [];
  int currentMatchday = 1;
  bool pageLoad = true;

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
    const url = 'https://api.openligadb.de/getcurrentgroup/bl1';
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
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        List<dynamic> matches = jsonDecode(response.body);

        final currentTime = DateTime.now();

        // Sort matches by their time
        matches
            .sort((a, b) => a['matchDateTime'].compareTo(b['matchDateTime']));

        // Check if all matches are finished
        final allMatchesFinished = matches.every((match) {
          final matchDateTime = DateTime.parse(match['matchDateTime']);
          final timeDifference = currentTime.difference(matchDateTime);
          return timeDifference.inMinutes > 105;
        });

        if (allMatchesFinished && pageLoad) {
          currentMatchday = matchday + 1;
          _fetchMatchesData(matchday + 1);
          pageLoad = false;
        }

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
  Widget _buildMatchRow(Map<String, dynamic> matchData, int currentMinute) {
    final date = matchData['matchDateTime'];
    final homeTeam = matchData['team1']['teamName'];
    final awayTeam = matchData['team2']['teamName'];
    final matchResult = matchData['matchResults'].isEmpty
        ? 'vs'
        : '${matchData['matchResults'][1]['pointsTeam1']} - ${matchData['matchResults'][1]['pointsTeam2']}';

    // Calculate time difference in minutes
    final matchDateTime = DateTime.parse(date);
    final currentTime = DateTime.now();
    final timeDifference = matchDateTime.difference(currentTime).inMinutes;

    // Determine text color based on time difference
    Color textColor = Colors.black;
    if (timeDifference < 105 && timeDifference > 0) {
      textColor = Colors.red;
    }

    final homeTeamIconUrl = matchData['team1']['teamIconUrl'];
    final awayTeamIconUrl = matchData['team2']['teamIconUrl'];

    return GestureDetector(
      onTap: () {
        _showMatchDetailDialog(matchData['matchID'].toString(),currentMinute);
      },
      child: Container(
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
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    _buildImageWidget(homeTeamIconUrl),
                    const SizedBox(height: 4),
                  ],
                ),
                const SizedBox(
                    width: 8), // Add spacing between team icon and text
                Column(
                  children: [
                    Text(
                      '$homeTeam ',
                      style: const TextStyle(fontSize: 14),
                    ),
                    if (currentMinute != -1)
                      Text(
                        '$currentMinute\'',
                        style: TextStyle(fontSize: 14, color: textColor, fontWeight: FontWeight.bold),
                      ),                    Text(
                      matchResult,
                      style: matchData['matchResults'].isEmpty
                          ? TextStyle(fontSize: 14, color: textColor)
                          : TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textColor),
                    ),

                    Text(
                      ' $awayTeam',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(
                    width: 8), // Add spacing between text and team icon
                Column(
                  children: [
                    _buildImageWidget(awayTeamIconUrl),
                    const SizedBox(height: 4),
                  ],
                ),
              ],
            ),

          ],
        ),
      ),
    );
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
                  : '${matchData['matchResults'][1]['pointsTeam1']} - ${matchData['matchResults'][1]['pointsTeam2']}';

              // Calculate time difference in minutes
              final matchDateTime = DateTime.parse(date);
              final currentTime = DateTime.now().add(const Duration(hours: 2));
              final timeDifference =
                  matchDateTime.difference(currentTime).inMinutes;

              // Determine text color based on time difference
              Color textColor = Colors.black;
              if (timeDifference < 105 && timeDifference > 0) {
                textColor = Colors.red;
              }

              int currentMinute = -1;
              if (timeDifference.abs() < 110){
                if(timeDifference.abs() < 45){
                  currentMinute =  timeDifference.abs();
                }else if(timeDifference.abs() > 47&& timeDifference.abs() < 60){
                  currentMinute =  45;
                }else if(timeDifference.abs() > 60 && timeDifference.abs() < 115){
                  currentMinute =  timeDifference.abs() - 17;
                }
}
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

              // Check if the match has the same game time as the previous match
              bool sameGameTimeAsPrevious = true;

              return Column(
                children: [
                  if (showTimeSeparator) SizedBox(height: 8),
                  if (showTimeSeparator)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  _formatTime(DateTime.parse(date)),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color.fromARGB(255, 66, 66, 66),
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Expanded(
                            flex: 3,
                            child: Divider(
                              thickness: 1, // Adjust thickness as needed
                              color: Color.fromARGB(
                                  255, 204, 204, 204), // Adjust color as needed
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(height: 8),
                  if (sameGameTimeAsPrevious) const SizedBox(height: 2),
                  if (sameGameTimeAsPrevious)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _buildMatchRow(matchData, currentMinute),
                    ),
                  if (!sameGameTimeAsPrevious) _buildMatchRow(matchData, currentMinute),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  void _showMatchDetailDialog(String matchId,int currentMinute) async {
    final response = await http.get(
      Uri.parse('https://api.openligadb.de/getmatchdata/$matchId'),
    );

    if (response.statusCode == 200) {
      final matchData = jsonDecode(response.body);
      final goals = matchData['goals'];

      final dialogContext = context;

      // Create a list of widgets to store the goal tiles
      List<Widget> goalTiles = [];

      if (goals.length > 0) {
        for (var i = 0; i < goals.length; i++) {
          final goal = goals[i];
          final team1ScoreBeforeGoal =
              goal['scoreTeam1'] - (i > 0 ? goals[i - 1]['scoreTeam1'] : 0);
          final team2ScoreBeforeGoal =
              goal['scoreTeam2'] - (i > 0 ? goals[i - 1]['scoreTeam2'] : 0);

          goalTiles.add(Align(
            alignment: team1ScoreBeforeGoal > 0
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              title: Row(
                mainAxisAlignment: team1ScoreBeforeGoal > 0
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.end,
                children: [
                  if (team1ScoreBeforeGoal > 0)
                    Icon(
                      Icons.sports_soccer,
                      size: 18,
                      color: Colors.black,
                    ),
                  SizedBox(width: 4), // Add this to adjust spacing
                  Text(
                    '${goal['goalGetterName']} ${goal['isPenalty'] ? '(P)' : ''} ${goal['isOwnGoal'] ? '(OG)' : ''}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 4), // Add this to adjust spacing
                  if (team2ScoreBeforeGoal > 0)
                    Icon(
                      Icons.sports_soccer,
                      size: 18,
                      color: Colors.black,
                    ),
                ],
              ),
              subtitle: Align(
                alignment: team1ScoreBeforeGoal > 0
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: Text(
                  goal['isOvertime']
                      ? goal['matchMinute'] < 90
                          ? '45+${goal['matchMinute'] - 45}\''
                          : '90+${goal['matchMinute'] - 90}\''
                      : goal['matchMinute'] > 90
                          ? '90+${goal['matchMinute'] - 90}\''
                          : '${goal['matchMinute']}\'',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black,
                  ),
                  textAlign: team1ScoreBeforeGoal > 0
                      ? TextAlign.left
                      : TextAlign.right,
                ),
              ),
            ),
          ));
        }
      } else {
        goalTiles.add(Center(
          child: Text(
            'Keine Tore bisher',
            style: TextStyle(
              fontSize: 12,
              color: Colors.black,
            ),
          ),
        ));
      }

      String fulltime_result = '';
      String halftime_result = '';

      try {
        fulltime_result =
            '${matchData['matchResults'][1]['pointsTeam1']} - ${matchData['matchResults'][1]['pointsTeam2']}';
        halftime_result =
            ' (${matchData['matchResults'][0]['pointsTeam1']} - ${matchData['matchResults'][0]['pointsTeam2']})';
      } catch (Exception) {
        String dateString = matchData['matchDateTime'];
        DateTime? matchDateTime = DateTime.tryParse(dateString);

        String formattedDateTime = matchDateTime != null
            ? '${matchDateTime.day.toString().padLeft(2, '0')}.${matchDateTime.month.toString().padLeft(2, '0')}.${matchDateTime.year} - ${matchDateTime.hour.toString().padLeft(2, '0')}:${matchDateTime.minute.toString().padLeft(2, '0')}'
            : '';

        fulltime_result = '$formattedDateTime';
      }
      var TextColor= Colors.black;
      if(currentMinute != -1){
        TextColor = Colors.red;
      }


      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.6,
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width:
                              40, // Adjust the width of the logo container as needed
                          height:
                              40, // Adjust the height of the logo container as needed
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                                8), // Adjust the radius as needed
                            child: _buildImageWidget(
                                matchData['team1']['teamIconUrl']),
                          ),
                        ),
                        SizedBox(width: 8),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '${matchData['team1']['teamName']} - ${matchData['team2']['teamName']}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          width:
                              40, // Adjust the width of the logo container as needed
                          height:
                              40, // Adjust the height of the logo container as needed
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                                8), // Adjust the radius as needed
                            child: _buildImageWidget(
                                matchData['team2']['teamIconUrl']),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Center(
                    child: Column(
                      children: [
                        Text(
                          fulltime_result,
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold, color: TextColor),
                        ),
                        if (currentMinute == -1)
                          Text(
                            halftime_result,
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        if (currentMinute != -1)
                          Text(
                            ' $currentMinute\'',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold, color: TextColor),
                          ),

                      ],
                    ),
                  ),
                  const Divider(
                    color: Colors.black,
                  ),
                  goals.isNotEmpty // Check if there are goals in the match
                      ? Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: goalTiles,
                            ),
                          ),
                        )
                      : Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                            ),
                          ),
                        ), // Empty container if no goals
                  Align(
                    alignment: Alignment.center,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the dialog
                      },
                      style: ElevatedButton.styleFrom(
                        primary: Color.fromRGBO(
                            235, 28, 45, 1.0), // Set the background color
                      ),
                      child: Text(
                        'Close',
                        style: TextStyle(
                            color: Colors.white), // Set the text color
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else {
      print('Failed to fetch match details: ${response.statusCode}');
    }
  }

  Widget _buildMatchdaySelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3), // changes position of shadow
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
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
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
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
      ),
    );
  }
}
