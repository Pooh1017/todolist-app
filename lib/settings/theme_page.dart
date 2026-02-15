import 'package:flutter/material.dart';
import '../main.dart'; // AppSettingsScope
import 'settings_base_page.dart';

// ✅ l10n (generated in lib/l10n)
import '../l10n/app_localizations.dart';

class ThemePage extends StatefulWidget {
  const ThemePage({super.key});

  @override
  State<ThemePage> createState() => _ThemePageState();
}

class _ThemePageState extends State<ThemePage> {
  String _value = 'light'; // light | dark

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = AppSettingsScope.of(context);
    final pref = settings.themePref; // light/dark
    final v = (pref == 'dark') ? 'dark' : 'light';
    if (_value != v) {
      setState(() => _value = v);
    }
  }

  Future<void> _save(String v) async {
    if (_value == v) return;
    setState(() => _value = v);
    await AppSettingsScope.of(context).setThemePref(v); // light/dark
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final t = AppLocalizations.of(context);

    return SettingsBasePage(
      title: t.theme,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
        children: [
          // ✅ Preview Card
          Card(
            elevation: 0,
            color: cs.surfaceVariant.withOpacity(
              theme.brightness == Brightness.dark ? 0.35 : 0.55,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: cs.outlineVariant.withOpacity(0.35)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: cs.primary.withOpacity(0.25)),
                    ),
                    child: Icon(Icons.palette_rounded, color: cs.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.themeApplyAllApp,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t.themeChooseHint,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          _ThemeOptionTile(
            title: t.light,
            subtitle: t.themeLightDesc,
            icon: Icons.light_mode_rounded,
            selected: _value == 'light',
            onTap: () => _save('light'),
          ),
          const SizedBox(height: 10),

          _ThemeOptionTile(
            title: t.dark,
            subtitle: t.themeDarkDesc,
            icon: Icons.dark_mode_rounded,
            selected: _value == 'dark',
            onTap: () => _save('dark'),
          ),

          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              t.themeNote,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeOptionTile extends StatelessWidget {
  const _ThemeOptionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final border = selected
        ? Border.all(color: cs.primary.withOpacity(0.55), width: 1.2)
        : Border.all(color: cs.outline.withOpacity(0.35), width: 1);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: selected ? cs.primary.withOpacity(0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: border,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: selected ? cs.primary.withOpacity(0.16) : cs.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected
                        ? cs.primary.withOpacity(0.25)
                        : cs.outline.withOpacity(0.25),
                  ),
                ),
                child: Icon(icon, color: selected ? cs.primary : cs.onSurface),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? cs.primary : Colors.transparent,
                  border: Border.all(
                    color: selected ? cs.primary : cs.onSurface.withOpacity(0.35),
                    width: 1.4,
                  ),
                ),
                child: selected
                    ? Icon(Icons.check, size: 14, color: cs.onPrimary)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
