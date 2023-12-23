import 'dart:io';
import 'dart:typed_data';

import 'package:chaleno/chaleno.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:jnovel_unofficial/db/novels_db.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher_string.dart';

class DownloadedFile {
  String name;
  String path;
  String url;
  DownloadedFile(this.name, this.path, this.url);
}

class FetchedNovel {
  String? title;

  String? url;

  FetchedNovel(this.title, this.url);

  // Factory constructor to create a FetchedNovel object from a JSON map
  factory FetchedNovel.fromJson(Map<String, String?> json) {
    return FetchedNovel(json['title'], json['url']);
  }

  // Method to convert the FetchedNovel object to a JSON map
  Map<String, dynamic> toJson() {
    final Map<String, String?> data = <String, String?>{};
    data['title'] = title;
    data['url'] = url;
    return data;
  }
}

class BookShelfUtilities {
  //urls where the novel list will be fetched

  final Map<String, String> _urls = {
    'ReadLater': 'none',
    'manga': 'https://jnovels.com/manga-cbz-cbr-pdf-download-jnovels/',
    'lightNovels': 'https://jnovels.com/light-novel-pdf-jnovels/',
    'webNovels': 'https://jnovels.com/webnovel-list-jnovels/'
  };

//get context and utilities
  Isar? _isar;

  ///check internet connection
  Future<ConnectivityResult> getConnectionStatus() async {
    ConnectivityResult connectivityResult =
        await (Connectivity().checkConnectivity());
    return connectivityResult;
  }

// Function to get the list of books and update the local database
  /// A Future function to retrieve a list of downloaded files from the device's storage.
  /// [isManga] parameter specifies whether to search for manga files (CBZ/CBR) or novel files (PDF/EPUB).
  /// Returns a List of file paths as strings.
  Future<Set<String>> getDownloadedFilePath(bool isManga) async {
    // Get the downloads directory
    final Directory? downloadsDir = await getDownloadsDirectory();

    // Check if downloads directory is not null
    if (downloadsDir != null) {
      // Get a stream of files in the downloads directory
      Stream<FileSystemEntity> files = downloadsDir.list();

      // Filter and map the files based on the specified type (manga or novel)
      if (isManga) {
        // Retrieve manga files (CBZ/CBR)
        List<String> mangasFound = await files
            .where((element) {
              String file = element.uri.toString();
              return file.toLowerCase().endsWith('cbz') ||
                  file.toString().endsWith('cbr');
            })
            .map((event) => event.uri.toString())
            .toList();

        // Return the list of manga files
        return mangasFound.toSet();
      } else {
        // Retrieve novel files (PDF/EPUB)
        List<String> novelsFound = await files
            .where((element) {
              String file = element.uri.toString();
              return file.toLowerCase().endsWith('pdf') ||
                  file.toString().endsWith('epub');
            })
            .map((event) => event.uri.toString())
            .toList();

        // Return the list of novel files
        return novelsFound.toSet();
      }
    }

    // Return an empty list if downloads directory is null
    return {};
  }

  Future<String?> getImageLink(String link) async {
    try {
      var parser = await Chaleno().load(link);
      Result? imageTag = parser?.querySelector(".featured-media img");
      String? src = imageTag?.src;
      return src;
    } catch (e) {
      rethrow;
    }
  }

// Asynchronous function to fetch novels from a specified URL and return a List of Map<String, String>
  Future<List<Novelist>> fetchBookListOnline(content) async {
    try {
      // Retrieve the URL corresponding to the specified content type from _urls map
      String url = _urls[content]!;

      // Load data from the specified URL using Chaleno parser
      var parser = await Chaleno().load(url);

      // Extract ordered list (ol) element from the parsed data
      Result? ol = parser?.querySelector("ol");

      // Extract all anchor (a) elements from the ordered list
      List<Result>? allA = ol?.querySelectorAll("a");

      // Map anchor elements to a List of Map<String, String> containing 'url' and 'title'
      List<Novelist> allBookTitles = allA!
          .map((e) => Novelist(
              e.text!.toLowerCase().replaceAll(RegExp(r'_|-'), ' '),
              content,
              e.href))
          .toList();

      // Return the list of all book titles and their URLs
      return allBookTitles;
// ignore: empty_catches
    } catch (e) {
      return [];
    }
  }

