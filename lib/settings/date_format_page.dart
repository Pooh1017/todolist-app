import 'package:flutter/material.dart';
import '../main.dart';
import 'settings_base_page.dart';

// ✅ l10n (generated in lib/l10n)
import '../l10n/app_localizations.dart';

class DateFormatPage extends StatefulWidget {
  const DateFormatPage({super.key});

  @override
  State<DateFormatPage> createState() => _DateFormatPageState();
}

class _DateFormatPageState extends State<DateFormatPage> {
  String fmt = 'dd-MM-yyyy';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    fmt = AppSettingsScope.of(context).dateFormat;
  }

  Future<void> _setFmt(String value) async {
    if (fmt == value) return;
    setState(() => fmt = value);
    await AppSettingsScope.of(context).setDateFormat(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final t = AppLocalizations.of(context);

    TextStyle? titleStyle() => theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w900,
          color: cs.onSurface,
        );

    TextStyle? subStyle() => theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: cs.onSurfaceVariant.withOpacity(0.9),
        );

    return SettingsBasePage(
      title: t.dateFormat,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 6),
        children: [
          RadioListTile<String>(
            value: 'dd-MM-yyyy',
            groupValue: fmt,
            activeColor: cs.primary,
            title: Text('31-12-2026', style: titleStyle()),
            subtitle: Text(t.dateFmtDmyDash, style: subStyle()),
            onChanged: (v) {
              if (v != null) _setFmt(v);
            },
          ),
          Divider(color: cs.outlineVariant.withOpacity(0.4), height: 1),

          RadioListTile<String>(
            value: 'dd/MM/yyyy',
            groupValue: fmt,
            activeColor: cs.primary,
            title: Text('31/12/2026', style: titleStyle()),
            subtitle: Text(t.dateFmtDmySlash, style: subStyle()),
            onChanged: (v) {
              if (v != null) _setFmt(v);
            },
          ),
          Divider(color: cs.outlineVariant.withOpacity(0.4), height: 1),

          RadioListTile<String>(
            value: 'MM/dd/yyyy',
            groupValue: fmt,
            activeColor: cs.primary,
            title: Text('12/31/2026', style: titleStyle()),
            subtitle: Text(t.dateFmtMdySlash, style: subStyle()),
            onChanged: (v) {
              if (v != null) _setFmt(v);
            },
          ),
          Divider(color: cs.outlineVariant.withOpacity(0.4), height: 1),

          RadioListTile<String>(
            value: 'yyyy-MM-dd',
            groupValue: fmt,
            activeColor: cs.primary,
            title: Text('2026-12-31', style: titleStyle()),
            subtitle: Text(t.dateFmtYmdDash, style: subStyle()),
            onChanged: (v) {
              if (v != null) _setFmt(v);
            },
          ),
        ],
      ),
    );
  }
}