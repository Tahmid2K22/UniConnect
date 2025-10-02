import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CountdownCard extends StatefulWidget {
  final String title;
  final int daysLeft;
  final IconData icon;
  final List<Color> gradientColors;

  const CountdownCard({
    super.key,
    required this.title,
    required this.daysLeft,
    required this.icon,
    this.gradientColors = const [Colors.blue, Colors.purple, Colors.black],
  });

  @override
  State<CountdownCard> createState() => _CountdownCardState();
}

class _CountdownCardState extends State<CountdownCard>
    with TickerProviderStateMixin {
  late AnimationController _numberController;
  late Animation<int> _numberAnimation;
  late AnimationController _gradientController;

  @override
  void initState() {
    super.initState();

    _numberController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _numberAnimation = IntTween(begin: 0, end: widget.daysLeft).animate(
      CurvedAnimation(parent: _numberController, curve: Curves.easeOut),
    );

    _numberController.forward();

    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _numberController.dispose();
    _gradientController.dispose();
    super.dispose();
  }

  LinearGradient _animatedGradient() {
    final t = _gradientController.value * 2 - 1;
    return LinearGradient(
      begin: Alignment(-1 + t, -1),
      end: Alignment(1 + t, 1),
      colors: widget.gradientColors.map((c) => c.withOpacity(0.85)).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_numberController, _gradientController]),
      builder: (context, _) {
        return Container(
          height: 240, // reduced height
          width: 200, // slightly slimmer
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            gradient: _animatedGradient(),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 10,
                spreadRadius: 1,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.25),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.4),
                    width: 1.5,
                  ),
                ),
                child: Icon(widget.icon, size: 32, color: Colors.white),
              ),

              // Days Left Number
              Column(
                children: [
                  FittedBox(
                    child: Text(
                      "${_numberAnimation.value}",
                      style: GoogleFonts.robotoMono(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.5,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.5),
                            offset: const Offset(2, 2),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "days left",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),

              // Title (max 2 lines with fade)
              Text(
                widget.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
