import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sqflite/sqflite.dart';

import 'home_page.dart';
import 'db/app_db.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _auth = FirebaseAuth.instance;

  // ✅ เก็บ instance ไว้ ไม่สร้างใหม่ทุกครั้ง
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  bool _loading = false;

  Future<void> _goHome() async {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  Future<void> _withLoading(Future<void> Function() fn) async {
    if (mounted) setState(() => _loading = true);
    try {
      await fn();
    } catch (e) {
      _toast('เกิดข้อผิดพลาด: $e');
      debugPrint('ERROR: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<bool> _tableExists(Database db, String table) async {
    final rows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [table],
    );
    return rows.isNotEmpty;
  }

  Future<void> _ensureUserLoginColumn(Database db) async {
    // กันเคสตาราง users ยังไม่มี (ไม่ให้ PRAGMA แล้วพัง)
    if (!await _tableExists(db, 'users')) return;

    final cols = await db.rawQuery("PRAGMA table_info(users)");
    final has = cols.any((r) => (r['name'] ?? '').toString() == 'last_login_ms');
    if (!has) {
      await db.execute("ALTER TABLE users ADD COLUMN last_login_ms INTEGER");
    }
  }

  // ✅ seed privileges ถ้ายังไม่มี (และต้องมีตาราง privileges ก่อน)
  Future<void> _ensurePrivilegesSeed(Database db) async {
    if (!await _tableExists(db, 'privileges')) return;

    await db.execute("INSERT OR IGNORE INTO privileges(name) VALUES ('Admin');");
    await db.execute("INSERT OR IGNORE INTO privileges(name) VALUES ('User');");
  }

  // ✅ หา privilege_id จากชื่อ role (ไม่เดาเป็น 1)
  Future<int> _getPrivilegeId(Database db, String roleName) async {
    if (!await _tableExists(db, 'privileges')) {
      throw Exception("ไม่พบตาราง privileges ใน SQLite");
    }

    final rows = await db.query(
      'privileges',
      columns: ['id'],
      where: 'name = ?',
      whereArgs: [roleName],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw Exception("ไม่พบ privilege '$roleName' ในตาราง privileges");
    }

    final v = rows.first['id'];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  // ✅ บันทึกผู้ใช้ + เวลา login ล่าสุดลง SQLite (แบบชัวร์)
  Future<void> _saveLoginToLocal(User u) async {
    final db = await AppDb.instance.db;

    // ทำให้แน่ใจว่า schema พร้อม (กัน crash ถ้า table ยังไม่พร้อม)
    await _ensureUserLoginColumn(db);
    await _ensurePrivilegesSeed(db);

    final email = (u.email ?? '').trim();
    if (email.isEmpty) {
      throw Exception('Firebase user ไม่มี email (บันทึกลง users ไม่ได้)');
    }

    // กันเคสตาราง users/app_settings ไม่มี
    if (!await _tableExists(db, 'users')) {
      throw Exception("ไม่พบตาราง users ใน SQLite");
    }
    if (!await _tableExists(db, 'app_settings')) {
      throw Exception("ไม่พบตาราง app_settings ใน SQLite");
    }

    final now = DateTime.now().millisecondsSinceEpoch;

    final displayName = (u.displayName ?? '').trim().isNotEmpty
        ? u.displayName!.trim()
        : email.split('@').first;

    final userPrivilegeId = await _getPrivilegeId(db, 'User');

    final exist = await db.query(
      'users',
      columns: ['id'],
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );

    if (exist.isEmpty) {
      await db.insert('users', {
        'display_name': displayName.isNotEmpty ? displayName : 'User',
        'email': email,
        'privilege_id': userPrivilegeId,
        'created_at_ms': now, // ✅ เพิ่มอันนี้ (NOT NULL)
        'last_login_ms': now,
      });
      debugPrint('INSERT users OK: $email');
    } else {
      await db.update(
        'users',
        {
          'display_name': displayName.isNotEmpty ? displayName : 'User',
          'privilege_id': userPrivilegeId,
          'last_login_ms': now,
        },
        where: 'email = ?',
        whereArgs: [email],
      );
      debugPrint('UPDATE users OK: $email');
    }

    await db.insert(
      'app_settings',
      {'key': 'current_user_email', 'value': email},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    debugPrint('SET current_user_email OK: $email');
  }

  Future<void> _signInWithGoogle() async {
    await _withLoading(() async {
      // ✅ บังคับให้เลือก account ใหม่ได้ (กันติด account เดิม)
      await _googleSignIn.signOut();

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return; // ผู้ใช้กดยกเลิก

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final cred = await _auth.signInWithCredential(credential);
      final user = cred.user;

      debugPrint('LOGIN OK: ${user?.email}');

      if (user != null) {
        await _saveLoginToLocal(user);
        debugPrint('SAVE LOGIN TO LOCAL OK');
      }

      _toast('เข้าสู่ระบบสำเร็จ: ${user?.email ?? ''}');
      await _goHome();
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final w = media.size.width;
    final cardWidth = w < 420 ? w - 36 : 420.0;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF7F8FC), Color(0xFFF1F3F8)],
              ),
            ),
          ),
          const Positioned(
            top: -80,
            left: -60,
            child: _GlowBlob(size: 220, color: Color(0xFF2E5E8D)),
          ),
          const Positioned(
            bottom: -90,
            right: -70,
            child: _GlowBlob(size: 260, color: Color(0xFF24C96A)),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: cardWidth),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(36),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.86),
                          borderRadius: BorderRadius.circular(36),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.55)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.10),
                              blurRadius: 38,
                              offset: const Offset(0, 18),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 2),
                            const Text(
                              'ยินดีต้อนรับสู่',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2F4158),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'To-Do List',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 32,
                                height: 1.05,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.2,
                                color: Color(0xFF2F4158),
                              ),
                            ),
                            const SizedBox(height: 14),
                            AspectRatio(
                              aspectRatio: 16 / 11,
                              child: Center(
                                child: Image.asset(
                                  'assets/images/login_illustration.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'เข้าสู่ระบบเพื่อเริ่มใช้งาน',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF2F4158)
                                    .withOpacity(0.65),
                              ),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              height: 54,
                              width: double.infinity,
                              child: _actionButton(
                                icon: 'assets/icons/google.png',
                                text: 'Continue with Google',
                                onTap: _signInWithGoogle,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'การเข้าสู่ระบบหมายถึงคุณยอมรับเงื่อนไขการใช้งาน',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF6C7A90)
                                    .withOpacity(0.75),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_loading)
            Container(
              color: Colors.black.withOpacity(0.10),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: _loading ? null : onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFFFFF), Color(0xFFF6F7FB)],
            ),
            border: Border.all(color: Colors.black.withOpacity(0.06)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F3F8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black.withOpacity(0.05)),
                ),
                child: Image.asset(icon),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  text,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2F4158),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withOpacity(0.22), color.withOpacity(0.00)],
          ),
        ),
      ),
    );
  }
}
