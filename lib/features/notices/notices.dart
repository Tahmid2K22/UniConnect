import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:uni_connect/firebase/firestore/database.dart';

class NoticesPage extends StatefulWidget {
  const NoticesPage({super.key});

  @override
  State<NoticesPage> createState() => _NoticesPageState();
}

class _NoticesPageState extends State<NoticesPage> {
  late Future<List<Map<String, dynamic>>> _noticesFuture;

  @override
  void initState() {
    super.initState();
    _noticesFuture = fetchNoticesFromFirestore();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E2C),
      appBar: AppBar(
        elevation: 10,
        backgroundColor: const Color(0xFF1A1A2E),
        iconTheme: const IconThemeData(
          color: Color.fromARGB(255, 255, 255, 255),
        ),
        centerTitle: true,
        title: ShaderMask(
          shaderCallback: (Rect bounds) {
            return const LinearGradient(
              colors: [
                Color.fromARGB(255, 255, 255, 255),
                Color.fromARGB(255, 255, 255, 255),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds);
          },
          child: const Text(
            'Notices',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: Colors.cyanAccent,
        backgroundColor: const Color(0xFF0E0E2C),
        onRefresh: () async {
          final fresh = await reloadNotices();
          setState(() {
            _noticesFuture = Future.value(fresh);
          });
        },
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _noticesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.cyanAccent),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  "Error loading notices: ${snapshot.error}",
                  style: GoogleFonts.poppins(
                    color: Colors.redAccent,
                    fontSize: 16,
                  ),
                ),
              );
            }
            final noticeList = snapshot.data ?? [];
            if (noticeList.isEmpty) {
              return Center(
                child: Text(
                  "No notices found.",
                  style: GoogleFonts.poppins(
                    color: Colors.white54,
                    fontSize: 16,
                  ),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(18),
              itemCount: noticeList.length,
              itemBuilder: (context, index) {
                final data = noticeList[index]['data'] ?? {};
                return Container(
                  margin: const EdgeInsets.only(bottom: 18),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.cyanAccent.withValues(alpha: 0.18),
                      width: 1.1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['title'] ?? "",
                        style: GoogleFonts.poppins(
                          color: Colors.cyanAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        data['desc'] ?? "",
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            color: Colors.white38,
                            size: 15,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            data['time'] ?? "",
                            style: GoogleFonts.poppins(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
