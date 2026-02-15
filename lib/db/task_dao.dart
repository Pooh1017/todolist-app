import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sqflite/sqflite.dart';
import '../models/task.dart';
import 'app_db.dart';

class TaskDao {
  TaskDao._();
  static final TaskDao instance = TaskDao._();

  static const table = 'tasks';

  // ---------- helpers ----------
  String _uid() => FirebaseAuth.instance.currentUser?.uid ?? '';

  // ✅ สร้าง cloud_id แบบไม่ต้องพึ่ง package เพิ่ม
  // (พอสำหรับ unique ข้ามเครื่อง: เวลา + random)
  String _newCloudId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final r = Random.secure().nextInt(1 << 32).toRadixString(16).padLeft(8, '0');
    return 't_${now}_$r';
  }

  // ✅ normalize ก่อนเขียนลง DB:
  // - userId ต้องมี
  // - updatedAt ต้อง > 0
  // - cloudId ต้องมี (เพื่อหลายเครื่อง)
  // - syncState: เขียนจากเครื่อง = pending(1) เว้นแต่บอกมาเป็น 0 จาก cloud
  Task _normalizeForWrite(Task t, {bool fromCloud = false}) {
    final uid = _uid().trim();
    final now = DateTime.now().millisecondsSinceEpoch;

    final fixedUser = (t.userId.trim().isNotEmpty) ? t.userId.trim() : uid;

    // ✅ cloud_id: ถ้าไม่มีให้สร้าง
    final curCloudId = (t.cloudId).trim();
    final fixedCloudId = curCloudId.isNotEmpty ? curCloudId : _newCloudId();

    final fixedUpdatedAt = (t.updatedAt > 0) ? t.updatedAt : now;

    // ✅ ถ้ามาจาก cloud ให้ถือว่า synced(0) ตาม task.syncState ที่ส่งมา
    // ✅ ถ้าเป็น local write ให้ mark pending=1 เสมอ
    final fixedSync = fromCloud ? t.syncState : 1;

    return t.copyWith(
      userId: fixedUser,
      cloudId: fixedCloudId,
      updatedAt: fixedUpdatedAt,
      syncState: fixedSync,
    );
  }

  // ============================
  // CREATE
  // ============================
  Future<int> insert(Task task) async {
    final db = await AppDb.instance.db;
    final t = _normalizeForWrite(task, fromCloud: false);

    // ✅ insert แบบไม่ส่ง id (ให้ sqlite สร้าง)
    final map = t.toMap()..remove('id');

    return db.insert(
      table,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ============================
  // UPDATE (ใช้กับ UI ในเครื่องนี้)
  // ============================
  Future<int> update(Task task) async {
    final db = await AppDb.instance.db;

    if (task.id == null) {
      throw ArgumentError('Task.id ต้องไม่เป็น null');
    }

    final t = _normalizeForWrite(task, fromCloud: false);
    final map = t.toMap()..remove('id');

    // อัปเดตด้วย id (ของเครื่องนี้) แต่ล็อกด้วย user_id ด้วย
    return db.update(
      table,
      map,
      where: 'id = ? AND user_id = ?',
      whereArgs: [t.id, t.userId],
    );
  }

  // ✅ UI เรียก updateTask(...)
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

  // ✅ ให้ UI เรียก delete(id) ได้
  Future<int> delete(int id) => deleteById(id);

  Future<int> deleteById(int id) async {
    final uid = _uid().trim();
    final now = DateTime.now().millisecondsSinceEpoch;
    final db = await AppDb.instance.db;

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

  // ============================
  // GET
  // ============================
  // (เก็บไว้รองรับโค้ดเดิมบางจุด)
  Future<Task?> getById(int id, String uid) async {
    final db = await AppDb.instance.db;

    final rows = await db.query(
      table,
      where: 'id = ? AND user_id = ? AND deleted = 0',
      whereArgs: [id, uid],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return Task.fromMap(rows.first);
  }

  // ✅ สำคัญ: ใช้ตอน sync หลายเครื่อง
  Future<Task?> getByCloudId(String uid, String cloudId, {bool includeDeleted = true}) async {
    final db = await AppDb.instance.db;

    final rows = await db.query(
      table,
      where: includeDeleted
          ? 'user_id = ? AND cloud_id = ?'
          : 'user_id = ? AND cloud_id = ? AND deleted = 0',
      whereArgs: [uid, cloudId],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return Task.fromMap(rows.first);
  }

  Future<List<Task>> getAll([String? uid]) async {
    final db = await AppDb.instance.db;
    final theUid = (uid ?? _uid()).trim();

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
    final db = await AppDb.instance.db;
    final theUid = (uid ?? _uid()).trim();
    final query = q.trim();

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
  // TOGGLES (ยังใช้อิง id ในเครื่องนี้ได้)
  // ============================
  Future<void> toggleDone(Task t) async {
    final id = t.id;
    if (id == null) return;

    final db = await AppDb.instance.db;
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
    final id = t.id;
    if (id == null) return;

    final db = await AppDb.instance.db;
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
    final db = await AppDb.instance.db;
    final theUid = (uid ?? _uid()).trim();

    final rows = await db.query(
      table,
      where: 'user_id = ? AND sync_state = 1',
      whereArgs: [theUid],
      orderBy: 'updated_at ASC, id ASC',
    );

    return rows.map(Task.fromMap).toList();
  }

  // ✅ สำคัญ: synced ต้อง mark ด้วย cloud_id (ไม่ใช่ id)
  Future<void> markSynced(String uid, String cloudId) async {
    final db = await AppDb.instance.db;

    await db.update(
      table,
      {'sync_state': 0},
      where: 'user_id = ? AND cloud_id = ?',
      whereArgs: [uid, cloudId],
    );
  }

  // ✅ upsert จาก cloud ต้อง match ด้วย (user_id, cloud_id)
  Future<void> upsertFromCloud(Task task) async {
    final db = await AppDb.instance.db;

    // จาก cloud ต้องมี cloudId
    final t = _normalizeForWrite(task, fromCloud: true);
    if (t.cloudId.trim().isEmpty) return;

    // ไม่ส่ง id (ปล่อยให้ local id ของแต่ละเครื่องเป็นของตัวเอง)
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
