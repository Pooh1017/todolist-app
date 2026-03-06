class Subtask {
  final int? id;
  final int taskId;
  final String title;
  final bool done;

  // ✅ ใช้เรียงลำดับ
  final int sortOrder;

  const Subtask({
    this.id,
    required this.taskId,
    required this.title,
    this.done = false,
    this.sortOrder = 0,
  });

  Subtask copyWith({
    int? id,
    int? taskId,
    String? title,
    bool? done,
    int? sortOrder,
  }) {
    return Subtask(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      done: done ?? this.done,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  // ============================
  // SQLite map
  // ============================
  Map<String, Object?> toMap() {
    return {
      'id': id,
      'task_id': taskId,
      'title': title.trim(),
      'done': done ? 1 : 0,
      'sort_order': sortOrder,
    };
  }

  static Subtask fromMap(Map<String, Object?> map) {
    final doneVal = map['done'];

    bool doneBool;
    if (doneVal is int) {
      doneBool = doneVal == 1;
    } else if (doneVal is bool) {
      doneBool = doneVal;
    } else {
      doneBool = false;
    }

    return Subtask(
      id: map['id'] as int?,
      taskId: (map['task_id'] as num).toInt(),
      title: (map['title'] ?? '').toString(),
      done: doneBool,
      sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  String toString() {
    return 'Subtask(id: $id, taskId: $taskId, title: $title, done: $done, sortOrder: $sortOrder)';
  }
}