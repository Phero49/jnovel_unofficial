import 'package:chaleno/chaleno.dart';
import 'package:flutter/material.dart';
import 'package:jnovel_unofficial/components/novel_card.dart';

class HomeTabWidget extends StatefulWidget {
  const HomeTabWidget(this.url, {super.key});
  final String url;
  @override
  State<HomeTabWidget> createState() => _HomeTabWidgetState();
}

class _HomeTabWidgetState extends State<HomeTabWidget> {
  int articleNumber = 0;
  int outOf = 1000;
  int currentPage = 1;
  Future<List<Result>> getArticles(String url, int page) async {
    Parser? parser = await Chaleno().load(url);
    List<Result>? articles = parser!.querySelectorAll("article");

    articleNumber = articles.length;
    if (page == 2) {
      String? title = parser.title();
      String totalPages = title!.split('of')[1].split('-')[0];
      outOf = int.parse(totalPages);
    }
    if (page == 1) {
      articles.removeRange(0, 3);
    }
    return articles;
  }

  Future<List<Novel>> getHomePage(String url, int page) async {
    List<Result> articles = await getArticles(url, page);
    List<Novel> novelist = [];

    for (var article in articles) {
      Result? h1 = article.querySelector("h1 a");
      String? title = h1!.text!.replaceFirst(RegExp(r"^DOWNLOAD"), '');
      String? href = h1.href;
      String? cover = article.querySelector("img")!.src;
      Novel novel = Novel(
        cover: cover,
        href: href,
        title: title,
        source: 'home',
      );
      novelist.add(novel);
    }

    return novelist;
  }

  int start = 1;
  int end = 6;
  bool loaded = false;

  Future<List<Novel>> firstSix() async {
    List<Novel> novelist = [];

    for (var i = start; i <= end; i++) {
      String url = "https://jnovels.com/page/$i/";

      List<Novel> novels = await getHomePage(url, i);
      novelist.addAll(novels);
    }
    loaded = true;
    return novelist;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: firstSix(),
      builder: (BuildContext context, AsyncSnapshot<List<Novel>> snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text("error"),
          );
        } else if (snapshot.hasData && loaded == true) {
          List<Novel> novels = snapshot.data as List<Novel>;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: EdgeInsets.only(bottom: 20),
                child: ElevatedButton.icon(
                  label: Text(
                    'Pages',
                    style: TextStyle(color: Colors.white),
                  ),
                  icon: Icon(Icons.pages),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => SingleChildScrollView(
                          child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text("Pages : "),
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          for (int page in List<int>.generate(
                              outOf ~/ 6, (index) => index + 1))
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: MouseRegion(
                                cursor: MaterialStateMouseCursor.clickable,
                                child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        Navigator.pop(context);
                                        currentPage = page;
                                        start = page;
                                        end = page + 6;
                                        loaded = false;
                                      });
                                    },
                                    child: currentPage == page
                                        ? CircleAvatar(
                                            radius: 15,
                                            backgroundColor: Color.fromARGB(
                                                255, 248, 244, 4),
                                            child: Text(
                                              "$page",
                                              style: currentPage == page
                                                  ? const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold)
                                                  : const TextStyle(),
                                            ))
                                        : Text("$page")),
                              ),
                            )
                        ],
                      )),
                    );
                  },
                ),
              ),
              Flexible(
                child: LayoutBuilder(
                    builder: (context, constraints) => GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: constraints.maxWidth > 900
                                      ? 4
                                      : constraints.maxWidth > 600
                                          ? 4
                                          : 3,
                                  mainAxisSpacing: 5,
                                  crossAxisSpacing: 5),
                          itemCount: novels.length,
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
                        )),
              ),
            ],
          );
        } else if (snapshot.connectionState == ConnectionState.waiting ||
            loaded == false) {
          return Center(
            child: CircularProgressIndicator(),
          );
        } else {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }
}
