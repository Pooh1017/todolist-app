import 'package:flutter/material.dart';
import '../main.dart'; // AppSettingsScope
import 'settings_base_page.dart';

// ✅ l10n (generated in lib/l10n)
import '../l10n/app_localizations.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  bool _enabled = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = AppSettingsScope.of(context);
    final v = settings.notificationsEnabled;
    if (_enabled != v) {
      setState(() => _enabled = v);
    }
  }

  Future<void> _toggle(bool v) async {
    if (_enabled == v) return;
    setState(() => _enabled = v);
    await AppSettingsScope.of(context).setNotificationsEnabled(v);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppLocalizations.of(context);

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
            onChanged: _toggle,
            activeColor: cs.primary,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        ],
      ),
    );
  }
}
