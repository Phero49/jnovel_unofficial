import 'package:jnovel_unofficial/screens/view_single_novel.dart';
import 'package:flutter/material.dart';

//novel class
class Novel {
  String? title;
  String? href;
  String? cover = "";
  String? description;
  final String source;
  Novel(
      {required this.cover,
      required this.href,
      required this.source,
      required this.title,
      this.description});
}

class NovelCardWidget extends StatelessWidget {
  const NovelCardWidget(this.novel, {Key? key}) : super(key: key);

  final Novel novel;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ViewSingleNovel(
                novel.href as String,
                "${novel.cover}",
                novel.title as String,
                source: novel.source,
              ),
            ),
          );
        },
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 100,
          ),
          child: Image.network(
            "${novel.cover}",
            fit: BoxFit.scaleDown,
            errorBuilder:
                (BuildContext context, Object error, StackTrace? stackTrace) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset('assets/images/6325254.jpg'),
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      novel.title as String,
                      maxLines: 1,
                      style: const TextStyle(
                          color: Colors.white,
                          overflow: TextOverflow.ellipsis,
                          fontWeight: FontWeight.w400,
                          fontSize: 13,
                          letterSpacing: 1.1),
                    ),
                  ),
                ],
              ); // Widget displayed when the image fails to load
            },
            loadingBuilder: (context, child, loadingProgress) => child,
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              // If the image was loaded synchronously, display it and the novel title.
              return Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: child), // Display the image
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      novel.title as String,
                      maxLines: 1,
                      style: const TextStyle(
                          color: Colors.white,
                          overflow: TextOverflow.ellipsis,
                          fontWeight: FontWeight.w400,
                          fontSize: 13,
                          letterSpacing: 1.1),
                    ),
                  ),
                ],
              );

              // If the image is loading asynchronously, show a loading indicator and the novel title.
            },
          ),
        ));
  }
}
