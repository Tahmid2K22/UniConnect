import 'package:hive/hive.dart';

part 'todo_task.g.dart';

@HiveType(typeId: 0)
class TodoTask extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? description;

  @HiveField(3)
  DateTime? dueDate;

  @HiveField(4)
  bool isDone;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  DateTime? completedAt;

  TodoTask({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.isDone = false,
    DateTime? createdAt,
    this.completedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'dueDate': dueDate?.toIso8601String(),
    'isDone': isDone,
    'createdAt': createdAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
  };

  factory TodoTask.fromJson(Map<String, dynamic> json) => TodoTask(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
    isDone: json['isDone'],
    createdAt: DateTime.parse(json['createdAt']),
    completedAt: json['completedAt'] != null
        ? DateTime.parse(json['completedAt'])
        : null,
  );
}
