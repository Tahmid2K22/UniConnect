import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../features/calendar/data_models.dart';
import '../features/calendar/calendar_uitils.dart';
import '../utils/glass_card.dart';
import '../firebase/firestore/database.dart';

class AcademicCalendarWidget extends StatelessWidget {
  const AcademicCalendarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: fetchCalendarFromFirestore(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 180,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox(
            height: 180,
            child: Center(child: Text("No calendar data available")),
          );
        }

        // Convert Firestore -> Semester model
        final semester = Semester.fromMap(snapshot.data!);
        final today = DateTime.now();

        final status = getCurrentCalendarStatus(semester, today);
        final semesterProgress = status.heroProgress;

        final t = stripTime(today);
        final currentVacation = semester.vacations.firstWhere(
          (v) =>
              !t.isBefore(stripTime(v.startDate)) &&
              !t.isAfter(stripTime(v.endDate)),
          orElse: () =>
              Vacation(name: "", startDate: DateTime(0), endDate: DateTime(0)),
        );
        final isVacationActive = currentVacation.name.isNotEmpty;

        final nextVacation = semester.vacations.firstWhere(
          (v) => stripTime(v.startDate).isAfter(t),
          orElse: () =>
              Vacation(name: "", startDate: DateTime(0), endDate: DateTime(0)),
        );

        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/calendar'),
          child: SizedBox(
            height: 180,
            child: GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Header
                        Flexible(
                          child: Text(
                            status.heroTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.pressStart2p(
                              fontSize: 16,
                              color: Colors.cyanAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(height: 2),
                        // Subtitle
                        Flexible(
                          child: Text(
                            status.heroSubtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ),

                        // Active Notes
                        if (getEventNotes(status.heroTitle).isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: getEventNotes(status.heroTitle).map((
                                  note,
                                ) {
                                  return Container(
                                    margin: const EdgeInsets.only(right: 6),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amberAccent.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
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
                                          size: 10,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          note,
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: 10,
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

                        const SizedBox(height: 6),

                        // Progress
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: semesterProgress,
                            minHeight: 10,
                            color: Colors.cyanAccent,
                            backgroundColor: Colors.white10,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Info Boxes
                        Row(
                          children: [
                            _MiniInfoBox(
                              title: isVacationActive
                                  ? "Reopens in"
                                  : "Next Vacation",
                              value: isVacationActive
                                  ? "${stripTime(currentVacation.endDate).difference(t).inDays}d"
                                  : nextVacation.name.isNotEmpty
                                  ? "${stripTime(nextVacation.startDate).difference(t).inDays}d"
                                  : "-",
                            ),
                            _MiniInfoBox(
                              title: "Finals",
                              value: t.isBefore(stripTime(semester.finalsStart))
                                  ? "${stripTime(semester.finalsStart).difference(t).inDays}d"
                                  : t.isAfter(stripTime(semester.finalsEnd))
                                  ? "Done"
                                  : "Now",
                            ),
                            _MiniInfoBox(
                              title: "Progress",
                              value: "${(semesterProgress * 100).toInt()}%",
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MiniInfoBox extends StatelessWidget {
  final String title;
  final String value;

  const _MiniInfoBox({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white12,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 9,
                color: Colors.white60,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.cyanAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
