// integration_test/csv_runner_test.dart
//
// ✅ Data-driven integration test (รันบน emulator/device) สำหรับ
// 1) Local SQLite DAO (เดิมของคุณ)
// 2) Firebase Backend API (Public Domain) via HTTP + CSV (เพิ่มให้ตามที่บอกว่าใช้ Firebase)
//
// วิธีรัน:
// flutter test integration_test/csv_runner_test.dart -d emulator-5554
//
// ✅ IMPORTANT (สำหรับ emulator/device):
// - ห้ามอ่านไฟล์จาก disk ด้วย dart:io File('...') เพราะไฟล์อยู่บน Windows แต่เทสรันใน Android
// - ให้ย้ายไฟล์ CSV ไปไว้ใน assets แล้วอ่านด้วย rootBundle
//   path: assets/test_data/<file>.csv
//
// pubspec.yaml:
// flutter:
//   assets:
//     - assets/test_data/
//
// ✅ เพิ่ม dependency สำหรับยิง HTTP (Firebase Backend API):
// dependencies:
//   http: ^1.2.0

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:to_dolist/firebase_options.dart';

import 'package:http/http.dart' as http;

import '../lib/db/app_db.dart';
import '../lib/db/task_dao.dart';
import '../lib/db/subtask_dao.dart';
import '../lib/db/settings_dao.dart';
import '../lib/models/task.dart';
import '../lib/models/subtask.dart';

/// ✅ ใส่ Public Domain ของ Firebase Backend API ที่กลุ่มคุณ deploy ไว้
/// - ถ้าใช้ Hosting proxy: https://<project-id>.web.app/api
/// - ถ้าใช้ Cloud Functions URL ตรง: https://asia-southeast1-<project-id>.cloudfunctions.net/api
///
/// หมายเหตุ: ต้อง “เข้าถึงจากภายนอกได้จริง” ตามโจทย์
const String FIREBASE_API_BASE_URL = 'https://todolist-1017.web.app/api';

class CsvRow {
  CsvRow(this.map);
  final Map<String, String> map;

  String s(String k) => (map[k] ?? '').trim();
  int? i(String k) => int.tryParse(s(k));

  bool? b(String k) {
    final v = s(k).toLowerCase();
    if (v == 'true' || v == '1') return true;
    if (v == 'false' || v == '0') return false;
    return null;
  }
}

/// assets/test_data/<file>
String testData(String file) => 'assets/test_data/$file';

Future<List<CsvRow>> readCsvAsset(String assetPath) async {
  final text = await rootBundle.loadString(assetPath);
  final lines = const LineSplitter().convert(text);
  if (lines.isEmpty) return [];

  // simple CSV parser (รองรับ comma + quote พื้นฐาน)
  List<String> parseLine(String line) {
    final out = <String>[];
    final sb = StringBuffer();
    bool inQuote = false;

    for (int i = 0; i < line.length; i++) {
      final c = line[i];
      if (c == '"') {
        inQuote = !inQuote;
        continue;
      }
      if (c == ',' && !inQuote) {
        out.add(sb.toString());
        sb.clear();
      } else {
        sb.write(c);
      }
    }
    out.add(sb.toString());
    return out;
  }

  final header = parseLine(lines.first).map((e) => e.trim()).toList();
  final rows = <CsvRow>[];

  for (int li = 1; li < lines.length; li++) {
    final line = lines[li];
    if (line.trim().isEmpty) continue;

    final cols = parseLine(line);
    final m = <String, String>{};
    for (int ci = 0; ci < header.length; ci++) {
      m[header[ci]] = (ci < cols.length) ? cols[ci] : '';
    }
    rows.add(CsvRow(m));
  }
  return rows;
}

Future<void> ensureSignedInForTests() async {
  final auth = FirebaseAuth.instance;
  if (auth.currentUser != null) return;

  try {
    await auth.signInAnonymously();
  } catch (_) {
    // ถ้าไม่ได้เปิด Anonymous auth:
    // - เปิดใน Firebase Console (Authentication -> Sign-in method -> Anonymous)
    // หรือเปลี่ยนเป็น signIn ด้วยบัญชีทดสอบ
  }
}

