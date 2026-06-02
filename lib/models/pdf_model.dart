import 'package:hive/hive.dart';

part 'pdf_model.g.dart';

@HiveType(typeId: 1)
class PdfModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String path;

  @HiveField(3)
  String folderId; // Can be empty if not in a custom folder

  @HiveField(4)
  DateTime timeAdded;

  @HiveField(5)
  int lastReadPage;

  PdfModel({
    required this.id,
    required this.name,
    required this.path,
    required this.folderId,
    required this.timeAdded,
    this.lastReadPage = 1,
  });
}
