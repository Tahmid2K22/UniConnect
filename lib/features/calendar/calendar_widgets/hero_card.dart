import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../calendar_uitils.dart';

class HeroCard extends StatefulWidget {
  final String title; // Dynamic: Week N / Vacation / Finals
  final double progress; // 0.0 – 1.0
  final String aiSummary; // Motivational line
  final List<Color> baseGradient; // Multiple colors for gradient

  const HeroCard({
    super.key,
    required this.title,
    required this.progress,
    required this.aiSummary,
    required this.baseGradient,
  });

  @override
  State<HeroCard> createState() => _HeroCardState();
}

class _HeroCardState extends State<HeroCard> with TickerProviderStateMixin {
  late AnimationController _gradientController;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  late Animation<int> _percentAnimation;

  @override
  void initState() {
    super.initState();

    // Gradient animation
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    // Progress animation
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _progressAnimation =
        Tween<double>(begin: 0, end: widget.progress.clamp(0.0, 1.0)).animate(
          CurvedAnimation(parent: _progressController, curve: Curves.easeOut),
        );
    _percentAnimation = IntTween(begin: 0, end: (widget.progress * 100).toInt())
        .animate(
          CurvedAnimation(parent: _progressController, curve: Curves.easeOut),
        );

    _progressController.forward();
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _gradientController,
      builder: (context, _) {
        // Shift gradient slightly for animation
        final alignmentShift = _gradientController.value * 2 - 1;

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 12,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                colors: widget.baseGradient,
                begin: Alignment(-1 + alignmentShift, -1),
                end: Alignment(1 + alignmentShift, 1),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left: Texts
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.aiSummary,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),

                      // Active Notes
                      if (getEventNotes(widget.title).isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: getEventNotes(widget.title).map((note) {
                                return Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amberAccent.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.amberAccent.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.push_pin_rounded,
                                        color: Colors.amberAccent,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        note,
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Right: Bubble progress
                SizedBox(
                  width: 100,
                  height: 100,
                  child: AnimatedBuilder(
                    animation: _progressController,
                    builder: (context, _) {
                      final fillPercent = _progressAnimation.value;
                      final displayPercent = _percentAnimation.value;

                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          // Glassy circle
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.1),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: widget.baseGradient.first.withOpacity(
                                    0.4,
                                  ),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),

                          // Fluid fill
                          ClipOval(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: FractionallySizedBox(
                                heightFactor: fillPercent,
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        widget.baseGradient.first.withOpacity(
                                          0.9,
                                        ), // darker
                                        widget.baseGradient.last.withOpacity(
                                          0.8,
                                        ), // slightly transparent
                                      ],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Percentage text
                          Text(
                            "$displayPercent%",
                            style: GoogleFonts.orbitron(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
