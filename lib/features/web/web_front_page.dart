import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uni_connect/features/web/web_layout.dart';
import 'package:uni_connect/utils/glass_card.dart';
import 'package:uni_connect/firebase/firestore/database.dart';
import 'package:uni_connect/utils/front_page_utils.dart';
import 'package:uni_connect/models/data_model.dart';
import 'package:uni_connect/features/routine/collect_data.dart';
import 'package:uni_connect/utils/notice_card.dart';
import 'dart:convert';

class WebFrontPage extends StatefulWidget {
  const WebFrontPage({super.key});

  @override
  State<WebFrontPage> createState() => _WebFrontPageState();
}

class _WebFrontPageState extends State<WebFrontPage> {
  Map<String, dynamic>? userProfile;
  DataModel? nextClass;
  List<Map<String, dynamic>>? _notices;
  List<Map<String, dynamic>>? _exams;
  List<Map<String, dynamic>>? _calendarEvents;
  Map<String, dynamic>? _ctMarksData;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    try {
      final profile = await loadUserProfile();
      final notices = await fetchNoticesFromFirestore();
      final exams = await fetchExamsFromFirestore();
      final calendar = await fetchCalendarFromFirestore();

      print('📊 Dashboard Data Loaded:');
      print('Profile: ${profile != null}');
      print('Notices: ${notices.length}');
      print('Exams: ${exams.length}');
      print('Calendar: ${calendar != null}');

      setState(() {
        userProfile = profile;
        _notices = notices;
        _exams = exams;
        _calendarEvents = calendar != null ? [calendar] : null;
      });

      if (profile != null) {
        _loadRoutine(profile['roll']);
        await _loadCtMarks(profile);
      }
    } catch (e) {
      print('❌ Error loading dashboard data: $e');
    }
  }

  Future<void> _loadCtMarks(Map<String, dynamic> profile) async {
    try {
      final ctMarksRaw = profile['ct_marks'];
      final Map<String, List<List<num>>> courses = {};

      if (ctMarksRaw == null) {
        print('⚠️ No CT marks data in profile');
        setState(() {
          _ctMarksData = {'courses': {}};
        });
        return;
      }

      // Convert to proper Map type
      final Map<String, dynamic> ctMarks = Map<String, dynamic>.from(
        ctMarksRaw as Map,
      );

      for (final entry in ctMarks.entries) {
        final key = entry.key;
        final value = entry.value;
        final match = RegExp(r'^(.+)_CT(\d+)_(\d+)$').firstMatch(key);

        if (match == null) continue;

        final courseName = match.group(1)!;
        final ctNumber = int.parse(match.group(2)!);
        final totalMark = num.parse(match.group(3)!);

        final obtained = (value as List).isNotEmpty ? value[0] as num : 0;

        if (!courses.containsKey(courseName)) {
          courses[courseName] = [];
        }
        while (courses[courseName]!.length < ctNumber) {
          courses[courseName]!.add([0, totalMark]);
        }
        courses[courseName]![ctNumber - 1] = [obtained, totalMark];
      }

      print('📈 CT Marks courses: ${courses.length}');

      if (mounted) {
        setState(() {
          _ctMarksData = {'courses': courses};
        });
      }
    } catch (e) {
      print('❌ Error loading CT marks: $e');
      setState(() {
        _ctMarksData = {'courses': {}};
      });
    }
  }

  Future<void> _loadRoutine(String? roll) async {
    if (roll == null) return;
    final routine =
        await RoutineCache.loadRoutine() ?? await CollectData.collectAllData();
    await RoutineCache.saveRoutine(routine);

    final rollInt = int.tryParse(roll) ?? 0;
    final isSectionA = rollInt >= 2207001 && rollInt <= 2207060;
    final sheetKey = isSectionA ? 'sheet1' : 'sheet2';

    final nextList = getTodayNextClass(routine[sheetKey] ?? []);

    if (mounted) {
      setState(() {
        nextClass = nextList.isNotEmpty
            ? nextList.first
            : DataModel(
                period: 'Relax',
                data: 'No classes scheduled',
                endTime: '',
              );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WebLayout(
      currentRoute: '/frontpage',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 768;
          final isTablet =
              constraints.maxWidth >= 768 && constraints.maxWidth < 1024;
          final sectionSpacing = isMobile ? 16.0 : (isTablet ? 20.0 : 24.0);
          final pagePadding =
              EdgeInsets.all(isMobile ? 16 : (isTablet ? 24 : 32));

          if (isMobile) {
            // Mobile: Single column layout
            return SingleChildScrollView(
              padding: pagePadding,
              child: Column(
                children: [
                  _WebProfileCard(userProfile: userProfile),
                  SizedBox(height: sectionSpacing),
                  _NextClassCard(
                    nextClass: nextClass,
                    userRoll: userProfile?['roll'],
                  ),
                  SizedBox(height: sectionSpacing),
                  _QuickActionsCard(),
                  SizedBox(height: sectionSpacing),
                  _QuickAnalyticsCard(
                    ctMarksData: _ctMarksData,
                    userProfile: userProfile,
                  ),
                  SizedBox(height: sectionSpacing),
                  _UpcomingExamsCard(exams: _exams),
                  SizedBox(height: sectionSpacing),
                  _BriefCalendarCard(calendarEvents: _calendarEvents),
                  SizedBox(height: sectionSpacing),
                  _NoticesSection(notices: _notices),
                ],
              ),
            );
          } else if (isTablet) {
            // Tablet: Two column layout
            return SingleChildScrollView(
              padding: pagePadding,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _WebProfileCard(userProfile: userProfile),
                        SizedBox(height: sectionSpacing),
                        _QuickActionsCard(),
                        SizedBox(height: sectionSpacing),
                        _NextClassCard(
                          nextClass: nextClass,
                          userRoll: userProfile?['roll'],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: sectionSpacing),
                  Expanded(
                    child: Column(
                      children: [
                        _QuickAnalyticsCard(
                          ctMarksData: _ctMarksData,
                          userProfile: userProfile,
                        ),
                        SizedBox(height: sectionSpacing),
                        _UpcomingExamsCard(exams: _exams),
                        SizedBox(height: sectionSpacing),
                        _BriefCalendarCard(calendarEvents: _calendarEvents),
                        SizedBox(height: sectionSpacing),
                        _NoticesSection(notices: _notices),
                      ],
                    ),
                  ),
                ],
              ),
            );
          } else {
            // Desktop: Three column layout (original)
            return SingleChildScrollView(
              padding: pagePadding,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column: Profile & Quick Actions (25%)
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        _WebProfileCard(userProfile: userProfile),
                        SizedBox(height: sectionSpacing),
                        _QuickActionsCard(),
                      ],
                    ),
                  ),
                  SizedBox(width: sectionSpacing),

                  // Center Column: Routine & Notices (45%)
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        _NextClassCard(
                          nextClass: nextClass,
                          userRoll: userProfile?['roll'],
                        ),
                        SizedBox(height: sectionSpacing),
                        _NoticesSection(notices: _notices),
                      ],
                    ),
                  ),
                  SizedBox(width: sectionSpacing),

                  // Right Column: Analytics, Exams & Calendar (30%)
                  Expanded(
                    flex: 4,
                    child: Column(
                      children: [
                        _QuickAnalyticsCard(
                          ctMarksData: _ctMarksData,
                          userProfile: userProfile,
                        ),
                        SizedBox(height: sectionSpacing),
                        _UpcomingExamsCard(exams: _exams),
                        SizedBox(height: sectionSpacing),
                        _BriefCalendarCard(calendarEvents: _calendarEvents),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}

class _WebProfileCard extends StatelessWidget {
  final Map<String, dynamic>? userProfile;

  const _WebProfileCard({required this.userProfile});

  @override
  Widget build(BuildContext context) {
    final isLoading = userProfile == null;

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.tealAccent[400],
              backgroundImage:
                  userProfile != null && userProfile!['profile_pic'] != null
                  ? MemoryImage(base64Decode(userProfile!['profile_pic']))
                  : null,
              child: isLoading
                  ? const CircularProgressIndicator()
                  : (userProfile!['profile_pic'] == null
                        ? const Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.black,
                          )
                        : null),
            ),
            const SizedBox(height: 16),
            Text(
              isLoading ? 'Loading profile...' : (userProfile?['name'] ?? ''),
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isLoading
                  ? 'Fetching your details'
                  : (userProfile?['university'] ?? ''),
              style: GoogleFonts.poppins(
                color: Colors.tealAccent[400],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              isLoading
                  ? 'Please wait a moment'
                  : '${userProfile?['department'] ?? ''} • Roll: ${userProfile?['roll'] ?? ''}',
              style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () => Navigator.pushNamed(context, '/profile'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('View Full Profile'),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _ActionButton(
                  icon: Icons.calendar_month,
                  label: 'Calendar',
                  onTap: () => Navigator.pushNamed(context, '/calendar'),
                ),
                _ActionButton(
                  icon: Icons.analytics,
                  label: 'Analytics',
                  onTap: () => Navigator.pushNamed(context, '/analytics'),
                ),
                _ActionButton(
                  icon: Icons.people_alt,
                  label: 'Teachers',
                  onTap: () => Navigator.pushNamed(context, '/teachers'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: const BoxConstraints(minWidth: 90),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.tealAccent[400], size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NextClassCard extends StatelessWidget {
  final DataModel? nextClass;
  final String? userRoll;

  const _NextClassCard({required this.nextClass, required this.userRoll});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Next Class',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Icon(Icons.class_outlined, color: Colors.tealAccent[400]),
              ],
            ),
            const SizedBox(height: 16),
            if (nextClass == null)
              const Center(child: CircularProgressIndicator())
            else ...[
              Text(
                filterClassForUser(nextClass!.data, userRoll ?? '0') ??
                    'No classes',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                nextClass!.period,
                style: GoogleFonts.poppins(
                  color: Colors.tealAccent[400],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pushNamed(context, '/routine'),
                child: const Text('View Full Routine'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoticesSection extends StatelessWidget {
  final List<Map<String, dynamic>>? notices;

  const _NoticesSection({required this.notices});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Latest Notices',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  '${notices?.length ?? 0}',
                  style: GoogleFonts.poppins(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (notices == null)
              _EmptyStateMessage(
                icon: Icons.notifications_active_outlined,
                title: 'Loading notices',
                subtitle: 'Fetching the latest updates',
              )
            else if (notices!.isEmpty)
              _EmptyStateMessage(
                icon: Icons.notifications_off_outlined,
                title: 'No notices yet',
                subtitle: 'Check back later for updates',
              )
            else
              Column(
                children: notices!.take(3).map((notice) {
                  final data = notice['data'] ?? {};
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: NoticeCard(
                      title: data['title'] ?? '',
                      desc: data['desc'] ?? '',
                      time: data['time'] ?? '',
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _QuickAnalyticsCard extends StatelessWidget {
  final Map<String, dynamic>? ctMarksData;
  final Map<String, dynamic>? userProfile;

  const _QuickAnalyticsCard({
    required this.ctMarksData,
    required this.userProfile,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Quick Analytics',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Icon(
                  Icons.analytics_outlined,
                  color: Colors.tealAccent[400],
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (userProfile != null && userProfile!['cgpa_list'] != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Current CGPA',
                    style: GoogleFonts.poppins(
                      color: Colors.white54,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '${(userProfile!['cgpa_list'] as List).last.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      color: Colors.tealAccent[400],
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            if (ctMarksData != null &&
                (ctMarksData!['courses'] as Map).isNotEmpty) ...[
              Text(
                'Recent CT Performance',
                style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 8),
              ..._buildCtSummary(),
            ] else ...[
              Text(
                'No CT data available',
                style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13),
              ),
            ],
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pushNamed(context, '/analytics'),
                child: const Text('View Full Analytics'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCtSummary() {
    final courses = ctMarksData!['courses'] as Map<String, List<List<num>>>;
    final widgets = <Widget>[];

    int count = 0;
    for (final entry in courses.entries) {
      if (count >= 2) break;
      final courseName = entry.key.length > 15
          ? '${entry.key.substring(0, 12)}...'
          : entry.key;
      final cts = entry.value;

      num total = 0;
      num obtained = 0;
      for (final ct in cts) {
        obtained += ct[0];
        total += ct[1];
      }

      final percentage = total > 0 ? (obtained / total * 100).round() : 0;

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  courseName,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$percentage%',
                style: GoogleFonts.poppins(
                  color: percentage >= 70
                      ? Colors.greenAccent
                      : (percentage >= 50 ? Colors.orange : Colors.redAccent),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
      count++;
    }

    return widgets;
  }
}

class _UpcomingExamsCard extends StatelessWidget {
  final List<Map<String, dynamic>>? exams;

  const _UpcomingExamsCard({required this.exams});

  @override
  Widget build(BuildContext context) {
    final upcomingExam = _getNextExam();

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Upcoming Exam',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Icon(
                  Icons.event_note_outlined,
                  color: Colors.tealAccent[400],
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (exams == null)
              _EmptyStateMessage(
                icon: Icons.event_note_outlined,
                title: 'Loading exams',
                subtitle: 'Syncing the exam schedule',
              )
            else if (upcomingExam != null) ...[
              Text(
                upcomingExam['title'] ?? '',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                upcomingExam['date'] ?? '',
                style: GoogleFonts.poppins(
                  color: Colors.tealAccent[400],
                  fontSize: 13,
                ),
              ),
              if (upcomingExam['daysLeft'] != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getDaysColor(upcomingExam['daysLeft']),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    upcomingExam['daysLeft'] == 0
                        ? 'Today'
                        : '${upcomingExam['daysLeft']} days left',
                    style: GoogleFonts.poppins(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ] else ...[
              _EmptyStateMessage(
                icon: Icons.event_busy_outlined,
                title: 'No upcoming exams',
                subtitle: 'You are all caught up',
              ),
            ],
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pushNamed(context, '/exam'),
                child: const Text('View All Exams'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic>? _getNextExam() {
    if (exams == null || exams!.isEmpty) return null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    Map<String, dynamic>? nextExam;
    int minDays = 9999;

    for (final exam in exams!) {
      final data = exam['data'] ?? {};
      final dateStr = data['date'];
      if (dateStr == null) continue;

      try {
        final examDate = DateTime.parse(dateStr);
        final daysUntil = examDate.difference(today).inDays;

        if (daysUntil >= 0 && daysUntil < minDays) {
          minDays = daysUntil;
          nextExam = {
            'title': data['title'],
            'date': data['date'],
            'time': data['time'],
            'daysLeft': daysUntil,
          };
        }
      } catch (e) {
        continue;
      }
    }

    return nextExam;
  }

  Color _getDaysColor(int daysLeft) {
    if (daysLeft <= 1) return Colors.redAccent;
    if (daysLeft <= 3) return Colors.orange;
    return Colors.greenAccent;
  }
}

class _BriefCalendarCard extends StatelessWidget {
  final List<Map<String, dynamic>>? calendarEvents;

  const _BriefCalendarCard({required this.calendarEvents});

  @override
  Widget build(BuildContext context) {
    final nextEvent = _getNextEvent();

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Academic Calendar',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Icon(
                  Icons.calendar_today_outlined,
                  color: Colors.tealAccent[400],
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (calendarEvents == null)
              _EmptyStateMessage(
                icon: Icons.calendar_today_outlined,
                title: 'Loading calendar',
                subtitle: 'Preparing your semester dates',
              )
            else if (nextEvent != null) ...[
              Text(
                nextEvent['title'] ?? '',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                nextEvent['subtitle'] ?? '',
                style: GoogleFonts.poppins(
                  color: Colors.tealAccent[400],
                  fontSize: 13,
                ),
              ),
            ] else ...[
              _EmptyStateMessage(
                icon: Icons.event_busy_outlined,
                title: 'No calendar data',
                subtitle: 'Add important dates to stay ahead',
              ),
            ],
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pushNamed(context, '/calendar'),
                child: const Text('View Full Calendar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic>? _getNextEvent() {
    if (calendarEvents == null || calendarEvents!.isEmpty) return null;

    final cal = calendarEvents!.first;
    final now = DateTime.now();

    // Try to parse semester dates
    try {
      final semesterStart = DateTime.parse(cal['semester_start'] ?? '');
      final plStart = DateTime.parse(cal['pl_start'] ?? '');
      final finalsStart = DateTime.parse(cal['finals_start'] ?? '');

      if (now.isBefore(semesterStart)) {
        final daysLeft = semesterStart.difference(now).inDays;
        return {
          'title': 'Semester Starting',
          'subtitle': '$daysLeft days until semester starts',
        };
      } else if (now.isBefore(plStart)) {
        final daysLeft = plStart.difference(now).inDays;
        return {
          'title': 'PL Break Approaching',
          'subtitle': '$daysLeft days until PL break',
        };
      } else if (now.isBefore(finalsStart)) {
        final daysLeft = finalsStart.difference(now).inDays;
        return {
          'title': 'Finals Approaching',
          'subtitle': '$daysLeft days until finals',
        };
      }
    } catch (e) {
      // Parsing failed
    }

    return {'title': 'Semester In Progress', 'subtitle': 'Stay focused!'};
  }
}

class _EmptyStateMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyStateMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white70, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
