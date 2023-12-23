import 'dart:io';
import 'dart:ui';

import 'package:chaleno/chaleno.dart';
import 'package:flutter/material.dart';
//import 'package:html/dom.dart' as htmlDom;
import 'package:html/parser.dart';
import 'package:isar/isar.dart';
import 'package:jnovel_unofficial/db/novels_db.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class ViewSingleNovel extends StatefulWidget {
  final String name;
  final String image;
  final String url;
  final String source;
  const ViewSingleNovel(this.url, this.image, this.name,
      {required this.source, super.key});

  @override
  State<ViewSingleNovel> createState() => _ViewSingleNovelState();
}

class SingleNovel {
  String? synopsis;
  String? downloadLink;
  String? image;
  String? name;

  SingleNovel(
      {this.downloadLink, this.image, this.name, required this.synopsis});
}

class _ViewSingleNovelState extends State<ViewSingleNovel> {
  List<SingleNovel> otherVolumes = [];
  Isar? _isar;

  final ScrollController _horiScrollController = ScrollController();
  Future<bool> getOtherVolumes() async {
    try {
      String url = widget.url;
      List<String> splitUrl = url.split('volume-');
      String title = splitUrl[0];
      List<String> volAndType = splitUrl[1].split('-');
      int volNumber = int.parse(volAndType[0]);
      String type = volAndType[1];

      for (var i = 1; i < volNumber; i++) {
        if (i > 1) {
          String url = '${title}volume-$i-$type';
          Parser? parser = await Chaleno().load("${title}volume-$i-$type");
          if (parser != null) {
            String? title = parser.title();
            if (title!.contains('Page not found') == false) {
              otherVolumes.add(extractNovelData(parser, url));
            }
          }
        } else {
          await getVolOne();
        }
      }
    } catch (e) {
      //rethrow;
    }

    return true;
    //  print(widget.url);
  }

  @override
  void initState() {
    super.initState();
    novelListDb().openDb();
    _isar = isardb;
  }

