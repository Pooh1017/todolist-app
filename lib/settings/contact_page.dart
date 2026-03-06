import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'settings_base_page.dart';

// ✅ l10n
import '../l10n/app_localizations.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  Future<void> _sendEmail(String email) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Support%20Todolist%20App',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final t = AppLocalizations.of(context);

    TextStyle? titleStyle() => theme.textTheme.bodyLarge?.copyWith(
          color: cs.onSurface,
          fontWeight: FontWeight.w900,
        );

    TextStyle? subStyle() => theme.textTheme.bodyMedium?.copyWith(
          color: cs.onSurfaceVariant.withOpacity(0.92),
          fontWeight: FontWeight.w700,
        );

    const email = 'thanapooh@gmail.com';

    return SettingsBasePage(
      title: t.contactUs,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 6),
        children: [
          ListTile(
            leading: Icon(Icons.email_outlined, color: cs.onSurfaceVariant),
            title: Text(t.email, style: titleStyle()),
            subtitle: Text(email, style: subStyle()),
            trailing: const Icon(Icons.open_in_new_rounded),
            onTap: () => _sendEmail(email),
          ),
        ],
      ),
    );
  }
}