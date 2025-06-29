import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'todo_task.dart';
import 'task_details_page.dart';
import 'package:uni_connect/features/navigation/side_navigation.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  late Box<TodoTask> todoBox;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late List<TodoTask> _tasks;

  @override
  void initState() {
    super.initState();
    todoBox = Hive.box<TodoTask>('todoBox');
    _tasks = [];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshTasks(initial: true);
    });
    todoBox.listenable().addListener(_refreshTasks);
  }

  @override
  void dispose() {
    todoBox.listenable().removeListener(_refreshTasks);
    super.dispose();
  }

  void _refreshTasks({bool initial = false}) {
    final boxTasks = todoBox.values.toList();
    boxTasks.sort(_compareTasks);

    // If initial, populate AnimatedList
    if (initial) {
      _tasks = List.from(boxTasks);
      for (int i = 0; i < _tasks.length; i++) {
        _listKey.currentState?.insertItem(i, duration: Duration.zero);
      }
      setState(() {});
      return;
    }

    // Handle deletions
    for (int i = _tasks.length - 1; i >= 0; i--) {
      final task = _tasks[i];
      if (!boxTasks.contains(task)) {
        final removedTask = _tasks.removeAt(i);
        _listKey.currentState?.removeItem(
          i,
          (context, animation) => SizeTransition(
            sizeFactor: animation,
            child: _buildTaskTile(removedTask, i, _isOverdue(removedTask)),
          ),
        );
      }
    }

    // Handle insertions
    for (int i = 0; i < boxTasks.length; i++) {
      if (i >= _tasks.length || _tasks[i] != boxTasks[i]) {
        _tasks.insert(i, boxTasks[i]);
        _listKey.currentState?.insertItem(i);
      }
    }

    setState(() {});
  }

  int _compareTasks(TodoTask a, TodoTask b) {
    if (a.isDone != b.isDone) return a.isDone ? 1 : -1;
    if (a.title != b.title) return a.title.compareTo(b.title);
    if (a.dueDate != null && b.dueDate != null) {
      return a.dueDate!.compareTo(b.dueDate!);
    }
    return 0;
  }

  void _onCheckboxChanged(bool? val, int index) {
    final oldTask = _tasks[index];
    setState(() {
      oldTask.isDone = val ?? false;
      if (oldTask.isDone) {
        oldTask.completedAt = DateTime.now();
      } else {
        oldTask.completedAt = null;
      }
      oldTask.save();

      // Remove from old position
      final removedTask = _tasks.removeAt(index);
      _listKey.currentState?.removeItem(
        index,
        (context, animation) => SizeTransition(
          sizeFactor: animation,
          child: _buildTaskTile(removedTask, index, _isOverdue(removedTask)),
        ),
        duration: const Duration(milliseconds: 300),
      );

      // Find new sorted position
      final newIndex = _tasks.indexWhere(
        (t) => _compareTasks(removedTask, t) < 0,
      );
      final insertAt = newIndex == -1 ? _tasks.length : newIndex;
      _tasks.insert(insertAt, removedTask);
      _listKey.currentState?.insertItem(
        insertAt,
        duration: const Duration(milliseconds: 300),
      );
    });
  }

  bool _isOverdue(TodoTask task) =>
      !task.isDone &&
      task.dueDate != null &&
      task.dueDate!.isBefore(DateTime.now());

  Widget _buildTaskTile(TodoTask task, int index, bool isOverdue) {
    return GestureDetector(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                TaskDetailsPage(task: task, taskKey: todoBox.keyAt(index)),
          ),
        );
        // After returning from details, refresh to avoid index errors
        _refreshTasks();
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: task.isDone
                ? Colors.green.withValues(alpha: 0.5)
                : isOverdue
                ? Colors.redAccent.withValues(alpha: 0.5)
                : Colors.white24,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.17),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
          backgroundBlendMode: BlendMode.overlay,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: task.isDone,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              activeColor: Colors.cyanAccent,
              checkColor: Colors.deepPurple,
              onChanged: (val) => _onCheckboxChanged(val, index),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: GoogleFonts.poppins(
                      color: task.isDone
                          ? Colors.greenAccent
                          : isOverdue
                          ? Colors.redAccent
                          : Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      decoration: task.isDone
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  if (task.description != null && task.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        task.description!,
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 15,
                          color: Colors.cyanAccent.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          task.dueDate != null
                              ? 'Due: ${task.dueDate!.toLocal().toString().split(' ')[0]}'
                              : 'No due date',
                          style: GoogleFonts.poppins(
                            color: isOverdue
                                ? Colors.redAccent
                                : Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        if (details.delta.dx < -10) {
          _scaffoldKey.currentState?.openEndDrawer();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        endDrawer: const SideNavigation(),
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/background/background3.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                  child: Row(
                    children: [
                      Text(
                        'To-Do List',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _tasks.isEmpty
                      ? Center(
                          child: Text(
                            'No tasks yet!\nTap + to add one.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 18,
                            ),
                          ),
                        )
                      : AnimatedList(
                          key: _listKey,
                          initialItemCount: _tasks.length,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 6,
                          ),
                          itemBuilder: (context, index, animation) {
                            if (index >= _tasks.length) return const SizedBox();
                            final task = _tasks[index];
                            final isOverdue = _isOverdue(task);
                            return SizeTransition(
                              sizeFactor: animation,
                              child: _buildTaskTile(task, index, isOverdue),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.cyanAccent,
          foregroundColor: Colors.deepPurple,
          elevation: 6,
          onPressed: () => _showAddTaskDialog(context),
          child: const Icon(Icons.add, size: 32),
        ),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    DateTime? selectedDueDate;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            backgroundColor: Colors.deepPurple.shade900.withValues(alpha: 0.92),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: Text(
              'Add New Task',
              style: GoogleFonts.poppins(
                color: Colors.cyanAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    style: GoogleFonts.poppins(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Title *',
                      labelStyle: TextStyle(color: Colors.cyanAccent),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.cyanAccent),
                      ),
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descController,
                    style: GoogleFonts.poppins(color: Colors.white70),
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      labelStyle: TextStyle(color: Colors.cyanAccent),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.cyanAccent),
                      ),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          selectedDueDate == null
                              ? 'No due date'
                              : 'Due: ${selectedDueDate!.toLocal().toString().split(' ')[0]}',
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.cyanAccent,
                        ),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() {
                              selectedDueDate = picked;
                            });
                          }
                        },
                        child: const Text('Pick Date'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.white70),
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Add'),
                onPressed: () {
                  if (titleController.text.trim().isEmpty) return;
                  final newTask = TodoTask(
                    id: DateTime.now().millisecondsSinceEpoch,
                    title: titleController.text.trim(),
                    description: descController.text.trim().isEmpty
                        ? null
                        : descController.text.trim(),
                    dueDate: selectedDueDate,
                    isDone: false,
                  );
                  todoBox.add(newTask);
                  // The listener will update the UI and AnimatedList
                  Navigator.of(ctx).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
