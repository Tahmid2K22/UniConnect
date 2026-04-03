import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_io/io.dart';
import 'package:uuid/uuid.dart';
import 'package:any_link_preview/any_link_preview.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/resource_item.dart';
import '../services/resource_service.dart';

class FileHandlers {
  static const Uuid _uuid = Uuid();

  static Future<void> pickAndSaveFiles(String parentId) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );

    if (result != null && result.files.isNotEmpty) {
      final appDir = await getApplicationDocumentsDirectory();
      final resourcesDir = Directory('${appDir.path}/uniconnect_resources');
      if (!await resourcesDir.exists()) {
        await resourcesDir.create(recursive: true);
      }

      for (var pickedFile in result.files) {
        if (pickedFile.path != null) {
          final originalFile = File(pickedFile.path!);
          final extension = pickedFile.extension ?? 'file';
          final targetPath = '${resourcesDir.path}/${_uuid.v4()}.$extension';

          final savedFile = await originalFile.copy(targetPath);

          final item = ResourceItem(
            id: _uuid.v4(),
            parentId: parentId,
            type: ResourceType.file,
            name: pickedFile.name,
            createdAt: DateTime.now(),
            localPath: savedFile.path,
          );
          await ResourceService.listenable.value.put(item.id, item);
        }
      }
    }
  }

  static Future<void> openLocalFile(String localPath) async {
    if (await File(localPath).exists()) {
      await OpenFilex.open(localPath);
    }
  }

  static Future<void> addLink(String parentId, String name, String url) async {
    String? thumbUrl;
    try {
      final metadata = await AnyLinkPreview.getMetadata(link: url);
      thumbUrl = metadata?.image;
    } catch (_) {}

    final item = ResourceItem(
      id: _uuid.v4(),
      parentId: parentId,
      type: ResourceType.link,
      name: name,
      createdAt: DateTime.now(),
      url: url,
      thumbnailUrl: thumbUrl,
    );
    await ResourceService.listenable.value.put(item.id, item);
  }

  static Future<void> openLink(String urlString) async {
    final uri = Uri.parse(urlString);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }
}
