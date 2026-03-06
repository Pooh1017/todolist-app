import 'package:flutter/material.dart';
import '../main.dart'; // AppSettingsScope
import '../utils/notification_service.dart';
import 'settings_base_page.dart';

// ✅ l10n
import '../l10n/app_localizations.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  bool _enabled = true;
  bool _busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = AppSettingsScope.of(context);
    _enabled = settings.notificationsEnabled;
  }

  Future<void> _toggle(bool v) async {
    if (_enabled == v || _busy) return;

    setState(() {
      _enabled = v;
      _busy = true;
    });

    try {
      await AppSettingsScope.of(context).setNotificationsEnabled(v);

      if (v) {
        await NotificationService.instance.init();
      } else {
        await NotificationService.instance.cancelAll();
      }

      if (!mounted) return;

      final t = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            v ? t.notificationsEnabledMessage : t.notificationsDisabledMessage,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;

      setState(() => _enabled = !v);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่สามารถเปลี่ยนการตั้งค่าการแจ้งเตือนได้'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppLocalizations.of(context)!;

    return SettingsBasePage(
      title: t.notificationsTitle,
      child: ListView(
        children: [
          SwitchListTile(
            title: Text(
              t.notificationsEnableTitle,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(t.notificationsEnableSubtitle),
            value: _enabled,
            onChanged: _busy ? null : _toggle,
            activeColor: cs.primary,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        ],
      ),
    );
  }
}