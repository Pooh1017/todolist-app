import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'calendar_page.dart';
import 'category_page.dart';
import 'overview_page.dart';
import 'search_page.dart';
import 'side_menu_drawer.dart';

import 'db/task_dao.dart';
import 'models/task.dart';

import 'task_detail_page.dart';
import 'utils/date_fmt.dart';

import 'l10n/app_localizations.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // ใช้เป็น fallback เฉพาะ light gradient เดิม
  static const _bgTop = Color(0xFFF6F7FB);
  static const _bgBottom = Color(0xFFF1F3F8);

  static const _blue = Color(0xFF2E5E8D);
  static const _green = Color(0xFF24C96A);
  static const _yellow = Color(0xFFE0D51C);
  static const _orange = Color(0xFFF08C63);

  bool _expandToday = true;
  bool _expandFuture = true;
  bool _expandBefore = true;
  bool _expandDoneToday = true;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey _calendarKey = GlobalKey();
  final GlobalKey _overviewKey = GlobalKey();

  int _tabIndex = 1; // 1=Home
  bool _loading = true;

  final List<Task> _tasks = [];
  DateTime _selectedDateForNewTask = DateTime.now();

  DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);
  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // ✅ ใช้สำหรับเวลา HH:mm อย่างเดียว
  String _two(int n) => n.toString().padLeft(2, '0');

  // ============================
  // ✅ Category key system (รองรับข้อมูลเก่าเป็นภาษาไทยด้วย)
  // ============================
  static const String _kWork = 'work';
  static const String _kTodoAll = 'todo_all';
  static const String _kPlan = 'plan';
  static const String _kNearDue = 'near_due';

  String _catKeyOf(Task t) {
    final c = (t.category).trim();

    // ✅ ข้อมูลใหม่: เก็บเป็น key
    if (c == _kWork || c == _kTodoAll || c == _kPlan || c == _kNearDue) return c;

    // ✅ รองรับข้อมูลเก่า (ไทย)
    if (c == 'งาน') return _kWork;
    if (c == 'สิ่งที่ต้องทำ') return _kTodoAll;
    if (c == 'ที่วางแผนไว้') return _kPlan;
    if (c == 'ใกล้ครบกำหนด') return _kNearDue;

    // fallback: ถ้าเป็นหมวดอื่นๆ ในอนาคต
    return c;
  }

  String _catLabel(BuildContext context, String catKeyOrLegacy) {
    final tr = AppLocalizations.of(context)!;
    final key = catKeyOrLegacy.trim();

    switch (key) {
      case _kWork:
        return tr.drawerCatWork;
      case _kTodoAll:
        return tr.drawerCatTodo;
      case _kPlan:
        return tr.drawerCatPlan;
      case _kNearDue:
        return tr.drawerCatImportant;
      default:
        // รองรับกรณีถูกส่งมาเป็นไทยเก่าโดยตรง
        if (key == 'งาน') return tr.drawerCatWork;
        if (key == 'สิ่งที่ต้องทำ') return tr.drawerCatTodo;
        if (key == 'ที่วางแผนไว้') return tr.drawerCatPlan;
        if (key == 'ใกล้ครบกำหนด') return tr.drawerCatImportant;

        return key;
    }
  }

  int _countCatBaseKey(String key) =>
      _tasks.where((t) => _catKeyOf(t) == key && !t.done && !t.starred).length;

  int _countTodo() => _tasks
      .where((t) => !t.done && (_catKeyOf(t) == _kTodoAll || t.starred))
      .length;

  void _setTab(int i) {
    if (_tabIndex == i) {
      _refreshTab(i);
      return;
    }
    setState(() => _tabIndex = i);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshTab(i));
  }

  void _refreshTab(int i) {
    if (i == 1) {
      _reload();
      return;
    }
    if (i == 2) {
      final st = _calendarKey.currentState;
      if (st != null) (st as dynamic).refresh();
      return;
    }
    if (i == 3) {
      final st = _overviewKey.currentState;
      if (st != null) (st as dynamic).refresh();
      return;
    }
  }

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final data = await TaskDao.instance.getAll();
    if (!mounted) return;
    setState(() {
      _tasks
        ..clear()
        ..addAll(data);
      _loading = false;
    });
  }

  Future<void> _openCategory(
    BuildContext context, {
    required String title,
    required Color color,
    required String categoryKey,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryPage(
          title: title,
          primaryColor: color,
          categoryKey: categoryKey, // ✅ logic (key)
        ),
      ),
    );
    await _reload();
  }

  Future<void> _handleDrawerSelect(String key) async {
    if (_tabIndex != 1) setState(() => _tabIndex = 1);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final t = AppLocalizations.of(context)!;

      switch (key) {
        case 'cat_work':
          await _openCategory(
            context,
            title: t.drawerCatWork,
            color: _green,
            categoryKey: _kWork,
          );
          break;

        case 'cat_todo':
          await _openCategory(
            context,
            title: t.drawerCatTodo,
            color: _yellow,
            categoryKey: _kTodoAll,
          );
          break;

        case 'cat_plan':
          await _openCategory(
            context,
            title: t.drawerCatPlan,
            color: _blue,
            categoryKey: _kPlan,
          );
          break;

        case 'cat_important':
          await _openNearDueAll(context);
          break;

        // map key เก่า
        case 'important':
          await _openCategory(
            context,
            title: t.drawerCatTodo,
            color: _yellow,
            categoryKey: _kTodoAll,
          );
          break;

        default:
          break;
      }
    });
  }

  Future<void> _openSearch(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SearchPage()),
    );
    await _reload();
  }

  Future<void> _openNearDueAll(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NearDueAllPage()),
    );
    await _reload();
  }

  Future<void> _openTask(Task t) async {
    final changed = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TaskDetailPage(task: t)),
    );
    if (changed == true) await _reload();
  }

  Future<TimeOfDay?> _showThaiTimeInputDialog({
    required TimeOfDay initial,
  }) async {
    final formKey = GlobalKey<FormState>();
    final ctrl = TextEditingController(
      text:
          '${initial.hour.toString().padLeft(2, '0')}:${initial.minute.toString().padLeft(2, '0')}',
    );

    String? validate(String? v) {
      final s = (v ?? '').trim();
      final m = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$').firstMatch(s);
      if (m == null) return 'กรุณาใส่เวลาเป็น HH:mm (เช่น 09:30, 18:05)';
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
        title: const Text('ใส่เวลา'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: ctrl,
            autofocus: true,
            keyboardType: TextInputType.datetime,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(hintText: 'HH:mm เช่น 09:30'),
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
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () {
              final now = TimeOfDay.now();
              ctrl.text =
                  '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
            },
            child: const Text('ตอนนี้'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() != true) return;
              Navigator.pop(context, parse(ctrl.text.trim()));
            },
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  // ✅ Dialog เพิ่มรายการ (เก็บ category เป็น key)
  Future<void> _openAddDialog() async {
    final ctrl = TextEditingController();
    final tr = AppLocalizations.of(context)!;

    DateTime pickedDateTime = _selectedDateForNewTask;
    String pickedCatKey = _kWork;

    // ✅ ตัวแปรที่คุณใช้ตอนสร้าง Task ต้องประกาศใน scope นี้
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    final result = await showGeneralDialog<Task>(
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

            final card = scheme.surface;
            final line = isDark
                ? Colors.white.withOpacity(0.10)
                : Colors.black.withOpacity(0.06);

            Color tint(Color base, Color accent, double amount) =>
                Color.lerp(base, accent, amount) ?? base;

            Future<void> pickDate() async {
              final d = await showDatePicker(
                context: context,
                initialDate: pickedDateTime,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (d == null) return;
              setLocalState(() {
                pickedDateTime = DateTime(
                  d.year,
                  d.month,
                  d.day,
                  pickedDateTime.hour,
                  pickedDateTime.minute,
                );
              });
            }

            Future<void> pickTime() async {
              final t = await _showThaiTimeInputDialog(
                initial: TimeOfDay(
                  hour: pickedDateTime.hour,
                  minute: pickedDateTime.minute,
                ),
              );
              if (t == null) return;

              setLocalState(() {
                pickedDateTime = DateTime(
                  pickedDateTime.year,
                  pickedDateTime.month,
                  pickedDateTime.day,
                  t.hour,
                  t.minute,
                );
              });
            }

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
                        color: card.withOpacity(isDark ? 0.80 : 0.92),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.12)
                              : Colors.white.withOpacity(0.45),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                Colors.black.withOpacity(isDark ? 0.35 : 0.08),
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
                            const SizedBox(height: 6),
                            Text(
                              tr.addTaskTitle,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: scheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _Field(controller: ctrl, hint: tr.addTaskHint),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                _chip(
                                  context,
                                  _catLabel(context, _kWork),
                                  pickedCatKey == _kWork,
                                  _green,
                                  () => setLocalState(
                                      () => pickedCatKey = _kWork),
                                ),
                                _chip(
                                  context,
                                  _catLabel(context, _kTodoAll),
                                  pickedCatKey == _kTodoAll,
                                  _yellow,
                                  () => setLocalState(
                                      () => pickedCatKey = _kTodoAll),
                                ),
                                _chip(
                                  context,
                                  _catLabel(context, _kPlan),
                                  pickedCatKey == _kPlan,
                                  _blue,
                                  () => setLocalState(
                                      () => pickedCatKey = _kPlan),
                                ),
                                _chip(
                                  context,
                                  _catLabel(context, _kNearDue),
                                  pickedCatKey == _kNearDue,
                                  _orange,
                                  () => setLocalState(
                                      () => pickedCatKey = _kNearDue),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(18),
                                    onTap: pickDate,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: tint(
                                            card, _blue, isDark ? 0.16 : 0.08),
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(color: line),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.event_rounded,
                                              color: _blue.withOpacity(0.90)),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              formatDate(context, pickedDateTime),
                                              style: TextStyle(
                                                color: scheme.onSurface,
                                                fontWeight: FontWeight.w700,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(18),
                                    onTap: pickTime,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: tint(
                                            card, _blue, isDark ? 0.16 : 0.08),
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(color: line),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.access_time_rounded,
                                              color: _blue.withOpacity(0.90)),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              '${_two(pickedDateTime.hour)}:${_two(pickedDateTime.minute)}',
                                              style: TextStyle(
                                                color: scheme.onSurface,
                                                fontWeight: FontWeight.w700,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              tr.dueLabel(
                                formatDate(context, pickedDateTime, withTime: true),
                              ),
                              style: TextStyle(
                                color: scheme.onSurface
                                    .withOpacity(isDark ? 0.70 : 0.60),
                                fontWeight: FontWeight.w700,
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
                                      foregroundColor:
                                          scheme.onSurface.withOpacity(0.75),
                                    ),
                                    child: Text(tr.cancel),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      final text = ctrl.text.trim();
                                      if (text.isEmpty) return;

                                      // ✅ ใช้ factory ที่คุณมีอยู่แล้ว กันพังเรื่อง updatedAt/syncState
                                      Navigator.pop(
                                        context,
                                        Task.newLocal(
                                          userId: uid,
                                          title: text,
                                          category: pickedCatKey,
                                          date: pickedDateTime,
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _blue,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: Text(tr.save),
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
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween(begin: 0.98, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );

    if (result == null) return;

    // ✅ ปรับ updatedAt เป็นเวลาปัจจุบัน (ถ้าคุณอยากบังคับแน่นอน)
    // (ไม่จำเป็นก็ได้ เพราะ newLocal ใส่ให้แล้ว)
    final saveTask = result.copyWith(updatedAt: nowMs);

    await TaskDao.instance.insert(saveTask);
    _selectedDateForNewTask = saveTask.date;
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
        ? accent.withOpacity(isDark ? 0.55 : 0.55)
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
            Text(
              label,
              style: TextStyle(color: fg, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(
    BuildContext context,
    String title,
    bool expanded,
    VoidCallback onTap,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
              color: scheme.onSurface.withOpacity(isDark ? 0.55 : 0.45),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final tr = AppLocalizations.of(context)!;

    final bgTop = isDark ? theme.scaffoldBackgroundColor : _bgTop;
    final bgBottom = isDark ? theme.scaffoldBackgroundColor : _bgBottom;

    final card = scheme.surface;
    final line =
        isDark ? Colors.white.withOpacity(0.10) : Colors.black.withOpacity(0.06);
    final inkC = scheme.onSurface;
    final mutedC = scheme.onSurface.withOpacity(isDark ? 0.70 : 0.60);

    final now = DateTime.now();
    final todayKey = _dayOnly(now);

    bool isOverdue(Task t) => !t.done && t.date.isBefore(now);
    bool isNearDue(Task t) =>
        !t.done &&
        !isOverdue(t) &&
        t.date.difference(now) <= const Duration(days: 2);

    final todayList = _tasks.where((t) {
      final d = _dayOnly(t.date);
      return !t.done && _isSameDay(d, todayKey);
    }).toList();

    final futureList = _tasks.where((t) {
      final d = _dayOnly(t.date);
      return !t.done && d.isAfter(todayKey);
    }).toList();

    final overdueList = _tasks.where((t) => isOverdue(t)).toList();
    final doneList = _tasks.where((t) => t.done).toList();

    todayList.sort((a, b) {
      final s = (b.starred ? 1 : 0) - (a.starred ? 1 : 0);
      if (s != 0) return s;
      return a.date.compareTo(b.date);
    });
    overdueList.sort((a, b) => a.date.compareTo(b.date));
    futureList.sort((a, b) => a.date.compareTo(b.date));
    doneList.sort((a, b) => b.date.compareTo(a.date));

    final workCount = _countCatBaseKey(_kWork);
    final todoCount = _countTodo();
    final planCount = _countCatBaseKey(_kPlan);

    final importantCount = _tasks
        .where((t) => !t.done && (isNearDue(t) || _catKeyOf(t) == _kNearDue))
        .length;

    return Scaffold(
      key: _scaffoldKey,
      drawer: SideMenuDrawer(
        onSelect: (key) => _handleDrawerSelect(key),
      ),
      floatingActionButton: _tabIndex == 1
          ? FloatingActionButton(
              onPressed: _openAddDialog,
              backgroundColor: _blue,
              foregroundColor: Colors.white,
              elevation: 0,
              child: const Icon(Icons.add_rounded),
            )
          : null,
      body: IndexedStack(
        index: _tabIndex,
        children: [
          const SizedBox.shrink(),

          // 1 Home
          Container(
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
                          onTap: () => _scaffoldKey.currentState?.openDrawer(),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: card,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: line),
                            ),
                            child: Icon(Icons.menu_rounded, color: inkC),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            tr.appTitle,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: inkC,
                            ),
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => _openSearch(context),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: card,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: line),
                            ),
                            child: Icon(Icons.search_rounded, color: mutedC),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _DashCard(
                            title: _catLabel(context, _kWork),
                            icon: Icons.work_rounded,
                            accent: _green,
                            count: workCount,
                            onTap: () => _openCategory(
                              context,
                              title: _catLabel(context, _kWork),
                              color: _green,
                              categoryKey: _kWork,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DashCard(
                            title: _catLabel(context, _kTodoAll),
                            icon: Icons.star_rounded,
                            accent: _yellow,
                            count: todoCount,
                            onTap: () => _openCategory(
                              context,
                              title: _catLabel(context, _kTodoAll),
                              color: _yellow,
                              categoryKey: _kTodoAll,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _DashCard(
                            title: _catLabel(context, _kPlan),
                            icon: Icons.event_note_rounded,
                            accent: _blue,
                            count: planCount,
                            onTap: () => _openCategory(
                              context,
                              title: _catLabel(context, _kPlan),
                              color: _blue,
                              categoryKey: _kPlan,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DashCard(
                            title: _catLabel(context, _kNearDue),
                            icon: Icons.priority_high_rounded,
                            accent: _orange,
                            count: importantCount,
                            onTap: () => _openNearDueAll(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _tasks.isEmpty
                          ? Center(
                              child: Text(
                                tr.emptyHome,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: mutedC,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          : ListView(
                              physics: const BouncingScrollPhysics(),
                              children: [
                                _sectionHeader(
                                  context,
                                  tr.homeToday,
                                  _expandToday,
                                  () => setState(
                                      () => _expandToday = !_expandToday),
                                ),
                                if (_expandToday && todayList.isNotEmpty)
                                  ...todayList.map((t) => _TaskRow(
                                        task: t,
                                        categoryText:
                                            _catLabel(context, _catKeyOf(t)),
                                        onToggleDone: () async {
                                          await TaskDao.instance.toggleDone(t);
                                          await _reload();
                                        },
                                        onToggleStar: () async {
                                          await TaskDao.instance.toggleStar(t);
                                          await _reload();
                                        },
                                        onDelete: () async {
                                          if (t.id != null) {
                                            await TaskDao.instance
                                                .deleteById(t.id!);
                                            await _reload();
                                          }
                                        },
                                        onOpen: () => _openTask(t),
                                      )),
                                if (_expandToday && todayList.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Text(
                                      tr.emptyToday,
                                      style: TextStyle(
                                        color: mutedC.withOpacity(0.9),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                _sectionHeader(
                                  context,
                                  tr.homeFuture,
                                  _expandFuture,
                                  () => setState(
                                      () => _expandFuture = !_expandFuture),
                                ),
                                if (_expandFuture && futureList.isNotEmpty)
                                  ...futureList.map((t) => _TaskRow(
                                        task: t,
                                        categoryText:
                                            _catLabel(context, _catKeyOf(t)),
                                        onToggleDone: () async {
                                          await TaskDao.instance.toggleDone(t);
                                          await _reload();
                                        },
                                        onToggleStar: () async {
                                          await TaskDao.instance.toggleStar(t);
                                          await _reload();
                                        },
                                        onDelete: () async {
                                          if (t.id != null) {
                                            await TaskDao.instance
                                                .deleteById(t.id!);
                                            await _reload();
                                          }
                                        },
                                        onOpen: () => _openTask(t),
                                      )),
                                if (_expandFuture && futureList.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Text(
                                      tr.emptyFuture,
                                      style: TextStyle(
                                        color: mutedC.withOpacity(0.9),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                _sectionHeader(
                                  context,
                                  tr.homeOverdue,
                                  _expandBefore,
                                  () => setState(
                                      () => _expandBefore = !_expandBefore),
                                ),
                                if (_expandBefore && overdueList.isNotEmpty)
                                  ...overdueList.map((t) => _TaskRow(
                                        task: t,
                                        categoryText:
                                            _catLabel(context, _catKeyOf(t)),
                                        onToggleDone: () async {
                                          await TaskDao.instance.toggleDone(t);
                                          await _reload();
                                        },
                                        onToggleStar: () async {
                                          await TaskDao.instance.toggleStar(t);
                                          await _reload();
                                        },
                                        onDelete: () async {
                                          if (t.id != null) {
                                            await TaskDao.instance
                                                .deleteById(t.id!);
                                            await _reload();
                                          }
                                        },
                                        onOpen: () => _openTask(t),
                                      )),
                                if (_expandBefore && overdueList.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Text(
                                      tr.emptyOverdue,
                                      style: TextStyle(
                                        color: mutedC.withOpacity(0.9),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                _sectionHeader(
                                  context,
                                  tr.homeDone,
                                  _expandDoneToday,
                                  () => setState(() =>
                                      _expandDoneToday = !_expandDoneToday),
                                ),
                                if (_expandDoneToday && doneList.isNotEmpty)
                                  ...doneList.map((t) => _TaskRow(
                                        task: t,
                                        categoryText:
                                            _catLabel(context, _catKeyOf(t)),
                                        onToggleDone: () async {
                                          await TaskDao.instance.toggleDone(t);
                                          await _reload();
                                        },
                                        onToggleStar: () async {
                                          await TaskDao.instance.toggleStar(t);
                                          await _reload();
                                        },
                                        onDelete: () async {
                                          if (t.id != null) {
                                            await TaskDao.instance
                                                .deleteById(t.id!);
                                            await _reload();
                                          }
                                        },
                                        onOpen: () => _openTask(t),
                                      )),
                                if (_expandDoneToday && doneList.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 24),
                                    child: Text(
                                      tr.emptyDone,
                                      style: TextStyle(
                                        color: mutedC.withOpacity(0.9),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 10),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          CalendarPage(key: _calendarKey),
          OverviewPage(key: _overviewKey),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                decoration: BoxDecoration(
                  color: card.withOpacity(isDark ? 0.78 : 0.92),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.10)
                        : Colors.white.withOpacity(0.55),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.35 : 0.08),
                      blurRadius: 28,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _NavIcon(
                      icon: Icons.home_rounded,
                      selected: _tabIndex == 1,
                      onTap: () => _setTab(1),
                    ),
                    _NavIcon(
                      icon: Icons.calendar_month_rounded,
                      selected: _tabIndex == 2,
                      onTap: () => _setTab(2),
                    ),
                    _NavIcon(
                      icon: Icons.pie_chart_rounded,
                      selected: _tabIndex == 3,
                      onTap: () => _setTab(3),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================
// ✅ หน้า “ใกล้ครบกำหนดรวม”
// ============================
class NearDueAllPage extends StatefulWidget {
  const NearDueAllPage({super.key});

  @override
  State<NearDueAllPage> createState() => _NearDueAllPageState();
}

class _NearDueAllPageState extends State<NearDueAllPage> {
  static const _bgTop = Color(0xFFF6F7FB);
  static const _bgBottom = Color(0xFFF1F3F8);

  bool _loading = true;
  final List<Task> _tasks = [];

  // ใช้ key เดียวกับ Home
  static const String _kNearDue = 'near_due';

  String _catKeyOf(Task t) {
    final c = (t.category).trim();
    if (c == _kNearDue) return c;
    if (c == 'ใกล้ครบกำหนด') return _kNearDue;
    return c;
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final data = await TaskDao.instance.getAll();
    if (!mounted) return;
    setState(() {
      _tasks
        ..clear()
        ..addAll(data);
      _loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _openTask(Task t) async {
    final changed = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TaskDetailPage(task: t)),
    );
    if (changed == true) await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final tr = AppLocalizations.of(context)!;

    final bgTop = isDark ? theme.scaffoldBackgroundColor : _bgTop;
    final bgBottom = isDark ? theme.scaffoldBackgroundColor : _bgBottom;

    final card = scheme.surface;
    final line =
        isDark ? Colors.white.withOpacity(0.10) : Colors.black.withOpacity(0.06);

    final now = DateTime.now();

    bool isOverdue(Task t) => !t.done && t.date.isBefore(now);
    bool isNearDue(Task t) =>
        !t.done &&
        !isOverdue(t) &&
        t.date.difference(now) <= const Duration(days: 2);

    final list = _tasks
        .where((t) => !t.done && (isNearDue(t) || _catKeyOf(t) == _kNearDue))
        .toList();

    list.sort((a, b) {
      final s = (b.starred ? 1 : 0) - (a.starred ? 1 : 0);
      if (s != 0) return s;
      return a.date.compareTo(b.date);
    });

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
                        child: Icon(Icons.arrow_back_rounded,
                            color: scheme.onSurface),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        tr.nearDueAllTitle,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: scheme.onSurface,
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
                  child: list.isEmpty
                      ? Center(
                          child: Text(
                            tr.nearDueAllEmpty,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: scheme.onSurface
                                  .withOpacity(isDark ? 0.70 : 0.60),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      : ListView(
                          physics: const BouncingScrollPhysics(),
                          children: [
                            ...list.map((t) => _TaskRow(
                                  task: t,
                                  categoryText: tr.drawerCatImportant,
                                  onToggleDone: () async {
                                    await TaskDao.instance.toggleDone(t);
                                    await _reload();
                                  },
                                  onToggleStar: () async {
                                    await TaskDao.instance.toggleStar(t);
                                    await _reload();
                                  },
                                  onDelete: () async {
                                    if (t.id != null) {
                                      await TaskDao.instance.deleteById(t.id!);
                                      await _reload();
                                    }
                                  },
                                  onOpen: () => _openTask(t),
                                )),
                            const SizedBox(height: 10),
                          ],
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

class _Field extends StatelessWidget {
  const _Field({required this.controller, required this.hint});
  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextField(
      controller: controller,
      textInputAction: TextInputAction.done,
      style: TextStyle(color: scheme.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            TextStyle(color: scheme.onSurface.withOpacity(isDark ? 0.55 : 0.45)),
        filled: true,
        fillColor: scheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.10)
                : Colors.black.withOpacity(0.06),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.10)
                : Colors.black.withOpacity(0.06),
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

class _DashCard extends StatelessWidget {
  const _DashCard({
    required this.title,
    required this.icon,
    required this.accent,
    required this.count,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final card = scheme.surface;
    final line =
        isDark ? Colors.white.withOpacity(0.10) : Colors.black.withOpacity(0.06);

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 92),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: line),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: accent.withOpacity(isDark ? 0.18 : 0.14),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: accent.withOpacity(isDark ? 0.28 : 0.22)),
              ),
              child: Icon(icon, size: 28, color: accent.withOpacity(0.95)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$count รายการ',
                    style: TextStyle(
                      color: scheme.onSurface.withOpacity(isDark ? 0.70 : 0.60),
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
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.task,
    required this.categoryText,
    required this.onToggleDone,
    required this.onToggleStar,
    required this.onDelete,
    required this.onOpen,
  });

  final Task task;
  final String categoryText;
  final VoidCallback onToggleDone;
  final VoidCallback onToggleStar;
  final Future<void> Function() onDelete;
  final VoidCallback onOpen;

  static const _blue = Color(0xFF2E5E8D);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final card = scheme.surface;
    final line =
        isDark ? Colors.white.withOpacity(0.10) : Colors.black.withOpacity(0.06);
    final mutedC = scheme.onSurface.withOpacity(isDark ? 0.70 : 0.60);

    final now = DateTime.now();
    final overdue = !task.done && task.date.isBefore(now);
    final nearDue =
        !task.done && !overdue && task.date.difference(now) <= const Duration(days: 1);

    final dateColor = overdue
        ? Colors.red
        : nearDue
            ? const Color(0xFFE0D51C)
            : mutedC;

    return Dismissible(
      key: ValueKey(
          'task_${task.id ?? task.title}_${task.date.millisecondsSinceEpoch}'),
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
        await onDelete();
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
                        ? _blue.withOpacity(isDark ? 0.22 : 0.14)
                        : (isDark
                            ? Colors.white.withOpacity(0.06)
                            : Colors.black.withOpacity(0.04)),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: task.done
                          ? _blue.withOpacity(isDark ? 0.55 : 0.40)
                          : (isDark
                              ? Colors.white.withOpacity(0.12)
                              : Colors.black.withOpacity(0.08)),
                    ),
                  ),
                  child: Icon(
                    task.done ? Icons.check_rounded : Icons.circle_outlined,
                    color: task.done ? _blue : mutedC,
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
                        decoration: task.done
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 2),
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: mutedC,
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
                    color: task.starred ? const Color(0xFFE0D51C) : mutedC,
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

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  static const _blue = Color(0xFF2E5E8D);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? _blue.withOpacity(isDark ? 0.22 : 0.14)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Icon(
            icon,
            color: selected
                ? _blue
                : scheme.onSurface.withOpacity(isDark ? 0.55 : 0.45),
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
