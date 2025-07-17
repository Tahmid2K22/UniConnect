import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class WeMissYouBadge extends StatefulWidget {
  const WeMissYouBadge();

  @override
  State<WeMissYouBadge> createState() => _WeMissYouBadgeState();
}

class _WeMissYouBadgeState extends State<WeMissYouBadge>
    with SingleTickerProviderStateMixin {
  bool _showMessage = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glowing blurred circle
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.pinkAccent.withValues(alpha: 0.30),
                  Colors.cyanAccent.withValues(alpha: 0.08),
                  Colors.transparent,
                ],
                radius: 0.95,
                center: Alignment(0, 0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyanAccent.withValues(alpha: 0.23),
                  blurRadius: 36,
                  spreadRadius: 4,
                  offset: Offset(0, 7),
                ),
              ],
            ),
          ),

          // Main badge content
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: _showMessage
                ? _WeMissYouTextWithSparkle()
                : Lottie.asset(
                    'assets/animations/Heart.json',
                    width: 90,
                    height: 90,
                    repeat: false,
                    onLoaded: (composition) {
                      Future.delayed(composition.duration, () {
                        if (mounted) {
                          setState(() {
                            _showMessage = true;
                          });
                        }
                      });
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _WeMissYouTextWithSparkle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // The frosted-glass effect circle
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.10),
            border: Border.all(
              color: Colors.cyanAccent.withValues(alpha: 0.5),
              width: 2.3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.pinkAccent.withValues(alpha: 0.11),
                blurRadius: 23,
                spreadRadius: 6,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.waving_hand_rounded,
                color: Colors.yellowAccent.withValues(alpha: 0.85),
                size: 38,
              ),
              const SizedBox(height: 7),
              Text(
                "We Miss You!",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
        // Sparkle or heart accent
        Positioned(
          left: 5,
          bottom: 4,
          child: Icon(
            Icons.favorite,
            color: Colors.pinkAccent.withValues(alpha: 0.8),
            size: 20,
          ),
        ),
        Positioned(
          right: 10,
          top: 15,
          child: Icon(
            Icons.auto_awesome,
            color: Colors.cyanAccent.withValues(alpha: 0.85),
            size: 15,
          ),
        ),
      ],
    );
  }
}