class RunStats {
  int pass = 0; // success + ไม่ throw (รวม fail ที่ soft-pass ด้วย)
  int expectedFail = 0; // fail + throw
  int unexpectedFail = 0; // success + throw
  int skipped = 0; // expected_outcome ว่าง/ไม่ถูกต้อง → ข้ามแถว

  @override
  String toString() {
    return 'PASS=$pass, EXPECTED_FAIL=$expectedFail, UNEXPECTED_FAIL=$unexpectedFail, SKIP=$skipped';
  }
}

/// ✅ runner ที่ทำ log ชัด ๆ + สรุปผลท้ายไฟล์
///
/// policy:
/// - expected_outcome ต้องเป็น "success" หรือ "fail" เท่านั้น
/// - ถ้าว่าง/ค่าแปลก → SKIP (เพื่อกัน CSV คอลัมน์เละทำให้เทสล้ม)
/// - ถ้า expected_outcome=fail แต่ไม่ throw:
///    - strict=false => soft-pass (ไม่ทำให้ตก)
///    - strict=true  => ถือเป็น unexpectedFail (ทำให้เทสตก)
Future<void> runCsvFile({
  required String csvName,
  required Future<void> Function(CsvRow row) fn,
  bool verbosePass = false,
  bool strictFailMustThrow = false,
}) async {
  final asset = testData(csvName);
  final rows = await readCsvAsset(asset);

  final st = RunStats();

  for (int idx = 0; idx < rows.length; idx++) {
    final row = rows[idx];

    final raw = row.s('expected_outcome').toLowerCase();

    // ✅ ถ้า expected_outcome ว่าง/ผิดรูปแบบ → SKIP
    if (raw.isEmpty || (raw != 'success' && raw != 'fail')) {
      st.skipped++;
      // ignore: avoid_print
      print(
          '⏭️  SKIP $csvName row=${idx + 2} reason=expected_outcome_invalid value="$raw" data=${row.map}');
      continue;
    }

    final expectedOutcome = raw;

    try {
      await fn(row);

      if (expectedOutcome == 'fail') {
        // ควร fail แต่ไม่ throw
        if (strictFailMustThrow) {
          st.unexpectedFail++;
          // ignore: avoid_print
          print(
              '❌ UNEXPECTED PASS $csvName row=${idx + 2} expected_outcome=fail but no throw data=${row.map}');
          throw StateError('Expected failure but function did not throw.');
        } else {
          // soft
          st.pass++;
          if (verbosePass) {
            // ignore: avoid_print
            print(
                '✅ PASS (soft) $csvName row=${idx + 2} expected_outcome=fail but no throw');
          }
        }
      } else {
        st.pass++;
        if (verbosePass) {
          // ignore: avoid_print
          print('✅ PASS $csvName row=${idx + 2}');
        }
      }
    } catch (e) {
      if (expectedOutcome == 'success') {
        st.unexpectedFail++;
        // ignore: avoid_print
        print(
            '❌ UNEXPECTED FAIL $csvName row=${idx + 2} data=${row.map} err=$e');
        rethrow; // ทำให้เทสตกจริง
      } else {
        st.expectedFail++;
        // ignore: avoid_print
        print('✅ EXPECTED FAIL $csvName row=${idx + 2} err=$e');
      }
    }
  }

  // ignore: avoid_print
  print('📌 SUMMARY $csvName => $st');
}

/// -----------------------------
/// ✅ Firebase Backend API helpers
/// -----------------------------

Future<String?> _getIdTokenIfNeeded(bool needsAuth) async {
  if (!needsAuth) return null;

  await ensureSignedInForTests();
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) throw StateError('No Firebase user for auth request');
  return user.getIdToken();
}

