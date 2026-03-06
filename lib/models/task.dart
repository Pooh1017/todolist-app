// lib/models/task.dart
import 'dart:math';

class Task {
  final int? id; // local sqlite id (ไว้ map subtasks ได้)

  /// ✅ แยก user
  final String userId;

  /// ✅ คีย์ซิงก์ข้ามเครื่อง (ต้องไม่ซ้ำ)
  final String cloudId;

  final String title;
  final String category;
  final DateTime date;

  final bool starred;
  final bool done;

  final String note;

  /// ✅ sync fields
  final int updatedAt; // ms epoch
  final bool deleted;
  final int syncState; // 0=ok,1=pending

  Task({
    this.id,
    required String userId,
    required String cloudId,
    required String title,
    required String category,
    required this.date,
    this.starred = false,
    this.done = false,
    String note = '',
    int? updatedAt,
    this.deleted = false,
    this.syncState = 1,
  })  : userId = userId.trim(),
        cloudId = cloudId.trim().isEmpty ? genCloudId() : cloudId.trim(),
        title = title.trim(),
        category = category.trim(),
        note = note,
        updatedAt = (updatedAt != null && updatedAt > 0)
            ? updatedAt
            : DateTime.now().millisecondsSinceEpoch;

  /// ✅ generate cloudId
  static String genCloudId([String prefix = 't']) {
    final r = Random.secure();
    final ts = DateTime.now().microsecondsSinceEpoch;
    final a = r.nextInt(1 << 32).toRadixString(16).padLeft(8, '0');
    final b = r.nextInt(1 << 32).toRadixString(16).padLeft(8, '0');
    return '${prefix}_${ts}_$a$b';
  }

  /// ✅ สร้างงานใหม่ local
  factory Task.newLocal({
    required String userId,
    required String title,
    required String category,
    required DateTime date,
    String? cloudId,
    bool starred = false,
    bool done = false,
    String note = '',
  }) {
    return Task(
      userId: userId,
      cloudId: (cloudId ?? '').trim().isEmpty ? genCloudId() : cloudId!.trim(),
      title: title,
      category: category,
      date: date,
      starred: starred,
      done: done,
      note: note,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
      deleted: false,
      syncState: 1,
    );
  }

  Task copyWith({
    int? id,
    String? userId,
    String? cloudId,
    String? title,
    String? category,
    DateTime? date,
    bool? starred,
    bool? done,
    String? note,
    int? updatedAt,
    bool? deleted,
    int? syncState,
  }) {
    return Task(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      cloudId: cloudId ?? this.cloudId,
      title: title ?? this.title,
      category: category ?? this.category,
      date: date ?? this.date,
      starred: starred ?? this.starred,
      done: done ?? this.done,
      note: note ?? this.note,
      updatedAt: updatedAt ?? this.updatedAt,
      deleted: deleted ?? this.deleted,
      syncState: syncState ?? this.syncState,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'cloud_id': cloudId,
      'title': title,
      'category': category,
      'date_ms': date.millisecondsSinceEpoch,
      'starred': starred ? 1 : 0,
      'done': done ? 1 : 0,
      'note': note,
      'updated_at': updatedAt,
      'deleted': deleted ? 1 : 0,
      'sync_state': syncState,
    };
  }

  static Task fromMap(Map<String, Object?> map) {
    int asInt(Object? v, {int fallback = 0}) {
      if (v == null) return fallback;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? fallback;
      return fallback;
    }

    bool asBool(Object? v, {bool fallback = false}) {
      if (v == null) return fallback;
      if (v is bool) return v;
      if (v is int) return v == 1;
      if (v is num) return v.toInt() == 1;
      if (v is String) {
        final s = v.toLowerCase().trim();
        if (s == '1' || s == 'true') return true;
        if (s == '0' || s == 'false') return false;
      }
      return fallback;
    }

    String asString(Object? v, {String fallback = ''}) {
      if (v == null) return fallback;
      if (v is String) return v;
      return v.toString();
    }

    final userId = asString(map['user_id']).trim();
    final cloudId = asString(map['cloud_id']).trim();

    final dateMs = asInt(
      map['date_ms'],
      fallback: DateTime.now().millisecondsSinceEpoch,
    );
    final updatedAt = asInt(map['updated_at'], fallback: dateMs);

    return Task(
      id: map['id'] as int?,
      userId: userId,
      cloudId: cloudId.isEmpty ? genCloudId('migr') : cloudId,
      title: asString(map['title']),
      category: asString(map['category']),
      date: DateTime.fromMillisecondsSinceEpoch(dateMs),
      starred: asBool(map['starred']),
      done: asBool(map['done']),
      note: asString(map['note']),
      updatedAt: updatedAt,
      deleted: asBool(map['deleted']),
      syncState: asInt(map['sync_state'], fallback: 1),
    );
  }

  @override
  String toString() {
    return 'Task(id: $id, userId: $userId, cloudId: $cloudId, title: $title, category: $category, date: $date, starred: $starred, done: $done, deleted: $deleted, syncState: $syncState, updatedAt: $updatedAt)';
  }
}