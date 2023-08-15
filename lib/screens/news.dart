import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchFeed();
  }

  void _fetchFeed() async {
    try {
      final response = await http
          .get(Uri.parse('https://newsfeed.kicker.de/news/bundesliga'));

      if (response.statusCode == 200) {
        final responseBody = response.body
            .replaceAll("Ã¼", "ü")
            .replaceAll("Ã¤", "ä")
            .replaceAll("Ã¶", "ö");
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

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? Center(
            child: CircularProgressIndicator(),
          )
        : ListView.separated(
            itemCount: _feed?.items?.length ?? 0,
            separatorBuilder: (context, index) => Divider(
              thickness: 1,
              color: Colors.grey,
            ),
            itemBuilder: (context, index) {
              final category = _feed!.items![index].categories?.first.value;
              final item = _feed!.items![index];
              final title = item.title ?? ''; // Decode HTML entities
              return ListTile(
                title: Text(title),
                subtitle: Text(category.toString()),
                onTap: () {
                  if (item.link != null && item.link!.isNotEmpty) {
                    _openInAppBrowser(item.link!, item.title!);
                  }
                },
              );
            },
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
