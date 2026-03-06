import 'package:sqflite/sqflite.dart';
import 'app_db.dart';

class PrivilegeDao {
  final AppDb _appDb = AppDb.instance;

  Future<Database> get _db async => _appDb.db;

  Future<int> insert(String name) async {
    final db = await _db;
    final value = name.trim();
    if (value.isEmpty) {
      throw ArgumentError('Privilege name must not be empty.');
    }

    return db.insert(
      'privileges',
      {'name': value},
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<int> update(int id, String name) async {
    final db = await _db;
    final value = name.trim();
    if (value.isEmpty) {
      throw ArgumentError('Privilege name must not be empty.');
    }

    return db.update(
      'privileges',
      {'name': value},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _db;

    // ถ้ามี user อ้างอยู่จะลบไม่ได้ตาม foreign key rule
    return db.delete(
      'privileges',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, Object?>>> search(String q) async {
    final db = await _db;
    final keyword = q.trim();

    return db.query(
      'privileges',
      where: 'name LIKE ?',
      whereArgs: ['%$keyword%'],
      orderBy: 'name ASC',
    );
  }

  Future<List<Map<String, Object?>>> getAll() async {
    final db = await _db;
    return db.query(
      'privileges',
      orderBy: 'name ASC',
    );
  }
}