import 'package:sqflite/sqflite.dart';
import 'app_db.dart';

/// เก็บค่า settings แบบ key-value ใน SQLite
class SettingsDao {
  SettingsDao._();
  static final SettingsDao instance = SettingsDao._();

  static const String table = 'app_settings';

  // Keys
  static const String kThemeMode = 'theme_mode'; // light | dark
  static const String kLanguage = 'language'; // th | en
  static const String kDateFormat = 'date_format'; // dd-MM-yyyy | MM/dd/yyyy | yyyy-MM-dd
  static const String kReminderMinutes = 'reminder_minutes'; // int
  static const String kNotificationsEnabled = 'notifications_enabled'; // 0|1

  Future<Database> get _db async => AppDb.instance.db;

  // ============================
  // String
  // ============================
  Future<void> setString(String key, String value) async {
    final db = await _db;

    final k = key.trim();
    if (k.isEmpty) {
      throw ArgumentError('Settings key must not be empty');
    }

    await db.insert(
      table,
      {
        'key': k,
        'value': value.trim(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getString(String key) async {
    final db = await _db;

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

  // ============================
  // Bool
  // ============================
  Future<void> setBool(String key, bool value) async {
    await setString(key, value ? '1' : '0');
  }

  Future<bool?> getBool(String key) async {
    final v = await getString(key);
    if (v == null) return null;

    final s = v.toLowerCase().trim();
    return s == '1' || s == 'true';
  }

  // ============================
  // Int
  // ============================
  Future<void> setInt(String key, int value) async {
    await setString(key, value.toString());
  }

  Future<int?> getInt(String key) async {
    final v = await getString(key);
    if (v == null) return null;

    return int.tryParse(v);
  }

  // ============================
  // Delete
  // ============================
  Future<void> remove(String key) async {
    final db = await _db;

    await db.delete(
      table,
      where: 'key = ?',
      whereArgs: [key],
    );
  }

  Future<void> clear() async {
    final db = await _db;
    await db.delete(table);
  }

  // ============================
  // Helper defaults
  // ============================
  Future<String> getThemeMode() async {
    return await getString(kThemeMode) ?? 'light';
  }

  Future<String> getLanguage() async {
    return await getString(kLanguage) ?? 'th';
  }

  Future<String> getDateFormat() async {
    return await getString(kDateFormat) ?? 'dd-MM-yyyy';
  }

  Future<int> getReminderMinutes() async {
    return await getInt(kReminderMinutes) ?? 10;
  }

  Future<bool> getNotificationsEnabled() async {
    return await getBool(kNotificationsEnabled) ?? true;
  }
}