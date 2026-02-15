import 'package:flutter/material.dart';
import '../main.dart';
import 'settings_base_page.dart';

// ✅ l10n (generated in lib/l10n)
import '../l10n/app_localizations.dart';

class ReminderDefaultPage extends StatefulWidget {
  const ReminderDefaultPage({super.key});

  @override
  State<ReminderDefaultPage> createState() => _ReminderDefaultPageState();
}

class _ReminderDefaultPageState extends State<ReminderDefaultPage> {
  int minutes = 10;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = AppSettingsScope.of(context);
    final v = settings.reminderMinutes;
    if (minutes != v) {
      setState(() => minutes = v);
    }
  }

  Future<void> _setMinutes(int value) async {
    if (minutes == value) return;
    setState(() => minutes = value);
    await AppSettingsScope.of(context).setReminderMinutes(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final t = AppLocalizations.of(context);

    return SettingsBasePage(
      title: t.defaultReminder,
      child: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.timer_outlined, color: cs.primary),
            title: Text(
              t.remindBefore,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            subtitle: Text(
              t.minutes(minutes),
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
                fontWeight: FontWeight.w700,
              ),
            ),
            trailing: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: minutes,
                dropdownColor: cs.surface,
                iconEnabledColor: cs.primary,
                items: <int>[5, 10, 30, 60]
                    .map(
                      (m) => DropdownMenuItem(
                        value: m,
                        child: Text(t.minutes(m)),
                      ),
                    )
                    .toList(),
                onChanged: (v) => _setMinutes(v ?? minutes),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
