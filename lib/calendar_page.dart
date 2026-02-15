// ignore_for_file: use_build_context_synchronously

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart'; // ✅ เพิ่ม

import 'db/task_dao.dart';
import 'models/task.dart';
import 'task_detail_page.dart';

// ✅ l10n (generated)
import 'l10n/app_localizations.dart';

// ✅ date format ตาม Settings ทั้งแอพ
import 'utils/date_fmt.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage>
    with WidgetsBindingObserver {
  // ✅ โทนเดียวกับหน้า Home
  static const _bgTopLight = Color(0xFFF6F7FB);
  static const _bgBottomLight = Color(0xFFF1F3F8);

  // ✅ โทนสีเดียวกับ Home
  static const _blue = Color(0xFF2E5E8D);
  static const _green = Color(0xFF24C96A);
  static const _yellow = Color(0xFFE0D51C);
  static const _orange = Color(0xFFF08C63);

  // ✅ uuid generator
  static const Uuid _uuid = Uuid();

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  bool _loading = true;
  bool _didAutoRefreshOnce = false;

  final Map<DateTime, List<Task>> _byDay = {};
  List<Task> _selectedTasks = [];

  DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

  Color _tint(Color base, Color accent, double amount) =>
      Color.lerp(base, accent, amount) ?? base;

  // ============================
  // ✅ Category key system (เหมือน Home)
  // ============================
  static const String _kWork = 'work';
  static const String _kTodoAll = 'todo_all';
  static const String _kPlan = 'plan';
  static const String _kNearDue = 'near_due';

  // ✅ รองรับข้อมูลเก่า (ภาษาไทย)
  String _catKeyOf(String raw) {
    final c = raw.trim();

    // คีย์ใหม่
    if (c == _kWork || c == _kTodoAll || c == _kPlan || c == _kNearDue) return c;

    // ข้อมูลเก่า (ไทย)
    if (c == 'งาน') return _kWork;
    if (c == 'สิ่งที่ต้องทำ') return _kTodoAll;
    if (c == 'ที่วางแผนไว้') return _kPlan;
    if (c == 'ใกล้ครบกำหนด') return _kNearDue;

    return _kWork;
  }

  String _catLabel(AppLocalizations l10n, String rawOrKey) {
    switch (_catKeyOf(rawOrKey)) {
      case _kWork:
        return l10n.drawerCatWork;
      case _kTodoAll:
        return l10n.drawerCatTodo;
      case _kPlan:
        return l10n.drawerCatPlan;
      case _kNearDue:
        return l10n.drawerCatImportant;
      default:
        return l10n.drawerCatWork;
    }
  }

  Color _catAccent(ColorScheme cs, String rawOrKey) {
    switch (_catKeyOf(rawOrKey)) {
      case _kWork:
        return _green;
      case _kTodoAll:
        return _yellow;
      case _kPlan:
        return _blue;
      case _kNearDue:
        return _orange;
      default:
        return cs.primary;
    }
  }

  // ✅ ให้ HomePage เรียกได้ตอนกดแท็บ (IndexedStack จะไม่ rebuild)
  Future<void> refresh() async => _reload();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _reload();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didAutoRefreshOnce) {
      _didAutoRefreshOnce = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _reload();
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (mounted) _reload();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _reload() async {
    if (!mounted) return;

    final uid = _uid;
    if (uid == null) {
      setState(() {
        _byDay.clear();
        _selectedTasks = [];
        _loading = false;
      });
      return;
    }

    setState(() => _loading = true);

    final all = await TaskDao.instance.getAll(uid);

    final map = <DateTime, List<Task>>{};
    for (final t in all) {
      final k = _dayKey(t.date);
      (map[k] ??= []).add(t);
    }

    final selKey = _dayKey(_selectedDay);

    final selected = List<Task>.from(map[selKey] ?? const []);
    selected.sort((a, b) {
      final s = (b.starred ? 1 : 0) - (a.starred ? 1 : 0);
      if (s != 0) return s;
      return a.date.compareTo(b.date);
    });

    if (!mounted) return;

    setState(() {
      _byDay
        ..clear()
        ..addAll(map);
      _selectedTasks = selected;
      _loading = false;
    });
  }

  List<Task> _eventsForDay(DateTime day) => _byDay[_dayKey(day)] ?? const [];

  Future<void> _openTask(Task t) async {
    final changed = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TaskDetailPage(task: t)),
    );
    if (changed == true && mounted) await _reload();
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  Future<TimeOfDay?> _showTimeInputDialog(
    BuildContext context, {
    required TimeOfDay initial,
  }) async {
    final l10n = AppLocalizations.of(context);

    final formKey = GlobalKey<FormState>();
    final ctrl = TextEditingController(
      text: '${_two(initial.hour)}:${_two(initial.minute)}',
    );

    String? validate(String? v) {
      final s = (v ?? '').trim();
      final m = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$').firstMatch(s);
      if (m == null) return l10n.timeInputInvalid;
      return null;
    }

    TimeOfDay parse(String s) {
      final parts = s.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }

    return showDialog<TimeOfDay>(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        title: Text(l10n.timeInputTitle),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: ctrl,
            autofocus: true,
            keyboardType: TextInputType.datetime,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(hintText: l10n.timeInputHint),
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
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              final now = TimeOfDay.now();
              ctrl.text = '${_two(now.hour)}:${_two(now.minute)}';
            },
            child: Text(l10n.now),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() != true) return;
              Navigator.pop(context, parse(ctrl.text.trim()));
            },
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  // ============================
  // ✅ เพิ่มรายการ
  // ============================
  Future<void> _addForSelectedDay() async {
    final uid = _uid;
    if (uid == null) return;

    final ctrl = TextEditingController();

    DateTime pickedDay = _selectedDay;
    TimeOfDay pickedTime = TimeOfDay.now();
    String pickedCatKey = _kWork;

    final created = await showGeneralDialog<Task>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'add',
      barrierColor: Colors.black.withOpacity(0.25),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, a1, a2) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            final theme = Theme.of(context);
            final scheme = theme.colorScheme;
            final isDark = theme.brightness == Brightness.dark;
            final l10n = AppLocalizations.of(context);

            final card = scheme.surface;
            final line = isDark
                ? Colors.white.withOpacity(0.10)
                : Colors.black.withOpacity(0.06);

            Future<void> pickDate() async {
              final d = await showDatePicker(
                context: context,
                initialDate: pickedDay,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (d == null) return;
              setLocalState(() => pickedDay = DateTime(d.year, d.month, d.day));
            }

            Future<void> pickTime() async {
              final picked =
                  await _showTimeInputDialog(context, initial: pickedTime);
              if (picked == null) return;
              setLocalState(() => pickedTime = picked);
            }

            final dayText = formatDate(context, pickedDay);
            final timeText = '${_two(pickedTime.hour)}:${_two(pickedTime.minute)}';

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
                              : Colors.white.withOpacity(0.45),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withOpacity(isDark ? 0.35 : 0.08),
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
                              l10n.addItemTitle,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: scheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: ctrl,
                              textInputAction: TextInputAction.done,
                              style: TextStyle(color: scheme.onSurface),
                              decoration: InputDecoration(
                                hintText: l10n.typeItemHint,
                                filled: true,
                                fillColor: scheme.surface,
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
                                    color: scheme.primary.withOpacity(0.70),
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                _chip(
                                  context,
                                  _catLabel(l10n, _kWork),
                                  pickedCatKey == _kWork,
                                  _catAccent(scheme, _kWork),
                                  () => setLocalState(
                                      () => pickedCatKey = _kWork),
                                ),
                                _chip(
                                  context,
                                  _catLabel(l10n, _kTodoAll),
                                  pickedCatKey == _kTodoAll,
                                  _catAccent(scheme, _kTodoAll),
                                  () => setLocalState(
                                      () => pickedCatKey = _kTodoAll),
                                ),
                                _chip(
                                  context,
                                  _catLabel(l10n, _kPlan),
                                  pickedCatKey == _kPlan,
                                  _catAccent(scheme, _kPlan),
                                  () => setLocalState(
                                      () => pickedCatKey = _kPlan),
                                ),
                                _chip(
                                  context,
                                  _catLabel(l10n, _kNearDue),
                                  pickedCatKey == _kNearDue,
                                  _catAccent(scheme, _kNearDue),
                                  () => setLocalState(
                                      () => pickedCatKey = _kNearDue),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: pickDate,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: _tint(card, scheme.primary,
                                      isDark ? 0.16 : 0.08),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: line),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.event_rounded,
                                        color: scheme.primary
                                            .withOpacity(0.90)),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        dayText,
                                        style: TextStyle(
                                          color: scheme.onSurface,
                                          fontWeight: FontWeight.w800,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      l10n.pickDate,
                                      style: TextStyle(
                                        color: scheme.onSurface.withOpacity(
                                            isDark ? 0.70 : 0.60),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: pickTime,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: _tint(card, scheme.primary,
                                      isDark ? 0.14 : 0.06),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: line),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.schedule_rounded,
                                        color: scheme.primary
                                            .withOpacity(0.90)),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        timeText,
                                        style: TextStyle(
                                          color: scheme.onSurface,
                                          fontWeight: FontWeight.w800,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      l10n.pickTime,
                                      style: TextStyle(
                                        color: scheme.onSurface.withOpacity(
                                            isDark ? 0.70 : 0.60),
                                        fontWeight: FontWeight.w700,
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
                                      foregroundColor: scheme.onSurface
                                          .withOpacity(0.75),
                                    ),
                                    child: Text(l10n.cancel),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      final text = ctrl.text.trim();
                                      if (text.isEmpty) return;

                                      final when = DateTime(
                                        pickedDay.year,
                                        pickedDay.month,
                                        pickedDay.day,
                                        pickedTime.hour,
                                        pickedTime.minute,
                                      );

                                      // ✅ แก้ตรงนี้: สร้าง cloudId ตอนกด Save
                                      final cloudId = _uuid.v4();

                                      Navigator.pop(
                                        context,
                                        Task.newLocal(
                                          userId: uid,
                                          title: text,
                                          category: pickedCatKey,
                                          date: when,
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: scheme.primary,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: Text(l10n.save),
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

    await TaskDao.instance.insert(created.copyWith(userId: uid));

    if (!mounted) return;

    setState(() {
      _selectedDay = _dayKey(created.date);
      _focusedDay = _selectedDay;
    });

    await _reload();
  }

  Widget _chip(
    BuildContext context,
    String label,
    bool selected,
    Color accent,
    VoidCallback onTap,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final base = scheme.surface;
    final bg = selected ? accent.withOpacity(isDark ? 0.22 : 0.18) : base;
    final border = selected
        ? accent.withOpacity(0.55)
        : (isDark
            ? Colors.white.withOpacity(0.12)
            : Colors.black.withOpacity(0.08));
    final fg = selected
        ? scheme.onSurface
        : scheme.onSurface.withOpacity(isDark ? 0.75 : 0.70);

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(color: fg, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteTask(Task task) async {
    if (task.id != null) {
      await TaskDao.instance.deleteById(task.id!);
    } else {
      await TaskDao.instance.deleteTask(task);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final l10n = AppLocalizations.of(context);

    final bgTop = isDark ? theme.scaffoldBackgroundColor : _bgTopLight;
    final bgBottom = isDark ? theme.scaffoldBackgroundColor : _bgBottomLight;

    final card = scheme.surface;
    final muted = scheme.onSurface.withOpacity(isDark ? 0.70 : 0.60);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _addForSelectedDay,
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        child: const Icon(Icons.add_rounded),
      ),
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
                    Text(
                      l10n.calendarTitle,
                      style: TextStyle(
                        fontSize: 20,
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
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: Container(
                      decoration: BoxDecoration(
                        color: card.withOpacity(isDark ? 0.82 : 0.92),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.12)
                              : Colors.white.withOpacity(0.55),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
                            blurRadius: 26,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: TableCalendar<Task>(
                        firstDay: DateTime.utc(2000, 1, 1),
                        lastDay: DateTime.utc(2100, 12, 31),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
                        eventLoader: _eventsForDay,
                        headerStyle: HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          leftChevronIcon:
                              Icon(Icons.chevron_left_rounded, color: muted),
                          rightChevronIcon:
                              Icon(Icons.chevron_right_rounded, color: muted),
                          titleTextStyle: TextStyle(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        calendarStyle: CalendarStyle(
                          todayDecoration: BoxDecoration(
                            color:
                                scheme.primary.withOpacity(isDark ? 0.22 : 0.12),
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: BoxDecoration(
                            color: scheme.primary,
                            shape: BoxShape.circle,
                          ),
                          markerDecoration: BoxDecoration(
                            color: scheme.primary.withOpacity(0.70),
                            shape: BoxShape.circle,
                          ),
                          defaultTextStyle:
                              TextStyle(color: scheme.onSurface),
                          weekendTextStyle:
                              TextStyle(color: scheme.onSurface),
                          outsideDaysVisible: false,
                        ),
                        daysOfWeekStyle: DaysOfWeekStyle(
                          weekdayStyle:
                              TextStyle(color: muted, fontWeight: FontWeight.w800),
                          weekendStyle:
                              TextStyle(color: muted, fontWeight: FontWeight.w800),
                        ),
                        onDaySelected: (selected, focused) {
                          setState(() {
                            _selectedDay = selected;
                            _focusedDay = focused;
                            _selectedTasks =
                                List<Task>.from(_eventsForDay(selected));
                            _selectedTasks.sort((a, b) {
                              final s = (b.starred ? 1 : 0) - (a.starred ? 1 : 0);
                              if (s != 0) return s;
                              return a.date.compareTo(b.date);
                            });
                          });
                        },
                        onPageChanged: (focused) =>
                            setState(() => _focusedDay = focused),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.calendarItemsTitle(formatDate(context, _selectedDay)),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: _loading
                      ? const SizedBox.shrink()
                      : _selectedTasks.isEmpty
                          ? Center(
                              child: Text(
                                l10n.calendarEmptyHint,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: scheme.onSurface
                                      .withOpacity(isDark ? 0.70 : 0.60),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              itemCount: _selectedTasks.length,
                              itemBuilder: (_, i) {
                                final task = _selectedTasks[i];
                                return _TaskTile(
                                  task: task,
                                  onOpen: () => _openTask(task),
                                  onToggleDone: () async {
                                    await TaskDao.instance.toggleDone(task);
                                    await _reload();
                                  },
                                  onToggleStar: () async {
                                    await TaskDao.instance.toggleStar(task);
                                    await _reload();
                                  },
                                  onDelete: () async {
                                    await _deleteTask(task);
                                    await _reload();
                                  },
                                  categoryText: _catLabel(l10n, task.category),
                                );
                              },
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

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.task,
    required this.categoryText,
    required this.onOpen,
    required this.onToggleDone,
    required this.onToggleStar,
    required this.onDelete,
  });

  final Task task;
  final String categoryText;
  final VoidCallback onOpen;
  final VoidCallback onToggleDone;
  final VoidCallback onToggleStar;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final card = scheme.surface;
    final line =
        isDark ? Colors.white.withOpacity(0.10) : Colors.black.withOpacity(0.06);
    final muted = scheme.onSurface.withOpacity(isDark ? 0.70 : 0.60);

    final now = DateTime.now();
    final overdue = !task.done && task.date.isBefore(now);
    final nearDue =
        !task.done && !overdue && task.date.difference(now) <= const Duration(days: 2);

    final dateColor = overdue
        ? Colors.red
        : nearDue
            ? const Color(0xFFE0D51C)
            : muted;

    // ✅ แก้ key: ใช้ cloudId ถ้ามี (กันชน/กันซ้ำก่อนมี id)
    final safeKey = (task.cloudId.trim().isNotEmpty)
        ? 'cal_task_${task.cloudId}'
        : 'cal_task_${task.id ?? task.title}_${task.date.millisecondsSinceEpoch}';

    return Dismissible(
      key: ValueKey(safeKey),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(isDark ? 0.20 : 0.12),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.red.withOpacity(isDark ? 0.35 : 0.25)),
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
            color: card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: line),
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
                        ? scheme.primary.withOpacity(isDark ? 0.22 : 0.14)
                        : (isDark
                            ? Colors.white.withOpacity(0.06)
                            : Colors.black.withOpacity(0.04)),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: task.done
                          ? scheme.primary.withOpacity(isDark ? 0.55 : 0.40)
                          : (isDark
                              ? Colors.white.withOpacity(0.12)
                              : Colors.black.withOpacity(0.08)),
                    ),
                  ),
                  child: Icon(
                    task.done ? Icons.check_rounded : Icons.circle_outlined,
                    color: task.done ? scheme.primary : muted,
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
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w900,
                        decoration:
                            task.done ? TextDecoration.lineThrough : TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 2),
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: muted,
                        ),
                        children: [
                          TextSpan(text: '$categoryText • '),
                          TextSpan(
                            text: formatDate(context, task.date, withTime: true),
                            style: TextStyle(
                              color: dateColor,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
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
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.12)
                          : Colors.black.withOpacity(0.08),
                    ),
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
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(':', '');
    final d = digits.length > 4 ? digits.substring(0, 4) : digits;
    final out = (d.length <= 2) ? d : '${d.substring(0, 2)}:${d.substring(2)}';

    return TextEditingValue(
      text: out,
      selection: TextSelection.collapsed(offset: out.length),
    );
  }
}
