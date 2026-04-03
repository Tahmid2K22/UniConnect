import 'package:universal_io/io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/resource_item.dart';
import '../services/resource_service.dart';

class ImageUtils {
  static const Uuid _uuid = Uuid();

  static Future<void> pickAndSaveImages(String parentId) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final appDir = await getApplicationDocumentsDirectory();
      final resourcesDir = Directory('${appDir.path}/uniconnect_resources');
      if (!await resourcesDir.exists()) {
        await resourcesDir.create(recursive: true);
      }

      for (var pickedFile in result.files) {
        if (pickedFile.path != null) {
          final file = File(pickedFile.path!);
          final targetPath = '${resourcesDir.path}/${_uuid.v4()}.jpg';

          final compressedFile = await FlutterImageCompress.compressAndGetFile(
            file.absolute.path,
            targetPath,
            quality: 70,
            format: CompressFormat.jpeg,
          );

          if (compressedFile != null) {
            final item = ResourceItem(
              id: _uuid.v4(),
              parentId: parentId,
              type: ResourceType.image,
              name: pickedFile.name,
              createdAt: DateTime.now(),
              localPath: compressedFile.path,
            );
            await ResourceService.listenable.value.put(item.id, item);
          }
        }
      }
    }
  }
}
