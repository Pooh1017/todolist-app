import 'package:flutter/material.dart';
import 'package:to_dolist/l10n/app_localizations.dart';

import '../main.dart'; // AppSettingsScope
import 'settings_base_page.dart';

class LanguagePage extends StatefulWidget {
  const LanguagePage({super.key});

  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  String _value = 'th'; // th | en

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = AppSettingsScope.of(context);
    final v = settings.locale.languageCode == 'en' ? 'en' : 'th';
    if (_value != v) {
      setState(() => _value = v);
    }
  }

  Future<void> _save(String v) async {
    if (_value == v) return;
    setState(() => _value = v);

    final settings = AppSettingsScope.of(context);
    await settings.setLocale(
      v == 'en' ? const Locale('en', 'US') : const Locale('th', 'TH'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppLocalizations.of(context)!;

    return SettingsBasePage(
      title: t.language,
      child: ListView(
        children: [
          RadioListTile<String>(
            value: 'th',
            groupValue: _value,
            onChanged: (v) => _save(v!),
            title: Text(t.thai),
            activeColor: cs.primary,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          const Divider(height: 1),
          RadioListTile<String>(
            value: 'en',
            groupValue: _value,
            onChanged: (v) => _save(v!),
            title: Text(t.english),
            activeColor: cs.primary,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        ],
      ),
    );
  }
}
