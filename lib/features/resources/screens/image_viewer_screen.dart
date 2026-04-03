import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:universal_io/io.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../models/resource_item.dart';

class ImageViewerScreen extends StatefulWidget {
  final List<ResourceItem> images;
  final int initialIndex;

  const ImageViewerScreen({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;

  bool _isDrawingMode = false;
  bool _isRotating = false;
  int _refreshKey = 0;

  // Drawing state
  final List<DrawnStroke> _strokes = [];
  DrawnStroke? _currentStroke;
  Color _selectedColor = Colors.redAccent;
  double _strokeWidth = 4.0;
  final GlobalKey _drawingKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
      _isDrawingMode = false;
      _strokes.clear();
      _currentStroke = null;
    });
  }

  void _saveDrawing() async {
    try {
      RenderRepaintBoundary boundary =
          _drawingKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final currentItem = widget.images[_currentIndex];
      final originalFile = File(currentItem.localPath!);
      await originalFile.writeAsBytes(pngBytes);

      if (mounted) {
        imageCache.clear();
        imageCache.clearLiveImages();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image saved successfully!')),
        );
        setState(() {
          _isDrawingMode = false;
          _strokes.clear();
          _currentStroke = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving: $e')));
      }
    }
  }

  void _undo() {
    if (_strokes.isNotEmpty) {
      setState(() {
        _strokes.removeLast();
      });
    }
  }

  /// Rotate the current image using flutter_image_compress (native speed)
  Future<void> _rotateCurrentImage(int angleDegrees) async {
    setState(() => _isRotating = true);

    try {
      final currentItem = widget.images[_currentIndex];
      final originalFile = File(currentItem.localPath!);

      final parts = currentItem.localPath!.split('.');
      final ext = (parts.length > 1 ? parts.last : 'jpg').toLowerCase();
      final tempPath = '${currentItem.localPath}_rot_temp.$ext';

      final targetAngle = (angleDegrees % 360 + 360) % 360;

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

      if (mounted) {
        imageCache.clear();
        imageCache.clearLiveImages();
        setState(() {
          _refreshKey++;
          _isRotating = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Image rotated!')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRotating = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error rotating: $e')));
      }
    }
  }

  void _showRotateOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2B175C),
        title: const Text('Rotate', style: TextStyle(color: Colors.white)),
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
                    _rotateCurrentImage(-90);
                  },
                ),
                const Text('Left', style: TextStyle(color: Colors.white70)),
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
                    _rotateCurrentImage(90);
                  },
                ),
                const Text('Right', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentItem = widget.images[_currentIndex];
    final file = File(currentItem.localPath!);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.7),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          _isDrawingMode
              ? 'Draw'
              : '${_currentIndex + 1} / ${widget.images.length}',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        actions: [
          if (_isDrawingMode) ...[
            IconButton(
              icon: const Icon(Icons.undo_rounded, color: Colors.white),
              onPressed: _undo,
              tooltip: 'Undo',
            ),
            IconButton(
              icon: const Icon(Icons.check_rounded, color: Colors.greenAccent),
              onPressed: _saveDrawing,
              tooltip: 'Save',
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.redAccent),
              onPressed: () {
                setState(() {
                  _isDrawingMode = false;
                  _strokes.clear();
                  _currentStroke = null;
                });
              },
              tooltip: 'Cancel',
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.rotate_right_rounded),
              onPressed: _isRotating ? null : _showRotateOptions,
              tooltip: 'Rotate',
            ),
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              onPressed: () {
                setState(() {
                  _isDrawingMode = true;
                });
              },
              tooltip: 'Draw',
            ),
          ],
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          _isDrawingMode
              ? SafeArea(
                  child: Column(
                    children: [
                      // Centered image + drawing canvas
                      Expanded(
                        child: Center(
                          child: RepaintBoundary(
                            key: _drawingKey,
                            child: Stack(
                              children: [
                                Image.file(file, fit: BoxFit.contain),
                                Positioned.fill(
                                  child: GestureDetector(
                                    onPanStart: (details) {
                                      setState(() {
                                        _currentStroke = DrawnStroke(
                                          color: _selectedColor,
                                          width: _strokeWidth,
                                          points: [details.localPosition],
                                        );
                                        _strokes.add(_currentStroke!);
                                      });
                                    },
                                    onPanUpdate: (details) {
                                      if (_currentStroke == null) return;
                                      setState(() {
                                        _currentStroke!.points.add(
                                          details.localPosition,
                                        );
                                      });
                                    },
                                    onPanEnd: (_) {
                                      setState(() {
                                        _currentStroke?.points.add(null);
                                        _currentStroke = null;
                                      });
                                    },
                                    child: CustomPaint(
                                      painter: _DrawingPainter(_strokes),
                                      size: Size.infinite,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Bottom toolbar
                      Container(
                        color: Colors.black87,
                        padding: const EdgeInsets.only(
                          top: 8,
                          bottom: 16,
                          left: 16,
                          right: 16,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Stroke width slider
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                thumbColor: _selectedColor,
                                activeTrackColor: _selectedColor.withValues(
                                  alpha: 0.8,
                                ),
                                inactiveTrackColor: Colors.white24,
                                trackHeight: 3,
                              ),
                              child: Slider(
                                value: _strokeWidth,
                                min: 2,
                                max: 16,
                                onChanged: (val) =>
                                    setState(() => _strokeWidth = val),
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Color swatches
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children:
                                  [
                                    Colors.redAccent,
                                    Colors.blueAccent,
                                    Colors.greenAccent,
                                    Colors.yellowAccent,
                                    Colors.white,
                                    Colors.black,
                                  ].map((color) {
                                    final isSelected = _selectedColor == color;
                                    return GestureDetector(
                                      onTap: () => setState(
                                        () => _selectedColor = color,
                                      ),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 150,
                                        ),
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                        ),
                                        width: isSelected ? 34 : 24,
                                        height: isSelected ? 34 : 24,
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isSelected
                                                ? Colors.cyanAccent
                                                : Colors.white38,
                                            width: isSelected ? 2.5 : 1,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              : PhotoViewGallery.builder(
                  key: ValueKey('gallery_$_refreshKey'),
                  pageController: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: widget.images.length,
                  builder: (context, index) {
                    final item = widget.images[index];
                    return PhotoViewGalleryPageOptions(
                      imageProvider: FileImage(File(item.localPath!)),
                      minScale: PhotoViewComputedScale.contained,
                      maxScale: PhotoViewComputedScale.covered * 3,
                      heroAttributes: PhotoViewHeroAttributes(tag: item.id),
                    );
                  },
                  scrollPhysics: const BouncingScrollPhysics(),
                  backgroundDecoration: const BoxDecoration(
                    color: Colors.black,
                  ),
                ),
          // Loading overlay for rotation
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
                      'Rotating...',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class DrawnStroke {
  final Color color;
  final double width;
  final List<Offset?> points;

  DrawnStroke({required this.color, required this.width, required this.points});
}

class _DrawingPainter extends CustomPainter {
  final List<DrawnStroke> strokes;

  _DrawingPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final points = stroke.points;
      for (int j = 0; j < points.length - 1; j++) {
        if (points[j] != null && points[j + 1] != null) {
          canvas.drawLine(points[j]!, points[j + 1]!, paint);
        } else if (points[j] != null && points[j + 1] == null) {
          canvas.drawPoints(ui.PointMode.points, [points[j]!], paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
