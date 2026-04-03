import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data_models.dart';
import '../calendar_uitils.dart';
import 'note_dialog.dart';

class SemesterBreakdownPage extends StatelessWidget {
  final Semester semester;

  const SemesterBreakdownPage({super.key, required this.semester});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();

    // 1️⃣ Build list of events dynamically
    final List<Map<String, dynamic>> events = generateSemesterEvents(
      semester,
      today,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Semester Breakdown",
          style: GoogleFonts.poppins(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        ...events.map((e) {
          // Assign background color dynamically
          Color bgColor;
          switch (e['type'] as EventType) {
            case EventType.week:
              bgColor = e['isCompleted']
                  ? Colors.grey.shade800
                  : Colors.blue.shade600;
              break;
            case EventType.vacation:
              bgColor = e['isCompleted']
                  ? Colors.grey.shade800
                  : Colors.green.shade500;
              break;
            case EventType.pl:
              bgColor = e['isCompleted']
                  ? Colors.grey.shade800
                  : Colors.indigo.shade600;
              break;
            case EventType.finals:
              bgColor = e['isCompleted']
                  ? Colors.grey.shade800
                  : Colors.orange.shade600;
              break;
          }

          IconData icon;
          switch (e['type'] as EventType) {
            case EventType.week:
              icon = Icons.check_circle_outline;
              break;
            case EventType.vacation:
              icon = Icons.beach_access;
              break;
            case EventType.pl:
              icon = Icons.shield;
              break;
            case EventType.finals:
              icon = Icons.emoji_events;
              break;
          }

          final String eventTitle = e['title'];
          final bool isCompleted = e['isCompleted'];
          final List<String> notes = getEventNotes(eventTitle);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => EventNoteDialog(
                    eventTitle: eventTitle,
                    isCompleted: isCompleted,
                  ),
                ).then((_) {
                  // Re-render when dialog is closed to show updated note count
                  (context as Element).markNeedsBuild();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      bgColor.withValues(alpha: 0.85),
                      bgColor.withValues(alpha: 0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.1),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Icon(icon, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  eventTitle,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    decoration: isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                              ),
                              if (notes.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.push_pin_rounded,
                                        color: Colors.amberAccent,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "${notes.length}",
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "${(e['start'] as DateTime).day}/${(e['start'] as DateTime).month} - ${(e['end'] as DateTime).day}/${(e['end'] as DateTime).month}",
                            style: GoogleFonts.openSans(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
