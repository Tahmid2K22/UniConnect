import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class AnimatedGradientCGPANumber extends StatefulWidget {
  final double avgCgpa;
  const AnimatedGradientCGPANumber({super.key, required this.avgCgpa});

  @override
  State<AnimatedGradientCGPANumber> createState() =>
      _AnimatedGradientCGPANumberState();
}

class _AnimatedGradientCGPANumberState extends State<AnimatedGradientCGPANumber>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late final AnimationController _gradientController;

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _gradientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradientColors = [
      Colors.cyanAccent,
      Colors.blueAccent,
      Colors.purpleAccent,
      Colors.cyanAccent,
    ];

    return Column(
      children: [
        // Animated Gradient Label
        AnimatedBuilder(
          animation: _gradientController,
          builder: (context, child) {
            final shift = _gradientController.value;
            return ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                  colors: gradientColors,
                  begin: Alignment(-1 + 2 * shift, 0),
                  end: Alignment(1 + 2 * shift, 0),
                  stops: const [0.0, 0.33, 0.66, 1.0],
                  tileMode: TileMode.mirror,
                ).createShader(
                  Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                );
              },
              blendMode: BlendMode.srcIn,
              child:
                  Text(
                        "Average CGPA",
                        style: GoogleFonts.poppins(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: Colors.white,
                        ),
                      )
                      .animate(onPlay: (controller) => controller.repeat())
                      .shimmer(
                        duration: 2200.ms,
                        color: Colors.white.withValues(alpha: 0.3),
                        angle: 0.2,
                      ),
            );
          },
        ),
        const SizedBox(height: 18),
        // Tappable animated CGPA number with count-up and animated gradient
        GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedScale(
            scale: _isPressed ? 1.11 : 1.0,
            duration: 220.ms,
            curve: Curves.easeOut,
            child:
                TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: widget.avgCgpa),
                      duration: const Duration(milliseconds: 1400),
                      curve: Curves.easeOutExpo,
                      builder: (context, value, child) {
                        final shift =
                            (DateTime.now().millisecondsSinceEpoch % 2000) /
                            2000.0;
                        return ShaderMask(
                          shaderCallback: (bounds) {
                            return LinearGradient(
                              colors: gradientColors,
                              begin: Alignment(-1 + 2 * shift, 0),
                              end: Alignment(1 + 2 * shift, 0),
                              stops: const [0.0, 0.33, 0.66, 1.0],
                              tileMode: TileMode.mirror,
                            ).createShader(
                              Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                            );
                          },
                          blendMode: BlendMode.srcIn,
                          child: Text(
                            value.toStringAsFixed(2),
                            style: GoogleFonts.poppins(
                              fontSize: 70,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.8,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  blurRadius: _isPressed ? 36 : 18,
                                  color: Colors.cyanAccent.withValues(
                                    alpha: _isPressed ? 0.7 : 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                    .animate(onPlay: (controller) => controller.repeat())
                    .shimmer(
                      duration: 2000.ms,
                      color: Colors.white.withValues(alpha: 0.2),
                      angle: 0.1,
                    ),
          ),
        ),
      ],
    );
  }
}
