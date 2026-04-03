import 'package:hive/hive.dart';

part 'resource_item.g.dart';

@HiveType(typeId: 10)
enum ResourceType {
  @HiveField(0)
  folder,
  @HiveField(1)
  image,
  @HiveField(2)
  file,
  @HiveField(3)
  link,
}

@HiveType(typeId: 11)
class ResourceItem extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String parentId; // 'root' for top-level

  @HiveField(2)
  ResourceType type;

  @HiveField(3)
  String name;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  String? localPath; // For images and files

  @HiveField(6)
  String? url; // For links

  @HiveField(7)
  int? colorValue; // For folders, ARGB value

  @HiveField(8)
  List<String>? groupIds; // For grouped images ("Sheet")

  @HiveField(9)
  String? thumbnailUrl; // For link previews or quick image thumbs

  ResourceItem({
    required this.id,
    required this.parentId,
    required this.type,
    required this.name,
    required this.createdAt,
    this.localPath,
    this.url,
    this.colorValue,
    this.groupIds,
    this.thumbnailUrl,
  });
}
