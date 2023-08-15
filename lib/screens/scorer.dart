import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../popup/error.dart';

class ScorerScreen extends StatefulWidget {
  @override
  _ScorerScreenState createState() => _ScorerScreenState();
}

class _ScorerScreenState extends State<ScorerScreen> {
  List<dynamic> topScorers = [];

  @override
  void initState() {
    super.initState();
    _fetchTopScorers();
  }

  void _fetchTopScorers() async {
    final seasonYear = DateTime.now().year.toString();
    final url = 'https://www.openligadb.de/api/getgoalgetters/bl1/$seasonYear';
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        List<dynamic> scorerDataList = jsonDecode(response.body);

        // Sort scorers by goals in descending order
        scorerDataList.sort((a, b) => b['goalCount'].compareTo(a['goalCount']));

        // Assign ranks to scorers based on goals
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
          topScorers = scorerDataList;
        });
      } else {
        ErrorPopup.show(context,
            'Die Torschützenliste konnte nicht geladen werden. \nBitte überprüfe deine Internetverbindung und versuche es erneut.');
      }
    } catch (e) {
      ErrorPopup.show(context,
          'Die Torschützenliste konnte nicht geladen werden. \nBitte überprüfe deine Internetverbindung und versuche es erneut.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: topScorers.isEmpty
              ? Center(
                  child: Text(
                    'Die Torschützenliste ist\nnach dem 1. Spieltag verfügbar.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              : DataTable(
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
                      DataCell(Text(playerName)),
                      DataCell(Text(goals.toString())),
                    ]);
                  }).toList(),
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
