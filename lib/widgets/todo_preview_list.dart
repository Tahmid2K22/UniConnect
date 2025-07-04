import 'package:flutter/material.dart';
import '../features/todo/todo_task.dart';
import 'glass_card.dart';

class TodoPreviewList extends StatelessWidget {
  final List<TodoTask> tasks;
  final VoidCallback onTap;
  const TodoPreviewList({super.key, required this.tasks, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return GestureDetector(
        onTap: onTap,
        child: GlassCard(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: const Text(
            "Add a task to get started!",
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }
    return Column(
      children: tasks.map((task) {
        return GestureDetector(
          onTap: onTap,
          child: SizedBox(
            width: double.infinity,
            child: GlassCard(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                task.title +
                    (task.dueDate != null
                        ? " (Due: ${task.dueDate!.toLocal().toString().split(' ')[0]})"
                        : ""),
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
