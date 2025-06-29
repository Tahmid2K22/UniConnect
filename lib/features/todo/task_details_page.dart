import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'todo_task.dart';

class TaskDetailsPage extends StatefulWidget {
  final TodoTask task;
  final int taskKey; // Hive key for the task

  const TaskDetailsPage({Key? key, required this.task, required this.taskKey})
    : super(key: key);

  @override
  State<TaskDetailsPage> createState() => _TaskDetailsPageState();
}

class _TaskDetailsPageState extends State<TaskDetailsPage> {
  bool isEditing = false;
  late TextEditingController titleController;
  late TextEditingController descController;
  DateTime? dueDate;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.task.title);
    descController = TextEditingController(text: widget.task.description ?? '');
    dueDate = widget.task.dueDate;
  }

  @override
  void dispose() {
    titleController.dispose();
    descController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    final box = Hive.box<TodoTask>('todoBox');
    final updatedTask = TodoTask(
      id: widget.task.id,
      title: titleController.text.trim(),
      description: descController.text.trim().isEmpty
          ? null
          : descController.text.trim(),
      dueDate: dueDate,
      isDone: widget.task.isDone,
      createdAt: widget.task.createdAt,
      completedAt: widget.task.completedAt,
    );
    box.put(widget.taskKey, updatedTask);
    setState(() => isEditing = false);
  }

  void _deleteTask() async {
    final box = Hive.box<TodoTask>('todoBox');
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.deepPurple.shade900.withValues(alpha: 0.92),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Delete Task',
          style: GoogleFonts.poppins(
            color: Colors.cyanAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this task?',
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
            style: TextButton.styleFrom(foregroundColor: Colors.white70),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await box.delete(widget.taskKey);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = Hive.box<TodoTask>('todoBox').get(widget.taskKey)!;
    final isOverdue =
        !task.isDone &&
        task.dueDate != null &&
        task.dueDate!.isBefore(DateTime.now());

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          isEditing ? 'Edit Task' : 'Task Details',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (!isEditing)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.cyanAccent),
              onPressed: () => setState(() => isEditing = true),
              tooltip: "Edit Task",
            ),
          if (!isEditing)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: _deleteTask,
              tooltip: "Delete Task",
            ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0E0E2C), Color(0xFF3A1C71)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: isEditing
                ? _buildEditCard(context)
                : _buildDetailsCard(context, task, isOverdue),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsCard(
    BuildContext context,
    TodoTask task,
    bool isOverdue,
  ) {
    return Container(
      key: const ValueKey('details'),
      width: MediaQuery.of(context).size.width * 0.92,
      constraints: const BoxConstraints(maxWidth: 500),
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: task.isDone
              ? Colors.green.withValues(alpha: 0.5)
              : isOverdue
              ? Colors.redAccent.withValues(alpha: 0.5)
              : Colors.white24,
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
        backgroundBlendMode: BlendMode.overlay,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
              fontSize: 24,
              fontWeight: FontWeight.bold,
              decoration: task.isDone
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
            ),
          ),
          const SizedBox(height: 12),
          if (task.description != null && task.description!.isNotEmpty)
            Text(
              task.description!,
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 18,
                color: Colors.cyanAccent.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 7),
              Text(
                task.dueDate != null
                    ? 'Due: ${task.dueDate!.toLocal().toString().split(' ')[0]}'
                    : 'No due date',
                style: GoogleFonts.poppins(
                  color: isOverdue ? Colors.redAccent : Colors.white70,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Icon(
                task.isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                color: task.isDone ? Colors.greenAccent : Colors.orangeAccent,
              ),
              const SizedBox(width: 7),
              Text(
                task.isDone ? 'Status: Done' : 'Status: Unfinished',
                style: GoogleFonts.poppins(
                  color: task.isDone ? Colors.greenAccent : Colors.orangeAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditCard(BuildContext context) {
    return Container(
      key: const ValueKey('edit'),
      width: MediaQuery.of(context).size.width * 0.92,
      constraints: const BoxConstraints(maxWidth: 500),
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.cyanAccent.withValues(alpha: 0.5),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
        backgroundBlendMode: BlendMode.overlay,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
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
          ),
          const SizedBox(height: 14),
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
            maxLines: 3,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  dueDate == null
                      ? 'No due date'
                      : 'Due: ${dueDate!.toLocal().toString().split(' ')[0]}',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 15,
                  ),
                ),
              ),
              TextButton(
                child: const Text('Pick Date'),
                style: TextButton.styleFrom(foregroundColor: Colors.cyanAccent),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: dueDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => dueDate = picked);
                },
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _saveChanges,
                child: const Text('Save Changes'),
              ),
              const SizedBox(width: 12),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.white70),
                onPressed: () => setState(() => isEditing = false),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
