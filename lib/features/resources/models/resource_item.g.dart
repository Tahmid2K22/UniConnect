// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resource_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ResourceItemAdapter extends TypeAdapter<ResourceItem> {
  @override
  final int typeId = 11;

  @override
  ResourceItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ResourceItem(
      id: fields[0] as String,
      parentId: fields[1] as String,
      type: fields[2] as ResourceType,
      name: fields[3] as String,
      createdAt: fields[4] as DateTime,
      localPath: fields[5] as String?,
      url: fields[6] as String?,
      colorValue: fields[7] as int?,
      groupIds: (fields[8] as List?)?.cast<String>(),
      thumbnailUrl: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ResourceItem obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.parentId)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.name)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.localPath)
      ..writeByte(6)
      ..write(obj.url)
      ..writeByte(7)
      ..write(obj.colorValue)
      ..writeByte(8)
      ..write(obj.groupIds)
      ..writeByte(9)
      ..write(obj.thumbnailUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResourceItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ResourceTypeAdapter extends TypeAdapter<ResourceType> {
  @override
  final int typeId = 10;

  @override
  ResourceType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ResourceType.folder;
      case 1:
        return ResourceType.image;
      case 2:
        return ResourceType.file;
      case 3:
        return ResourceType.link;
      default:
        return ResourceType.folder;
    }
  }

  @override
  void write(BinaryWriter writer, ResourceType obj) {
    switch (obj) {
      case ResourceType.folder:
        writer.writeByte(0);
        break;
      case ResourceType.image:
        writer.writeByte(1);
        break;
      case ResourceType.file:
        writer.writeByte(2);
        break;
      case ResourceType.link:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResourceTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
