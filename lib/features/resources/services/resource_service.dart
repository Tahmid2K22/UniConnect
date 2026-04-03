import 'package:universal_io/io.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/resource_item.dart';

class ResourceService {
  static final Box<ResourceItem> _box = Hive.box<ResourceItem>('resourcesBox');
  static const Uuid _uuid = Uuid();

  static ValueListenable<Box<ResourceItem>> get listenable => _box.listenable();

  static List<ResourceItem> getItems(String parentId) {
    var items = _box.values.where((item) => item.parentId == parentId).toList();
    // Sort: Folders first, then by date descending
    items.sort((a, b) {
      if (a.type == ResourceType.folder && b.type != ResourceType.folder) {
        return -1;
      }
      if (a.type != ResourceType.folder && b.type == ResourceType.folder) {
        return 1;
      }
      return b.createdAt.compareTo(a.createdAt);
    });
    return items;
  }

  static Future<String> addFolder(
    String name,
    String parentId,
    int colorValue, {
    List<String>? groupIds,
  }) async {
    final id = _uuid.v4();
    final item = ResourceItem(
      id: id,
      parentId: parentId,
      type: ResourceType.folder,
      name: name,
      createdAt: DateTime.now(),
      colorValue: colorValue,
      groupIds: groupIds,
    );
    await _box.put(item.id, item);
    return id;
  }

  static Future<void> deleteItem(ResourceItem item) async {
    if (item.type == ResourceType.folder) {
      // Recursively delete children
      final children = getItems(item.id);
      for (var child in children) {
        await deleteItem(child);
      }
    } else if (item.localPath != null) {
      // Delete local file
      final file = File(item.localPath!);
      if (await file.exists()) {
        await file.delete();
      }
    }
    await _box.delete(item.id);
  }

  static Future<void> renameItem(ResourceItem item, String newName) async {
    item.name = newName;
    item.save();
  }
}
