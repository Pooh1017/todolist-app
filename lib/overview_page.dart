import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'db/task_dao.dart';
import 'models/task.dart';

// ✅ ใช้ตัวเดียวทั้งแอพ
import 'utils/date_fmt.dart';

// ✅ localization
import 'l10n/app_localizations.dart';

class OverviewPage extends StatefulWidget {
  const OverviewPage({super.key});

  @override
  State<OverviewPage> createState() => OverviewPageState();
}

class OverviewPageState extends State<OverviewPage> {
  // accent
  static const _blue = Color(0xFF2E5E8D);
  static const _green = Color(0xFF24C96A);
  static const _red = Color(0xFFE05A5A);
  static const _yellow = Color(0xFFE0D51C);

  bool _loading = true;

  // counts
  int _doneCount = 0;
  int _overdueCount = 0;
  int _inProgressCount = 0;
  int _nearDueCount = 0;

  // 30 days
  List<Task> _next30Days = [];
  int _count30 = 0;

  Future<void> refresh() async => _reload();

  @override
  void initState() {
    super.initState();
    _reload();
  }

  // ============================
  // ✅ Category key system (รองรับข้อมูลเก่าเป็นภาษาไทยด้วย)
  // ============================
  static const String _kWork = 'work';
  static const String _kTodoAll = 'todo_all';
  static const String _kPlan = 'plan';
  static const String _kNearDue = 'near_due';

  String _catKeyOf(Task t) {
    final c = (t.category).trim();

    // ข้อมูลใหม่ (key)
    if (c == _kWork || c == _kTodoAll || c == _kPlan || c == _kNearDue) return c;

    // ข้อมูลเก่า (ไทย)
    if (c == 'งาน') return _kWork;
    if (c == 'สิ่งที่ต้องทำ') return _kTodoAll;
    if (c == 'ที่วางแผนไว้') return _kPlan;
    if (c == 'ใกล้ครบกำหนด') return _kNearDue;

    return c;
  }

  String _catLabel(BuildContext context, String keyOrLegacy) {
    final tr = AppLocalizations.of(context)!;
    final key = keyOrLegacy.trim();

    switch (key) {
      case _kWork:
        return tr.drawerCatWork;
      case _kTodoAll:
        return tr.drawerCatTodo; // ✅ แก้จาก drawerTodo
      case _kPlan:
        return tr.drawerCatPlan;
      case _kNearDue:
        return tr.drawerCatImportant;
      default:
        // เผื่อเจอไทยเก่า
        if (key == 'งาน') return tr.drawerCatWork;
        if (key == 'สิ่งที่ต้องทำ') return tr.drawerCatTodo;
        if (key == 'ที่วางแผนไว้') return tr.drawerCatPlan;
        if (key == 'ใกล้ครบกำหนด') return tr.drawerCatImportant;
        return key;
    }
  }

  // ============================
  bool _isDone(Task t) => t.done;
  bool _isOverdue(Task t, DateTime now) => !t.done && t.date.isBefore(now);

  bool _isNearDue(Task t, DateTime now) {
    if (t.done) return false;
    if (_isOverdue(t, now)) return false;
    return t.date.difference(now) <= const Duration(days: 2);
  }

  bool _isInProgress(Task t, DateTime now) {
    if (t.done) return false;
    if (_isOverdue(t, now)) return false;
    if (_isNearDue(t, now)) return false;
    return true;
  }

  // ✅ งาน “ภายใน 30 วัน” (ไม่รวมย้อนหลัง)
  List<Task> _pickWithin30(List<Task> all) {
    final now = DateTime.now();
    final end = now.add(const Duration(days: 30));

    final list = all.where((t) {
      if (t.done) return false;
      if (t.date.isBefore(now)) return false; // ✅ ไม่รวมย้อนหลัง
      return !t.date.isAfter(end);
    }).toList();

    // star -> time
    list.sort((a, b) {
      final s = (b.starred ? 1 : 0) - (a.starred ? 1 : 0);
      if (s != 0) return s;
      return a.date.compareTo(b.date);
    });

    return list;
  }

