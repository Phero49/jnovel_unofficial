import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:jnovel_unofficial/db/novels_db.dart';
import 'package:url_launcher/url_launcher_string.dart';

class ReadLaterScreen extends StatefulWidget {
  ReadLaterScreen({super.key});

  @override
  State<ReadLaterScreen> createState() => _ReadLaterState();
}

class _ReadLaterState extends State<ReadLaterScreen> {
  @override
  Future<List<ReadLater>> getContent() async {
    await novelListDb().openDb();
    IsarCollection<ReadLater> col = isardb!.collection<ReadLater>();
    List<ReadLater> mylist = await col.filter().titleIsNotEmpty().findAll();

    mylist.sort((a, b) => b.id.compareTo(a.id));
    return mylist;
  }

  Future<bool> removed(String title) async {
    IsarCollection<ReadLater> col = isardb!.collection<ReadLater>();
    bool done = false;
    isardb!.writeTxn(() async {
      await col.deleteByTitle(title);
      done = true;
    });
    return done;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: FutureBuilder(
        future: getContent(),
        builder:
            (BuildContext context, AsyncSnapshot<List<ReadLater>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Text("${snapshot.error}");
          }

          if (snapshot.data!.isEmpty) {
            return const Center(
              child: Text('You dont have anything saved '),
            );
          } else {
            List<ReadLater> data = snapshot.data!;
            return LayoutBuilder(
              builder: (context, constraints) {
                return GridView.builder(
                    padding: const EdgeInsets.all(15),
                    shrinkWrap: true,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: constraints.maxWidth > 900
                            ? 4
                            : constraints.maxWidth > 600
                                ? 4
                                : 3,
                        mainAxisSpacing: 20,
                        mainAxisExtent: 400,
                        crossAxisSpacing: 15),
                    itemCount: data.length,
                    itemBuilder: (BuildContext context, int index) {
                      ReadLater book = data[index];

                      Uint8List bytes =
                          Uint8List.fromList(GZipCodec().decode(book.cover!));
                      return MouseRegion(
                          cursor: MaterialStateMouseCursor.clickable,
                          child: GestureDetector(
                              onTap: () async {
                                await launchUrlString(book.url!);
                              },
                              child: Column(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(5.0),
                                    child: Image.memory(
                                      bytes,
                                      fit: BoxFit.fill,
                                      height: 200,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Center(
                                    child: SelectableText(
                                      "${book.title}",
                                      maxLines: 2,
                                      style: const TextStyle(
                                        overflow: TextOverflow.ellipsis,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 15,
                                  ),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      "Added on: ${DateTime.parse(book.addedOn!).toLocal()}",
                                      maxLines: 1,
                                      style: TextStyle(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 8,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Color.fromARGB(255, 223, 115, 66),
                                      ),
                                      onPressed: () async {
                                        bool done = await removed(book.title!);
                                        if (true) {
                                          setState(() {});
                                        }
                                      },
                                      icon: Icon(Icons.delete),
                                      label:
                                          const Text("Remove from read later"),
                                    ),
                                  ),
                                ],
                              )));
                    });
              },
            );
          }
        },
      ),
    );
  }
}
