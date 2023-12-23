import 'package:flutter/material.dart';
import 'package:chaleno/chaleno.dart';
import 'package:jnovel_unofficial/components/novel_card.dart';

class NovelListWidget extends StatefulWidget {
  const NovelListWidget(this.url, {required this.type, super.key});
  final String url;
  final String type;
  // final String title;
  @override
  State<NovelListWidget> createState() => _NovelListWidgetState();
}

class _NovelListWidgetState extends State<NovelListWidget> {
  Future<String?> getImage(String link) async {
    var parser = await Chaleno().load(link);
    Result? imageTag = parser?.querySelector(".featured-media img");
    String? src = imageTag?.src;
    return src;
  }

  List<String> Alpha =
      List.generate(26, (index) => String.fromCharCode(index + 65));
  String currentLatter = '';
  @override
  void initState() {
    super.initState();
    currentLatter = Alpha[0];
  }

  bool loaded = false;

  Stream<List<Novel>> getNovels(String url) async* {
    var parser = await Chaleno().load("$url");
    Result? ol = parser?.querySelector("ol");
    List<Result>? allA = ol?.querySelectorAll("a");

    List<Result>? a = allA!
        .where((element) => element.text!.startsWith(currentLatter))
        .toList();
    List<Novel> novelList = [];

    for (Result link in a) {
      String? title = link.text;
      String? href = link.href;
      String? cover = await getImage(href!);
      Novel novel =
          Novel(cover: cover, title: title, href: href, source: 'list');
      novelList.add(novel);
      yield novelList;
      if (loaded == false) {
        loaded = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: getNovels(widget.url),
      builder: (BuildContext context, AsyncSnapshot<List<Novel>> snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text("error"),
          );
        } else if (snapshot.hasData && loaded == true) {
          List<Novel> novels = snapshot.data!;
          int length = novels.length;

          return Column(
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 7,
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    color: const Color.fromARGB(255, 2, 88, 131),
                    child: Text(
                      "a-z".toUpperCase(),
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                  ),
                  for (String latter in Alpha)
                    MouseRegion(
                      cursor: MaterialStateMouseCursor.clickable,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            currentLatter = latter;
                            loaded = false;
                          });
                        },
                        child: Text(
                          latter,
                          style: latter == currentLatter
                              ? const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                  color: Colors.blue)
                              : const TextStyle(),
                        ),
                      ),
                    )
                ],
              ),
              SizedBox(
                height: 20,
              ),
              Flexible(
                  child: LayoutBuilder(
                      builder: (context, constraints) => GridView.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: constraints.maxWidth > 900
                                        ? 6
                                        : constraints.maxWidth > 600
                                            ? 4
                                            : 2,
                                    mainAxisSpacing: 5,
                                    crossAxisSpacing: 5),
                            itemCount: length,
                            itemBuilder: (BuildContext context, int index) {
                              if (novels.isEmpty) {
                                return Container(
                                  decoration: const BoxDecoration(
                                    color: Color.fromARGB(255, 189, 22, 22),
                                  ),
                                  child: Text("${novels}"),
                                );
                              } else {
                                Novel novel = novels[index];
                                return NovelCardWidget(novel);
                              }
                            },
                          )))
            ],
          );
        } else {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }
}
