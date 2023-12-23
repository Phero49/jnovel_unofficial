import 'package:flutter/material.dart';

class LibraryPage extends StatelessWidget {
  LibraryPage({super.key});
  final List<Map<String, String>> cardData = [
    {
      'imagePath': 'assets/images/IN-ANOTHER-WORLD-WITH-MY-SMARTPHONE.webp',
      'label': 'Light novels',
      'content': 'lightNovels',
    },
    {
      'imagePath': 'assets/images/01526-i-will-kill-the-author.jpg',
      'label': 'Web Novels',
      'content': 'webNovels',
    },
    {
      'imagePath': 'assets/images/Naruto-v72-000.webp',
      'label': 'Manga',
      'content': 'manga',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My library'),
      ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return GridView.count(
            padding: const EdgeInsets.only(top: 100, left: 10, right: 10),
            crossAxisCount: constraints.maxWidth < 800 ? 2 : 3,
            crossAxisSpacing: 20,
            children: [
              for (var d in cardData)
                MouseRegion(
                  cursor: MaterialStateMouseCursor.clickable,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/books',
                          arguments: {'content': "${d['content']}"});
                    },
                    child: Card(
                      color: const Color.fromARGB(221, 153, 153, 153),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(fit: BoxFit.cover, "${d['imagePath']}"),
                          SizedBox.expand(
                            child: Container(
                              color: const Color.fromARGB(132, 0, 0, 0),
                            ),
                          ),
                          Center(
                            child: Text(d['label']!),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
