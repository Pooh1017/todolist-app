import 'dart:ui';
import 'package:flutter/material.dart';

class SettingsBasePage extends StatelessWidget {
  const SettingsBasePage({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // ✅ Gradient background that adapts to theme
    final isDark = _isDark(context);
    final bgTop = isDark ? const Color(0xFF0F172A) : const Color(0xFFF6F7FB);
    final bgBottom = isDark ? const Color(0xFF111827) : const Color(0xFFF1F3F8);

    // ✅ Surfaces
    final cardBg = cs.surface.withOpacity(isDark ? 0.82 : 0.92);
    final topbarBg = cs.surface.withOpacity(isDark ? 0.70 : 0.70);
    final outline = cs.outline.withOpacity(isDark ? 0.22 : 0.16);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgTop, bgBottom],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                child: _TopBar(
                  title: title,
                  onBack: () => Navigator.pop(context),
                  backgroundColor: topbarBg,
                  borderColor: outline,
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: outline, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.35 : 0.06),
                        blurRadius: 22,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: DefaultTextStyle(
                    style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ) ??
                        TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                    child: child,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.onBack,
    required this.backgroundColor,
    required this.borderColor,
  });

  final String title;
  final VoidCallback onBack;
  final Color backgroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(
                  theme.brightness == Brightness.dark ? 0.35 : 0.06,
                ),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: onBack,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 20,
                    color: cs.onSurface.withOpacity(0.92),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: cs.onSurface,
                    ) ??
                    TextStyle(
                      fontSize: 18.5,
                      fontWeight: FontWeight.w900,
                      color: cs.onSurface,
                    ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
