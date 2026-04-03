import 'package:universal_io/io.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import 'package:uni_connect/features/navigation/side_navigation.dart';
import 'package:uni_connect/features/web/web_layout.dart';
import 'models/resource_item.dart';
import 'services/resource_service.dart';
import 'widgets/resource_fab.dart';
import 'utils/image_utils.dart';
import 'utils/file_handlers.dart';
import 'screens/image_viewer_screen.dart';

class ResourcesPage extends StatefulWidget {
  const ResourcesPage({super.key});

  @override
  State<ResourcesPage> createState() => _ResourcesPageState();
}

class _ResourcesPageState extends State<ResourcesPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Breadcrumb navigation tracking: List of parent IDs and their names
  final List<Map<String, String>> _pathStack = [
    {'id': 'root', 'name': 'Resources'},
  ];

  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};
  bool _isGridView = true;
  bool _isRotating = false;

  String get currentParentId => _pathStack.last['id']!;

  void _navigateUp() {
    if (_pathStack.length > 1) {
      if (_isSelectionMode) {
        setState(() {
          _isSelectionMode = false;
          _selectedIds.clear();
        });
        return;
      }
      setState(() {
        _pathStack.removeLast();
      });
    }
  }

  void _navigateToFolder(String id, String name) {
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
      _pathStack.add({'id': id, 'name': name});
    });
  }

  void _showCreateFolderDialog() {
    String folderName = '';
    int selectedColor = Colors.blueAccent.value;

    final List<Color> colorOptions = [
      Colors.blueAccent,
      Colors.redAccent,
      Colors.greenAccent,
      Colors.orangeAccent,
      Colors.purpleAccent,
      Colors.cyanAccent,
      Colors.amberAccent,
      Colors.pinkAccent,
      Colors.tealAccent,
      Colors.indigoAccent,
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateBuilder) {
            return AlertDialog(
              backgroundColor: const Color(0xFF2B175C),
              title: Text(
                'Create Folder',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    autofocus: true,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Folder Name',
                      hintStyle: TextStyle(color: Colors.white54),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white54),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.cyanAccent),
                      ),
                    ),
                    onChanged: (val) => folderName = val,
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: colorOptions.map((c) {
                      final isSelected = c.value == selectedColor;
                      return GestureDetector(
                        onTap: () =>
                            setStateBuilder(() => selectedColor = c.value),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: c,
                            border: isSelected
                                ? Border.all(color: Colors.white, width: 3)
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(color: Colors.white54),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (folderName.trim().isNotEmpty) {
                      ResourceService.addFolder(
                        folderName.trim(),
                        currentParentId,
                        selectedColor,
                      );
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                  ),
                  child: Text(
                    'Create',
                    style: GoogleFonts.poppins(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showRenameDialog(ResourceItem item) {
    String newName = item.name;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2B175C),
          title: Text(
            'Rename',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          content: TextField(
            autofocus: true,
            style: TextStyle(color: Colors.white),
            controller: TextEditingController(text: item.name),
            decoration: InputDecoration(
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white54),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.cyanAccent),
              ),
            ),
            onChanged: (val) => newName = val,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (newName.trim().isNotEmpty && newName != item.name) {
                  ResourceService.renameItem(item, newName.trim());
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
              ),
              child: Text(
                'Rename',
                style: GoogleFonts.poppins(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showItemOptions(ResourceItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF181A2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.edit_rounded, color: Colors.white),
                title: Text(
                  'Rename',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showRenameDialog(item);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_rounded, color: Colors.redAccent),
                title: Text(
                  'Delete',
                  style: GoogleFonts.poppins(color: Colors.redAccent),
                ),
                onTap: () {
                  Navigator.pop(context);
                  ResourceService.deleteItem(item);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddImageDialog() async {
    await ImageUtils.pickAndSaveImages(currentParentId);
  }

  void _showAddFileDialog() async {
    await FileHandlers.pickAndSaveFiles(currentParentId);
  }

  void _showAddLinkDialog() {
    String name = '';
    String url = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2B175C),
          title: Text(
            'Add Link',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Link Name',
                  hintStyle: TextStyle(color: Colors.white54),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white54),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.cyanAccent),
                  ),
                ),
                onChanged: (val) => name = val,
              ),
              const SizedBox(height: 12),
              TextField(
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'https://...',
                  hintStyle: TextStyle(color: Colors.white54),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white54),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.cyanAccent),
                  ),
                ),
                onChanged: (val) => url = val,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (url.trim().isNotEmpty) {
                  final finalName = name.trim().isEmpty ? 'Link' : name.trim();
                  FileHandlers.addLink(currentParentId, finalName, url.trim());
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
              ),
              child: Text(
                'Add',
                style: GoogleFonts.poppins(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBreadcrumbs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: _pathStack.asMap().entries.map((entry) {
          int idx = entry.key;
          var path = entry.value;
          bool isLast = idx == _pathStack.length - 1;

          return Row(
            children: [
              GestureDetector(
                onTap: isLast
                    ? null
                    : () {
                        setState(() {
                          _pathStack.removeRange(idx + 1, _pathStack.length);
                        });
                      },
                child: Text(
                  path['name']!,
                  style: GoogleFonts.poppins(
                    color: isLast ? Colors.cyanAccent : Colors.white70,
                    fontWeight: isLast ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 16,
                  ),
                ),
              ),
              if (!isLast)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Icon(
                    Icons.chevron_right,
                    color: Colors.white54,
                    size: 20,
                  ),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_rounded, size: 80, color: Colors.white24),
          const SizedBox(height: 16),
          Text(
            'This folder is empty',
            style: GoogleFonts.poppins(color: Colors.white54, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Use the + button to add resources',
            style: GoogleFonts.poppins(color: Colors.white38, fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _deleteSelected(List<ResourceItem> items) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2B175C),
        title: Text(
          'Delete Selected?',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete ${_selectedIds.length} items?',
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              for (var id in _selectedIds) {
                final item = items.firstWhere((e) => e.id == id);
                ResourceService.deleteItem(item);
              }
              setState(() {
                _isSelectionMode = false;
                _selectedIds.clear();
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _moveSelected(List<ResourceItem> currentItems) {
    final rootItems = ResourceService.listenable.value.values.toList();
    final allFolders = rootItems
        .where((e) => e.type == ResourceType.folder && e.id != currentParentId)
        .toList();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2B175C),
          title: Text(
            'Move to Folder',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                // Option: Create new folder, then move
                ListTile(
                  leading: const Icon(
                    Icons.create_new_folder_rounded,
                    color: Colors.cyanAccent,
                  ),
                  title: Text(
                    'New Folder...',
                    style: GoogleFonts.poppins(
                      color: Colors.cyanAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showCreateFolderDialogThenMove(currentItems);
                  },
                ),
                const Divider(color: Colors.white24),
                ListTile(
                  leading: const Icon(Icons.home_rounded, color: Colors.white),
                  title: Text(
                    'Resources (Root)',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                  onTap: () {
                    _performMove(currentItems, 'root');
                    Navigator.pop(context);
                  },
                ),
                for (var folder in allFolders)
                  ListTile(
                    leading: Icon(
                      Icons.folder_rounded,
                      color: Color(
                        folder.colorValue ?? Colors.blueAccent.value,
                      ),
                    ),
                    title: Text(
                      folder.name,
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                    onTap: () {
                      _performMove(currentItems, folder.id);
                      Navigator.pop(context);
                    },
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.white54),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCreateFolderDialogThenMove(
    List<ResourceItem> currentItems,
  ) async {
    String folderName = '';
    int selectedColor = Colors.blueAccent.value;
    final List<Color> colorOptions = [
      Colors.blueAccent,
      Colors.redAccent,
      Colors.greenAccent,
      Colors.orangeAccent,
      Colors.purpleAccent,
      Colors.cyanAccent,
      Colors.amberAccent,
      Colors.pinkAccent,
      Colors.tealAccent,
      Colors.indigoAccent,
    ];

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setS) {
            return AlertDialog(
              backgroundColor: const Color(0xFF2B175C),
              title: Text(
                'New Folder',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Folder Name',
                      hintStyle: const TextStyle(color: Colors.white54),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white54),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.cyanAccent),
                      ),
                    ),
                    onChanged: (val) => folderName = val,
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: colorOptions.map((c) {
                      final isSel = c.value == selectedColor;
                      return GestureDetector(
                        onTap: () => setS(() => selectedColor = c.value),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: c,
                            border: isSel
                                ? Border.all(color: Colors.white, width: 3)
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(color: Colors.white54),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (folderName.trim().isNotEmpty) {
                      final newId = await ResourceService.addFolder(
                        folderName.trim(),
                        currentParentId,
                        selectedColor,
                      );
                      if (mounted) {
                        _performMove(currentItems, newId);
                        Navigator.pop(context);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                  ),
                  child: Text(
                    'Create & Move',
                    style: GoogleFonts.poppins(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _performMove(List<ResourceItem> currentItems, String targetParentId) {
    for (var id in _selectedIds) {
      final item = currentItems.firstWhere((e) => e.id == id);
      item.parentId = targetParentId;
      item.save();
    }
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }

  Future<void> _groupToSheet(List<ResourceItem> currentItems) async {
    // Prompt for sheet name
    String sheetName = '';
    bool confirmed = false;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2B175C),
          title: Text(
            'Name this Sheet',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          content: TextField(
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Sheet Name',
              hintStyle: const TextStyle(color: Colors.white54),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white54),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.cyanAccent),
              ),
            ),
            onChanged: (val) => sheetName = val,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (sheetName.trim().isNotEmpty) {
                  confirmed = true;
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
              ),
              child: Text(
                'Create',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (!confirmed || !mounted) return;

    // Build groupIds list from selected image IDs
    final selectedImages = currentItems
        .where(
          (e) => _selectedIds.contains(e.id) && e.type == ResourceType.image,
        )
        .toList();
    final groupIds = selectedImages.map((e) => e.id).toList();

    final newSheetId = await ResourceService.addFolder(
      sheetName.trim(),
      currentParentId,
      Colors.pinkAccent.value,
      groupIds: groupIds,
    );
    _performMove(currentItems, newSheetId);
  }

  void _showRotateDirectionPicker(List<ResourceItem> selectedItems) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2B175C),
        title: Text(
          'Rotate Direction',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.rotate_left_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _batchRotate(selectedItems, angle: -90);
                  },
                ),
                Text('Left', style: GoogleFonts.poppins(color: Colors.white70)),
              ],
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.rotate_right_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _batchRotate(selectedItems, angle: 90);
                  },
                ),
                Text(
                  'Right',
                  style: GoogleFonts.poppins(color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _batchRotate(
    List<ResourceItem> currentItems, {
    int angle = 90,
  }) async {
    setState(() => _isRotating = true);

    for (var id in _selectedIds.toList()) {
      final item = currentItems.firstWhere((e) => e.id == id);
      if (item.type == ResourceType.image && item.localPath != null) {
        final originalFile = File(item.localPath!);
        if (!await originalFile.exists()) continue;

        try {
          final parts = item.localPath!.split('.');
          final ext = (parts.length > 1 ? parts.last : 'jpg').toLowerCase();
          final tempPath = '${item.localPath}_rot_temp.$ext';
          final targetAngle = (angle % 360 + 360) % 360;

          final compressedFile = await FlutterImageCompress.compressAndGetFile(
            originalFile.absolute.path,
            tempPath,
            quality: 100,
            rotate: targetAngle,
          );

          if (compressedFile != null) {
            final bytes = await File(compressedFile.path).readAsBytes();
            await originalFile.writeAsBytes(bytes);
            await File(compressedFile.path).delete();
          }

          await FileImage(originalFile).evict();
        } catch (e) {
          debugPrint('Error rotating image $id: $e');
        }
      }
    }
    if (mounted) {
      imageCache.clear();
      imageCache.clearLiveImages();
      setState(() {
        _isRotating = false;
        _isSelectionMode = false;
        _selectedIds.clear();
      });
    }
  }

  Widget _buildSelectionBar(List<ResourceItem> currentItems) {
    final selectedItems = currentItems
        .where((e) => _selectedIds.contains(e.id))
        .toList();
    final allImages =
        selectedItems.isNotEmpty &&
        selectedItems.every((e) => e.type == ResourceType.image);

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _isSelectionMode = false;
                    _selectedIds.clear();
                  });
                },
              ),
              const SizedBox(width: 8),
              Text(
                '${_selectedIds.length} Selected',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Row(
            children: [
              if (allImages) ...[
                IconButton(
                  icon: const Icon(
                    Icons.rotate_right_rounded,
                    color: Colors.white,
                  ),
                  tooltip: 'Batch Rotate',
                  onPressed: () => _showRotateDirectionPicker(selectedItems),
                ),
                IconButton(
                  icon: const Icon(Icons.layers_rounded, color: Colors.white),
                  tooltip: 'Group to Sheet',
                  onPressed: () => _groupToSheet(selectedItems),
                ),
              ],
              IconButton(
                icon: const Icon(
                  Icons.drive_file_move_rounded,
                  color: Colors.white,
                ),
                tooltip: 'Move',
                onPressed: () => _moveSelected(currentItems),
              ),
              IconButton(
                icon: const Icon(Icons.delete_rounded, color: Colors.redAccent),
                tooltip: 'Delete',
                onPressed: () => _deleteSelected(currentItems),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFolderCover(ResourceItem item) {
    final isSheet = item.groupIds != null && item.groupIds!.isNotEmpty;

    if (!isSheet) {
      return Icon(
        Icons.folder_rounded,
        size: 64,
        color: Color(item.colorValue ?? Colors.blueAccent.value),
      );
    }

    // Sheet: Show up to 3 stacked image thumbnails
    final childImages = ResourceService.listenable.value.values
        .where(
          (e) =>
              e.parentId == item.id &&
              e.type == ResourceType.image &&
              e.localPath != null,
        )
        .take(3)
        .toList()
        .reversed
        .toList();

    if (childImages.isEmpty) {
      return Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.folder_rounded,
            size: 64,
            color: Color(item.colorValue ?? Colors.pinkAccent.value),
          ),
          const Positioned(
            right: 0,
            bottom: 0,
            child: Icon(Icons.layers_rounded, size: 16, color: Colors.white70),
          ),
        ],
      );
    }

    return SizedBox(
      width: 130,
      height: 130,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (int i = 0; i < childImages.length; i++)
            Positioned(
              top: i * 12.0,
              left: i * 12.0,
              child: Transform.rotate(
                angle: (i - 1) * 0.22,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: 6,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      File(childImages[i].localPath!),
                      key: ValueKey(
                        '${childImages[i].localPath}_${File(childImages[i].localPath!).existsSync() ? File(childImages[i].localPath!).lastModifiedSync().millisecondsSinceEpoch : 0}',
                      ),
                      width: 86,
                      height: 86,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGridItem(ResourceItem item) {
    final isSelected = _selectedIds.contains(item.id);
    final bool isFullBleed =
        (item.type == ResourceType.image && item.localPath != null) ||
        (item.type == ResourceType.link && item.thumbnailUrl != null);

    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          _toggleSelection(item.id);
          return;
        }

        if (item.type == ResourceType.folder) {
          _navigateToFolder(item.id, item.name);
        } else if (item.type == ResourceType.image) {
          final items = ResourceService.getItems(currentParentId);
          final images = items
              .where((e) => e.type == ResourceType.image)
              .toList();
          final initialIndex = images.indexWhere((e) => e.id == item.id);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ImageViewerScreen(images: images, initialIndex: initialIndex),
            ),
          );
        } else if (item.type == ResourceType.file && item.localPath != null) {
          FileHandlers.openLocalFile(item.localPath!);
        } else if (item.type == ResourceType.link && item.url != null) {
          FileHandlers.openLink(item.url!);
        }
      },
      onLongPress: () {
        if (!_isSelectionMode) {
          setState(() {
            _isSelectionMode = true;
            _selectedIds.add(item.id);
          });
        } else {
          _showItemOptions(item);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isFullBleed
              ? Colors.transparent
              : isSelected
              ? Colors.cyanAccent.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: isFullBleed
              ? null
              : Border.all(
                  color: isSelected ? Colors.cyanAccent : Colors.white10,
                  width: isSelected ? 2 : 1,
                ),
        ),
        foregroundDecoration: isFullBleed && isSelected
            ? BoxDecoration(
                color: Colors.cyanAccent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.cyanAccent, width: 3),
              )
            : null,
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: isFullBleed ? StackFit.expand : StackFit.loose,
          children: [
            if (isFullBleed) ...[
              // Full bleed image/link thumbnail
              if (item.type == ResourceType.image)
                Image.file(
                  File(item.localPath!),
                  key: ValueKey(
                    '${item.localPath}_${File(item.localPath!).existsSync() ? File(item.localPath!).lastModifiedSync().millisecondsSinceEpoch : 0}',
                  ),
                  fit: BoxFit.cover,
                )
              else if (item.type == ResourceType.link)
                Image.network(item.thumbnailUrl!, fit: BoxFit.cover),
              // Gradient overlay at bottom for text readability
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                  child: Text(
                    item.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ] else ...[
              // Centered icon + name for folders and files
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (item.type == ResourceType.folder)
                      _buildFolderCover(item)
                    else if (item.type == ResourceType.image)
                      const Icon(
                        Icons.image_rounded,
                        size: 64,
                        color: Colors.purpleAccent,
                      )
                    else if (item.type == ResourceType.file)
                      const Icon(
                        Icons.insert_drive_file_rounded,
                        size: 64,
                        color: Colors.orangeAccent,
                      )
                    else if (item.type == ResourceType.link)
                      const Icon(
                        Icons.link_rounded,
                        size: 64,
                        color: Colors.greenAccent,
                      ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        item.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Options button
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: Colors.white54,
                  size: 20,
                ),
                onPressed: () => _showItemOptions(item),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(ResourceItem item) {
    final isSelected = _selectedIds.contains(item.id);

    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          _toggleSelection(item.id);
          return;
        }
        if (item.type == ResourceType.folder) {
          _navigateToFolder(item.id, item.name);
        } else if (item.type == ResourceType.image) {
          final items = ResourceService.getItems(currentParentId);
          final images = items
              .where((e) => e.type == ResourceType.image)
              .toList();
          final initialIndex = images.indexWhere((e) => e.id == item.id);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ImageViewerScreen(images: images, initialIndex: initialIndex),
            ),
          );
        } else if (item.type == ResourceType.file && item.localPath != null) {
          FileHandlers.openLocalFile(item.localPath!);
        } else if (item.type == ResourceType.link && item.url != null) {
          FileHandlers.openLink(item.url!);
        }
      },
      onLongPress: () {
        if (!_isSelectionMode) {
          setState(() {
            _isSelectionMode = true;
            _selectedIds.add(item.id);
          });
        } else {
          _showItemOptions(item);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.cyanAccent.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.cyanAccent : Colors.white10,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Leading icon / thumbnail
            SizedBox(
              width: 44,
              height: 44,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildListItemLeading(item),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.more_vert_rounded,
                color: Colors.white54,
                size: 20,
              ),
              onPressed: () => _showItemOptions(item),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListItemLeading(ResourceItem item) {
    if (item.type == ResourceType.folder) {
      final isSheet = item.groupIds != null && item.groupIds!.isNotEmpty;
      return Icon(
        isSheet ? Icons.collections_bookmark_rounded : Icons.folder_rounded,
        size: 36,
        color: Color(
          item.colorValue ??
              (isSheet ? Colors.pinkAccent.value : Colors.blueAccent.value),
        ),
      );
    } else if (item.type == ResourceType.image && item.localPath != null) {
      return Image.file(
        File(item.localPath!),
        key: ValueKey(
          '${item.localPath}_${File(item.localPath!).existsSync() ? File(item.localPath!).lastModifiedSync().millisecondsSinceEpoch : 0}',
        ),
        fit: BoxFit.cover,
      );
    } else if (item.type == ResourceType.file) {
      return const Icon(
        Icons.insert_drive_file_rounded,
        size: 36,
        color: Colors.orangeAccent,
      );
    } else if (item.type == ResourceType.link && item.thumbnailUrl != null) {
      return Image.network(item.thumbnailUrl!, fit: BoxFit.cover);
    } else if (item.type == ResourceType.link) {
      return const Icon(
        Icons.link_rounded,
        size: 36,
        color: Colors.greenAccent,
      );
    }
    return const Icon(
      Icons.help_outline_rounded,
      size: 36,
      color: Colors.white38,
    );
  }

  @override
  Widget build(BuildContext context) {
    final backgroundGradient = const LinearGradient(
      colors: [Color(0xFF1A144B), Color(0xFF2B175C), Color(0xFF181A2A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final content = GestureDetector(
      onHorizontalDragUpdate: (details) {
        if (!kIsWeb && details.delta.dx < -10) {
          _scaffoldKey.currentState?.openEndDrawer();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        endDrawer: kIsWeb ? null : const SideNavigation(),
        backgroundColor: const Color(0xFF181A2A),
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(gradient: backgroundGradient),
              child: SafeArea(
                bottom: false,
                child: ValueListenableBuilder<Box<ResourceItem>>(
                  valueListenable: ResourceService.listenable,
                  builder: (context, box, _) {
                    final items = ResourceService.getItems(currentParentId);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isSelectionMode)
                          _buildSelectionBar(items)
                        else
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              16.0,
                              16.0,
                              16.0,
                              0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    if (_pathStack.length > 1)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          right: 8.0,
                                        ),
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.arrow_back_rounded,
                                            color: Colors.white,
                                          ),
                                          onPressed: _navigateUp,
                                        ),
                                      ),
                                    Text(
                                      'Resources',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: kIsWeb ? 32 : 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        _isGridView
                                            ? Icons.view_list_rounded
                                            : Icons.grid_view_rounded,
                                        color: Colors.white,
                                      ),
                                      tooltip: _isGridView
                                          ? 'List View'
                                          : 'Grid View',
                                      onPressed: () => setState(
                                        () => _isGridView = !_isGridView,
                                      ),
                                    ),
                                    if (!kIsWeb)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.menu_rounded,
                                          color: Colors.white,
                                        ),
                                        onPressed: () => _scaffoldKey
                                            .currentState
                                            ?.openEndDrawer(),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        if (!_isSelectionMode) _buildBreadcrumbs(),
                        const Divider(color: Colors.white10, height: 1),
                        Expanded(
                          child: items.isEmpty
                              ? _buildEmptyState()
                              : _isGridView
                              ? GridView.builder(
                                  padding: const EdgeInsets.all(16),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: kIsWeb ? 4 : 2,
                                        crossAxisSpacing: 16,
                                        mainAxisSpacing: 16,
                                        childAspectRatio: 1.0,
                                      ),
                                  itemCount: items.length,
                                  itemBuilder: (context, index) {
                                    return _buildGridItem(items[index]);
                                  },
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  itemCount: items.length,
                                  itemBuilder: (context, index) {
                                    return _buildListItem(items[index]);
                                  },
                                ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            if (_isRotating)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.cyanAccent),
                      SizedBox(height: 16),
                      Text(
                        'Rotating images...',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        floatingActionButton: _isSelectionMode
            ? null
            : ResourceFab(
                onAddFolder: _showCreateFolderDialog,
                onAddImage: _showAddImageDialog,
                onAddFile: _showAddFileDialog,
                onAddLink: _showAddLinkDialog,
              ),
      ),
    );

    if (kIsWeb) {
      return WebLayout(currentRoute: '/resources', child: content);
    }
    return content;
  }
}
