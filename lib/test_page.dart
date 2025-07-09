import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Mock data for demonstration
final mockUser = {'name': 'Alex', 'image': 'assets/profile/profile.jpg'};
final mockExam = {
  'title': 'Math Midterm',
  'date': '2025-07-10',
  'time': '10:00 AM',
};
final mockClass = {'subject': 'Physics', 'period': '10:30 AM - 12:00 PM'};
final mockTasks = [
  {'title': 'Finish Lab Report', 'due': '2025-07-06'},
  {'title': 'Read Chapter 7', 'due': '2025-07-07'},
  {'title': 'Group Project', 'due': '2025-07-08'},
  {'title': 'Assignment 3', 'due': '2025-07-09'},
];
final mockNotices = [
  {
    'title': 'Campus Closed Friday',
    'desc': 'Due to weather, campus will be closed this Friday.',
    'time': '2025-07-05 09:00',
  },
  {
    'title': 'Library Renovation',
    'desc': 'Library closed for renovation next week.',
    'time': '2025-07-04 15:30',
  },
  {
    'title': 'New Cafeteria Menu',
    'desc': 'Check out the new menu at the cafeteria!',
    'time': '2025-07-03 12:00',
  },
];

class FocusFrontPage extends StatelessWidget {
  const FocusFrontPage({super.key});

  @override
  Widget build(BuildContext context) {
    // For progress summary
    final int completedTasks = 1;
    final int totalTasks = mockTasks.length;

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E2C),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.cyan,
        tooltip: "Quick Add",
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top: User Avatar, App Name, Greeting
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: AssetImage(mockUser['image']!),
                    backgroundColor: Colors.cyanAccent.withOpacity(0.2),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "UniConnect",
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.cyanAccent,
                        ),
                      ),
                      Text(
                        "Good morning, ${mockUser['name']}!",
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Next Class Card
              _DashboardCard(
                icon: Icons.class_,
                color: Colors.green,
                title: "Next Class",
                titleValue: mockClass['subject'] ?? "",
                subtitle: mockClass['period'] ?? "",
                onTap: () {},
              ),
              const SizedBox(height: 12),

              // Upcoming Exam Card (calm color)
              _DashboardCard(
                icon: Icons.event,
                color: Colors.blueAccent,
                title: "Upcoming Exam",
                titleValue: mockExam['title'] ?? "",
                subtitle: "${mockExam['date']} • ${mockExam['time']}",
                onTap: () {},
              ),
              const SizedBox(height: 16),

              // Notices (horizontal scroll)
              Text(
                "Notices",
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 110,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: mockNotices
                      .map(
                        (notice) => _NoticeCard(
                          title: notice['title'] ?? "",
                          desc: notice['desc'] ?? "",
                          time: notice['time'] ?? "",
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Todo List (horizontal scroll)
              Text(
                "Todo",
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 90,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: mockTasks
                      .map(
                        (task) => _TodoCard(
                          title: task['title'] ?? "",
                          due: task['due'] ?? "",
                        ),
                      )
                      .toList(),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text(
                    "View all",
                    style: TextStyle(color: Colors.cyanAccent),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Task Graph (small, as a card)
              Card(
                color: Colors.white.withOpacity(0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 80,
                  child: Center(
                    child: Text(
                      "[Monthly Task Graph]",
                      style: GoogleFonts.poppins(
                        color: Colors.white38,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Progress Summary / Motivation
              Card(
                color: Colors.white.withOpacity(0.06),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.emoji_events,
                        color: Colors.amber.shade300,
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Today's Progress",
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "$completedTasks of $totalTasks tasks completed",
                              style: GoogleFonts.poppins(
                                color: Colors.cyanAccent,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              completedTasks == totalTasks
                                  ? "All done! 🎉"
                                  : (completedTasks > 0
                                        ? "Great progress, keep going!"
                                        : "Let's get started!"),
                              style: GoogleFonts.poppins(
                                color: Colors.white54,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 70),
            ],
          ),
        ),
      ),
    );
  }
}

// Dashboard Card Widget
class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String titleValue;
  final String subtitle;
  final VoidCallback onTap;
  const _DashboardCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.titleValue,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white.withOpacity(0.07),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      child: ListTile(
        leading: Icon(icon, color: color, size: 32),
        title: Text(
          title,
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titleValue,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

// Notice Card for horizontal scroll
class _NoticeCard extends StatelessWidget {
  final String title;
  final String desc;
  final String time;
  const _NoticeCard({
    required this.title,
    required this.desc,
    required this.time,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.09),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.cyanAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Text(
            time,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// Todo Card for horizontal scroll
class _TodoCard extends StatelessWidget {
  final String title;
  final String due;
  const _TodoCard({required this.title, required this.due});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.09),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.cyanAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Due: $due",
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const Spacer(),
          Align(
            alignment: Alignment.bottomRight,
            child: Icon(Icons.chevron_right, color: Colors.white24, size: 18),
          ),
        ],
      ),
    );
  }
}
