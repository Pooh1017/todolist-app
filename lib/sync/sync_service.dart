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
    final cloudId = task.cloudId.trim();
    if (uid.trim().isEmpty || cloudId.isEmpty) return;

    await _fs.upsertTask(uid, task);
  }

  @override
  Future<List<Task>> fetchAll(String uid) async {
    if (uid.trim().isEmpty) return [];

    final maps = await _fs.fetchTasks(uid, includeDeleted: true);
    return maps.map((m) => _fs.taskFromCloud(uid, m)).toList();
  }
}

class SyncService {
  SyncService({
    required this.taskDao,
    required this.cloud,
  });

  static final SyncService instance = SyncService(
    taskDao: TaskDao.instance,
    cloud: FirestoreCloudApi(FirestoreService()),
  );

  final TaskDao taskDao;
  final CloudApi cloud;

  bool _syncing = false;

  Future<void> syncNow() async {
    if (_syncing) return;

    final uid = FirebaseAuth.instance.currentUser?.uid?.trim() ?? '';
    if (uid.isEmpty) return;

    _syncing = true;
    try {
      // 1) PUSH local -> cloud
      final pending = await taskDao.getPending(uid);

      for (final t in pending) {
        final cid = t.cloudId.trim();
        if (cid.isEmpty) continue;

        try {
          await cloud.uploadTask(uid, t);
          await taskDao.markSynced(uid, cid);
        } catch (_) {
          // upload fail -> ค้าง pending ไว้ sync รอบหน้า
        }
      }

      // 2) PULL cloud -> local
      final remote = await cloud.fetchAll(uid);

      for (final r in remote) {
        final cid = r.cloudId.trim();
        if (cid.isEmpty) continue;

        try {
          final local = await taskDao.getByCloudId(
            uid,
            cid,
            includeDeleted: true,
          );

          // rule:
          // - ถ้า local ไม่มี -> เอา cloud ลง
          // - ถ้า cloud ใหม่กว่า -> เอา cloud ลง
          // - ถ้าเวลาเท่ากัน -> ใช้ cloud เพื่อให้ผลคงที่
          final shouldApply = local == null ||
              r.updatedAt > local.updatedAt ||
              r.updatedAt == local.updatedAt;

          if (shouldApply) {
            await taskDao.upsertFromCloud(
              r.copyWith(syncState: 0),
            );
          }
        } catch (_) {
          // ignore item error
        }
      }
    } finally {
      _syncing = false;
    }
  }
}