  Future<void> _reload() async {
    if (!mounted) return;
    setState(() => _loading = true);

    final all = await TaskDao.instance.getAll();
    final now = DateTime.now();

    final done = all.where(_isDone).length;
    final overdue = all.where((t) => _isOverdue(t, now)).length;
    final nearDue = all.where((t) => _isNearDue(t, now)).length;
    final inProgress = all.where((t) => _isInProgress(t, now)).length;

    final next30 = _pickWithin30(all);

    if (!mounted) return;
    setState(() {
      _doneCount = done;
      _overdueCount = overdue;
      _nearDueCount = nearDue;
      _inProgressCount = inProgress;

      _next30Days = next30;
      _count30 = next30.length;

      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final tr = AppLocalizations.of(context)!;

    final total = _doneCount + _overdueCount + _inProgressCount + _nearDueCount;

    // background (โทนเดียวกับหน้าอื่น)
    final bgTop = isDark ? const Color(0xFF0F1720) : const Color(0xFFF6F7FB);
    final bgBottom = isDark ? const Color(0xFF0B121A) : const Color(0xFFF1F3F8);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgTop, bgBottom],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _GlassProfileHeader(user: user),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Text(
                      tr.overviewTitle,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: scheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    if (_loading)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                _GlassBox(
                  child: Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          title: tr.overviewDoneCard,
                          value: _doneCount.toString(),
                          accent: _green,
                          icon: Icons.check_circle_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SummaryCard(
                          title: tr.overviewPendingCard,
                          value:
                              (_inProgressCount + _nearDueCount + _overdueCount)
                                  .toString(),
                          accent: _blue,
                          icon: Icons.timelapse_rounded,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  tr.overviewPieTitle,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),

                _GlassBox(
                  child: _loading
                      ? const SizedBox(
                          height: 180,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : total == 0
                          ? SizedBox(
                              height: 180,
                              child: Center(
                                child: Text(
                                  tr.overviewEmptyAll,
                                  style: TextStyle(
                                    color: scheme.onSurface.withOpacity(
                                        isDark ? 0.70 : 0.60),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            )
                          : Row(
                              children: [
                                SizedBox(
                                  width: 160,
                                  height: 160,
                                  child: _PieChart(
                                    strokeWidth: 22,
                                    baseColor: (isDark
                                        ? Colors.white.withOpacity(0.10)
                                        : Colors.black.withOpacity(0.06)),
                                    segments: [
                                      _PieSegment(
                                        value: _doneCount.toDouble(),
                                        color: _green,
                                        label: tr.statusDone,
                                      ),
                                      _PieSegment(
                                        value: _overdueCount.toDouble(),
                                        color: _red,
                                        label: tr.statusOverdue,
                                      ),
                                      _PieSegment(
                                        value: _inProgressCount.toDouble(),
                                        color: _blue,
                                        label: tr.statusInProgress,
                                      ),
                                      _PieSegment(
                                        value: _nearDueCount.toDouble(),
                                        color: _yellow,
                                        label: tr.statusNearDue,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _Legend(
                                    items: [
                                      _LegendItem(
                                          color: _green,
                                          title: tr.statusDone,
                                          value: _doneCount),
                                      _LegendItem(
                                          color: _red,
                                          title: tr.statusOverdue,
                                          value: _overdueCount),
                                      _LegendItem(
                                          color: _blue,
                                          title: tr.statusInProgress,
                                          value: _inProgressCount),
                                      _LegendItem(
                                          color: _yellow,
                                          title: tr.statusNearDue,
                                          value: _nearDueCount),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        tr.overviewNext30Title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _CountBox(
                      value: _count30,
                      accent: scheme.primary,
                      label: tr.overviewCountLabel,
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Expanded(
                  child: _GlassBox(
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : _next30Days.isEmpty
                            ? Center(
                                child: Text(
                                  tr.overviewNext30Empty,
                                  style: TextStyle(
                                    color: scheme.onSurface.withOpacity(
                                        isDark ? 0.70 : 0.60),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              )
                            : _MiniList(
                                tasks: _next30Days,
                                categoryText: (t) =>
                                    _catLabel(context, _catKeyOf(t)),
                              ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================
// Legend
// ==========================
class _Legend extends StatelessWidget {
  const _Legend({required this.items});
  final List<_LegendItem> items;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...items.map(
          (it) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration:
                      BoxDecoration(color: it.color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    it.title,
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
                Text(
                  '${it.value}',
                  style: TextStyle(
                    color: scheme.onSurface.withOpacity(isDark ? 0.70 : 0.60),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendItem {
  final Color color;
  final String title;
  final int value;
  const _LegendItem(
      {required this.color, required this.title, required this.value});
}

// ==========================
// Pie Chart (CustomPainter)
// ==========================
class _PieChart extends StatelessWidget {
  const _PieChart({
    required this.segments,
    this.strokeWidth = 22,
    required this.baseColor,
  });

  final List<_PieSegment> segments;
  final double strokeWidth;
  final Color baseColor;

  @override
  Widget build(BuildContext context) {
    // ✅ บังคับ size เพื่อให้ CustomPaint วาดแน่นอน
    return SizedBox.expand(
      child: CustomPaint(
        painter: _PiePainter(
          segments: segments,
          strokeWidth: strokeWidth,
          baseColor: baseColor,
        ),
      ),
    );
  }
}

class _PieSegment {
  final double value;
  final Color color;
  final String label;
  const _PieSegment(
      {required this.value, required this.color, required this.label});
}

class _PiePainter extends CustomPainter {
  _PiePainter(
      {required this.segments,
      required this.strokeWidth,
      required this.baseColor});

  final List<_PieSegment> segments;
  final double strokeWidth;
  final Color baseColor;

  @override
  void paint(Canvas canvas, Size size) {
    final total = segments.fold<double>(
        0, (s, e) => s + (e.value <= 0 ? 0 : e.value));

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - strokeWidth / 2;

    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = baseColor;
    canvas.drawCircle(center, radius, basePaint);

    if (total <= 0) return;

    var start = -math.pi / 2;
    for (final seg in segments) {
      final v = seg.value <= 0 ? 0 : seg.value;
      if (v == 0) continue;

      final sweep = (v / total) * (2 * math.pi);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = seg.color;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        false,
        paint,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _PiePainter old) {
    if (old.strokeWidth != strokeWidth) return true;
    if (old.baseColor != baseColor) return true;
    if (old.segments.length != segments.length) return true;
    for (var i = 0; i < segments.length; i++) {
      if (old.segments[i].value != segments[i].value) return true;
      if (old.segments[i].color != segments[i].color) return true;
    }
    return false;
  }
}

// ==========================
// Glass Profile
// ==========================
class _GlassProfileHeader extends StatelessWidget {
  const _GlassProfileHeader({required this.user});
  final User? user;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final name = (user?.displayName ?? 'Name  Lastname').trim();
    final email = (user?.email ?? 'User@gmail.com').trim();
    final photoUrl = user?.photoURL;

    final card = scheme.surface;
    final border =
        isDark ? Colors.white.withOpacity(0.12) : Colors.white.withOpacity(0.55);

    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: card.withOpacity(isDark ? 0.82 : 0.92),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.30 : 0.08),
                blurRadius: 28,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: scheme.primary.withOpacity(0.55), width: 2),
                ),
                child: CircleAvatar(
                  backgroundColor:
                      scheme.primary.withOpacity(isDark ? 0.12 : 0.10),
                  backgroundImage:
                      (photoUrl != null && photoUrl.isNotEmpty)
                          ? NetworkImage(photoUrl)
                          : null,
                  child: (photoUrl == null || photoUrl.isEmpty)
                      ? Icon(Icons.person_rounded,
                          color: scheme.onSurface.withOpacity(0.65), size: 30)
                      : null,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'Name  Lastname' : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email.isEmpty ? 'User@gmail.com' : email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color:
                            scheme.onSurface.withOpacity(isDark ? 0.70 : 0.60),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================
// Glass Box Wrapper
// ==========================
class _GlassBox extends StatelessWidget {
  const _GlassBox({required this.child, this.padding});
  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final card = scheme.surface;
    final border =
        isDark ? Colors.white.withOpacity(0.12) : Colors.white.withOpacity(0.55);

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: padding ?? const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: card.withOpacity(isDark ? 0.82 : 0.92),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.30 : 0.06),
                blurRadius: 18,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// ==========================
// Summary Card
// ==========================
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.accent,
    required this.icon,
  });

  final String title;
  final String value;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 96,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: accent.withOpacity(isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withOpacity(isDark ? 0.35 : 0.26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: accent.withOpacity(isDark ? 0.22 : 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.onSurface.withOpacity(isDark ? 0.70 : 0.60),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Center(
            child: Text(
              value,
              style: TextStyle(
                color: scheme.onSurface,
                fontWeight: FontWeight.w900,
                fontSize: 26,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================
// Mini List (30 วัน)
// ==========================
class _MiniList extends StatelessWidget {
  const _MiniList({required this.tasks, required this.categoryText});

  final List<Task> tasks;
  final String Function(Task t) categoryText;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final now = DateTime.now();

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: tasks.length,
      shrinkWrap: true,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        color:
            isDark ? Colors.white.withOpacity(0.10) : Colors.black.withOpacity(0.06),
      ),
      itemBuilder: (_, i) {
        final t = tasks[i];

        final isOverdue = !t.done && t.date.isBefore(now);
        final dueSoon =
            !t.done && !isOverdue && t.date.difference(now) <= const Duration(days: 2);

        final bg = isOverdue
            ? Colors.red.withOpacity(isDark ? 0.12 : 0.07)
            : dueSoon
                ? scheme.primary.withOpacity(isDark ? 0.16 : 0.08)
                : Colors.transparent;

        final dotColor = isOverdue
            ? Colors.red
            : dueSoon
                ? scheme.primary
                : Colors.transparent;

        final timeColor = isOverdue
            ? Colors.red.withOpacity(0.92)
            : dueSoon
                ? scheme.primary.withOpacity(0.95)
                : scheme.onSurface.withOpacity(isDark ? 0.70 : 0.60);

        return Container(
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      categoryText(t),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.onSurface.withOpacity(isDark ? 0.70 : 0.60),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                formatDate(context, t.date, withTime: true),
                style: TextStyle(color: timeColor, fontWeight: FontWeight.w800, fontSize: 12),
              ),
              const SizedBox(width: 6),
              if (t.starred)
                const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFE0D51C),
                  size: 18,
                ),
            ],
          ),
        );
      },
    );
  }
}

// ==========================
// Count Box
// ==========================
class _CountBox extends StatelessWidget {
  const _CountBox({required this.value, required this.accent, required this.label});
  final int value;
  final Color accent;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 108,
      height: 76,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: accent.withOpacity(isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(isDark ? 0.35 : 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: scheme.onSurface.withOpacity(isDark ? 0.70 : 0.60),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          const Spacer(),
          Center(
            child: Text(
              '$value',
              style: TextStyle(
                color: scheme.onSurface,
                fontWeight: FontWeight.w900,
                fontSize: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
