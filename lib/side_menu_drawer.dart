import 'dart:ui';
import 'package:flutter/material.dart';
import 'settings/settings_page.dart';

// ✅ l10n
import 'l10n/app_localizations.dart';

class SideMenuDrawer extends StatelessWidget {
  const SideMenuDrawer({
    super.key,
    required this.onSelect,
  });

  final void Function(String key) onSelect;

  static const _bgTop = Color(0xFFF6F7FB);
  static const _bgBottom = Color(0xFFF1F3F8);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final t = AppLocalizations.of(context);

    final bgTop = isDark ? const Color(0xFF0F1720) : _bgTop;
    final bgBottom = isDark ? const Color(0xFF0B121A) : _bgBottom;

    final line = isDark
        ? Colors.white.withOpacity(0.10)
        : Colors.black.withOpacity(0.06);

    return Drawer(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(26),
          bottomRight: Radius.circular(26),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [bgTop, bgBottom],
              ),
              border: Border(
                right: BorderSide(
                  color: isDark
                      ? Colors.white.withOpacity(0.10)
                      : Colors.white.withOpacity(0.55),
                  width: 1.2,
                ),
              ),
            ),
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                children: [
                  _Header(
                    title: t.drawerAppTitle,
                    subtitle: t.drawerAppSubtitle,
                    onClose: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 12),

                  _SectionTitle(t.drawerMenuSection),

                  // สิ่งที่ต้องทำ (รวมดาว)
                  _MenuTile(
                    icon: Icons.star_rounded,
                    iconColor: const Color(0xFFE0D51C),
                    title: t.drawerTodo,
                    showChevron: false,
                    onTap: () => _tapKey(context, 'cat_todo'),
                  ),

                  const SizedBox(height: 10),
                  _SectionTitle(t.drawerCategorySection),

                  _GlassCard(
                    child: _CategoryExpansion(
                      onTapKey: (key) => _tapKey(context, key),
                    ),
                  ),

                  const SizedBox(height: 14),
                  _SectionTitle(t.settingsTitle),

                  _MenuTile(
                    icon: Icons.settings_rounded,
                    title: t.settings,
                    onTap: () => _openSettings(context),
                  ),

                  const SizedBox(height: 10),

                  // Divider(color: line),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _tapKey(BuildContext context, String key) {
    Navigator.pop(context);
    onSelect(key);
  }

  void _openSettings(BuildContext context) {
    Navigator.pop(context);
    Future.microtask(() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SettingsPage()),
      );
    });
  }
}

