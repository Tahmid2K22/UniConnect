import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:hive_flutter/hive_flutter.dart';

import 'todo_task.dart';
import 'task_details_page.dart';

class FinishedTasksPage extends StatefulWidget {
  const FinishedTasksPage({super.key});

  @override
  State<FinishedTasksPage> createState() => _FinishedTasksPageState();
}

class _FinishedTasksPageState extends State<FinishedTasksPage> {
  late Box<TodoTask> todoBox;
  late List<MapEntry<dynamic, TodoTask>> finishedTasks = [];
  GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();
    todoBox = Hive.box<TodoTask>('todoBox');
    _loadFinishedTasks();
    todoBox.listenable().addListener(_loadFinishedTasks);
  }

  @override
  void dispose() {
    todoBox.listenable().removeListener(_loadFinishedTasks);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradient = LinearGradient(
      colors: [
        const Color(0xFF00FFD0).withValues(alpha: 0.15),
        const Color(0xFF121232).withValues(alpha: 0.85),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF121232),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.cyanAccent),
        title: Text(
          'Finished Tasks',
          style: GoogleFonts.poppins(
            color: Colors.cyanAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: finishedTasks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 80,
                    color: Colors.cyanAccent.withValues(alpha: 0.4),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No finished tasks yet!',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Complete some tasks and they will appear here.',
                    style: GoogleFonts.poppins(
                      color: Colors.white38,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : Container(
              decoration: BoxDecoration(gradient: gradient),
              child: AnimatedList(
                key: _listKey,
                initialItemCount: finishedTasks.length,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                itemBuilder: (context, index, animation) {
                  final entry = finishedTasks[index];
                  return _buildTaskItem(entry, index, animation);
                },
              ),
            ),
    );
  }

  //Load finished tasks start ----------------------------------------------------------------------------------------------

  void _loadFinishedTasks() {
    final allEntries = todoBox.toMap().entries.toList();
    final newList = allEntries.where((entry) => entry.value.isDone).toList();
    setState(() {
      finishedTasks = newList;
      // Force AnimatedList to rebuild after external deletion
      _listKey = GlobalKey<AnimatedListState>();
    });
  }

  //Load finished tasks end ----------------------------------------------------------------------------------------------

  //Delete task utils
  Future<void> _deleteTaskWithWarning(int index) async {
    final entry = finishedTasks[index];
    final task = entry.value;
    final now = DateTime.now();
    final completedAt = task.completedAt ?? DateTime(2000);
    final completedDay = DateTime(
      completedAt.year,
      completedAt.month,
      completedAt.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    final daysSinceCompletion = today.difference(completedDay).inDays;

    bool canDelete = true;
    if (daysSinceCompletion <= 30) {
      canDelete =
          await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF222244),
              title: Text(
                'Warning',
                style: GoogleFonts.poppins(color: Colors.cyanAccent),
              ),
              content: Text(
                'This task was completed within the last 30 days.\n'
                'Deleting it will affect your 30-day progression data.\n'
                'Are you sure you want to delete it?',
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(color: Colors.cyanAccent),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    'Delete',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                ),
              ],
            ),
          ) ??
          false;
    }

    if (canDelete) {
      final removedItem = finishedTasks.removeAt(index);
      _listKey.currentState?.removeItem(
        index,
        (context, animation) => _buildTaskItem(removedItem, index, animation),
        duration: Duration(milliseconds: 500),
      );
      await todoBox.delete(entry.key);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Task deleted')));
    }
  }

  //Data format utils
  String _formatDate(DateTime? date) {
    if (date == null) return '';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final completedDate = DateTime(date.year, date.month, date.day);

    final diffDays = today.difference(completedDate).inDays;

    final timeStr =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    if (diffDays == 0) {
      return 'Today, $timeStr';
    } else if (diffDays == 1) {
      return 'Yesterday, $timeStr';
    } else {
      return '$diffDays days ago, $timeStr';
    }
  }

  //Build task items utils
  Widget _buildTaskItem(
    MapEntry<dynamic, TodoTask> entry,
    int index,
    Animation<double> animation,
  ) {
    final task = entry.value;
    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: GestureDetector(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TaskDetailsPage(
                  task: task,
                  taskKey: entry.key,
                  isFinishedTask: true,
                ),
              ),
            );
            if (result == 'deleted_finished') {
              _loadFinishedTasks();
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                colors: [
                  Colors.cyanAccent.withValues(alpha: 0.13),
                  Colors.white.withValues(alpha: 0.03),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyanAccent.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
              border: Border.all(
                color: Colors.cyanAccent.withValues(alpha: 0.18),
                width: 1.4,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyanAccent.withValues(alpha: 0.5),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: Colors.cyanAccent,
                  size: 32,
                ),
              ),
              title: Text(
                task.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.lineThrough,
                  letterSpacing: 0.2,
                ),
              ),
              subtitle: task.completedAt != null
                  ? Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: Colors.white38,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          _formatDate(task.completedAt),
                          style: GoogleFonts.poppins(
                            color: Colors.white38,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    )
                  : null,
              trailing: IconButton(
                icon: Icon(
                  Icons.delete_forever_rounded,
                  color: Colors.redAccent,
                  size: 28,
                ),
                tooltip: 'Delete task',
                onPressed: () => _deleteTaskWithWarning(index),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
