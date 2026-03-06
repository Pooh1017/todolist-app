import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sqflite/sqflite.dart';

import '../models/task.dart';
import 'app_db.dart';

class TaskDao {
  TaskDao._();
  static final TaskDao instance = TaskDao._();

  static const String table = 'tasks';

  Future<Database> get _db async => AppDb.instance.db;

  // ============================
  // helpers
  // ============================
  String _uid() => FirebaseAuth.instance.currentUser?.uid?.trim() ?? '';

  String _newCloudId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final r =
        Random.secure().nextInt(1 << 32).toRadixString(16).padLeft(8, '0');
    return 't_${now}_$r';
  }

  Task _normalizeForWrite(Task t, {required bool fromCloud}) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final currentUid = _uid();

    final fixedUserId =
        t.userId.trim().isNotEmpty ? t.userId.trim() : currentUid;

    final currentCloudId = t.cloudId.trim();
    final fixedCloudId =
        currentCloudId.isNotEmpty ? currentCloudId : _newCloudId();

    final fixedUpdatedAt = t.updatedAt > 0 ? t.updatedAt : now;

    return t.copyWith(
      userId: fixedUserId,
      cloudId: fixedCloudId,
      updatedAt: fixedUpdatedAt,
      syncState: fromCloud ? 0 : 1,
    );
  }

  // ============================
  // CREATE
  // ============================
  Future<int> insert(Task task) async {
    final db = await _db;
    final t = _normalizeForWrite(task, fromCloud: false);

    if (t.userId.trim().isEmpty) {
      throw StateError('Cannot insert task: user_id is empty.');
    }

    final map = t.toMap()..remove('id');

    return db.insert(
      table,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ============================
  // UPDATE
  // ============================
  Future<int> update(Task task) async {
    final db = await _db;

    if (task.id == null) {
      throw ArgumentError('Task.id ต้องไม่เป็น null');
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final t = _normalizeForWrite(
      task.copyWith(updatedAt: now),
      fromCloud: false,
    );

    if (t.userId.trim().isEmpty) {
      throw StateError('Cannot update task: user_id is empty.');
    }

    final map = t.toMap()..remove('id');

    return db.update(
      table,
      map,
      where: 'id = ? AND user_id = ?',
      whereArgs: [t.id, t.userId],
    );
  }

  Future<int> updateTask(Task task) => update(task);

  // ============================
  // SOFT DELETE
  // ============================
  Future<int> deleteTask(Task task) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    return update(
      task.copyWith(
        deleted: true,
        syncState: 1,
        updatedAt: now,
      ),
    );
  }

  Future<int> delete(int id) => deleteById(id);

  Future<int> deleteById(int id) async {
    final db = await _db;
    final uid = _uid();
    final now = DateTime.now().millisecondsSinceEpoch;

    if (uid.isEmpty) return 0;

    return db.update(
      table,
      {
        'deleted': 1,
        'sync_state': 1,
        'updated_at': now,
      },
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, uid],
    );
  }

  Future<int> hardDeleteById(int id) async {
    final db = await _db;
    final uid = _uid();

    if (uid.isEmpty) return 0;

    return db.delete(
      table,
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, uid],
    );
  }

  // ============================
  // GET
  // ============================
  Future<Task?> getById(int id, String uid) async {
    final db = await _db;

    final rows = await db.query(
      table,
      where: 'id = ? AND user_id = ? AND deleted = 0',
      whereArgs: [id, uid.trim()],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return Task.fromMap(rows.first);
  }

  Future<Task?> getByCloudId(
    String uid,
    String cloudId, {
    bool includeDeleted = true,
  }) async {
    final db = await _db;

    final rows = await db.query(
      table,
      where: includeDeleted
          ? 'user_id = ? AND cloud_id = ?'
          : 'user_id = ? AND cloud_id = ? AND deleted = 0',
      whereArgs: [uid.trim(), cloudId.trim()],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return Task.fromMap(rows.first);
  }

  Future<List<Task>> getAll([String? uid]) async {
    final db = await _db;
    final theUid = (uid ?? _uid()).trim();

    if (theUid.isEmpty) return [];

    final rows = await db.query(
      table,
      where: 'user_id = ? AND deleted = 0',
      whereArgs: [theUid],
      orderBy: 'date_ms DESC, id DESC',
    );

    return rows.map(Task.fromMap).toList();
  }

  // ============================
  // SEARCH
  // ============================
  Future<List<Task>> search(String q, [String? uid]) async {
    final db = await _db;
    final theUid = (uid ?? _uid()).trim();
    final query = q.trim();

    if (theUid.isEmpty) return [];

    if (query.isEmpty) {
      final rows = await db.query(
        table,
        where: 'user_id = ? AND deleted = 0',
        whereArgs: [theUid],
        orderBy: 'updated_at DESC, id DESC',
      );
      return rows.map(Task.fromMap).toList();
    }

    final like = '%$query%';
    final rows = await db.query(
      table,
      where: '''
user_id = ? AND deleted = 0 AND (
  title LIKE ? OR note LIKE ? OR category LIKE ?
)
''',
      whereArgs: [theUid, like, like, like],
      orderBy: 'updated_at DESC, id DESC',
    );

    return rows.map(Task.fromMap).toList();
  }

  // ============================
  // TOGGLES
  // ============================
  Future<void> toggleDone(Task t) async {
    final db = await _db;
    final id = t.id;
    if (id == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;

    await db.update(
      table,
      {
        'done': t.done ? 0 : 1,
        'updated_at': now,
        'sync_state': 1,
      },
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, t.userId],
    );
  }

  Future<void> toggleStar(Task t) async {
    final db = await _db;
    final id = t.id;
    if (id == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;

    await db.update(
      table,
      {
        'starred': t.starred ? 0 : 1,
        'updated_at': now,
        'sync_state': 1,
      },
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, t.userId],
    );
  }

  // ============================
  // SYNC
  // ============================
  Future<List<Task>> getPending([String? uid]) async {
    final db = await _db;
    final theUid = (uid ?? _uid()).trim();

    if (theUid.isEmpty) return [];

    final rows = await db.query(
      table,
      where: 'user_id = ? AND sync_state = 1',
      whereArgs: [theUid],
      orderBy: 'updated_at ASC, id ASC',
    );

    return rows.map(Task.fromMap).toList();
  }

  Future<void> markSynced(String uid, String cloudId) async {
    final db = await _db;

    await db.update(
      table,
      {'sync_state': 0},
      where: 'user_id = ? AND cloud_id = ?',
      whereArgs: [uid.trim(), cloudId.trim()],
    );
  }

  Future<void> upsertFromCloud(Task task) async {
    final db = await _db;

    final t = _normalizeForWrite(task, fromCloud: true);
    if (t.userId.trim().isEmpty || t.cloudId.trim().isEmpty) return;

    final map = t.toMap()..remove('id');

    final count = await db.update(
      table,
      map,
      where: 'user_id = ? AND cloud_id = ?',
      whereArgs: [t.userId, t.cloudId],
    );

    if (count == 0) {
      await db.insert(
        table,
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }
}