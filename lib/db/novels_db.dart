import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
part 'novels_db.g.dart';

Isar? isardb;

@collection
class ReadLater {
  Id id = Isar.autoIncrement;
  @Index(unique: true, replace: true)
  String? title;
  String? url;
  List<int>? cover;
  String? addedOn;
}

@collection
class Novelist {
  Id id = Isar.autoIncrement;
  String? category;
  @Index(composite: [CompositeIndex('category')], unique: true, replace: true)
  late String name;

  String? url;

  Novelist(this.name, this.category, this.url);
}

@collection
class DownloadedBooks {
  Id? id;
  @Index(unique: true, replace: true)
  String? filePath;

  List<int>? cover;
  String? url;
  String? category;
}

@collection
class Announcements {
  Id? id;
  bool? read;
}

class novelListDb {
  Future<void> openDb() async {
    if (isardb == null) {
      final dir = await getApplicationDocumentsDirectory();

      final isar = await Isar.open(
        [
          NovelistSchema,
          DownloadedBooksSchema,
          ReadLaterSchema,
          AnnouncementsSchema
        ],
        directory: dir.path,
      );

      isardb = isar;
    }
  }
}
