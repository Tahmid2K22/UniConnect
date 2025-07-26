import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:marquee/marquee.dart';
import '../../features/chatbot/gemini_summary.dart';

class TopSection extends StatefulWidget {
  final String? userName;
  final String? nextClassTitle;
  final String? nextClassTime;
  final String? nextExamTitle;
  final String? nextExamTime;
  final String? noticesText;
  final int? daysUntilExam;
  final bool hasNextClass;
  final bool hasNextExam;
  final Function()? onTapNextClass;
  final Function()? onTapNextExam;

  const TopSection({
    this.userName,
    this.nextClassTitle,
    this.nextClassTime,
    this.nextExamTitle,
    this.nextExamTime,
    this.daysUntilExam,
    this.noticesText,
    required this.hasNextClass,
    required this.hasNextExam,
    this.onTapNextClass,
    this.onTapNextExam,
    super.key,
  });

  @override
  State<TopSection> createState() => _TopSectionState();
}

class _TopSectionState extends State<TopSection>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  int _pageIndex = 0;
  late final AnimationController _gradientController;

  bool get _trulyHasNextClass =>
      widget.nextClassTitle != null && widget.nextClassTitle != 'Rest up!';

  String? _aiTitle;
  String? _aiDescription;
  bool _isLoadingAi = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _gradientController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat();
    Future.delayed(const Duration(milliseconds: 700), () {
      _fetchAndSetAiSummary();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _gradientController.dispose();
    super.dispose();
  }

  LinearGradient _getGradient(int index) {
    switch (index) {
      case 0:
        final period = _getTimePeriod();
        List<Color> gradientColors;

        switch (period) {
          case 'morning':
            gradientColors = [
              const Color(0xFFFFD580),
              const Color(0xFFFFE0B2),
              const Color(0xFFFFF8E1),
            ];
            break;

          case 'noon':
            gradientColors = [
              const Color(0xFF81D4FA),
              const Color(0xFF4DD0E1),
              const Color(0xFFB2EBF2),
            ];
            break;

          case 'evening':
            gradientColors = [
              const Color(0xFFFFAB91),
              const Color(0xFFF48FB1),
              const Color(0xFFCE93D8),
            ];
            break;

          case 'night':
            gradientColors = [
              const Color(0xFF3F51B5),
              const Color(0xFF5C6BC0),
              const Color(0xFF7986CB),
            ];
            break;

          case 'midnight':
          default:
            gradientColors = [
              const Color(0xFF212121),
              const Color(0xFF37474F),
              const Color(0xFF455A64),
            ];
            break;
        }

        return LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          transform: GradientRotation(_gradientController.value * 2 * 3.1415),
        );

      case 1:
        if (_trulyHasNextClass) {
          return LinearGradient(
            colors: [Colors.cyan, Colors.indigoAccent, Colors.purple],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            transform: GradientRotation(_gradientController.value * 2 * 3.1415),
          );
        } else {
          return LinearGradient(
            colors: [
              Color(0xFFff9a9e),
              Color(0xFFfad0c4),
              Color(0xFFfadadd),
              Color(0xFFcbb4d4),
            ],

            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            transform: GradientRotation(_gradientController.value * 2 * 3.1415),
          );
        }
      default:
        if (!widget.hasNextExam) {
          return LinearGradient(
            colors: [Colors.deepPurple, Colors.black54],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            transform: GradientRotation(_gradientController.value * 2 * 3.1415),
          );
        }
        if ((widget.daysUntilExam ?? 99) < 0) {
          return LinearGradient(
            colors: [Colors.grey, Colors.black, Colors.purple[700]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            transform: GradientRotation(_gradientController.value * 2 * 3.1415),
          );
        }
        if ((widget.daysUntilExam ?? 99) == 0) {
          return LinearGradient(
            colors: [Colors.redAccent, Colors.purple, Colors.pinkAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            transform: GradientRotation(_gradientController.value * 2 * 3.1415),
          );
        }
        if ((widget.daysUntilExam ?? 99) <= 3) {
          return LinearGradient(
            colors: [Colors.orange, Colors.deepOrange, Colors.amberAccent],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            transform: GradientRotation(_gradientController.value * 2 * 3.1415),
          );
        }
        return LinearGradient(
          colors: [Colors.greenAccent, Colors.blue, Colors.blueAccent],
          begin: Alignment.bottomRight,
          end: Alignment.topLeft,
          transform: GradientRotation(_gradientController.value * 2 * 3.1415),
        );
    }
  }

  Widget _gradientText(
    String text, {
    double fontSize = 28,
    FontWeight fontWeight = FontWeight.bold,
  }) {
    return AnimatedBuilder(
      animation: _gradientController,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              colors: [
                Colors.cyanAccent,
                Colors.blueAccent,
                Colors.lightBlueAccent,
                Colors.cyanAccent,
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: const [0.0, 0.33, 0.66, 1.0],
              tileMode: TileMode.mirror,
              transform: GradientRotation(
                _gradientController.value * 2 * 3.1415,
              ),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: Colors.white,
        ),
        overflow: TextOverflow.fade,
        maxLines: 1,
      ),
    );
  }

  Widget _buildMarqueeText(String text, {TextStyle? style}) {
    final threshold = 25;
    if (text.length <= threshold) {
      return Text(
        text,
        style: style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return SizedBox(
      height: style?.fontSize != null ? style!.fontSize! * 1.2 : 18,
      child: ClipRect(
        child: Marquee(
          text: text,
          style: style,
          blankSpace: 40.0,
          velocity: 40.0,
          startPadding: 5.0,
          accelerationDuration: Duration.zero,
          decelerationDuration: Duration.zero,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userName = widget.userName ?? '';
    final nextClass = _trulyHasNextClass
        ? widget.nextClassTitle ?? '-'
        : 'No class scheduled';
    final nextExam = widget.hasNextExam
        ? widget.nextExamTitle ?? '-'
        : 'No upcoming exam';
    final nextClassTime = _trulyHasNextClass ? widget.nextClassTime ?? '-' : '';

    return Column(
      children: [
        // AppBar section
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _gradientText('Hi, $userName', fontSize: 28),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.menu,
                  color: Colors.cyanAccent,
                  size: 30,
                ),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Main PageView Card
        SizedBox(
          height: 240, // Increased height for better space
          child: AnimatedBuilder(
            animation: _gradientController,
            builder: (context, _) => PageView(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _pageIndex = i),
              children: [
                // Page 1: Summary
                _AnimatedCard(
                  gradient: _getGradient(0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 28,
                      horizontal: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 600),
                          switchInCurve: Curves.easeIn,
                          switchOutCurve: Curves.easeOut,
                          child:
                              _isLoadingAi ||
                                  _aiTitle == null ||
                                  _aiDescription == null
                              ? Column(
                                  key: const ValueKey('defaultText'),
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Welcome to UniConnect',
                                      style: GoogleFonts.poppins(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            _isDarkTimePeriod(_getTimePeriod())
                                            ? Colors.white.withValues(
                                                alpha: 0.85,
                                              )
                                            : Colors.black.withValues(
                                                alpha: 0.85,
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      "What's on your mind this ${_getTimePeriod()}? Are you doing well?",
                                      style: GoogleFonts.poppins(
                                        color:
                                            _isDarkTimePeriod(_getTimePeriod())
                                            ? Colors.white.withValues(
                                                alpha: 0.6,
                                              )
                                            : Colors.black.withValues(
                                                alpha: 0.6,
                                              ),

                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                )
                              : Column(
                                  key: const ValueKey('aiText'),
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _aiTitle!,
                                      style: GoogleFonts.poppins(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            _isDarkTimePeriod(_getTimePeriod())
                                            ? Colors.white.withValues(
                                                alpha: 0.85,
                                              )
                                            : Colors.black.withValues(
                                                alpha: 0.85,
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      _aiDescription!,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color:
                                            _isDarkTimePeriod(_getTimePeriod())
                                            ? Colors.white.withValues(
                                                alpha: 0.6,
                                              )
                                            : Colors.black.withValues(
                                                alpha: 0.6,
                                              ),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            // Next Class area: left half
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    height: 20,
                                    child: ClipRect(
                                      child: _buildMarqueeText(
                                        _trulyHasNextClass
                                            ? (widget.nextClassTitle ?? "")
                                            : "No class scheduled",
                                        style: GoogleFonts.poppins(
                                          color:
                                              _isDarkTimePeriod(
                                                _getTimePeriod(),
                                              )
                                              ? Colors.white.withValues(
                                                  alpha: 0.7,
                                                )
                                              : Colors.black.withValues(
                                                  alpha: 0.7,
                                                ),

                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  SizedBox(
                                    height: 18,
                                    child: ClipRect(
                                      child: _buildMarqueeText(
                                        _trulyHasNextClass
                                            ? (widget.nextClassTime ?? "")
                                            : "",
                                        style: GoogleFonts.poppins(
                                          color:
                                              _isDarkTimePeriod(
                                                _getTimePeriod(),
                                              )
                                              ? Colors.white.withValues(
                                                  alpha: 0.7,
                                                )
                                              : Colors.black.withValues(
                                                  alpha: 0.7,
                                                ),

                                          fontWeight: FontWeight.w400,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(
                              width: 25,
                            ), // gap between left and right halves
                            // Exam area: right half
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    height: 20,
                                    child: ClipRect(
                                      child: _buildMarqueeText(
                                        widget.hasNextExam
                                            ? (widget.nextExamTitle ?? "")
                                            : "No upcoming exam",
                                        style: GoogleFonts.poppins(
                                          color:
                                              _isDarkTimePeriod(
                                                _getTimePeriod(),
                                              )
                                              ? Colors.white.withValues(
                                                  alpha: 0.7,
                                                )
                                              : Colors.black.withValues(
                                                  alpha: 0.7,
                                                ),

                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  SizedBox(
                                    height: 18,
                                    child: ClipRect(
                                      child: _buildMarqueeText(
                                        widget.hasNextExam
                                            ? (widget.nextExamTime ?? "")
                                            : "",
                                        style: GoogleFonts.poppins(
                                          color:
                                              _isDarkTimePeriod(
                                                _getTimePeriod(),
                                              )
                                              ? Colors.white.withValues(
                                                  alpha: 0.7,
                                                )
                                              : Colors.black.withValues(
                                                  alpha: 0.7,
                                                ),

                                          fontWeight: FontWeight.w400,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Swipe left for more info!"),
                        duration: Duration(milliseconds: 700),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                // Page 2: Next Class details
                _AnimatedCard(
                  gradient: _getGradient(1),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: _trulyHasNextClass ? widget.onTapNextClass : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 24,
                      ),
                      child: _trulyHasNextClass
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Upcoming Class",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  height: 28,
                                  child: ClipRect(
                                    child: _buildMarqueeText(
                                      nextClass,
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 22,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                ),
                                if (nextClassTime.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 20,
                                    child: ClipRect(
                                      child: _buildMarqueeText(
                                        nextClassTime,
                                        style: GoogleFonts.poppins(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w400,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: _buildMarqueeText(
                                    "No Classes Right Now",
                                    style: GoogleFonts.poppins(
                                      color: Colors.black54,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 22,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Chill! Next class info will show up here.",
                                  style: GoogleFonts.poppins(
                                    color: Colors.black38,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                // Page 3: Next Exam details
                _AnimatedCard(
                  gradient: _getGradient(2),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: widget.hasNextExam ? widget.onTapNextExam : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 28,
                        horizontal: 24,
                      ),
                      child: widget.hasNextExam
                          ? Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Upcoming Exam",
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      _buildMarqueeText(
                                        nextExam,
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          "Days to go",
                                          style: GoogleFonts.poppins(
                                            color: widget.daysUntilExam == 0
                                                ? Colors.amberAccent
                                                : widget.daysUntilExam! < 0
                                                ? Colors.white
                                                : widget.daysUntilExam! <= 3
                                                ? Colors.black45
                                                : Colors.greenAccent,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          "${widget.daysUntilExam ?? ''}",
                                          style: GoogleFonts.poppins(
                                            color: widget.daysUntilExam == 0
                                                ? Colors.amberAccent
                                                : widget.daysUntilExam! < 0
                                                ? Colors.white
                                                : widget.daysUntilExam! <= 3
                                                ? Colors.black45
                                                : Colors.greenAccent,
                                            fontSize: 80,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.event_rounded,
                                    size: 38,
                                    color: Colors.white70,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "No Upcoming Exams",
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Enjoy yourself! No exams coming up.",
                                    style: GoogleFonts.poppins(
                                      color: Colors.white54,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Page indicator dots
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 6),
                width: _pageIndex == i ? 20 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: _pageIndex == i ? Colors.cyanAccent : Colors.white24,
                  borderRadius: BorderRadius.circular(16),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  String _getTimePeriod() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 17) return 'noon';
    if (hour >= 17 && hour < 21) return 'evening';
    if (hour >= 21 || hour < 2) return 'night';
    // hour in [2, 5)
    return 'midnight';
  }

  bool _isDarkTimePeriod(String period) {
    return period == 'night' || period == 'midnight';
  }

  Future<void> _fetchAndSetAiSummary() async {
    if (widget.noticesText == null) {
      return;
    }

    setState(() {
      _isLoadingAi = true;
    });

    try {
      final result = await fetchGeminiSummary(
        userName: widget.userName ?? '',
        notices: widget.noticesText ?? '',
        examTitle: widget.nextExamTitle ?? '',
        examDate: widget.nextExamTime ?? '',
      );
      setState(() {
        _aiTitle = result.title;
        _aiDescription = result.description;
        _isLoadingAi = false;
      });
    } catch (e, st) {
      print("[AI Summary] Exception: $e \n$st");
      setState(() {
        _aiTitle = null;
        _aiDescription = null;
        _isLoadingAi = false;
      });
    }
  }
}

class _AnimatedCard extends StatelessWidget {
  final LinearGradient gradient;
  final Widget child;
  final VoidCallback? onTap;

  const _AnimatedCard({
    required this.gradient,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.purpleAccent.withValues(alpha: 0.20),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: card,
        ),
      );
    }
    return card;
  }
}
