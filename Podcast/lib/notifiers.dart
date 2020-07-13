import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webfeed/webfeed.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

final url = "https://itsallwidgets.com/podcast/feed";

class Podcast with ChangeNotifier {
  RssFeed _feed;
  RssItem _selectedItem;
  Map<RssItem, String> downloadLocations = {};

  RssFeed get feed => _feed;
  void parse(String xmlStr) async {
    final res = await http.get(url);
    final xmlStr = res.body;
    _feed = RssFeed.parse(xmlStr);
    notifyListeners();
  }

  RssItem get selectedItem => _selectedItem;
  set selectedItem(RssItem value) {
    _selectedItem = value;
    notifyListeners();
  }

  Future<bool> download(RssItem item) async {
    final client = http.Client();
    final uri = Uri.parse(item.guid);
    final req = http.Request("GET", uri);
    final res = await client.send(req);
    bool success = false;

    if (res.statusCode != 200)
      throw Exception("Unexpected HTTP code: ${res.statusCode}");

    String filepath = await getDownloadPath(path.split(item.guid).last);
    final file = File(await getDownloadPath(filepath));
    await res.stream.pipe(file.openWrite()).whenComplete(() {
      downloadLocations[item] = filepath;
      success = true;
    }).catchError((e) => print("Error $e"));

    return success;
  }

  Future<String> getDownloadPath(String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    final prefix = dir.uri.path;
    return path.join(prefix, filename);
  }
}
