import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ResourceFab extends StatefulWidget {
  final VoidCallback onAddFolder;
  final VoidCallback onAddImage;
  final VoidCallback onAddFile;
  final VoidCallback onAddLink;

  const ResourceFab({
    super.key,
    required this.onAddFolder,
    required this.onAddImage,
    required this.onAddFile,
    required this.onAddLink,
  });

  @override
  State<ResourceFab> createState() => _ResourceFabState();
}

class _ResourceFabState extends State<ResourceFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      value: _isOpen ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.easeOutQuad,
      parent: _controller,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    _isOpen = !_isOpen;
    if (_isOpen) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() {});
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          FloatingActionButton.small(
            heroTag: label,
            backgroundColor: color,
            onPressed: () {
              _toggle();
              onTap();
            },
            child: Icon(icon, color: Colors.white),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final double scale = _expandAnimation.value;
            if (scale == 0.0) return const SizedBox.shrink();

            return IgnorePointer(
              ignoring: !_isOpen && _controller.isDismissed,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Transform.scale(
                    scale: scale,
                    alignment: Alignment.bottomRight,
                    child: _buildActionButton(
                      label: 'Add Link',
                      icon: Icons.link_rounded,
                      color: Colors.blueAccent,
                      onTap: widget.onAddLink,
                    ),
                  ),
                  Transform.scale(
                    scale: scale,
                    alignment: Alignment.bottomRight,
                    child: _buildActionButton(
                      label: 'Add File',
                      icon: Icons.insert_drive_file_rounded,
                      color: Colors.orangeAccent,
                      onTap: widget.onAddFile,
                    ),
                  ),
                  Transform.scale(
                    scale: scale,
                    alignment: Alignment.bottomRight,
                    child: _buildActionButton(
                      label: 'Add Image',
                      icon: Icons.image_rounded,
                      color: Colors.purpleAccent,
                      onTap: widget.onAddImage,
                    ),
                  ),
                  Transform.scale(
                    scale: scale,
                    alignment: Alignment.bottomRight,
                    child: _buildActionButton(
                      label: 'Create Folder',
                      icon: Icons.create_new_folder_rounded,
                      color: Colors.greenAccent[700]!,
                      onTap: widget.onAddFolder,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        FloatingActionButton(
          heroTag: 'main_fab',
          backgroundColor: Colors.cyanAccent,
          onPressed: _toggle,
          child: AnimatedRotation(
            turns: _isOpen ? 0.125 : 0, // Rotates 45 degrees to make an 'X'
            duration: const Duration(milliseconds: 250),
            child: Icon(Icons.add_rounded, color: Colors.black87, size: 32),
          ),
        ),
      ],
    );
  }
}
