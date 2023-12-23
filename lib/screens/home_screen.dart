import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:jnovel_unofficial/screens/home_novels.dart';
import 'package:jnovel_unofficial/screens/novel_list.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:jnovel_unofficial/db/novels_db.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void dispose() {
    super.dispose();
  }

  List<Map<String, String>> items = [
    {"label": "Home", "url": "https://jnovels.com/", "type": "none"},
    {
      "label": "Light novels (pdf)",
      "type": "lightNovels",
      "url": "https://jnovels.com/11light-1novel27-pdf"
    },
    {
      "label": "Light novels (Epub)",
      "type": "lightNovels",
      "url": "https://jnovels.com/hlight-10novel26-epub"
    },
    {
      "label": "Web novels",
      "url": "https://jnovels.com/hwebnovels-lista13/",
      "type": "webNovels"
    },
    {
      "label": "manga",
      "url": "https://jnovels.com/manga-cbz-cbr-pdfs-download108/",
      "type": "manga"
    }
  ];
  Future<ConnectivityResult> getConnectionStatus() async {
    ConnectivityResult connectivityResult =
        await (Connectivity().checkConnectivity());
    return connectivityResult;
  }

  Map<String, dynamic>? _config;
  message() async {
    const String url =
        'https://raw.githubusercontent.com/Phero49/messages/main/message.json';
    final HttpClientRequest request = await HttpClient().getUrl(Uri.parse(url));
    final HttpClientResponse response = await request.close();
    if (response.statusCode == HttpStatus.ok) {
      final String responseBody = await response.transform(utf8.decoder).join();
      final Map<String, dynamic> config = json.decode(responseBody);
      await novelListDb().openDb();
      Isar? db = isardb;

      if (config['message'] == true && db != null) {
        IsarCollection<Announcements> coll = db.collection<Announcements>();
        int id = config['id'];
        Announcements? res = await coll.get(id);
        if (res == null) {
          _config = config;
        }
      }
    } else {}
  }

  @override
  void initState() {
    super.initState();
    message();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> actions = [
      TextButton.icon(
          onPressed: () {
            Navigator.pushNamed(context, '/library');
          },
          label: const Text(
            'My downloads',
            style: TextStyle(color: Colors.white),
          ),
          icon: const Icon(
            Icons.download_done,
            color: Colors.white,
          )),
      TextButton.icon(
          onPressed: () {
            Navigator.pushNamed(context, '/read_later');
          },
          label:
              const Text('read later', style: TextStyle(color: Colors.white)),
          icon: const Icon(Icons.bookmark, color: Colors.white))
    ];
    return DefaultTabController(
        length: items.length,
        child: Scaffold(
            appBar: AppBar(
              title: const Text("JNovels-unofficial"),
              actions: [
                GestureDetector(
                  onTap: () {
                    Uri uri = Uri.parse(
                        "https://discord.com/channels/1181104968367882250/1181104968367882253");
                    launchUrl(uri);
                  },
                  child: const CircleAvatar(
                    radius: 20,
                    backgroundImage:
                        AssetImage('assets/images/pngwing.com.png'),
                  ),
                ),
                SizedBox(
                  width: 20,
                ),
                PopupMenuButton(
                  child: Icon(Icons.more_vert),
                  itemBuilder: (context) => [
                    for (var action in actions) PopupMenuItem(child: action)
                  ],
                )
              ],
              bottom: TabBar(
                  padding: const EdgeInsets.only(bottom: 7),
                  isScrollable: true,
                  tabs: [
                    for (String label in items.map((e) => e['label'] as String))
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(label.toUpperCase()),
                      )
                  ]),
            ),
            body: FutureBuilder(
              future: getConnectionStatus(),
              builder: (BuildContext context,
                  AsyncSnapshot<ConnectivityResult> snapshot) {
                if (snapshot.hasData) {
                  ConnectivityResult res = snapshot.data as ConnectivityResult;
                  if (res == ConnectivityResult.none) {
                    return Center(child: Text("no internet connection "));
                  } else {
                    message();
                    Future.delayed(const Duration(seconds: 5), () {
                      if (_config != null) {
                        return showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text('announcement 📢'),
                              content: Container(
                                constraints: BoxConstraints(maxWidth: 400),
                                child: SingleChildScrollView(
                                    child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                      Text("${_config!['body']}"),
                                      TextButton(
                                          onPressed: () {
                                            Uri uri =
                                                Uri.parse(_config!['link']);
                                            launchUrl(uri);
                                          },
                                          child: const Text(
                                            'click here to learn more',
                                            style:
                                                TextStyle(color: Colors.orange),
                                          ))
                                    ])),
                              ),
                            );
                          },
                        ).then((value) async {
                          Isar? db = isardb;
                          IsarCollection<Announcements> coll =
                              db!.collection<Announcements>();

                          int id = _config!['id'];

                          db.writeTxn(() async {
                            Announcements a = Announcements()
                              ..id = id
                              ..read = true;
                            await coll.put(a);
                          });
                        });
                      } else {
                        return null;
                      }
                    });
                    return TabBarView(
                      children: [
                        for (Map item in items)
                          item['label'] == "Home"
                              ? Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: HomeTabWidget(item['url']),
                                )
                              : Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: NovelListWidget(
                                    item['url'],
                                    type: item['type'],
                                  ),
                                )
                      ],
                    );
                  }
                } else {
                  return Center(
                    child: Text('checking for connection'),
                  );
                }
              },
            )));
  }
}