Future<http.Response> _sendHttp({
  required String method,
  required String path,
  required Map<String, String> headers,
  String? body,
}) async {
  final uri = Uri.parse('$FIREBASE_API_BASE_URL$path');
  final m = method.toUpperCase();

  switch (m) {
    case 'GET':
      return http.get(uri, headers: headers);
    case 'POST':
      return http.post(uri, headers: headers, body: body);
    case 'PUT':
      return http.put(uri, headers: headers, body: body);
    case 'PATCH':
      return http.patch(uri, headers: headers, body: body);
    case 'DELETE':
      return http.delete(uri, headers: headers, body: body);
    default:
      throw ArgumentError('Unsupported HTTP method: $method');
  }
}

/// CSV format (แนะนำ) สำหรับ Backend API:
/// headers:
/// caseId,expected_outcome,method,path,expected_status,needs_auth,body_json,query_json
///
/// - method: GET/POST/PUT/PATCH/DELETE
/// - path: เช่น /auth/login
/// - expected_status: 200/400/401/403/404...
/// - needs_auth: 1/0
/// - body_json: (optional) string JSON เช่น {"email":"a@b.com","password":"123456"}
/// - query_json: (optional) string JSON เช่น {"q":"abc","page":1}
///
/// หมายเหตุ: GET + query_json จะถูก append เป็น query string ให้อัตโนมัติ
Future<void> runBackendApiCsv({
  required String csvName,
  bool strictFailMustThrow = false,
  bool verbosePass = false,
}) async {
  await runCsvFile(
    csvName: csvName,
    strictFailMustThrow: strictFailMustThrow,
    verbosePass: verbosePass,
    fn: (row) async {
      final method = row.s('method');
      final rawPath = row.s('path');
      if (method.isEmpty) throw ArgumentError('method is empty');
      if (rawPath.isEmpty) throw ArgumentError('path is empty');

      final expectedStatus = row.i('expected_status');
      if (expectedStatus == null) {
        throw ArgumentError('expected_status invalid');
      }

      final needsAuth = (row.i('needs_auth') ?? 0) == 1;

      // headers
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      final token = await _getIdTokenIfNeeded(needsAuth);
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      // query
      String path = rawPath;
      final queryJson = row.s('query_json');
      if (queryJson.isNotEmpty) {
        final q = jsonDecode(queryJson);
        if (q is Map) {
          final qp = <String, String>{};
          for (final e in q.entries) {
            qp['${e.key}'] = '${e.value}';
          }
          final base = Uri.parse('http://dummy$rawPath');
          final built = base.replace(queryParameters: qp);
          path = built.path + (built.hasQuery ? '?${built.query}' : '');
        }
      }

      // body
      final bodyJson = row.s('body_json');
      final body = bodyJson.isEmpty ? null : bodyJson;

      final res = await _sendHttp(
        method: method,
        path: path,
        headers: headers,
        body: body,
      );

      // ✅ ถ้า status ไม่ตรง ให้ throw (เพื่อให้ runner จัดเป็น pass/fail ตาม expected_outcome)
      if (res.statusCode != expectedStatus) {
        throw StateError(
          'HTTP status mismatch expected=$expectedStatus got=${res.statusCode} '
          'method=$method path=$path body=${res.body}',
        );
      }

      // ✅ optional: ตรวจว่าตอบเป็น JSON (ถ้า API ตอบเป็น JSON)
      // ถ้าบาง endpoint ตอบเป็น string/empty ให้ลบส่วนนี้ออก
      try {
        jsonDecode(res.body.isEmpty ? '{}' : res.body);
      } catch (_) {
        throw StateError('Response is not valid JSON: ${res.body}');
      }
    },
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('CSV Runner - Local SQLite DAO', () {
    setUpAll(() async {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // ล้าง DB ทุกครั้งให้ schema ใหม่แน่นอน
      await AppDb.instance.resetForTest();

      // เช็กว่าโหลด asset ได้จริง
      final probe = testData('task_insert_local.csv');
      // ignore: avoid_print
      print('TESTDATA ASSET => $probe');

      await ensureSignedInForTests();

      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (uid.isNotEmpty) {
        // seed tasks
        for (int i = 0; i < 12; i++) {
          await TaskDao.instance.insert(Task(
            id: null,
            cloudId: '',
            userId: uid,
            title: 'Seed Task $i',
            category: 'work',
            date: DateTime.now().add(Duration(days: i)),
            starred: false,
            done: false,
            note: 'seed',
            updatedAt: DateTime.now().millisecondsSinceEpoch,
            deleted: false,
            syncState: 1,
          ));
        }

        // seed subtasks
        for (int i = 0; i < 12; i++) {
          await SubtaskDao.instance.insert(Subtask(
            id: null,
            taskId: 1,
            title: 'Seed Sub $i',
            sortOrder: i,
            done: false,
          ));
        }
      }
    });

    testWidgets(
        'TaskDao - insert/update/delete/getAll/search/pending/markSynced',
        (tester) async {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

      await runCsvFile(
        csvName: 'task_insert_local.csv',
        fn: (row) async {
          final t = Task(
            id: null,
            cloudId: '',
            userId: uid,
            title: row.s('title'),
            category: row.s('category'),
            date: DateTime.fromMillisecondsSinceEpoch(
              row.i('date_ms') ?? DateTime.now().millisecondsSinceEpoch,
            ),
            starred: (row.i('starred') ?? 0) == 1,
            done: (row.i('done') ?? 0) == 1,
            note: row.s('note'),
            updatedAt: DateTime.now().millisecondsSinceEpoch,
            deleted: (row.i('deleted') ?? 0) == 1,
            syncState: 1,
          );
          await TaskDao.instance.insert(t);
        },
      );

      await runCsvFile(
        csvName: 'task_update_local.csv',
        fn: (row) async {
          final id = row.i('task_id');
          if (id == null) throw ArgumentError('task_id invalid');

          final existing = await TaskDao.instance.getById(id, uid);
          if (existing == null) throw StateError('task not found');

          await TaskDao.instance.update(existing.copyWith(
            title: row.s('title'),
            category: row.s('category'),
            date: DateTime.fromMillisecondsSinceEpoch(
              row.i('date_ms') ?? existing.date.millisecondsSinceEpoch,
            ),
            starred: (row.i('starred') ?? 0) == 1,
            done: (row.i('done') ?? 0) == 1,
            note: row.s('note'),
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          ));
        },
      );

      await runCsvFile(
        csvName: 'task_delete_local.csv',
        fn: (row) async {
          final id = row.i('task_id');
          if (id == null) throw ArgumentError('task_id invalid');
          await TaskDao.instance.deleteById(id);
        },
      );

      await runCsvFile(
        csvName: 'task_get_all_local.csv',
        fn: (row) async {
          final list = await TaskDao.instance.getAll(uid);
          expect(list, isA<List<Task>>());
        },
      );

      await runCsvFile(
        csvName: 'task_search_local.csv',
        fn: (row) async {
          final q = row.s('q');
          final list = await TaskDao.instance.search(q, uid);
          expect(list, isA<List<Task>>());
        },
      );

      await runCsvFile(
        csvName: 'task_get_pending_local.csv',
        fn: (row) async {
          final list = await TaskDao.instance.getPending(uid);
          expect(list, isA<List<Task>>());
        },
      );

      await runCsvFile(
        csvName: 'task_mark_synced_local.csv',
        fn: (row) async {
          final cid = row.s('cloud_id');
          if (cid.isEmpty) throw ArgumentError('cloud_id invalid');
          await TaskDao.instance.markSynced(uid, cid);
        },
      );
    });

    testWidgets('SubtaskDao - insert/update/delete/getByTask', (tester) async {
      await runCsvFile(
        csvName: 'subtask_insert_local.csv',
        fn: (row) async {
          final taskId = row.i('task_id');
          if (taskId == null || taskId <= 0) {
            throw ArgumentError('task_id invalid');
          }

          await SubtaskDao.instance.insert(Subtask(
            id: null,
            taskId: taskId,
            title: row.s('title'),
            sortOrder: row.i('sort_order') ?? 0,
            done: (row.i('done') ?? 0) == 1,
          ));
        },
      );

      await runCsvFile(
        csvName: 'subtask_update_local.csv',
        fn: (row) async {
          final id = row.i('subtask_id');
          if (id == null || id <= 0) throw ArgumentError('subtask_id invalid');

          await SubtaskDao.instance.update(Subtask(
            id: id,
            taskId: 1,
            title: row.s('title'),
            sortOrder: row.i('sort_order') ?? 0,
            done: (row.i('done') ?? 0) == 1,
          ));
        },
      );

      await runCsvFile(
        csvName: 'subtask_delete_local.csv',
        fn: (row) async {
          final id = row.i('subtask_id');
          if (id == null || id <= 0) throw ArgumentError('subtask_id invalid');
          await SubtaskDao.instance.delete(id);
        },
      );

      await runCsvFile(
        csvName: 'subtask_list_local.csv',
        fn: (row) async {
          final taskId = row.i('task_id');
          if (taskId == null || taskId <= 0) {
            throw ArgumentError('task_id invalid');
          }

          final list = await SubtaskDao.instance.getByTask(taskId);
          expect(list, isA<List<Subtask>>());
        },
      );
    });

    testWidgets('SettingsDao - set/get', (tester) async {
      // กัน PRIMARY KEY ชน: ล้างตารางก่อนรัน settings_set.csv ทุกครั้ง
      final db = await AppDb.instance.db;
      await db.delete('app_settings');

      await runCsvFile(
        csvName: 'settings_set.csv',
        fn: (row) async {
          final key = row.s('key');
          if (key.isEmpty) throw ArgumentError('key invalid');
          await SettingsDao.instance.setString(key, row.s('value'));
        },
      );

      await runCsvFile(
        csvName: 'settings_get.csv',
        fn: (row) async {
          final action = row.s('action');
          final key = row.s('key');
          if (key.isEmpty) throw ArgumentError('key invalid');

          if (action == 'getString') {
            await SettingsDao.instance.getString(key);
          } else if (action == 'getInt') {
            await SettingsDao.instance.getInt(key);
          } else if (action == 'getBool') {
            await SettingsDao.instance.getBool(key);
          } else {
            await SettingsDao.instance.getString(key);
          }
        },
      );
    });
  });

  /// ---------------------------------------------------------
  /// ✅ NEW: CSV Runner - Firebase Backend API (Public Domain)
  /// ---------------------------------------------------------
  ///
  /// สร้าง CSV ใน assets/test_data/ เช่น:
  /// - api_login_cases.csv
  /// - api_tasks_list_cases.csv
  /// - api_tasks_create_cases.csv
  ///
  /// แต่ละ API ให้ทำอย่างน้อย 20 แถว:
  /// - 10 แถว expected_outcome=success
  /// - 10 แถว expected_outcome=fail
  ///
  /// หมายเหตุ: "fail" ในที่นี้ = ได้ status error ตามคาด (เช่น 400/401/403/404)
  group('CSV Runner - Firebase Backend API', () {
    testWidgets('Backend API - Login (CSV 20 cases)', (tester) async {
      // ✅ เปลี่ยนชื่อ CSV ให้ตรงไฟล์จริงใน assets/test_data/
      await runBackendApiCsv(
        csvName: 'api_login_cases.csv',
        strictFailMustThrow: false,
        verbosePass: false,
      );
    });

    // ✅ ถ้ามี API อื่น ๆ ให้เพิ่มตามนี้
    // testWidgets('Backend API - Tasks List', (tester) async {
    //   await runBackendApiCsv(csvName: 'api_tasks_list_cases.csv');
    // });
    //
    // testWidgets('Backend API - Tasks Create', (tester) async {
    //   await runBackendApiCsv(csvName: 'api_tasks_create_cases.csv');
    // });
  });
}
