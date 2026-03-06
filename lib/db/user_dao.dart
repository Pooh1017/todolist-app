import 'package:sqflite/sqflite.dart';
import 'app_db.dart';

class UserDao {
  UserDao._();
  static final UserDao instance = UserDao._();

  static const String table = 'users';

  Future<Database> get _db async => AppDb.instance.db;

  // ============================
  // CREATE
  // ============================
  Future<int> insert({
    required String displayName,
    String? email,
    required int privilegeId,
  }) async {
    final db = await _db;

    final name = displayName.trim();
    final mail = email?.trim();
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    if (name.isEmpty) {
      throw ArgumentError('displayName must not be empty');
    }

    return db.insert(
      table,
      {
        'display_name': name,
        'email': (mail == null || mail.isEmpty) ? null : mail,
        'privilege_id': privilegeId,
        'created_at_ms': nowMs,
        'last_login_ms': nowMs,
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  // ============================
  // UPDATE
  // ============================
  Future<int> update({
    required int id,
    required String displayName,
    String? email,
    required int privilegeId,
  }) async {
    final db = await _db;

    final name = displayName.trim();
    final mail = email?.trim();

    if (name.isEmpty) {
      throw ArgumentError('displayName must not be empty');
    }

    return db.update(
      table,
      {
        'display_name': name,
        'email': (mail == null || mail.isEmpty) ? null : mail,
        'privilege_id': privilegeId,
      },
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

  // ============================
  // READ
  // ============================
  Future<Map<String, Object?>?> getById(int id) async {
    final db = await _db;

    final rows = await db.query(
      table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<List<Map<String, Object?>>> search(String q) async {
    final db = await _db;
    final keyword = q.trim();

    if (keyword.isEmpty) {
      return db.query(
        table,
        orderBy: 'id DESC',
      );
    }

    return db.query(
      table,
      where: 'display_name LIKE ? OR email LIKE ?',
      whereArgs: ['%$keyword%', '%$keyword%'],
      orderBy: 'id DESC',
    );
  }

  Future<List<Map<String, Object?>>> getAll() async {
    final db = await _db;

    return db.query(
      table,
      orderBy: 'id DESC',
    );
  }

  Future<List<Map<String, Object?>>> allWithPrivilege() async {
    final db = await _db;

    return db.rawQuery('''
      SELECT 
        u.id, 
        u.display_name, 
        u.email, 
        u.privilege_id,
        u.created_at_ms, 
        u.last_login_ms,
        p.name AS privilege_name
      FROM users u
      JOIN privileges p ON p.id = u.privilege_id
      ORDER BY u.id DESC
    ''');
  }

  // ============================
  // LOGIN TIME
  // ============================
  Future<int> updateLastLogin(int id) async {
    final db = await _db;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    return db.update(
      table,
      {
        'last_login_ms': nowMs,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}