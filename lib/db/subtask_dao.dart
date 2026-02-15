import 'package:sqflite/sqflite.dart';
import '../models/subtask.dart';
import 'app_db.dart';

class SubtaskDao {
  SubtaskDao._();
  static final SubtaskDao instance = SubtaskDao._();

  static const table = 'subtasks';

  Future<int> insert(Subtask s) async {
    final db = await AppDb.instance.db;
    return db.insert(
      table,
      s.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> update(Subtask s) async {
    final db = await AppDb.instance.db;
    final id = s.id;
    if (id == null) throw ArgumentError('Subtask.id ต้องไม่เป็น null ตอน update');
    return db.update(
      table,
      s.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> delete(int id) async {
    final db = await AppDb.instance.db;
    return db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  // ✅ ตรงกับที่คุณเรียก: getByTask(id)
  Future<List<Subtask>> getByTask(int taskId) async {
    final db = await AppDb.instance.db;
    final rows = await db.query(
      table,
      where: 'task_id = ?',
      whereArgs: [taskId],
      orderBy: 'sort_order ASC, id ASC',
    );
    return rows.map(Subtask.fromMap).toList();
  }

  Future<void> toggleDone(Subtask s) async {
    await update(s.copyWith(done: !s.done));
  }
}
