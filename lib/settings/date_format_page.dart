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
    final settings = AppSettingsScope.of(context);
    fmt = settings.dateFormat;
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

    Future<void> setFmt(String value) async {
      setState(() => fmt = value);
      await AppSettingsScope.of(context).setDateFormat(value);
    }

    return SettingsBasePage(
      title: t.dateFormat,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 6),
        children: [
          // dd-MM-yyyy
          RadioListTile<String>(
            value: 'dd-MM-yyyy',
            groupValue: fmt,
            activeColor: cs.primary,
            title: Text('31-12-2026', style: titleStyle()),
            subtitle: Text(
              t.dateFmtDmyDash,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onSurfaceVariant.withOpacity(0.9),
              ),
            ),
            onChanged: (v) => setFmt(v ?? fmt),
          ),
          Divider(color: cs.outlineVariant.withOpacity(0.4), height: 1),

          // dd/MM/yyyy
          RadioListTile<String>(
            value: 'dd/MM/yyyy',
            groupValue: fmt,
            activeColor: cs.primary,
            title: Text('31/12/2026', style: titleStyle()),
            subtitle: Text(
              t.dateFmtDmySlash,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onSurfaceVariant.withOpacity(0.9),
              ),
            ),
            onChanged: (v) => setFmt(v ?? fmt),
          ),
          Divider(color: cs.outlineVariant.withOpacity(0.4), height: 1),

          // MM/dd/yyyy
          RadioListTile<String>(
            value: 'MM/dd/yyyy',
            groupValue: fmt,
            activeColor: cs.primary,
            title: Text('12/31/2026', style: titleStyle()),
            subtitle: Text(
              t.dateFmtMdySlash,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onSurfaceVariant.withOpacity(0.9),
              ),
            ),
            onChanged: (v) => setFmt(v ?? fmt),
          ),
          Divider(color: cs.outlineVariant.withOpacity(0.4), height: 1),

          // yyyy-MM-dd
          RadioListTile<String>(
            value: 'yyyy-MM-dd',
            groupValue: fmt,
            activeColor: cs.primary,
            title: Text('2026-12-31', style: titleStyle()),
            subtitle: Text(
              t.dateFmtYmdDash,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onSurfaceVariant.withOpacity(0.9),
              ),
            ),
            onChanged: (v) => setFmt(v ?? fmt),
          ),
        ],
      ),
    );
  }
}
