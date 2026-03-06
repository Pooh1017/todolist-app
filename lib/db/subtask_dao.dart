import 'package:sqflite/sqflite.dart';
import '../models/subtask.dart';
import 'app_db.dart';

class SubtaskDao {
  SubtaskDao._();
  static final SubtaskDao instance = SubtaskDao._();

  static const String table = 'subtasks';

  Future<Database> get _db async => AppDb.instance.db;

  // ============================
  // INSERT
  // ============================
  Future<int> insert(Subtask s) async {
    final db = await _db;

    if (s.taskId == null) {
      throw ArgumentError('Subtask.taskId ต้องไม่เป็น null');
    }

    return db.insert(
      table,
      s.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ============================
  // UPDATE
  // ============================
  Future<int> update(Subtask s) async {
    final db = await _db;

    final id = s.id;
    if (id == null) {
      throw ArgumentError('Subtask.id ต้องไม่เป็น null ตอน update');
    }

    return db.update(
      table,
      s.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============================
  // DELETE
  // ============================
  Future<int> delete(int id) async {
    final db = await _db;

    return db.delete(
      table,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteByTask(int taskId) async {
    final db = await _db;

    return db.delete(
      table,
      where: 'task_id = ?',
      whereArgs: [taskId],
    );
  }

  // ============================
  // READ
  // ============================
  Future<List<Subtask>> getByTask(int taskId) async {
    final db = await _db;

    final rows = await db.query(
      table,
      where: 'task_id = ?',
      whereArgs: [taskId],
      orderBy: 'sort_order ASC, id ASC',
    );

    return rows.map(Subtask.fromMap).toList();
  }

  // ============================
  // TOGGLE DONE
  // ============================
  Future<void> toggleDone(Subtask s) async {
    await update(s.copyWith(done: !s.done));
  }

  // ============================
  // UPDATE SORT ORDER
  // ============================
  Future<void> updateSort(int id, int sortOrder) async {
    final db = await _db;

    await db.update(
      table,
      {'sort_order': sortOrder},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}