  Future<bool> updateDataBaseBookList(String content) async {
    try {
      var connection = await getConnectionStatus();
      if (connection != ConnectivityResult.none) {
        // Open the local Isar database

        // Get the collection of novelists from the database
        if (_isar != null) {
          IsarCollection<Novelist> novelist = _isar!.collection<Novelist>();
          List<Novelist>? books =
              await novelist.filter().categoryEqualTo(content).findAll();

          List<Novelist> allBookTitles = await fetchBookListOnline(content);
          // Update the novelists data based on content type

          if (books.isNotEmpty || allBookTitles.length > books.length) {
            await _isar?.writeTxn(() async {
              await novelist.putAll(allBookTitles);
            });

            // Close the Isar database connection
          }
          return true;
        } else {
          return false;
        }
      } else {
        return false;
      }
    } catch (e) {
      rethrow;
    }
  }

// Function to open the local Isar database

// Function to close the Isar database connection
  void closeIsarDatabase() {
    if (_isar != null) {
      _isar!.close();
    }
  }

  String cleanName(String fileName) {
    List splitName = fileName.split(' ');
    int max = splitName.length >= 3
        ? 3
        : splitName.length == 2
            ? 2
            : 1;
    String firstThree = splitName
        .sublist(0, max)
        .join('')
        .split(RegExp(r'volume[1-9]|book[1-9]|vol'))[0];
    return firstThree;
  }

  // Asynchronous function to filter downloaded books based on content type
  Future<List<DownloadedFile>> filterDownloadedBooks(content) async {
    try {
      // Call updateDataBaseBookList to ensure the database is up-to-date
      await updateDataBaseBookList(content);

      // Open the Isar database
      Isar? db = _isar;

      // Initialize an empty list to store filtered book paths
      List<DownloadedFile> bookList = [];
      Set<String> downloadedFileList =
          await getDownloadedFilePath(content == 'manga');

      var booksRecords = await db!.collection<Novelist>();
      var contents =
          await booksRecords.filter().categoryEqualTo(content).findAll();
      if (contents.isNotEmpty) {
        for (var element in downloadedFileList) {
          var uri = Uri.parse(element);
          var fileName = uri.pathSegments.last
              .toLowerCase()
              .replaceAll(RegExp(r'[_|,]'), ' ');
          var firstThree = cleanName(fileName);
          var results = contents.toList().where((item) {
            String concatenatedString = item.name.split(" ").join('');
            return concatenatedString.startsWith(firstThree);
          }).toList();

          if (results.isNotEmpty) {
            var item = results[0];

            bookList
                .add(DownloadedFile(item.name, element, item.url as String));
          }
        }
      }

      // Return the list of filtered book paths
      return bookList;
    } catch (e) {
      rethrow;
    }
  }

// Asynchronous function to insert downloaded books into the local database
  Stream<List<DownloadedBooks>> insertBooks(String content) async* {
    late Isar isar;
    if (_isar == null) {
      await openIsarDatabase();
      isar = _isar!;
    }

    try {
      // Open the Isar database

      // Get the collection of DownloadedBooks from the database
      IsarCollection<DownloadedBooks> downloadedBooks =
          isar.collection<DownloadedBooks>();

      // Filter downloaded books based on content type
      List<DownloadedFile> downloadedLocalBooks =
          await filterDownloadedBooks(content);
      int count = await downloadedBooks.count();

      var booklist = isar.novelists;
      List<DownloadedBooks> yieldBooks = [];

      // Check if there are new downloaded books to insert
      if (downloadedLocalBooks.length > count) {
        for (var bookName in downloadedLocalBooks) {
          var checkBook =
              await booklist.filter().urlEqualTo(bookName.url).count();
          if (checkBook == 0) {
            // Fetch online books list

            // Extract file name without extension

            // Get the image link for the book
            String? imageLink = await getImageLink(bookName.url);

            // Fetch the book cover image from the URL
            Uri uriComponents = Uri.parse(imageLink!);
            var uri = Uri.https(uriComponents.host, uriComponents.path);
            var res = await http.get(uri);

            // Check if the image was fetched successfully
            if (res.statusCode == 200) {
              // Convert image bytes to a list
              List<int> image =
                  GZipCodec(gzip: true, level: 9).encode(res.bodyBytes);

              // Insert the downloaded book details into the database
              var d = DownloadedBooks()
                ..cover = image
                ..category = content
                ..filePath = bookName.path
                ..url = bookName.url;

              isar.writeTxn(() async {
                downloadedBooks.put(d);
              });
              yieldBooks.add(d);
              yield yieldBooks;
            }
          }
        }
      } else {
        var savedBooks =
            await downloadedBooks.filter().categoryEqualTo(content).findAll();
        yield savedBooks;
      } // Close the Isar database connection

      // Indicate successful insertion

      // Catch any exceptions and return false indicating failure
    } catch (e) {
      rethrow;
    }
  }

