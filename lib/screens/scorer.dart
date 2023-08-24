import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ScorerScreen extends StatefulWidget {
  @override
  _ScorerScreenState createState() => _ScorerScreenState();
}

class _ScorerScreenState extends State<ScorerScreen> {
  List<Map<String, dynamic>> topScorers = [];

  @override
  void initState() {
    super.initState();
    _fetchTopScorers();
  }

  Future<void> _fetchTopScorers() async {
    final seasonYear = DateTime.now().year.toString();
    final url = 'https://www.openligadb.de/api/getgoalgetters/bl1/$seasonYear';
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        List<dynamic> scorerDataList = jsonDecode(response.body);

        scorerDataList.sort((a, b) => b['goalCount'].compareTo(a['goalCount']));

        int currentRank = 1;
        int currentGoals = -1;

        for (final scorerData in scorerDataList) {
          final goals = scorerData['goalCount'];

          if (goals < currentGoals) {
            currentRank++;
            currentGoals = goals;
          }

          currentGoals = goals;
          scorerData['rank'] = currentRank;
        }

        setState(() {
          topScorers = List<Map<String, dynamic>>.from(scorerDataList);
        });
      } else {
        _showErrorPopup(
            'Die Torschützenliste konnte nicht geladen werden. Bitte überprüfe deine Internetverbindung und versuche es erneut.');
      }
    } catch (e) {
      _showErrorPopup(
          'Die Torschützenliste konnte nicht geladen werden. Bitte überprüfe deine Internetverbindung und versuche es erneut.');
    }
  }

  void _showErrorPopup(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Fehler'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: topScorers.isEmpty
            ? CircularProgressIndicator()
            : SingleChildScrollView(
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Card(
                    elevation: 7,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DataTable(
                      columnSpacing: 24,
                      headingTextStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                      columns: const <DataColumn>[
                        DataColumn(label: Text('Rang')),
                        DataColumn(label: Text('Spieler')),
                        DataColumn(label: Text('Tore')),
                      ],
                      rows: topScorers.map((scorerData) {
                        final playerName = scorerData['goalGetterName'];
                        final goals = scorerData['goalCount'];
                        final rank = scorerData['rank'];

                        return DataRow(cells: [
                          DataCell(Text(rank.toString())),
                          DataCell(
                            Container(
                              width: 200, // Adjust the width as needed
                              child: Text(playerName),
                            ),
                          ),
                          DataCell(Text(goals.toString())),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: ScorerScreen(),
  ));
}
