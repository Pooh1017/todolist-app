import 'package:sqflite/sqflite.dart';
import 'app_db.dart';

class PrivilegeDao {
  Future<Database> get _db async => AppDb.instance.db;

  Future<int> insert(String name) async {
    final db = await _db;
    return db.insert('privileges', {'name': name});
  }

  Future<int> update(int id, String name) async {
    final db = await _db;
    return db.update('privileges', {'name': name}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> delete(int id) async {
    final db = await _db;
    // ถ้ามี user อ้างอยู่จะลบไม่ได้ (RESTRICT)
    return db.delete('privileges', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, Object?>>> search(String q) async {
    final db = await _db;
    return db.query(
      'privileges',
      where: 'name LIKE ?',
      whereArgs: ['%$q%'],
      orderBy: 'name ASC',
    );
  }
}
