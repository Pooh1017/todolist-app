// lib/sync/sync_service.dart
import 'package:firebase_auth/firebase_auth.dart';

import '../db/task_dao.dart';
import '../models/task.dart';
import '../cloud/firestore_service.dart';

abstract class CloudApi {
  Future<void> uploadTask(String uid, Task task);
  Future<List<Task>> fetchAll(String uid);
}

class FirestoreCloudApi implements CloudApi {
  FirestoreCloudApi(this._fs);
  final FirestoreService _fs;

  @override
  Future<void> uploadTask(String uid, Task task) async {
    // ✅ หลายเครื่อง: ต้องใช้ cloudId (ไม่ใช่ id)
    if (task.cloudId.trim().isEmpty) return;
    await _fs.upsertTask(uid, task);
  }

  @override
  Future<List<Task>> fetchAll(String uid) async {
    final maps = await _fs.fetchTasks(uid, includeDeleted: true);
    return maps.map((m) => _fs.taskFromCloud(uid, m)).toList();
  }
}

class SyncService {
  SyncService({
    required this.taskDao,
    required this.cloud,
  });

  final TaskDao taskDao;
  final CloudApi cloud;

  Future<void> syncNow() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;

    // 1) PUSH local -> cloud
    final pending = await taskDao.getPending(uid);
    for (final t in pending) {
      // ✅ ต้องมี cloudId
      if (t.cloudId.trim().isEmpty) continue;

      try {
        await cloud.uploadTask(uid, t);
        await taskDao.markSynced(uid, t.cloudId);
      } catch (_) {
        // upload fail → ค้าง pending ไว้รอบหน้า
      }
    }

    // 2) PULL cloud -> local
    final remote = await cloud.fetchAll(uid);

    for (final r in remote) {
      final cid = r.cloudId.trim();
      if (cid.isEmpty) continue;

      try {
        final local = await taskDao.getByCloudId(uid, cid, includeDeleted: true);

        // ✅ rule: cloud ใหม่กว่า → เขียนทับ
        // ✅ tie-breaker: ถ้า updatedAt เท่ากัน ให้ "เลือก cloud" คงที่ (กัน flip)
        final shouldApply =
            (local == null) || (r.updatedAt > local.updatedAt) || (r.updatedAt == local.updatedAt);

        if (shouldApply) {
          await taskDao.upsertFromCloud(r.copyWith(syncState: 0));
        }
      } catch (_) {
        // ignore
      }
    }
  }
}