  Widget actionBtn(String url) {
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: () async {
            Uri _url = Uri.parse(url);
            launchUrl(_url);
          },
          label: const Text("Download"),
          icon: const Icon(Icons.file_download_outlined),
        ),
        const SizedBox(
          width: 12,
        ),
        ElevatedButton.icon(
          onPressed: () async {
            Uri uriComponents = Uri.parse(widget.image);
            var uri = Uri.https(uriComponents.host, uriComponents.path);
            var res = await http.get(uri);

            List<int> image =
                GZipCodec(gzip: true, level: 9).encode(res.bodyBytes);

            IsarCollection<ReadLater> readLater =
                isardb!.collection<ReadLater>();
            isardb!.writeTxn(() async {
              var ob = ReadLater()
                ..cover = image
                ..title = widget.name
                ..url = widget.url
                ..addedOn = DateTime.now().toString();
              readLater.put(ob);
            });
          },
          label: const Text("read later"),
          icon: const Icon(Icons.bookmark_add),
        )
      ],
    );
  }

  SingleNovel extractNovelData(Parser parser, url) {
    String? img = parser.querySelector('.featured-media img').src;
    String? name = parser.querySelector('.post-title a').href;
    var h = parser.querySelectorAll('p a').map((e) {
      print(e.innerHTML);
      if (e.text!.toLowerCase().contains('volume ') == true) {
        return e;
      }
    });
    String usedSelector = '.synopsis-description';
    String downloadLink = url;
    //get description  section and
    Result? synopsisResults = parser.querySelector(usedSelector);
    //get download list inside description if exist

    if (synopsisResults.innerHTML == null) {
      synopsisResults = parser.querySelector("#editdescription");
      usedSelector = "#editdescription";
    }
    String synopsis = '';

    if (synopsisResults.innerHTML != null) {
      var document =
          parseFragment(parser.querySelector(usedSelector).innerHTML);

      if (document.querySelector('ol') != null) {
        document.querySelector('ol')!.remove();
      }
      synopsis = document.text as String;
    } else {
      Result? p = parser.querySelector('.post-content ');
      List<Result>? ps = p.querySelectorAll('p');
      for (var i = 2; i < ps!.length; i++) {
        var el = ps[i];
        if (el.html!.startsWith('<p>')) {
          synopsis += '${el.text!}\n\n';
        } else {
          break;
        }
      }
    }

    return SingleNovel(
        synopsis: synopsis, downloadLink: downloadLink, image: img, name: name);
  }

  Future<void> getVolOne() async {
    String baseUrl = 'https://jnovels.com/?s=${widget.name}';
    Parser? parser = await Chaleno().load(baseUrl);
    if (parser != null) {
      if (!parser.title()!.contains('Page not found')) {
        Result a = parser.querySelector('.post-content a');

        Parser? p = await Chaleno().load(a.href!);
        if (!p!.title()!.contains('Page not found')) {
          print(a.href);
          SingleNovel singleNovel = extractNovelData(p, a.href);
          print(singleNovel);
          otherVolumes.add(singleNovel);
        }
      }
    }
  }

  Future<SingleNovel> getNovel() async {
    if (widget.source == 'home') {
      //if  url comes from home check is it not volume one its its not generate urls for other volumes
      bool isNoteVolumeOne =
          widget.name.toLowerCase().contains(RegExp('volume [2-9]'));

      if (isNoteVolumeOne) {
        //  getOtherVolumes();
      }
    }
    Parser? parser = await Chaleno().load(widget.url);

    Result ol = parser!.querySelector("ol");

    List<Result>? a = ol.querySelectorAll("a");
    List<Map<int, String>> otherVol = [];

    for (int index in List.generate(a!.length, (index) => index)) {
      String href = a[index].href as String;
      otherVol.add({index: href});
    }
    return extractNovelData(parser, widget.url);
  }

  Widget featureImage() {
    return Image.network(widget.image as String,
        width: 300,
        height: 400,
        fit: BoxFit.scaleDown,
        loadingBuilder: (context, child, loadingProgress) => child,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          // If the image was loaded synchronously, display it and the novel title.
          return child;
        });
  }

  Widget novelTitle() {
    return SelectableText(
      widget.name
          .toLowerCase()
          .replaceAll(RegExp('\.pdf|\.epub'), '')
          .toUpperCase()
          .trim(),
      style: const TextStyle(
        color: Color.fromARGB(213, 255, 255, 255),
        fontWeight: FontWeight.w800,
        fontSize: 17,
      ),
    );
  }

  Widget description(SingleNovel snapshot) {
    String synopsis = '${snapshot.synopsis}'.trim().length > 2
        ? snapshot.synopsis!.trim()
        : 'unable to fetch description from jnovel  click download to go to jnovel'
            .toUpperCase();

    return Text(
      synopsis,
      style: const TextStyle(
          color: Color.fromARGB(224, 255, 254, 254), height: 1.8),
    );
  }

  int jump = 30;

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
    return LayoutBuilder(
        builder: (context, constraint) => FutureBuilder(
              future: getNovel(),
              builder:
                  (BuildContext context, AsyncSnapshot<SingleNovel> snapshot) {
                if (snapshot.hasData) {
                  return Scaffold(
                      appBar: AppBar(
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
                              for (var action in actions)
                                PopupMenuItem(child: action)
                            ],
                          )
                        ],
                      ),
                      body: Stack(
                        children: [
                          SizedBox.expand(
                            child: ImageFiltered(
                              imageFilter:
                                  ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Image.network(widget.image,
                                  fit: BoxFit.cover,
                                  loadingBuilder:
                                      (context, child, loadingProgress) =>
                                          child,
                                  frameBuilder: (context, child, frame,
                                      wasSynchronouslyLoaded) {
                                    // If the image was loaded synchronously, display it and the novel title.
                                    return child;
                                  }),
                            ),
                          ),
                          SizedBox.expand(
                            child: Container(
                              color: const Color.fromARGB(146, 0, 0, 0),
                            ),
                          ),
                          SingleChildScrollView(
                            padding: const EdgeInsets.only(
                                top: 20, left: 8, right: 8),
                            child: Center(
                              child: Container(
                                  constraints:
                                      const BoxConstraints(maxWidth: 900),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      constraint.maxWidth > 900
                                          ? Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                featureImage(),
                                                Container(
                                                  constraints:
                                                      const BoxConstraints(
                                                          maxWidth: 400),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      novelTitle(),
                                                      description(
                                                          snapshot.data!),
                                                      actionBtn(snapshot.data!
                                                              .downloadLink
                                                          as String)
                                                    ],
                                                  ),
                                                )
                                              ],
                                            )
                                          : Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                featureImage(),
                                                SizedBox(
                                                  height: 10,
                                                ),
                                                novelTitle(),
                                                SizedBox(
                                                  height: 10,
                                                ),
                                                description(snapshot.data!),
                                                SizedBox(
                                                  height: 10,
                                                ),
                                                const SizedBox(
                                                  height: 10,
                                                ),
                                                actionBtn(snapshot.data!
                                                    .downloadLink as String)
                                              ],
                                            ),
                                      Padding(
                                          padding: const EdgeInsets.only(
                                              top: 30, bottom: 20),
                                          child: Text(
                                            "Download Other Volumes ",
                                            style: TextStyle(
                                                color: Colors.grey.shade300,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600),
                                          )),
                                      Flexible(
                                        child: FutureBuilder(
                                          future: getOtherVolumes(),
                                          builder: (BuildContext context,
                                              AsyncSnapshot snapshot) {
                                            if (snapshot.hasError) {
                                              return Text("l${snapshot.error}");
                                            } else if (snapshot
                                                    .connectionState ==
                                                ConnectionState.waiting) {
                                              return const CircularProgressIndicator();
                                            } else {
                                              return Wrap(
                                                children: [
                                                  for (SingleNovel novel
                                                      in otherVolumes)
                                                    Card(
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .start,
                                                        children: [
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(8.0),
                                                            child:
                                                                Image.network(
                                                              novel.image!,
                                                              width: constraint
                                                                          .maxWidth >
                                                                      800
                                                                  ? 200
                                                                  : 100,
                                                            ),
                                                          )
                                                        ],
                                                      ),
                                                    ),
                                                ],
                                              );
                                            }
                                          },
                                        ),
                                      )
                                    ],
                                  )),
                            ),
                          ),
                        ],
                      ));
                } else if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return Scaffold(
                      body: Container(
                    child: const CircularProgressIndicator(),
                  ));
                } else {
                  return Scaffold(
                    appBar: AppBar(),
                    body: const Center(
                      child: Text(
                          'Opps something went wrong am are working  on it'),
                    ),
                  );
                }
              },
            ));
  }
}
