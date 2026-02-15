class Subtask {
  final int? id;
  final int taskId;
  final String title;
  final bool done;

  // ✅ ใช้เรียงลำดับ (ตรงกับที่ TaskDetailPage ใช้)
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

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'task_id': taskId,
      'title': title,
      'done': done ? 1 : 0,
      'sort_order': sortOrder,
    };
  }

  static Subtask fromMap(Map<String, Object?> map) {
    return Subtask(
      id: map['id'] as int?,
      taskId: map['task_id'] as int,
      title: map['title'] as String,
      done: (map['done'] as int) == 1,
      sortOrder: (map['sort_order'] as int?) ?? 0,
    );
  }
}
