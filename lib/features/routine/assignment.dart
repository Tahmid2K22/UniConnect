import 'package:flutter/material.dart';

import 'package:uni_connect/utils/AnimatedAssignmentCard.dart';

class AssignmentPage extends StatelessWidget {
  final List<List<String>> assignments;
  const AssignmentPage({super.key, required this.assignments});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        elevation: 10,
        backgroundColor: const Color(0xFF1A1A2E),
        iconTheme: const IconThemeData(
          color: Color.fromARGB(255, 255, 255, 255),
        ),
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
            'Assignments',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
              letterSpacing: 1.2,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0E0E2C), Color(0xFF0E0E2C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: assignments.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.assignment_turned_in,
                      color: Colors.cyanAccent.withValues(alpha: 0.5),
                      size: 70,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "No assignments or projects!",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(
                  vertical: 30,
                  horizontal: 10,
                ),
                itemCount: assignments.length,
                itemBuilder: (context, index) {
                  return AnimatedAssignmentCard(
                    key: ValueKey(index), // <-- Add this line
                    index: index,
                    title: 'Assignment ${index + 1}',
                    description: assignments[index][0],
                  );
                },
              ),
      ),
    );
  }
}

//Glass card utils
