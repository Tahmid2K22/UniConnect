import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CountdownCard extends StatefulWidget {
  final String title;
  final DateTime targetDate;
  final IconData icon;
  final List<Color> gradientColors;

  const CountdownCard({
    super.key,
    required this.title,
    required this.targetDate,
    required this.icon,
    this.gradientColors = const [Colors.blue, Colors.purple, Colors.black],
  });

  @override
  State<CountdownCard> createState() => _CountdownCardState();
}

class _CountdownCardState extends State<CountdownCard>
    with TickerProviderStateMixin {
  late AnimationController _gradientController;
  Timer? _timer;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calculateTimeLeft();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _calculateTimeLeft();
    });

    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  void _calculateTimeLeft() {
    final now = DateTime.now();
    if (widget.targetDate.isAfter(now)) {
      if (mounted) {
        setState(() {
          _timeLeft = widget.targetDate.difference(now);
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _timeLeft = Duration.zero;
        });
      }
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
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
      animation: _gradientController,
      builder: (context, _) {
        final days = _timeLeft.inDays;
        final hours = _timeLeft.inHours % 24;
        final mins = _timeLeft.inMinutes % 60;
        final secs = _timeLeft.inSeconds % 60;

        return Container(
          height: 240,
          width: 200,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            gradient: _animatedGradient(),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 10,
                spreadRadius: 1,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Event Title
              Text(
                widget.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 12),

              // 2x2 Grid using Wrap or Table
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildTimeSlot(days.toString().padLeft(2, '0'), "Days"),
                        const SizedBox(width: 12),
                        _buildTimeSlot(
                          hours.toString().padLeft(2, '0'),
                          "Hours",
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildTimeSlot(mins.toString().padLeft(2, '0'), "Mins"),
                        const SizedBox(width: 12),
                        _buildTimeSlot(secs.toString().padLeft(2, '0'), "Secs"),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimeSlot(String value, String label) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: GoogleFonts.robotoMono(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.cyanAccent,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 10, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
