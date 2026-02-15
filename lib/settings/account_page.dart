import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'settings_base_page.dart';

// ✅ l10n (generated in lib/l10n)
import '../l10n/app_localizations.dart';

// ✅ Login อยู่ที่ lib/login_page.dart
import '../login_page.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  Future<void> _logout(BuildContext context) async {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final t = AppLocalizations.of(context);

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t.logoutConfirmTitle),
        content: Text(t.logoutConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: cs.error,
              foregroundColor: cs.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.logout),
          ),
        ],
      ),
    );

    if (ok != true) return;

    // ✅ 1) ออกจาก Firebase
    await FirebaseAuth.instance.signOut();

    // ✅ 2) ออกจาก GoogleSignIn ด้วย (สำคัญมาก ไม่งั้นมันจำ session เดิม)
    // - signOut: ออกจากแอป แต่ยังจำบัญชีในเครื่องได้
    // - disconnect: ตัดสิทธิ์/ล้าง session ลึกกว่า (ทำให้ต้องเลือกบัญชีใหม่บ่อยขึ้น)
    try {
      final gs = GoogleSignIn();
      await gs.signOut();
      await gs.disconnect(); // ถ้าอยาก “ออกจริงแบบต้องเลือกบัญชีใหม่” แนะนำเปิดไว้
    } catch (_) {
      // บางกรณีผู้ใช้ไม่ได้ล็อกอินด้วย Google ก็จะ throw ได้ ปล่อยผ่าน
    }

    if (!context.mounted) return;

    // ✅ 3) กลับไปหน้า Login แบบล้าง route ทั้งหมด
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final t = AppLocalizations.of(context);

    final user = FirebaseAuth.instance.currentUser;

    final displayName = user?.displayName ?? t.notSetName;
    final email = user?.email ?? '—';
    final photoUrl = user?.photoURL;
    final uid = user?.uid ?? '-';

    final dividerColor = cs.outlineVariant.withOpacity(isDark ? 0.25 : 0.40);

    return SettingsBasePage(
      title: t.account,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: cs.primary.withOpacity(isDark ? 0.20 : 0.12),
                  backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                      ? NetworkImage(photoUrl)
                      : null,
                  child: (photoUrl == null || photoUrl.isEmpty)
                      ? Icon(
                          Icons.person_rounded,
                          size: 30,
                          color: cs.onSurfaceVariant.withOpacity(0.9),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurfaceVariant.withOpacity(0.90),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: dividerColor),

          ListTile(
            leading: Icon(Icons.badge_outlined, color: cs.onSurfaceVariant),
            title: Text(
              t.username,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w900,
              ),
            ),
            subtitle: Text(
              displayName,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant.withOpacity(0.92),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          ListTile(
            leading: Icon(Icons.email_outlined, color: cs.onSurfaceVariant),
            title: Text(
              t.email,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w900,
              ),
            ),
            subtitle: Text(
              email,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant.withOpacity(0.92),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          ListTile(
            leading: Icon(Icons.key_outlined, color: cs.onSurfaceVariant),
            title: Text(
              t.userId,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w900,
              ),
            ),
            subtitle: Text(
              uid,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant.withOpacity(0.92),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          ListTile(
            leading: Icon(Icons.login_rounded, color: cs.onSurfaceVariant),
            title: Text(
              t.signedInWith,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w900,
              ),
            ),
            subtitle: Text(
              _providerText(t, user),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant.withOpacity(0.92),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(height: 10),
          Divider(height: 1, color: dividerColor),
          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FilledButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout_rounded),
              label: Text(t.logout),
              style: FilledButton.styleFrom(
                backgroundColor: cs.error,
                foregroundColor: cs.onError,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),

          const SizedBox(height: 6),
        ],
      ),
    );
  }

  static String _providerText(AppLocalizations t, User? user) {
    if (user == null) return '-';

    final providers = user.providerData.map((p) => p.providerId).toList();

    if (providers.contains('google.com')) return 'Google';
    if (providers.contains('password')) return t.providerEmailPassword;
    if (providers.contains('phone')) return t.providerPhone;

    return providers.join(', ');
  }
}

