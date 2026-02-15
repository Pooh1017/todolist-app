// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'db/task_dao.dart';
import 'models/task.dart';
import 'task_detail_page.dart';

// ✅ ใช้รูปแบบวันที่ตาม Settings ทั้งแอพ
import 'utils/date_fmt.dart';

// ✅ l10n
import 'l10n/app_localizations.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({
    super.key,
    required this.title,
    required this.primaryColor,

    // ✅ ใช้ key แทน title เพื่อให้ logic ไม่พังตอนเปลี่ยนภาษา
    required this.categoryKey, // 'work' | 'todo_all' | 'plan' | 'near_due'
  });

  final String title; // ใช้แสดงบนหัวหน้า
  final Color primaryColor;

  // ✅ key ที่เสถียร ไม่เปลี่ยนตามภาษา
  final String categoryKey;

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  // ✅ โทนเดียวกับหน้า Home (fallback light gradient)
  static const _bgTopLight = Color(0xFFF6F7FB);
  static const _bgBottomLight = Color(0xFFF1F3F8);

  // ✅ คีย์หมวดหมู่ (ให้ตรงกับ HomePage)
  static const String _kWork = 'work';
  static const String _kTodoAll = 'todo_all';
  static const String _kPlan = 'plan';
  static const String _kNearDue = 'near_due';

  bool _loading = true;
  final List<Task> _items = [];

  // ✅ หน้ารวม “สิ่งที่ต้องทำ (รวมดาว)”
  bool get _isTodoAllPage => widget.categoryKey == _kTodoAll;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  // ============================
  // ✅ Category mapping (รองรับข้อมูลเก่าไทยด้วย)
  // ============================

  String _catKeyOf(Task t) {
    final c = (t.category).trim();

    // ข้อมูลใหม่: เก็บเป็น key
    if (c == _kWork || c == _kTodoAll || c == _kPlan || c == _kNearDue) {
      return c;
    }

    // ข้อมูลเก่า (ไทย)
    if (c == 'งาน') return _kWork;
    if (c == 'สิ่งที่ต้องทำ') return _kTodoAll;
    if (c == 'ที่วางแผนไว้') return _kPlan;
    if (c == 'ใกล้ครบกำหนด') return _kNearDue;

    return c;
  }

  String _catLabel(BuildContext context, String catKeyOrLegacy) {
    final t = AppLocalizations.of(context)!;
    final key = catKeyOrLegacy.trim();

    switch (key) {
      case _kWork:
        return t.drawerCatWork;
      case _kTodoAll:
        return t.drawerCatTodo;
      case _kPlan:
        return t.drawerCatPlan;
      case _kNearDue:
        return t.drawerCatImportant;
      default:
        // fallback กรณีเป็นไทยเก่า
        if (key == 'งาน') return t.drawerCatWork;
        if (key == 'สิ่งที่ต้องทำ') return t.drawerCatTodo;
        if (key == 'ที่วางแผนไว้') return t.drawerCatPlan;
        if (key == 'ใกล้ครบกำหนด') return t.drawerCatImportant;
        return key;
    }
  }

  Future<void> _reload() async {
    if (!mounted) return;
    setState(() => _loading = true);

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) {
      setState(() {
        _items.clear();
        _loading = false;
      });
      return;
    }

    final all = await TaskDao.instance.getAll(uid);
    if (!mounted) return;

    List<Task> data;

    if (_isTodoAllPage) {
      // ✅ รวม todo_all + starred เฉพาะที่ยังไม่เสร็จ
      data = all
          .where((x) => !x.done && (_catKeyOf(x) == _kTodoAll || x.starred))
          .toList();
    } else {
      // ✅ หน้าอื่น: เอาตามหมวด และไม่เอางาน starred
      data = all
          .where((x) =>
              !x.done && _catKeyOf(x) == widget.categoryKey && !x.starred)
          .toList();
    }

    // ✅ เรียง: ดาวก่อน แล้วตามเวลา
    data.sort((a, b) {
      final s = (b.starred ? 1 : 0) - (a.starred ? 1 : 0);
      if (s != 0) return s;
      return a.date.compareTo(b.date);
    });

    setState(() {
      _items
        ..clear()
        ..addAll(data);
      _loading = false;
    });
  }

  Color _tint(Color base, Color accent, double amount) =>
      Color.lerp(base, accent, amount) ?? base;

  String _two(int n) => n.toString().padLeft(2, '0');
  String _timeText(TimeOfDay t) => '${_two(t.hour)}:${_two(t.minute)}';

  Future<TimeOfDay?> _showThaiTimeInputDialog(
    BuildContext context, {
    required TimeOfDay initial,
  }) async {
    final t = AppLocalizations.of(context)!;

    final formKey = GlobalKey<FormState>();
    final ctrl = TextEditingController(
      text:
          '${initial.hour.toString().padLeft(2, '0')}:${initial.minute.toString().padLeft(2, '0')}',
    );

    String? validate(String? v) {
      final s = (v ?? '').trim();
      final m = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$').firstMatch(s);
      if (m == null) return t.timeInvalidHint;
      return null;
    }

    TimeOfDay parse(String s) {
      final parts = s.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }

    return showDialog<TimeOfDay>(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return AlertDialog(
          title: Text(t.timeInputTitle),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: ctrl,
              autofocus: true,
              keyboardType: TextInputType.datetime,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(hintText: t.timeInputHint),
              validator: validate,
              onFieldSubmitted: (_) {
                if (formKey.currentState?.validate() == true) {
                  Navigator.pop(context, parse(ctrl.text.trim()));
                }
              },
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d:]')),
                LengthLimitingTextInputFormatter(5),
                _TimeTextInputFormatter(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t.cancel),
            ),
            TextButton(
              onPressed: () {
                final now = TimeOfDay.now();
                ctrl.text =
                    '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
              },
              child: Text(t.nowText),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() != true) return;
                Navigator.pop(context, parse(ctrl.text.trim()));
              },
              child: Text(t.okText),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addTask({
    required Color card,
    required Color ink,
    required Color muted,
    required Color line,
    required bool isDark,
  }) async {
    final t = AppLocalizations.of(context)!;
    final ctrl = TextEditingController();

    DateTime pickedDate = DateTime.now();
    TimeOfDay pickedTime = TimeOfDay.now();

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    final created = await showGeneralDialog<Task>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'add',
      barrierColor: Colors.black.withOpacity(0.25),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, a1, a2) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                      decoration: BoxDecoration(
                        color: card.withOpacity(isDark ? 0.82 : 0.92),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.12)
                              : Colors.white.withOpacity(0.40),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                Colors.black.withOpacity(isDark ? 0.35 : 0.10),
                            blurRadius: 30,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isTodoAllPage
                                  ? t.addItemTitle
                                  : t.addInCategoryTitle(widget.title),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: ink,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: ctrl,
                              textInputAction: TextInputAction.done,
                              style: TextStyle(
                                color: ink,
                                fontWeight: FontWeight.w700,
                              ),
                              decoration: InputDecoration(
                                hintText: t.addItemHint,
                                hintStyle:
                                    TextStyle(color: muted.withOpacity(0.9)),
                                filled: true,
                                fillColor: card,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide(color: line),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide(color: line),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide(
                                    color:
                                        widget.primaryColor.withOpacity(0.55),
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () async {
                                final d = await showDatePicker(
                                  context: context,
                                  initialDate: pickedDate,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (d != null) {
                                  setLocalState(() => pickedDate = d);
                                }
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: _tint(
                                    card,
                                    widget.primaryColor,
                                    isDark ? 0.18 : 0.10,
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: line),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.event_rounded,
                                        color: widget.primaryColor
                                            .withOpacity(0.92)),
                                    const SizedBox(width: 10),
                                    Text(
                                      formatDate(context, pickedDate),
                                      style: TextStyle(
                                        color: ink,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      t.pickDate,
                                      style: TextStyle(
                                        color: muted.withOpacity(0.9),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () async {
                                final x = await _showThaiTimeInputDialog(
                                  context,
                                  initial: pickedTime,
                                );
                                if (x != null) {
                                  setLocalState(() => pickedTime = x);
                                }
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: _tint(
                                    card,
                                    widget.primaryColor,
                                    isDark ? 0.14 : 0.06,
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: line),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.access_time_rounded,
                                        color: widget.primaryColor
                                            .withOpacity(0.92)),
                                    const SizedBox(width: 10),
                                    Text(
                                      _timeText(pickedTime),
                                      style: TextStyle(
                                        color: ink,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      t.pickTime,
                                      style: TextStyle(
                                        color: muted.withOpacity(0.9),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      foregroundColor: muted,
                                    ),
                                    child: Text(t.cancel),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      final text = ctrl.text.trim();
                                      if (text.isEmpty) return;

                                      final dt = DateTime(
                                        pickedDate.year,
                                        pickedDate.month,
                                        pickedDate.day,
                                        pickedTime.hour,
                                        pickedTime.minute,
                                      );

                                      final catKey = _isTodoAllPage
                                          ? _kTodoAll
                                          : widget.categoryKey;

                                      // ✅ FIX: ใช้ newLocal เพื่อได้ cloudId/updatedAt/syncState อัตโนมัติ
                                      Navigator.pop(
                                        context,
                                        Task.newLocal(
                                          userId: uid,
                                          title: text,
                                          category: catKey,
                                          date: dt,
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: widget.primaryColor,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: Text(t.save),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
      transitionBuilder: (_, anim, __, child) {
        final curved =
            CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween(begin: 0.98, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );

    if (created == null) return;

    // ✅ ใส่ userId ให้ชัวร์ (กันกรณีถูกส่งมาว่าง)
    await TaskDao.instance.insert(created.copyWith(userId: uid));
    await _reload();
  }

  Color _accentForTask(Task x) {
    if (!_isTodoAllPage) return widget.primaryColor;

    final k = _catKeyOf(x);
    if (k == _kWork) return const Color(0xFF24C96A);
    if (k == _kTodoAll) return const Color(0xFFE0D51C);
    if (k == _kPlan) return const Color(0xFF2E5E8D);
    if (k == _kNearDue) return const Color(0xFFF08C63);

    return widget.primaryColor;
  }

  Future<void> _openTask(Task x) async {
    final changed = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TaskDetailPage(task: x)),
    );
    if (changed == true) await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final bgTop = isDark ? theme.scaffoldBackgroundColor : _bgTopLight;
    final bgBottom = isDark ? theme.scaffoldBackgroundColor : _bgBottomLight;

    final card = scheme.surface;
    final ink = scheme.onSurface;
    final muted = scheme.onSurface.withOpacity(isDark ? 0.70 : 0.60);
    final line =
        isDark ? Colors.white.withOpacity(0.10) : Colors.black.withOpacity(0.06);

    final titleText = _isTodoAllPage ? t.todoAllTitle : widget.title;

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
                Row(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: card,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: line),
                        ),
                        child: Icon(Icons.arrow_back_rounded, color: ink),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        titleText,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: ink,
                        ),
                      ),
                    ),
                    if (_loading)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: _loading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: widget.primaryColor.withOpacity(0.9),
                          ),
                        )
                      : _items.isEmpty
                          ? Center(
                              child: Text(
                                t.categoryEmptyHint,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: muted.withOpacity(0.95),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              itemCount: _items.length,
                              itemBuilder: (_, i) {
                                final x = _items[i];
                                final accent = _accentForTask(x);

                                return _TaskTile(
                                  task: x,
                                  accent: accent,
                                  categoryText:
                                      _catLabel(context, _catKeyOf(x)),
                                  card: card,
                                  ink: ink,
                                  muted: muted,
                                  line: line,
                                  isDark: isDark,
                                  onOpen: () => unawaited(_openTask(x)),
                                  onToggleDone: () => unawaited(() async {
                                    await TaskDao.instance.toggleDone(x);
                                    await _reload();
                                  }()),
                                  onToggleStar: () => unawaited(() async {
                                    await TaskDao.instance.toggleStar(x);
                                    await _reload();
                                  }()),
                                  onDelete: () => unawaited(() async {
                                    if (x.id != null) {
                                      await TaskDao.instance.deleteById(x.id!);
                                      await _reload();
                                    }
                                  }()),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => unawaited(_addTask(
          card: card,
          ink: ink,
          muted: muted,
          line: line,
          isDark: isDark,
        )),
        backgroundColor: widget.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.task,
    required this.accent,
    required this.categoryText,
    required this.card,
    required this.ink,
    required this.muted,
    required this.line,
    required this.isDark,
    required this.onOpen,
    required this.onToggleDone,
    required this.onToggleStar,
    required this.onDelete,
  });

  final Task task;
  final Color accent;
  final String categoryText;

  final Color card;
  final Color ink;
  final Color muted;
  final Color line;
  final bool isDark;

  final VoidCallback onOpen;
  final VoidCallback onToggleDone;
  final VoidCallback onToggleStar;
  final VoidCallback onDelete;

  Color _tint(Color base, Color accent, double amount) =>
      Color.lerp(base, accent, amount) ?? base;

  @override
  Widget build(BuildContext context) {
    final cardBg = _tint(card, accent, isDark ? 0.10 : 0.06);
    final cardBorder = accent.withOpacity(isDark ? 0.28 : 0.18);
    final chipBg = accent.withOpacity(isDark ? 0.18 : 0.14);

    return Dismissible(
      key: ValueKey(
          'cat_task_${task.id ?? task.cloudId}_${task.date.millisecondsSinceEpoch}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(isDark ? 0.20 : 0.12),
          borderRadius: BorderRadius.circular(22),
          border:
              Border.all(color: Colors.red.withOpacity(isDark ? 0.35 : 0.25)),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.red),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return true;
      },
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onOpen,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: cardBorder),
          ),
          child: Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: onToggleDone,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: task.done
                        ? accent.withOpacity(isDark ? 0.22 : 0.16)
                        : (isDark
                            ? Colors.white.withOpacity(0.06)
                            : Colors.black.withOpacity(0.04)),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: task.done
                          ? accent.withOpacity(isDark ? 0.55 : 0.45)
                          : line,
                    ),
                  ),
                  child: Icon(
                    task.done ? Icons.check_rounded : Icons.circle_outlined,
                    color: task.done ? accent : muted,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ink,
                        fontWeight: FontWeight.w900,
                        decoration: task.done
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: chipBg,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                                color:
                                    accent.withOpacity(isDark ? 0.35 : 0.25)),
                          ),
                          child: Text(
                            categoryText,
                            style: TextStyle(
                              color: accent.withOpacity(0.98),
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        Text(
                          formatDate(context, task.date, withTime: true),
                          style: TextStyle(
                            color: muted.withOpacity(0.98),
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: onToggleStar,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.black.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: line),
                  ),
                  child: Icon(
                    task.starred ? Icons.star_rounded : Icons.star_border_rounded,
                    color: task.starred ? const Color(0xFFE0D51C) : muted,
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

class _TimeTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(':', '');
    final d = digits.length > 4 ? digits.substring(0, 4) : digits;
    final out = (d.length <= 2) ? d : '${d.substring(0, 2)}:${d.substring(2)}';

    return TextEditingValue(
      text: out,
      selection: TextSelection.collapsed(offset: out.length),
    );
  }
}
