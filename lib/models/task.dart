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
    required this.title,
    required this.category,
    required this.date,
    this.starred = false,
    this.done = false,
    this.note = '',
    int? updatedAt,
    this.deleted = false,
    this.syncState = 1,
  })  : userId = userId.trim(),
        cloudId = (cloudId.trim().isEmpty ? genCloudId() : cloudId.trim()),
        updatedAt = (updatedAt != null && updatedAt > 0)
            ? updatedAt
            : DateTime.now().millisecondsSinceEpoch;

  /// ✅ generate cloudId (ไม่ต้องพึ่ง package)
  static String genCloudId([String prefix = 't']) {
    final r = Random();
    final ts = DateTime.now().microsecondsSinceEpoch;
    final a = r.nextInt(1 << 32).toRadixString(16);
    final b = r.nextInt(1 << 32).toRadixString(16);
    return '${prefix}_${ts}_$a$b';
  }

  /// ✅ สร้างงานใหม่ local (กันลืม cloudId/updatedAt/syncState)
  factory Task.newLocal({
    required String userId,
    required String title,
    required String category,
    required DateTime date,
    bool starred = false,
    bool done = false,
    String note = '',
  }) {
    return Task(
      userId: userId,
      cloudId: genCloudId(),
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
    int _asInt(Object? v, {int fallback = 0}) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? fallback;
      return fallback;
    }

    bool _asBool01(Object? v) => _asInt(v) == 1;

    String _asString(Object? v, {String fallback = ''}) {
      if (v == null) return fallback;
      if (v is String) return v;
      return v.toString();
    }

    final userId = _asString(map['user_id']).trim();
    final cloudId = _asString(map['cloud_id']).trim();

    final dateMs = _asInt(
      map['date_ms'],
      fallback: DateTime.now().millisecondsSinceEpoch,
    );
    final updatedAt = _asInt(map['updated_at'], fallback: dateMs);

    return Task(
      id: map['id'] as int?,
      userId: userId,
      cloudId: cloudId.isEmpty ? genCloudId('migr') : cloudId,
      title: _asString(map['title']),
      category: _asString(map['category']),
      date: DateTime.fromMillisecondsSinceEpoch(dateMs),
      starred: _asBool01(map['starred']),
      done: _asBool01(map['done']),
      note: _asString(map['note']),
      updatedAt: updatedAt,
      deleted: _asBool01(map['deleted']),
      syncState: _asInt(map['sync_state'], fallback: 1),
    );
  }
}
