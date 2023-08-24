import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_svg/flutter_svg.dart';
import '../popup/error.dart';

class TableScreen extends StatefulWidget {
  @override
  _TableScreenState createState() => _TableScreenState();
}

class _TableScreenState extends State<TableScreen> {
  List<dynamic> tableData = [];

  @override
  void initState() {
    super.initState();
    _fetchTableData();
  }

  void _fetchTableData() async {
    final seasonYear = DateTime.now().year.toString();
    final url = 'https://www.openligadb.de/api/getbltable/bl1/$seasonYear';
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        setState(() {
          tableData = jsonDecode(response.body);
        });
      } else {
        print('Failed to fetch table data: ${response.statusCode}');
      }
    } catch (e) {
      ErrorPopup.show(context,
          'Die Tabelle konnte nicht geladen werden. \nBitte überprüfe deine Internetverbindung und versuche es erneut.');
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

  Color getRankBackgroundColor(int rank) {
    // Define your ranking color scheme here
    if (rank == 1) {
      return Colors.orange;
    } else if (rank >= 2 && rank <= 4) {
      return Colors.green;
    } else if (rank == 5) {
      return Colors.blue;
    } else if (rank == 6) {
      return Colors.purple;
    } else if (rank == 16) {
      return Colors.yellow;
    } else if (rank > 16) {
      return Colors.red;
    } else {
      // Return a default background color for other ranks
      return Colors.transparent;
    }
  }

  Container buildCellWithLeftBorder(
      int rank, Color backgroundColor, Widget child) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 14),
      alignment: Alignment.bottomCenter,
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: backgroundColor, width: 4.0)),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 0, vertical: 8),
          child: Table(
            columnWidths: const {
              0: FixedColumnWidth(30),
              1: FixedColumnWidth(200),
              2: FixedColumnWidth(30),
              3: FixedColumnWidth(30),
              4: FixedColumnWidth(30),
              5: FixedColumnWidth(30),
              6: FixedColumnWidth(30),
              7: FixedColumnWidth(30),
            },
            children: [
              const TableRow(
                children: [
                  TableCell(child: Text('')),
                  TableCell(child: Text('')),
                  TableCell(
                      child: Center(
                          child: Text('Sp',
                              style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.bold)))),
                  TableCell(
                      child: Center(
                          child: Text('S',
                              style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.bold)))),
                  TableCell(
                      child: Center(
                          child: Text('U',
                              style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.bold)))),
                  TableCell(
                      child: Center(
                          child: Text('D',
                              style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.bold)))),
                  TableCell(
                      child: Center(
                          child: Text('Diff',
                              style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.bold)))),
                  TableCell(
                      child: Center(
                          child: Text('Pkt',
                              style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.bold)))),
                ],
              ),
              // Loop through each team data and create a TableRow for each team
              ...tableData.map((teamData) {
                final rank = '${tableData.indexOf(teamData) + 1}';
                final teamName = teamData['teamName'];
                final matchesPlayed = teamData['matches'];
                final matchesWon = teamData['won'];
                final matchesDrawn = teamData['draw'];
                final matchesLost = teamData['lost'];
                final goalDiff = teamData['goalDiff'];
                final points = teamData['points'];
                final icon = teamData['teamIconUrl'];

                return TableRow(
                  children: [
                    buildCellWithLeftBorder(
                      int.parse(rank),
                      getRankBackgroundColor(int.parse(rank)),
                      Text('$rank',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    TableCell(
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            _buildImageWidget(icon),
                            SizedBox(width: 8),
                            Text(teamName,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.normal)),
                          ],
                        ),
                      ),
                    ),
                    TableCell(
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Center(
                            child: Text('$matchesPlayed',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.normal))),
                      ),
                    ),
                    TableCell(
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Center(
                            child: Text('$matchesWon',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.normal))),
                      ),
                    ),
                    TableCell(
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Center(
                            child: Text('$matchesDrawn',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.normal))),
                      ),
                    ),
                    TableCell(
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Center(
                            child: Text('$matchesLost',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.normal))),
                      ),
                    ),
                    TableCell(
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Center(
                            child: Text('$goalDiff',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.normal))),
                      ),
                    ),
                    TableCell(
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Center(
                            child: Text('$points',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.normal))),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ],
          ),
        ),
        SizedBox(
            height: 16), // Adding some spacing between the table and legend
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: const Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LegendItem(
                    color: Colors.orange,
                    label: 'Meister',
                  ),
                  LegendItem(
                    color: Colors.green,
                    label: 'Champions League',
                  ),
                  LegendItem(
                    color: Colors.blue,
                    label: 'Europa League',
                  )
                ],
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LegendItem(
                    color: Colors.purple,
                    label: 'Conference League',
                  ),
                  LegendItem(
                    color: Colors.yellow,
                    label: 'Relegation',
                  ),
                  LegendItem(
                    color: Colors.red,
                    label: 'Abstieg',
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          color: color,
        ),
        SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 14)),
        SizedBox(width: 12),
      ],
    );
  }
}
