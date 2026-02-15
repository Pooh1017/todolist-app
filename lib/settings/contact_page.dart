import 'package:flutter/material.dart';
import 'settings_base_page.dart';

// ✅ l10n (generated in lib/l10n)
import '../l10n/app_localizations.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final t = AppLocalizations.of(context);

    final dividerColor = cs.outlineVariant.withOpacity(isDark ? 0.25 : 0.40);

    TextStyle? titleStyle() => theme.textTheme.bodyLarge?.copyWith(
          color: cs.onSurface,
          fontWeight: FontWeight.w900,
        );

    TextStyle? subStyle() => theme.textTheme.bodyMedium?.copyWith(
          color: cs.onSurfaceVariant.withOpacity(0.92),
          fontWeight: FontWeight.w700,
        );

    return SettingsBasePage(
      title: t.contactUs,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 6),
        children: [
          // ✅ เหลือเฉพาะ Email
          ListTile(
            leading: Icon(Icons.email_outlined, color: cs.onSurfaceVariant),
            title: Text(t.email, style: titleStyle()),
            subtitle: Text(t.supportEmail, style: subStyle()),
            // ถ้าจะทำกดเปิดแอพเมลภายหลัง ใส่ onTap ได้
          ),
        ],
      ),
    );
  }
}
