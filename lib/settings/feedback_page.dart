import 'package:flutter/material.dart';
import 'settings_base_page.dart';

// ✅ l10n (generated in lib/l10n)
import '../l10n/app_localizations.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final ctrl = TextEditingController();

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final t = AppLocalizations.of(context);

    final fill = cs.surfaceVariant
        .withOpacity(theme.brightness == Brightness.dark ? 0.55 : 0.75);
    final outline = cs.outlineVariant.withOpacity(0.55);

    return SettingsBasePage(
      title: t.feedback,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        children: [
          Text(
            t.feedbackPrompt,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: ctrl,
            maxLines: 6,
            style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurface),
            decoration: InputDecoration(
              hintText: t.feedbackHint,
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant.withOpacity(0.9),
                fontWeight: FontWeight.w700,
              ),
              filled: true,
              fillColor: fill,
              contentPadding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    BorderSide(color: cs.primary.withOpacity(0.9), width: 1.4),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 46,
            child: ElevatedButton(
              onPressed: () {
                final text = ctrl.text.trim();
                if (text.isEmpty) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(t.feedbackSentExample),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: cs.inverseSurface,
                  ),
                );
                ctrl.clear();
              },
              child: Text(t.send),
            ),
          ),
        ],
      ),
    );
  }
}