  Future<void> openIsarDatabase() async {
    await novelListDb().openDb();
    _isar ??= isardb;
  }
}

class BookShelf extends StatefulWidget {
  const BookShelf({super.key});

  @override
  State<BookShelf> createState() => _BookShelfState();
}

class _BookShelfState extends State<BookShelf> {
  late String _content;
  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    BookShelfUtilities().closeIsarDatabase();
  }

  @override
  Widget build(BuildContext context) {
    // Get the arguments passed to the current route
    final Object? args = ModalRoute.of(context)!.settings.arguments;

    // Extract 'content' key from the arguments
    Map<String, String> contents = args as Map<String, String>;
    String? content = contents['content'];
    _content = content as String;
    final BookShelfUtilities utils = BookShelfUtilities();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'downloaded $content',
        ),
        actions: [],
      ),
      body: StreamBuilder(
        stream: utils.insertBooks(content),
        builder: (BuildContext context,
            AsyncSnapshot<List<DownloadedBooks>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return const Center(child: Text("opps error"));
            } else {
              var data = snapshot.data;

              if (snapshot.data == null) {
                return Container(
                  child: const Text('null'),
                );
              } else {
                if (data!.isEmpty) {
                  return Center(
                      child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Text(
                        '$_content downloaded from jnovels  could`nt be found in the downloads folder',
                        textAlign: TextAlign.center),
                  ));
                } else {
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return GridView.builder(
                        padding: const EdgeInsets.all(15),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: constraints.maxWidth > 900
                                ? 5
                                : constraints.maxWidth > 600
                                    ? 4
                                    : 3,
                            mainAxisSpacing: 20,
                            crossAxisSpacing: 5),
                        itemCount: data!.length,
                        itemBuilder: (BuildContext context, int index) {
                          DownloadedBooks book = data[index];
                          Uri uri = Uri.file(book.filePath as String);
                          String name =
                              Uri.decodeComponent(uri.pathSegments.last);
                          Uint8List bytes = Uint8List.fromList(
                              GZipCodec().decode(book.cover!));

                          return MouseRegion(
                              cursor: MaterialStateMouseCursor.clickable,
                              child: GestureDetector(
                                  onTap: () async {
                                    print(uri.toFilePath());

                                    await launchUrlString(uri.toFilePath());
                                  },
                                  child: Card(
                                      child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      children: [
                                        Expanded(
                                            child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(5.0),
                                                child: Image.memory(bytes))),
                                        const SizedBox(height: 20),
                                        Center(
                                            child: SelectableText(
                                          "${name}",
                                          maxLines: 2,
                                          style: const TextStyle(
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        )),
                                      ],
                                    ),
                                  ))));
                        },
                      );
                    },
                  );
                }
              }
            }
          } else {
            return const Center(child: Text('error'));
          }
        },
      ),
    );
  }
}
