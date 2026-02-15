import 'package:sqflite/sqflite.dart';

import 'app_db.dart';

/// เก็บค่า settings แบบ key-value ใน SQLite
class SettingsDao {
  SettingsDao._();
  static final SettingsDao instance = SettingsDao._();

  static const table = 'app_settings';

  // Keys
  static const kThemeMode = 'theme_mode'; // light | dark
  static const kLanguage = 'language'; // th | en
  static const kDateFormat = 'date_format'; // dd-MM-yyyy | MM/dd/yyyy | yyyy-MM-dd
  static const kReminderMinutes = 'reminder_minutes'; // int
  static const kNotificationsEnabled = 'notifications_enabled'; // 0|1

  Future<void> setString(String key, String value) async {
    final db = await AppDb.instance.db;
    await db.insert(
      table,
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getString(String key) async {
    final db = await AppDb.instance.db;
    final rows = await db.query(
      table,
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> setBool(String key, bool value) => setString(key, value ? '1' : '0');
  Future<bool?> getBool(String key) async {
    final v = await getString(key);
    if (v == null) return null;
    return v == '1' || v.toLowerCase() == 'true';
  }

  Future<void> setInt(String key, int value) => setString(key, value.toString());
  Future<int?> getInt(String key) async {
    final v = await getString(key);
    if (v == null) return null;
    return int.tryParse(v);
  }
}
