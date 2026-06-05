import 'package:hive/hive.dart';

part 'folder_model.g.dart';

@HiveType(typeId: 0)
class FolderModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  DateTime createdAt;

  @HiveField(3)
  int? colorValue;

  FolderModel({
    required this.id,
    required this.name,
    required this.createdAt,
    this.colorValue,
  });
}
