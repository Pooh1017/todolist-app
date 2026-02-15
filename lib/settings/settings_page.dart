import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../db/settings_dao.dart';

// ✅ ใช้ไฟล์ที่ generate อยู่ใน lib/l10n (ตามโปรเจกต์คุณ)
import '../l10n/app_localizations.dart';


import 'account_page.dart';
import 'theme_page.dart';
import 'notification_page.dart';
import 'date_format_page.dart';
import 'reminder_default_page.dart';
import 'language_page.dart';
import 'rate_app_page.dart';
import 'contact_page.dart';
import 'feedback_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  static const String appLink =
      'https://play.google.com/store/apps/details?id=com.example.todo';

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // ✅ เก็บ “ค่าจริง” ไว้ แล้วค่อยแปลงเป็นข้อความตามภาษาใน build()
  String _theme = 'light'; // light/dark/system(legacy)
  String _lang = 'th'; // th/en
  String _dateFmt = 'dd-MM-yyyy';
  int _rem = 10;
  bool _notiEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettingSummaries();
  }

  Future<void> _loadSettingSummaries() async {
    // อ่านจาก SQLite ผ่าน SettingsDao (key-value)
    final theme = await SettingsDao.instance.getString('theme_mode') ?? 'system';
    final lang = await SettingsDao.instance.getString('language') ?? 'th';
    final dateFmt =
        await SettingsDao.instance.getString('date_format') ?? 'dd-MM-yyyy';
    final rem =
        await SettingsDao.instance.getInt('default_reminder_minutes') ?? 10;
    final notiEnabled =
        await SettingsDao.instance.getBool('notifications_enabled') ?? true;

    if (!mounted) return;

    setState(() {
      _theme = theme;
      _lang = lang;
      _dateFmt = dateFmt;
      _rem = rem;
      _notiEnabled = notiEnabled;
    });
  }

  void _go(BuildContext context, Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    await _loadSettingSummaries();
  }

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  String _themeLabel(AppLocalizations t, String v) {
    switch (v) {
      case 'light':
        return t.light;
      case 'dark':
        return t.dark;
      default:
        // legacy ค่าเก่า “system”
        return t.system;
    }
  }

  String _langLabel(AppLocalizations t, String v) {
    switch (v) {
      case 'en':
        return t.english;
      default:
        return t.thai;
    }
  }

  String _dateFmtLabel(AppLocalizations t, String v) {
    switch (v) {
      case 'dd/MM/yyyy':
        return t.dateFmtDmySlash;
      case 'MM/dd/yyyy':
        return t.dateFmtMdySlash;
      case 'yyyy-MM-dd':
        return t.dateFmtYmdDash;
      default:
        return t.dateFmtDmyDash;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = _isDark(context);

    final t = AppLocalizations.of(context);

    // ✅ Theme-adaptive gradient (close to your original light look)
    final bgTop = isDark ? const Color(0xFF0F172A) : const Color(0xFFF6F7FB);
    final bgBottom = isDark ? const Color(0xFF111827) : const Color(0xFFF1F3F8);

    final themeText = _themeLabel(t, _theme);
    final langText = _langLabel(t, _lang);
    final fmtText = _dateFmtLabel(t, _dateFmt);
    final remText = t.minutes(_rem);
    final notiText = _notiEnabled ? t.onText : t.offText;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgTop, bgBottom],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                child: _TopBar(
                  title: t.settingsTitle,
                  onBack: () => Navigator.pop(context),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                  children: [
                    _SectionTitle(t.sectionCustomize),
                    _SettingRow(
                      icon: Icons.person_outline_rounded,
                      title: t.account,
                      onTap: () => _go(context, const AccountPage()),
                    ),
                    _SettingRow(
                      icon: Icons.palette_outlined,
                      title: t.theme,
                      subtitle: themeText,
                      onTap: () => _go(context, const ThemePage()),
                    ),
                    _SettingRow(
                      icon: Icons.notifications_none_rounded,
                      title: t.notificationsAndReminder,
                      subtitle: notiText,
                      onTap: () => _go(context, const NotificationPage()),
                    ),

                    const SizedBox(height: 14),
                    _SectionTitle(t.sectionDateTime),
                    _SettingRow(
                      icon: Icons.calendar_month_outlined,
                      title: t.dateFormat,
                      subtitle: fmtText,
                      onTap: () => _go(context, const DateFormatPage()),
                    ),
                    _SettingRow(
                      icon: Icons.alarm_outlined,
                      title: t.defaultReminder,
                      subtitle: remText,
                      onTap: () => _go(context, const ReminderDefaultPage()),
                    ),

                    const SizedBox(height: 14),
                    _SectionTitle(t.sectionAbout),
                    _SettingRow(
                      icon: Icons.language_rounded,
                      title: t.language,
                      subtitle: langText,
                      onTap: () => _go(context, const LanguagePage()),
                    ),
                    _SettingRow(
                      icon: Icons.ios_share_rounded,
                      title: t.shareApp,
                      onTap: () => Share.share(
                        t.shareMessage(SettingsPage.appLink),
                      ),
                    ),
                    _SettingRow(
                      icon: Icons.star_border_rounded,
                      title: t.rate5Stars,
                      onTap: () => _go(context, const RateAppPage()),
                    ),
                    _SettingRow(
                      icon: Icons.g_mobiledata_rounded,
                      title: t.contactUs,
                      onTap: () => _go(context, const ContactPage()),
                    ),
                    _SettingRow(
                      icon: Icons.feedback_outlined,
                      title: t.feedback,
                      onTap: () => _go(context, const FeedbackPage()),
                    ),

                    const SizedBox(height: 18),
                    Center(
                      child: Text(
                        t.versionLabel('0.1'),
                        style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: cs.onSurfaceVariant.withOpacity(0.85),
                            ) ??
                            TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurfaceVariant.withOpacity(0.85),
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ===== UI helpers =====

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = _isDark(context);

    final bg = cs.surface.withOpacity(isDark ? 0.70 : 0.70);
    final border = cs.outline.withOpacity(isDark ? 0.22 : 0.16);

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.35 : 0.06),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: onBack,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 20,
                    color: cs.onSurface.withOpacity(0.92),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: cs.onSurface,
                    ) ??
                    TextStyle(
                      fontSize: 18.5,
                      fontWeight: FontWeight.w900,
                      color: cs.onSurface,
                    ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: cs.onSurfaceVariant.withOpacity(0.90),
              letterSpacing: 0.2,
            ) ??
            TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: cs.onSurfaceVariant.withOpacity(0.90),
              letterSpacing: 0.2,
            ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = _isDark(context);

    final tileBg = cs.surface.withOpacity(isDark ? 0.78 : 0.86);
    final border = cs.outline.withOpacity(isDark ? 0.22 : 0.14);

    final iconBg = cs.primary.withOpacity(isDark ? 0.16 : 0.12);
    final iconColor = cs.onSurface.withOpacity(0.90);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: tileBg,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: border, width: 1),
                      ),
                      child: Icon(icon, color: iconColor, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: cs.onSurface,
                                ) ??
                                TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: cs.onSurface,
                                ),
                          ),
                          if (subtitle != null &&
                              subtitle!.trim().isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              subtitle!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: cs.onSurfaceVariant
                                        .withOpacity(0.90),
                                  ) ??
                                  TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: cs.onSurfaceVariant
                                        .withOpacity(0.90),
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: cs.onSurface.withOpacity(0.30),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
