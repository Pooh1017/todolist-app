import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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
  bool _sending = false;

  static const String _toEmail = 'thanapooh@gmail.com';

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  Future<void> _sendFeedback() async {
    final t = AppLocalizations.of(context);
    final text = ctrl.text.trim();
    if (text.isEmpty || _sending) return;

    FocusScope.of(context).unfocus();
    setState(() => _sending = true);

    try {
      final subject = Uri.encodeComponent('Feedback from To-Do List App');
      final body = Uri.encodeComponent(text);

      final uri = Uri.parse(
        'mailto:$_toEmail?subject=$subject&body=$body',
      );

      final ok = await launchUrl(uri);

      if (!mounted) return;

      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เปิดอีเมลเพื่อส่งข้อความไปที่ $_toEmail แล้ว'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        ctrl.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ไม่สามารถเปิดแอปอีเมลได้'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final t = AppLocalizations.of(context);

    final fill = cs.surfaceContainerHighest
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
              onPressed: _sending ? null : _sendFeedback,
              child: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(t.send),
            ),
          ),
        ],
      ),
    );
  }
}