import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:hive_flutter/hive_flutter.dart';

import 'todo_task.dart';
import 'task_details_page.dart';
import 'finished_tasks_page.dart';

import 'package:uni_connect/features/navigation/transition.dart';
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
        backgroundColor: const Color(0xFF0E0E2C),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                child: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  iconTheme: const IconThemeData(color: Colors.white),
                  title: Text(
                    'To-Do List',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  actions: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.repeat, color: Colors.cyanAccent),
                          tooltip: 'Manage Daily Tasks',
                          onPressed: _showDailyTasksDialog,
                        ),
                        SizedBox(width: 8),
                        IconButton(
                          icon: Icon(Icons.history, color: Colors.cyanAccent),
                          tooltip: 'View Finished Tasks',
                          onPressed: () {
                            Navigator.of(context).push(
                              NicePageRoute(page: const FinishedTasksPage()),
                            );
                          },
                        ),
                      ],
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
                            axis: Axis.vertical,
                            axisAlignment: 0.0,
                            child: _buildTaskTile(task, index, isOverdue),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),

        floatingActionButton: Stack(
          children: [
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 80.0, right: 18.0),
                child: FloatingActionButton(
                  heroTag: 'addDailyTasks',
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.cyanAccent,
                  onPressed: _addDailyTasksToTodo,
                  tooltip: 'Add Daily Tasks', // Implement this function below
                  child: Icon(Icons.playlist_add_check),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 18.0, right: 18.0),
                child: FloatingActionButton(
                  heroTag: 'addTask',
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.deepPurple,
                  onPressed: () => _showAddTaskDialog(context),
                  child: Icon(Icons.add, size: 32),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _refreshTasks({bool initial = false}) {
    final boxTasks = todoBox.values.where((t) => !t.isDone).toList();
    boxTasks.sort(_compareTasks);

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
          (context, animation) => FadeTransition(
            opacity: animation,
            child: _buildTaskTile(removedTask, i, _isOverdue(removedTask)),
          ),
          duration: const Duration(milliseconds: 400),
        );
      }
    }

    // Handle insertions
    for (int i = 0; i < boxTasks.length; i++) {
      if (i >= _tasks.length || _tasks[i] != boxTasks[i]) {
        _tasks.insert(i, boxTasks[i]);
        _listKey.currentState?.insertItem(
          i,
          duration: const Duration(milliseconds: 400),
        );
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
    final removedTask = _tasks[index];
    removedTask.isDone = val ?? false;
    if (removedTask.isDone) {
      removedTask.completedAt = DateTime.now();
      removedTask.save();

      // Animate fade-out, then remove from the list
      // For deletions (removals), use this in removeItem:

      _listKey.currentState?.removeItem(
        index,
        (context, animation) => SizeTransition(
          sizeFactor: animation,
          axis: Axis.vertical,
          axisAlignment: 0.0,
          child: _buildTaskTile(
            removedTask,
            0,
            _isOverdue(removedTask),
          ), // Use 0 or any fixed number here
        ),
        duration: const Duration(milliseconds: 400),
      );

      setState(() {
        _tasks.removeAt(index);
      });
    } else {
      removedTask.completedAt = null;
      removedTask.save();
    }
  }

  bool _isOverdue(TodoTask task) =>
      !task.isDone &&
      task.dueDate != null &&
      task.dueDate!.isBefore(DateTime.now());

  Widget _buildTaskTile(TodoTask task, int index, bool isOverdue) {
    return GestureDetector(
      onTap: () async {
        final key = todoBox.keys.firstWhere(
          (k) => todoBox.get(k) == task,
          orElse: () => null,
        );
        if (key != null) {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TaskDetailsPage(
                task: task,
                taskKey: key,
                isFinishedTask: false,
              ),
            ),
          );
        }

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

  void _showDailyTasksDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.deepPurple.shade900.withAlpha(235),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            'Manage Daily Tasks',
            style: GoogleFonts.poppins(
              color: Colors.cyanAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
              minWidth: 320,
              maxWidth: 400,
            ),
            child: SingleChildScrollView(child: DailyTasksEditor()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
            ),
          ],
        );
      },
    );
  }

  void _addDailyTasksToTodo() async {
    final dailyBox = Hive.box<TodoTask>('dailyTaskBox');
    final todoBox = Hive.box<TodoTask>('todoBox');
    final dailyTasks = dailyBox.values.toList();

    if (dailyTasks.isEmpty) {
      // Show toast if no daily tasks
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No daily tasks found!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    for (var task in dailyTasks) {
      todoBox.add(
        TodoTask(
          id: DateTime.now().millisecondsSinceEpoch,
          title: task.title,
          description: task.description,
          dueDate: task.dueDate,
          isDone: false,
        ),
      );
    }
    setState(() {});
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

class DailyTasksEditor extends StatefulWidget {
  const DailyTasksEditor({super.key});

  @override
  _DailyTasksEditorState createState() => _DailyTasksEditorState();
}

class _DailyTasksEditorState extends State<DailyTasksEditor> {
  late Box<TodoTask> dailyBox;
  List<TodoTask> _dailyTasks = [];

  @override
  void initState() {
    super.initState();
    dailyBox = Hive.box<TodoTask>('dailyTaskBox');
    _loadDailyTasks();
  }

  void _loadDailyTasks() {
    setState(() {
      _dailyTasks = dailyBox.values.toList();
    });
  }

  void _showAddDailyTaskDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    DateTime? selectedDueDate;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            backgroundColor: Colors.deepPurple.shade900.withAlpha(230),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: Text(
              'Add Daily Task',
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
                  dailyBox.add(newTask);
                  setState(() {});
                  Navigator.of(ctx).pop();
                  _loadDailyTasks();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _removeTask(int index) async {
    await dailyBox.deleteAt(index);
    _loadDailyTasks();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 340,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.deepPurple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(Icons.add),
              label: Text('Add New Daily Task'),
              onPressed: _showAddDailyTaskDialog,
            ),
          ),

          const SizedBox(height: 12),
          _dailyTasks.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Text(
                    'No daily tasks yet!',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _dailyTasks.length,
                  itemBuilder: (context, index) {
                    final task = _dailyTasks[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(20),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.cyanAccent.withAlpha(60),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              task.title,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () => _removeTask(index),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}
