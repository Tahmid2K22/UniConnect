import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:ui';

class DataModel {
  final String period;
  final String data;
  final String endTime;

  DataModel({required this.period, required this.data, required this.endTime});
}

class Routine extends StatefulWidget {
  final List<List<String>> sectionAData;
  final List<List<String>> sectionBData;

  const Routine({
    super.key,
    required this.sectionAData,
    required this.sectionBData,
  });

  @override
  State<Routine> createState() => _RoutineState();
}

class _RoutineState extends State<Routine> with SingleTickerProviderStateMixin {
  String _selectedSection = 'Section B';
  List<DataModel> _displayData = [];
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _loadSection();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadSection() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedSection = prefs.getString('section') ?? 'Section B';
      _updateDisplayData();
    });
  }

  void _updateDisplayData() {
    setState(() {
      _displayData = _selectedSection == "Section A"
          ? _getTodayNextClass(widget.sectionAData)
          : _getTodayNextClass(widget.sectionBData);
    });
    _controller.reset();
    _controller.forward();
  }

  List<DataModel> _getTodayNextClass(List<List<String>> sectionData) {
    if (sectionData.isEmpty) {
      return [
        DataModel(period: 'No data', data: 'No classes scheduled', endTime: ''),
      ];
    }

    final now = DateTime.now();
    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final today = weekdays[now.weekday - 1];

    try {
      final todayRow = sectionData.firstWhere(
        (row) => row.isNotEmpty && row[0] == today,
        orElse: () => [],
      );

      if (todayRow.isEmpty) {
        return [DataModel(period: 'No classes', data: 'Rest up!', endTime: '')];
      }

      for (int i = 1; i < sectionData[0].length; i++) {
        final period = sectionData[0][i];
        final classTitle = todayRow[i];

        if (classTitle.isEmpty || classTitle == '-') continue;

        final timeRange = RegExp(r'\((.*?)\)').firstMatch(period)?.group(1);
        if (timeRange == null) continue;

        final endTimeStr = timeRange.split('-')[1].trim();
        final endTime = DateFormat('hh:mm a').parse(endTimeStr);
        final endDateTime = DateTime(
          now.year,
          now.month,
          now.day,
          endTime.hour,
          endTime.minute,
        );

        if (now.isBefore(endDateTime)) {
          return [
            DataModel(period: period, data: classTitle, endTime: endTimeStr),
          ];
        }
      }
    } catch (e) {
      debugPrint('Error processing class data: $e');
    }

    return [
      DataModel(period: 'No more classes', data: 'Rest up!', endTime: ''),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0E0E2C), Color(0xFF0E0E2C)],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 25),
          _buildSectionSelector(),
          const SizedBox(height: 25),
          Expanded(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: _displayData.isEmpty
                      ? _buildEmptyState()
                      : _buildClassCard(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 30),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF6C3483), Color(0xFF0F3460)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.cyanAccent.withValues(alpha: 0.3),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: DropdownButton<String>(
        value: _selectedSection,
        dropdownColor: const Color(0xFF1A1A2E),
        icon: Icon(Icons.arrow_drop_down, color: Colors.cyanAccent),
        iconSize: 32,
        underline: const SizedBox(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
        items: ['Section A', 'Section B'].map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Row(
              children: [
                Icon(Icons.class_, color: Colors.cyanAccent, size: 20),
                const SizedBox(width: 12),
                Text(value),
              ],
            ),
          );
        }).toList(),
        onChanged: (String? newValue) async {
          if (newValue != null) {
            setState(() => _selectedSection = newValue);
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('section', newValue);
            _updateDisplayData();
          }
        },
      ),
    );
  }

  Widget _buildClassCard() {
    final item = _displayData.first;
    return Center(
      child: GlassCard(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "NEXT CLASS",
                    style: TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.cyanAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _selectedSection,
                      style: TextStyle(
                        color: Colors.cyanAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Text(
                item.period,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(Icons.schedule, color: Colors.cyanAccent, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    "Until ${item.endTime}",
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Text(
                item.data,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 25),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => _showFullScheduleDialog(context),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C3483), Color(0xFF00DBDE)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyanAccent.withValues(alpha: 0.4),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.arrow_forward, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullScheduleDialog(BuildContext context) {
    final sectionData = _selectedSection == "Section A"
        ? widget.sectionAData
        : widget.sectionBData;

    // Get today's row and headers
    final now = DateTime.now();
    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final today = weekdays[now.weekday - 1];
    final headers = sectionData.isNotEmpty ? sectionData[0] : [];
    final todayRow = sectionData.firstWhere(
      (row) => row.isNotEmpty && row[0] == today,
      orElse: () => [],
    );

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(18),
          child: GlassCard(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),

              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 28,
                    horizontal: 18,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "$today Schedule",
                        style: const TextStyle(
                          color: Colors.cyanAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (headers.isEmpty || todayRow.isEmpty)
                        const Text(
                          "No schedule found for today.",
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: headers.length - 1,
                          separatorBuilder: (_, _) =>
                              const Divider(color: Colors.white12, height: 18),
                          itemBuilder: (context, idx) {
                            // idx+1 because first column is the day name
                            final period = headers[idx + 1];
                            final classTitle = todayRow.length > idx + 1
                                ? todayRow[idx + 1]
                                : '';
                            if (classTitle == '-' || classTitle.isEmpty) {
                              return const SizedBox.shrink();
                            }

                            // Highlight current/next class
                            final timeMatch = RegExp(
                              r'\((.*?)\)',
                            ).firstMatch(period);
                            bool isCurrent = false;
                            if (timeMatch != null) {
                              final timeRange = timeMatch.group(1)!;
                              final startTimeStr = timeRange
                                  .split('-')[0]
                                  .trim();
                              final endTimeStr = timeRange.split('-')[1].trim();
                              try {
                                final start = DateFormat(
                                  'hh:mm a',
                                ).parse(startTimeStr);
                                final end = DateFormat(
                                  'hh:mm a',
                                ).parse(endTimeStr);
                                final startDateTime = DateTime(
                                  now.year,
                                  now.month,
                                  now.day,
                                  start.hour,
                                  start.minute,
                                );
                                final endDateTime = DateTime(
                                  now.year,
                                  now.month,
                                  now.day,
                                  end.hour,
                                  end.minute,
                                );
                                if (now.isAfter(startDateTime) &&
                                    now.isBefore(endDateTime)) {
                                  isCurrent = true;
                                }
                              } catch (_) {}
                            }

                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeInOutCubic,
                              decoration: BoxDecoration(
                                color: isCurrent
                                    ? Colors.cyanAccent.withValues(alpha: 0.12)
                                    : Colors.white.withValues(alpha: 0.03),
                                borderRadius: BorderRadius.circular(14),
                                border: isCurrent
                                    ? Border.all(
                                        color: Colors.cyanAccent,
                                        width: 1.5,
                                      )
                                    : null,
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 10,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isCurrent ? Icons.play_arrow : Icons.circle,
                                    color: isCurrent
                                        ? Colors.cyanAccent
                                        : Colors.white24,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      period,
                                      style: TextStyle(
                                        color: isCurrent
                                            ? Colors.cyanAccent
                                            : Colors.white,
                                        fontWeight: isCurrent
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      classTitle,
                                      style: TextStyle(
                                        color: isCurrent
                                            ? Colors.cyanAccent
                                            : Colors.white70,
                                        fontWeight: isCurrent
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 18),
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.cyanAccent,
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text("CLOSE"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sentiment_satisfied_alt,
            color: Colors.cyanAccent.withValues(alpha: 0.3),
            size: 70,
          ),
          const SizedBox(height: 20),
          const Text(
            "No classes remaining today!",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Enjoy your free time",
            style: TextStyle(
              color: Colors.cyanAccent.withValues(alpha: 0.7),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  const GlassCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.cyanAccent.withValues(alpha: 0.05),
            Colors.deepPurple.withValues(alpha: 0.07),
          ],
        ),
        border: Border.all(
          color: Colors.cyanAccent.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurpleAccent.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: child,
        ),
      ),
    );
  }
}
