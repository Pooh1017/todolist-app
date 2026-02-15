import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDb {
  AppDb._();
  static final AppDb instance = AppDb._();

  static const _dbName = 'todo_app.db';

  // ✅ เพิ่มเป็น v7 เพราะเพิ่ม cloud_id + unique index (รองรับหลายเครื่อง)
  static const _dbVersion = 7;

  Database? _db;

  // ============================
  // ✅ สำหรับ Integration Test: reset DB
  // ============================
  Future<void> resetForTest() async {
    final databasesPath = await getDatabasesPath();
    final path = p.join(databasesPath, _dbName);

    // ปิด DB ถ้าเปิดอยู่
    if (_db != null) {
      await _db!.close();
      _db = null;
    }

    // ลบไฟล์ DB เดิม
    final f = File(path);
    if (await f.exists()) {
      await f.delete();
    }

    // เปิดใหม่ → บังคับ onCreate
    await db;
  }

  // ============================
  // DB getter
  // ============================
  Future<Database> get db async {
    final existing = _db;
    if (existing != null) return existing;

    final databasesPath = await getDatabasesPath();
    final path = p.join(databasesPath, _dbName);

    final database = await openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

    _db = database;
    return database;
  }

  // ============================
  // CREATE
  // ============================
  Future<void> _onCreate(Database db, int version) async {
    await _createTasksTable(db);
    await _createSubtasksTable(db);
    await _createSettingsTable(db);

    await _createUserPrivilegeTables(db);
    await _seedDefaultPrivileges(db);
  }

  // ============================
  // UPGRADE
  // ============================
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await _ensureTasksTable(db);
    await _ensureSubtasksTable(db);
    await _createSettingsTable(db);

    if (oldVersion < 7) {
      await _ensureTaskColumn(db, 'cloud_id', "TEXT NOT NULL DEFAULT ''");
      await _ensureTaskIndexes(db);
    }

    await _ensureTaskIndexes(db);
    await _ensureSubtaskIndexes(db);
  }

  // ============================
  // tasks
  // ============================
  Future<void> _createTasksTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,

        user_id TEXT NOT NULL,
        cloud_id TEXT NOT NULL,

        title TEXT NOT NULL,
        category TEXT NOT NULL,
        date_ms INTEGER NOT NULL,

        starred INTEGER NOT NULL DEFAULT 0,
        done INTEGER NOT NULL DEFAULT 0,
        note TEXT NOT NULL DEFAULT '',

        updated_at INTEGER NOT NULL,
        deleted INTEGER NOT NULL DEFAULT 0,
        sync_state INTEGER NOT NULL DEFAULT 1
      );
    ''');

    await _ensureTaskIndexes(db);
  }

  Future<void> _ensureTasksTable(Database db) async {
    final exists = await _tableExists(db, 'tasks');
    if (!exists) {
      await _createTasksTable(db);
      return;
    }

    await _ensureTaskColumn(db, 'cloud_id', "TEXT NOT NULL DEFAULT ''");
    await _ensureTaskIndexes(db);
  }

  Future<void> _ensureTaskIndexes(Database db) async {
    await _ensureIndex(db, 'idx_tasks_user',
        'CREATE INDEX IF NOT EXISTS idx_tasks_user ON tasks(user_id);');

    await _ensureIndex(
      db,
      'idx_tasks_user_cloud',
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_tasks_user_cloud ON tasks(user_id, cloud_id);',
    );
  }

  // ============================
  // subtasks
  // ============================
  Future<void> _createSubtasksTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS subtasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        done INTEGER NOT NULL DEFAULT 0,
        sort_order INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY(task_id) REFERENCES tasks(id) ON DELETE CASCADE
      );
    ''');

    await _ensureSubtaskIndexes(db);
  }

  Future<void> _ensureSubtasksTable(Database db) async {
    final exists = await _tableExists(db, 'subtasks');
    if (!exists) {
      await _createSubtasksTable(db);
      return;
    }

    await _ensureSubtaskIndexes(db);
  }

  Future<void> _ensureSubtaskIndexes(Database db) async {
    await _ensureIndex(
      db,
      'idx_subtasks_task',
      'CREATE INDEX IF NOT EXISTS idx_subtasks_task ON subtasks(task_id);',
    );
  }

  // ============================
  // settings
  // ============================
  Future<void> _createSettingsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      );
    ''');
  }

  // ============================
  // users + privileges
  // ============================
  Future<void> _createUserPrivilegeTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS privileges (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        display_name TEXT NOT NULL,
        email TEXT,
        privilege_id INTEGER NOT NULL,
        created_at_ms INTEGER NOT NULL,
        last_login_ms INTEGER
      );
    ''');
  }

  Future<void> _seedDefaultPrivileges(Database db) async {
    await db.execute("INSERT OR IGNORE INTO privileges(name) VALUES ('Admin');");
    await db.execute("INSERT OR IGNORE INTO privileges(name) VALUES ('User');");
  }

  // ============================
  // helpers
  // ============================
  Future<bool> _tableExists(Database db, String table) async {
    final r = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=? LIMIT 1;",
      [table],
    );
    return r.isNotEmpty;
  }

  Future<void> _ensureIndex(Database db, String name, String sql) async {
    await db.execute(sql);
  }

  Future<void> _ensureTaskColumn(Database db, String name, String sqlTypeAndDefault) async {
    final cols = await db.rawQuery('PRAGMA table_info(tasks)');
    final has = cols.any((r) => (r['name'] ?? '').toString() == name);
    if (has) return;

    await db.execute('ALTER TABLE tasks ADD COLUMN $name $sqlTypeAndDefault;');
  }

  Future<void> close() async {
    final d = _db;
    if (d != null) {
      await d.close();
      _db = null;
    }
  }
}
