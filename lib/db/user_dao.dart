import 'package:sqflite/sqflite.dart';
import 'app_db.dart';

class UserDao {
  Future<Database> get _db async => AppDb.instance.db;

  Future<int> insert({
    required String displayName,
    String? email,
    required int privilegeId,
  }) async {
    final db = await _db;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    return db.insert('users', {
      'display_name': displayName,
      'email': email,
      'privilege_id': privilegeId,
      'created_at_ms': nowMs,   // ✅ required (NOT NULL)
      'last_login_ms': nowMs,   // (optional แต่ใส่ไว้ก็ดี)
    });
  }

  Future<int> update({
    required int id,
    required String displayName,
    String? email,
    required int privilegeId,
  }) async {
    final db = await _db;

    return db.update(
      'users',
      {
        'display_name': displayName,
        'email': email,
        'privilege_id': privilegeId,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _db;
    return db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, Object?>>> search(String q) async {
    final db = await _db;
    return db.query(
      'users',
      where: 'display_name LIKE ? OR email LIKE ?',
      whereArgs: ['%$q%', '%$q%'],
      orderBy: 'id DESC',
    );
  }

  Future<List<Map<String, Object?>>> allWithPrivilege() async {
    final db = await _db;
    return db.rawQuery('''
      SELECT u.id, u.display_name, u.email, u.privilege_id,
             u.created_at_ms, u.last_login_ms,
             p.name AS privilege_name
      FROM users u
      JOIN privileges p ON p.id = u.privilege_id
      ORDER BY u.id DESC
    ''');
  }
}