// ====== Widgets used by SideMenuDrawer ======

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    required this.onClose,
  });

  final String title;
  final String subtitle;
  final VoidCallback onClose;

  static const _blue = Color(0xFF2E5E8D);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final ink = scheme.onSurface;
    final muted = scheme.onSurface.withOpacity(isDark ? 0.70 : 0.60);
    final line = isDark
        ? Colors.white.withOpacity(0.10)
        : Colors.black.withOpacity(0.06);

    return _GlassCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _blue.withOpacity(isDark ? 0.18 : 0.12),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: _blue.withOpacity(isDark ? 0.28 : 0.22)),
            ),
            child: Icon(Icons.checklist_rounded,
                color: _blue.withOpacity(0.95), size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: muted,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onClose,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: scheme.surface.withOpacity(isDark ? 0.75 : 0.70),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: line, width: 1.0),
              ),
              child: Icon(Icons.close_rounded, color: muted),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final muted = scheme.onSurface.withOpacity(isDark ? 0.65 : 0.55);

    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          color: muted,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.showChevron = true,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  final bool showChevron;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final ink = scheme.onSurface;
    final muted = scheme.onSurface.withOpacity(isDark ? 0.70 : 0.60);

    return _GlassCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: (iconColor ?? ink.withOpacity(0.85))),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: ink,
                  ),
                ),
              ),
              if (showChevron) Icon(Icons.chevron_right_rounded, color: muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubTile extends StatelessWidget {
  const _SubTile({
    required this.title,
    required this.icon,
    required this.accent,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  Color _tint(Color base, Color accent, double amount) =>
      Color.lerp(base, accent, amount) ?? base;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final ink = scheme.onSurface;
    final muted = scheme.onSurface.withOpacity(isDark ? 0.70 : 0.60);
    final card = scheme.surface;

    final cardBg = _tint(card, accent, isDark ? 0.12 : 0.06);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withOpacity(isDark ? 0.28 : 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.28 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(isDark ? 0.18 : 0.14),
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: accent.withOpacity(isDark ? 0.32 : 0.25)),
                  ),
                  child: Icon(icon, color: accent.withOpacity(0.95), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w900,
                          color: ink,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: muted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ✅ ExpansionTile ที่ลูกศรเริ่มชี้ไปขวา และตอนเปิดชี้ลง
class _CategoryExpansion extends StatefulWidget {
  const _CategoryExpansion({required this.onTapKey});
  final void Function(String key) onTapKey;

  @override
  State<_CategoryExpansion> createState() => _CategoryExpansionState();
}

class _CategoryExpansionState extends State<_CategoryExpansion> {
  bool _expanded = false;

  // สีเหมือนหน้า Home
  static const _blue = Color(0xFF2E5E8D); // ที่วางแผนไว้
  static const _green = Color(0xFF24C96A); // งาน
  static const _yellow = Color(0xFFE0D51C); // สิ่งที่ต้องทำ
  static const _orange = Color(0xFFF08C63); // ใกล้ครบกำหนด

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final t = AppLocalizations.of(context);

    final ink = scheme.onSurface;
    final muted = scheme.onSurface.withOpacity(isDark ? 0.70 : 0.60);
    final line = isDark
        ? Colors.white.withOpacity(0.10)
        : Colors.black.withOpacity(0.06);

    return Theme(
      data: theme.copyWith(
        dividerColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: ExpansionTile(
        onExpansionChanged: (v) => setState(() => _expanded = v),
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        childrenPadding: const EdgeInsets.only(bottom: 10),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _blue.withOpacity(isDark ? 0.18 : 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: line),
          ),
          child: Icon(Icons.grid_view_rounded, color: _blue.withOpacity(0.95)),
        ),
        title: Text(
          t.drawerCategoriesTitle,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: ink,
          ),
        ),
        subtitle: Text(
          t.drawerCategoriesSubtitle,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: muted,
          ),
        ),
        trailing: Icon(
          _expanded ? Icons.expand_more_rounded : Icons.chevron_right_rounded,
          color: muted,
        ),
        children: [
          _SubTile(
            title: t.drawerCatWork,
            subtitle: t.drawerCatWorkSub,
            icon: Icons.work_rounded,
            accent: _green,
            onTap: () => widget.onTapKey('cat_work'),
          ),
          _SubTile(
            title: t.drawerCatTodo,
            subtitle: t.drawerCatTodoSub,
            icon: Icons.star_rounded,
            accent: _yellow,
            onTap: () => widget.onTapKey('cat_todo'),
          ),
          _SubTile(
            title: t.drawerCatPlan,
            subtitle: t.drawerCatPlanSub,
            icon: Icons.event_note_rounded,
            accent: _blue,
            onTap: () => widget.onTapKey('cat_plan'),
          ),
          _SubTile(
            title: t.drawerCatImportant,
            subtitle: t.drawerCatImportantSub,
            icon: Icons.priority_high_rounded,
            accent: _orange,
            onTap: () => widget.onTapKey('cat_important'),
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final card = scheme.surface;
    final line = isDark
        ? Colors.white.withOpacity(0.10)
        : Colors.black.withOpacity(0.06);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: card.withOpacity(isDark ? 0.80 : 0.86),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.12)
              : Colors.white.withOpacity(0.55),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.30 : 0.06),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: line, width: 0.0),
        ),
        child: child,
      ),
    );
  }
}
