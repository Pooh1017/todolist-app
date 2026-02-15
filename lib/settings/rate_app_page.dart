import 'package:flutter/material.dart';
import 'settings_base_page.dart';

// ✅ l10n (generated in lib/l10n)
import '../l10n/app_localizations.dart';

class RateAppPage extends StatelessWidget {
  const RateAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final t = AppLocalizations.of(context);

    return SettingsBasePage(
      title: t.rate5Stars,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 12),
        children: [
          ListTile(
            leading: Icon(Icons.star_rounded, color: cs.primary),
            title: Text(
              t.rateThanksTitle,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            subtitle: Text(t.rateNoteSubtitle),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: FilledButton.icon(
              onPressed: () {
                // TODO: ขั้นต่อไปค่อยใส่การเปิด Play Store / App Store
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(t.rateSnackExample)),
                );
              },
              icon: const Icon(Icons.open_in_new_rounded),
              label: Text(
                t.goToStore,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded),
              label: Text(
                t.goBack,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
