import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------- helpers safe cast ----------
  int _asInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  bool _asBool(dynamic v, {bool fallback = false}) {
    if (v == null) return fallback;
    if (v is bool) return v;
    if (v is int) return v == 1;
    if (v is num) return v.toInt() == 1;
    if (v is String) {
      final s = v.toLowerCase().trim();
      if (s == 'true' || s == '1') return true;
      if (s == 'false' || s == '0') return false;
    }
    return fallback;
  }

  String _asString(dynamic v, {String fallback = ''}) {
    if (v == null) return fallback;
    if (v is String) return v;
    return v.toString();
  }

  CollectionReference<Map<String, dynamic>> _tasksRef(String uid) {
    return _db.collection('users').doc(uid).collection('tasks');
  }

  // ============================
  // ✅ upsert งานขึ้น cloud
  // ============================
  Future<void> upsertTask(String uid, Task t) async {
    final cloudId = t.cloudId.trim();
    if (cloudId.isEmpty) return;

    await _tasksRef(uid).doc(cloudId).set(
      {
        'cloudId': cloudId,
        'localId': t.id, // debug only

        'title': t.title,
        'category': t.category,
        'dateMs': t.date.millisecondsSinceEpoch,
        'starred': t.starred,
        'done': t.done,
        'note': t.note,
        'updatedAt': t.updatedAt,
        'deleted': t.deleted,

        'userId': uid,
      },
      SetOptions(merge: true),
    );
  }

  // ============================
  // ✅ ดึงงานจาก cloud
  // ============================
  Future<List<Map<String, dynamic>>> fetchTasks(
    String uid, {
    bool includeDeleted = true,
  }) async {
    Query<Map<String, dynamic>> q = _tasksRef(uid);

    if (!includeDeleted) {
      q = q.where('deleted', isEqualTo: false);
    }

    q = q.orderBy('updatedAt', descending: true);

    final snap = await q.get();

    return snap.docs.map((d) {
      final data = d.data();

      // ✅ กันกรณีข้อมูลเก่าไม่มี cloudId ใน field
      data['cloudId'] = _asString(data['cloudId'], fallback: d.id).trim();

      return data;
    }).toList();
  }

  // ============================
  // ✅ แปลงข้อมูล cloud -> Task
  // ============================
  Task taskFromCloud(String uid, Map<String, dynamic> m) {
    final dateMs = _asInt(
      m['dateMs'],
      fallback: DateTime.now().millisecondsSinceEpoch,
    );

    final updatedAt = _asInt(m['updatedAt'], fallback: dateMs);
    final cloudId = _asString(m['cloudId']).trim();

    return Task(
      id: null,
      cloudId: cloudId,
      userId: uid,
      title: _asString(m['title']),
      category: _asString(m['category']),
      date: DateTime.fromMillisecondsSinceEpoch(dateMs),
      starred: _asBool(m['starred'], fallback: false),
      done: _asBool(m['done'], fallback: false),
      note: _asString(m['note']),
      updatedAt: updatedAt,
      deleted: _asBool(m['deleted'], fallback: false),
      syncState: 0,
    );
  }

  // ============================
  // ✅ ลบงานบน cloud แบบ soft delete
  // ============================
  Future<void> softDeleteTask(String uid, Task t) async {
    final cloudId = t.cloudId.trim();
    if (cloudId.isEmpty) return;

    await _tasksRef(uid).doc(cloudId).set(
      {
        'cloudId': cloudId,
        'deleted': true,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
        'userId': uid,
      },
      SetOptions(merge: true),
    );
  }
}