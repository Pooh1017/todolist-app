import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'db/task_dao.dart';
import 'db/subtask_dao.dart';
import 'models/task.dart';
import 'models/subtask.dart';

// ✅ ใช้ formatter เดียวทั้งแอพ (ตาม Settings + Locale)
import 'utils/date_fmt.dart';

// ✅ ใช้คำแปล
import 'l10n/app_localizations.dart';

class TaskDetailPage extends StatefulWidget {
  const TaskDetailPage({super.key, required this.task});
  final Task task;

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  late Task _task;
  late TextEditingController _titleCtrl;
  late TextEditingController _noteCtrl;

  // ✅ งานย่อยจาก DB
  bool _subLoading = true;
  final List<Subtask> _subtasks = [];

  // Reminder (ชั่วคราว)
  Duration _remindBefore = const Duration(minutes: 5);
  String _remindType = 'notify'; // ✅ เก็บเป็น key (ไม่ผูกภาษา)

  // ✅ ใช้ส่งกลับว่ามีการเปลี่ยนแปลงไหม
  bool _changed = false;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? _task.userId;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    _titleCtrl = TextEditingController(text: _task.title);
    _noteCtrl = TextEditingController(text: _task.note);
    _loadSubtasks();
  }

  Future<void> _loadSubtasks() async {
    final id = _task.id;
    if (id == null) {
      if (!mounted) return;
      setState(() {
        _subtasks.clear();
        _subLoading = false;
      });
      return;
    }

    final list = await SubtaskDao.instance.getByTask(id);
    list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    if (!mounted) return;
    setState(() {
      _subtasks
        ..clear()
        ..addAll(list);
      _subLoading = false;
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  // -------- helpers --------
  String _two(int n) => n.toString().padLeft(2, '0');
  String _formatTime(DateTime dt) => '${_two(dt.hour)}:${_two(dt.minute)}';

  // ✅ map categoryKey -> label (ตามภาษา) + รองรับไทยเก่า
  String _catKeyOfTask() {
    final c = _task.category.trim();

    if (c == 'work' || c == 'todo_all' || c == 'plan' || c == 'near_due') {
      return c;
    }

    switch (c) {
      case 'งาน':
        return 'work';
      case 'สิ่งที่ต้องทำ':
        return 'todo_all';
      case 'ที่วางแผนไว้':
        return 'plan';
      case 'ใกล้ครบกำหนด':
        return 'near_due';
      default:
        return 'todo_all';
    }
  }

  String _catLabel(AppLocalizations tr, String key) {
    switch (key) {
      case 'work':
        return tr.drawerCatWork;
      case 'todo_all':
        return tr.drawerCatTodo;
      case 'plan':
        return tr.drawerCatPlan;
      case 'near_due':
        return tr.drawerCatImportant;
      default:
        return tr.drawerCatTodo;
    }
  }

  Color _catAccent(ColorScheme cs, String key) {
    switch (key) {
      case 'work':
        return const Color(0xFF24C96A);
      case 'todo_all':
        return const Color(0xFFE0D51C);
      case 'plan':
        return const Color(0xFF2E5E8D);
      case 'near_due':
        return const Color(0xFFF08C63);
      default:
        return cs.primary;
    }
  }

  IconData _catIcon(String key) {
    switch (key) {
      case 'work':
        return Icons.work_rounded;
      case 'todo_all':
        return Icons.star_rounded;
      case 'plan':
        return Icons.event_note_rounded;
      case 'near_due':
        return Icons.priority_high_rounded;
      default:
        return Icons.star_rounded;
    }
  }

  Color _tint(Color base, Color accent, double amount) =>
      Color.lerp(base, accent, amount) ?? base;

  // ✅ reminder type key -> label (fallback)
  String _remindTypeLabel(AppLocalizations tr, String key) {
    final isTh = Localizations.localeOf(context).languageCode == 'th';
    switch (key) {
      case 'notify':
        return isTh ? 'การแจ้งเตือน' : 'Notification';
      case 'sound':
        return isTh ? 'เสียง' : 'Sound';
      case 'vibrate':
        return isTh ? 'สั่น' : 'Vibrate';
      default:
        return isTh ? 'การแจ้งเตือน' : 'Notification';
    }
  }

  String _remindBeforeLabel(AppLocalizations tr, Duration d) {
    final isTh = Localizations.localeOf(context).languageCode == 'th';

    if (d.inMinutes == 0) return isTh ? 'ตรงเวลา' : 'On time';
    if (d.inMinutes < 60) {
      return isTh ? '${d.inMinutes} นาที ก่อน' : '${d.inMinutes} min before';
    }
    if (d.inHours < 24) {
      return isTh ? '${d.inHours} ชม. ก่อน' : '${d.inHours} hr before';
    }
    return isTh ? '${d.inDays} วัน ก่อน' : '${d.inDays} day before';
  }

  // -------- save --------
  Future<void> _saveTitleIfChanged() async {
    final newTitle = _titleCtrl.text.trim();
    if (newTitle.isEmpty) return;
    if (newTitle == _task.title) return;

    final updated = _task.copyWith(
      title: newTitle,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
      syncState: 1,
    );
    await TaskDao.instance.updateTask(updated);

    if (!mounted) return;
    setState(() => _task = updated);
    _changed = true;
  }

  Future<void> _saveNoteIfChanged() async {
    final note = _noteCtrl.text.trim();
    if (note == _task.note) return;

    final updated = _task.copyWith(
      note: note,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
      syncState: 1,
    );
    await TaskDao.instance.updateTask(updated);

    if (!mounted) return;
    setState(() => _task = updated);
    _changed = true;
  }

  Future<void> _popSafely() async {
    // ✅ บันทึกก่อนออกทุกครั้ง
    await _saveTitleIfChanged();
    await _saveNoteIfChanged();
    if (!mounted) return;
    Navigator.pop(context, _changed);
  }

  // -------- pick category --------
  Future<void> _pickCategory() async {
    final tr = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    const cats = ['work', 'todo_all', 'plan', 'near_due'];
    final currentKey = _catKeyOfTask();

    final selectedKey = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        final sheetBg = cs.surface.withOpacity(isDark ? 0.92 : 0.96);
        final border = cs.outlineVariant.withOpacity(isDark ? 0.35 : 0.50);

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  decoration: BoxDecoration(
                    color: sheetBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.22 : 0.08),
                        blurRadius: 28,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: cs.onSurface.withOpacity(isDark ? 0.22 : 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...cats.map((key) {
                        final isSel = key == currentKey;
                        final accent = _catAccent(cs, key);
                        final icon = _catIcon(key);

                        return ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: accent.withOpacity(isDark ? 0.20 : 0.14),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: accent.withOpacity(isDark ? 0.35 : 0.22),
                              ),
                            ),
                            child: Icon(icon, color: accent.withOpacity(0.95)),
                          ),
                          title: Text(
                            _catLabel(tr, key),
                            style: TextStyle(
                              color: cs.onSurface,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          trailing:
                              isSel ? Icon(Icons.check_rounded, color: accent) : null,
                          onTap: () => Navigator.pop(context, key),
                        );
                      }),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    if (selectedKey == null || selectedKey == currentKey) return;

    final updated = _task.copyWith(
      category: selectedKey,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
      syncState: 1,
    );
    await TaskDao.instance.updateTask(updated);

    if (!mounted) return;
    setState(() => _task = updated);
    _changed = true;
  }

  Future<void> _pickDueDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _task.date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(data: Theme.of(context), child: child!),
    );
    if (d == null) return;

    final updated = _task.copyWith(
      date: DateTime(d.year, d.month, d.day, _task.date.hour, _task.date.minute),
      updatedAt: DateTime.now().millisecondsSinceEpoch,
      syncState: 1,
    );
    await TaskDao.instance.updateTask(updated);

    if (!mounted) return;
    setState(() => _task = updated);
    _changed = true;
  }

  // ✅ เวลาไทยแบบ “พิมพ์ใส่” HH:mm (24 ชม.)
  Future<TimeOfDay?> _showThaiTimeInputDialog({
    required TimeOfDay initial,
    required String title,
    required String hint,
    required String invalidText,
    required String cancelText,
    required String nowText,
    required String okText,
  }) async {
    final formKey = GlobalKey<FormState>();
    final ctrl = TextEditingController(
      text:
          '${initial.hour.toString().padLeft(2, '0')}:${initial.minute.toString().padLeft(2, '0')}',
    );

    String? validate(String? v) {
      final s = (v ?? '').trim();
      final m = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$').firstMatch(s);
      if (m == null) return invalidText;
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
        final cs = Theme.of(context).colorScheme;
        return AlertDialog(
          title: Text(title),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: ctrl,
              autofocus: true,
              keyboardType: TextInputType.datetime,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(hintText: hint),
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
              child: Text(cancelText),
            ),
            TextButton(
              onPressed: () {
                final now = TimeOfDay.now();
                ctrl.text =
                    '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
              },
              child: Text(nowText),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
              ),
              onPressed: () {
                if (formKey.currentState?.validate() != true) return;
                Navigator.pop(context, parse(ctrl.text.trim()));
              },
              child: Text(okText),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickDueTime() async {
    final tr = AppLocalizations.of(context)!;

    final t = await _showThaiTimeInputDialog(
      initial: TimeOfDay(hour: _task.date.hour, minute: _task.date.minute),
      title: tr.timeInputTitle,
      hint: tr.timeInputHint,
      invalidText: tr.timeInvalidHint,
      cancelText: tr.cancel,
      nowText: tr.nowText,
      okText: tr.okText,
    );
    if (t == null) return;

    final updated = _task.copyWith(
      date: DateTime(
        _task.date.year,
        _task.date.month,
        _task.date.day,
        t.hour,
        t.minute,
      ),
      updatedAt: DateTime.now().millisecondsSinceEpoch,
      syncState: 1,
    );
    await TaskDao.instance.updateTask(updated);

    if (!mounted) return;
    setState(() => _task = updated);
    _changed = true;
  }

  Future<void> _pickRemindBefore() async {
    final tr = AppLocalizations.of(context)!;

    const options = <Duration>[
      Duration(minutes: 0),
      Duration(minutes: 5),
      Duration(minutes: 10),
      Duration(minutes: 30),
      Duration(hours: 1),
      Duration(days: 1),
    ];

    final chosen = await showModalBottomSheet<Duration>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final cs = Theme.of(context).colorScheme;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        final sheetBg = cs.surface.withOpacity(isDark ? 0.92 : 0.96);
        final border = cs.outlineVariant.withOpacity(isDark ? 0.35 : 0.50);

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  decoration: BoxDecoration(
                    color: sheetBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.22 : 0.08),
                        blurRadius: 28,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 10),
                      ...options.map((d) {
                        final selected = d == _remindBefore;
                        return ListTile(
                          title: Text(
                            _remindBeforeLabel(tr, d),
                            style: TextStyle(
                              color: cs.onSurface,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          trailing: selected
                              ? Icon(Icons.check_rounded, color: cs.primary)
                              : null,
                          onTap: () => Navigator.pop(context, d),
                        );
                      }),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    if (chosen == null) return;
    setState(() => _remindBefore = chosen);
    _changed = true;
  }

  Future<void> _pickRemindType() async {
    final tr = AppLocalizations.of(context)!;
    const options = ['notify', 'sound', 'vibrate'];

    final chosen = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final cs = Theme.of(context).colorScheme;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        final sheetBg = cs.surface.withOpacity(isDark ? 0.92 : 0.96);
        final border = cs.outlineVariant.withOpacity(isDark ? 0.35 : 0.50);

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  decoration: BoxDecoration(
                    color: sheetBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.22 : 0.08),
                        blurRadius: 28,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 10),
                      ...options.map((k) {
                        final selected = k == _remindType;
                        return ListTile(
                          title: Text(
                            _remindTypeLabel(tr, k),
                            style: TextStyle(
                              color: cs.onSurface,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          trailing: selected
                              ? Icon(Icons.check_rounded, color: cs.primary)
                              : null,
                          onTap: () => Navigator.pop(context, k),
                        );
                      }),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    if (chosen == null) return;
    setState(() => _remindType = chosen);
    _changed = true;
  }

  // -------- subtask actions --------
  Future<void> _addSubtask() async {
    final tr = AppLocalizations.of(context)!;
    final isTh = Localizations.localeOf(context).languageCode == 'th';

    if (_task.id == null) return;

    final ctrl = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        title: Text(isTh ? 'เพิ่มงานย่อย' : 'Add subtask'),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            hintText: isTh ? 'พิมพ์งานย่อย...' : 'Type subtask...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final t = ctrl.text.trim();
              if (t.isEmpty) return;
              Navigator.pop(context, t);
            },
            child: Text(isTh ? 'เพิ่ม' : 'Add'),
          ),
        ],
      ),
    );

    if (text == null || text.trim().isEmpty) return;

    final nextOrder = _subtasks.isEmpty
        ? 0
        : (_subtasks
                .map((e) => e.sortOrder)
                .reduce((a, b) => a > b ? a : b) +
            1);

    await SubtaskDao.instance.insert(
      Subtask(
        taskId: _task.id!,
        title: text.trim(),
        sortOrder: nextOrder,
      ),
    );

    _changed = true;
    await _loadSubtasks();
  }

  Future<void> _deleteSubtask(Subtask s) async {
    final id = s.id;
    if (id == null) return;
    await SubtaskDao.instance.delete(id);
    _changed = true;
    await _loadSubtasks();
  }

  Future<void> _toggleSubtaskDone(Subtask s) async {
    await SubtaskDao.instance.toggleDone(s);
    _changed = true;
    await _loadSubtasks();
  }

  Future<void> _confirmDeleteTask() async {
    final tr = AppLocalizations.of(context)!;
    final isTh = Localizations.localeOf(context).languageCode == 'th';

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isTh ? 'ลบรายการนี้?' : 'Delete this task?'),
        content:
            Text(isTh ? 'การลบจะไม่สามารถกู้คืนได้' : 'This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(isTh ? 'ลบ' : 'Delete'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    // ✅ FIX: ใช้ deleteById (ใน DAO คุณเป็น soft delete)
    if (_task.id != null) {
      await TaskDao.instance.deleteById(_task.id!);
    }
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _duplicate() async {
    final isTh = Localizations.localeOf(context).languageCode == 'th';

    // ✅ FIX: constructor ต้องมี userId + sync fields
    final copy = Task.newLocal(
      userId: _uid,
      title: _task.title,
      category: _task.category,
      date: _task.date,
      starred: _task.starred,
      done: _task.done,
      note: _task.note,
    );

    final newId = await TaskDao.instance.insert(copy);

    final oldId = _task.id;
    if (oldId != null) {
      final olds = await SubtaskDao.instance.getByTask(oldId);
      for (final s in olds) {
        await SubtaskDao.instance.insert(
          Subtask(
            taskId: newId,
            title: s.title,
            done: s.done,
            sortOrder: s.sortOrder,
          ),
        );
      }
    }

    if (!mounted) return;
    _changed = true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(isTh ? 'สร้างสำเนาแล้ว' : 'Duplicated')),
    );
  }

  Future<void> _openMenu(TapDownDetails details) async {
    final isTh = Localizations.localeOf(context).languageCode == 'th';
    final pos = details.globalPosition;

    final value = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(pos.dx, pos.dy, pos.dx, pos.dy),
      items: [
        PopupMenuItem(value: 'dup', child: Text(isTh ? 'สร้างสำเนา' : 'Duplicate')),
        PopupMenuItem(value: 'del', child: Text(isTh ? 'ลบ' : 'Delete')),
      ],
    );

    switch (value) {
      case 'dup':
        await _duplicate();
        break;
      case 'del':
        await _confirmDeleteTask();
        break;
    }
  }

  // -------- widgets --------
  Widget _pillRight(String text, ColorScheme cs, bool isDark) {
    final base = cs.surface;
    final tint = _tint(base, cs.primary, isDark ? 0.10 : 0.06);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: tint.withOpacity(isDark ? 0.92 : 1.0),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: cs.outlineVariant.withOpacity(isDark ? 0.35 : 0.55),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _rowTile({
    required IconData icon,
    required String label,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 34,
              child: Icon(
                icon,
                color: cs.onSurfaceVariant.withOpacity(0.95),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final bgTop = cs.surface;
    final bgBottom = _tint(cs.surface, cs.primary, isDark ? 0.06 : 0.04);

    final card = cs.surface.withOpacity(isDark ? 0.82 : 0.92);
    final border = cs.outlineVariant.withOpacity(isDark ? 0.32 : 0.55);
    final divider = cs.outlineVariant.withOpacity(isDark ? 0.25 : 0.35);

    final remindAt = _task.date.subtract(_remindBefore);
    final isTh = Localizations.localeOf(context).languageCode == 'th';

    final catKey = _catKeyOfTask();
    final catLabel = _catLabel(tr, catKey);

    return PopScope(
      canPop: false, // ✅ ดัก back แล้ว save ก่อนออก
      onPopInvoked: (didPop) async {
        if (didPop) return;
        await _popSafely();
      },
      child: Scaffold(
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
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Row(
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: _popSafely,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: card,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: border),
                          ),
                          child: Icon(Icons.arrow_back_rounded, color: cs.onSurface),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTapDown: _openMenu,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: card,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: border),
                          ),
                          child: Icon(Icons.more_vert_rounded, color: cs.onSurface),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: _pickCategory,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: card,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: _catAccent(cs, catKey),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  catLabel,
                                  style: TextStyle(
                                    color: cs.onSurfaceVariant.withOpacity(0.95),
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: cs.onSurfaceVariant.withOpacity(0.75),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      TextField(
                        controller: _titleCtrl,
                        onSubmitted: (_) => _saveTitleIfChanged(),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: cs.onSurface,
                          height: 1.05,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),

                      const SizedBox(height: 10),

                      InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _addSubtask,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Icon(Icons.add_rounded, color: cs.primary.withOpacity(0.95)),
                              const SizedBox(width: 8),
                              Text(
                                isTh ? 'เพิ่มงานย่อย' : 'Add subtask',
                                style: TextStyle(
                                  color: cs.primary.withOpacity(0.95),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      if (_subLoading)
                        const Padding(
                          padding: EdgeInsets.only(top: 6, bottom: 6),
                          child: Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),

                      if (!_subLoading && _subtasks.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        ..._subtasks.map(
                          (s) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: card,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: border),
                              ),
                              child: Row(
                                children: [
                                  InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: () => _toggleSubtaskDone(s),
                                    child: Padding(
                                      padding: const EdgeInsets.all(6),
                                      child: Icon(
                                        s.done
                                            ? Icons.check_box_rounded
                                            : Icons.check_box_outline_blank_rounded,
                                        color: s.done
                                            ? cs.primary
                                            : cs.onSurfaceVariant.withOpacity(0.85),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      s.title,
                                      style: TextStyle(
                                        color: cs.onSurface,
                                        fontWeight: FontWeight.w800,
                                        decoration: s.done
                                            ? TextDecoration.lineThrough
                                            : TextDecoration.none,
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: () => _deleteSubtask(s),
                                    child: Padding(
                                      padding: const EdgeInsets.all(6),
                                      child: Icon(
                                        Icons.close_rounded,
                                        color: cs.onSurfaceVariant.withOpacity(0.85),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 8),
                      Divider(height: 1, color: divider),
                      const SizedBox(height: 8),

                      _rowTile(
                        icon: Icons.calendar_month_rounded,
                        label: isTh ? 'วันที่ครบกำหนด' : 'Due date',
                        trailing: _pillRight(formatDate(context, _task.date), cs, isDark),
                        onTap: _pickDueDate,
                      ),
                      Divider(height: 1, color: divider),

                      _rowTile(
                        icon: Icons.access_time_rounded,
                        label: isTh ? 'เวลา & แจ้งเตือน' : 'Time & reminder',
                        trailing: _pillRight(_formatTime(_task.date), cs, isDark),
                        onTap: _pickDueTime,
                      ),

                      const SizedBox(height: 4),

                      Padding(
                        padding: const EdgeInsets.only(left: 40),
                        child: _rowTile(
                          icon: Icons.notifications_active_rounded,
                          label: isTh ? 'เตือนก่อน' : 'Remind before',
                          trailing: _pillRight(_remindBeforeLabel(tr, _remindBefore), cs, isDark),
                          onTap: _pickRemindBefore,
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.only(left: 40),
                        child: _rowTile(
                          icon: Icons.tune_rounded,
                          label: isTh ? 'ประเภทการแจ้งเตือน' : 'Reminder type',
                          trailing: _pillRight(_remindTypeLabel(tr, _remindType), cs, isDark),
                          onTap: _pickRemindType,
                        ),
                      ),

                      Divider(height: 1, color: divider),

                      _rowTile(
                        icon: Icons.notes_rounded,
                        label: isTh ? 'หมายเหตุ' : 'Note',
                        trailing: Text(
                          _noteCtrl.text.trim().isEmpty
                              ? (isTh ? 'เพิ่ม' : 'Add')
                              : (isTh ? 'แก้ไข' : 'Edit'),
                          style: TextStyle(
                            color: cs.primary.withOpacity(0.95),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        onTap: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text(isTh ? 'หมายเหตุ' : 'Note'),
                              content: TextField(
                                controller: _noteCtrl,
                                maxLines: 4,
                                decoration: InputDecoration(
                                  hintText: isTh ? 'พิมพ์หมายเหตุ...' : 'Type a note...',
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: Text(isTh ? 'ปิด' : 'Close'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text(tr.save),
                                ),
                              ],
                            ),
                          );

                          if (ok == true) {
                            await _saveNoteIfChanged();
                            if (mounted) setState(() {});
                          }
                        },
                      ),

                      const SizedBox(height: 18),

                      Container(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        decoration: BoxDecoration(
                          color: card,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: () async {
                                  await TaskDao.instance.toggleDone(_task);
                                  if (!mounted) return;
                                  setState(() => _task = _task.copyWith(done: !_task.done));
                                  _changed = true;
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _task.done
                                        ? cs.primary.withOpacity(isDark ? 0.22 : 0.12)
                                        : cs.onSurface.withOpacity(isDark ? 0.08 : 0.04),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: border),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _task.done
                                            ? Icons.check_rounded
                                            : Icons.circle_outlined,
                                        color: _task.done ? cs.primary : cs.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _task.done
                                            ? (isTh ? 'เสร็จแล้ว' : 'Completed')
                                            : (isTh ? 'ยังไม่เสร็จ' : 'Not done'),
                                        style: TextStyle(
                                          color: cs.onSurface,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () async {
                                await TaskDao.instance.toggleStar(_task);
                                if (!mounted) return;
                                setState(() => _task = _task.copyWith(starred: !_task.starred));
                                _changed = true;
                              },
                              child: Container(
                                width: 56,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: cs.onSurface.withOpacity(isDark ? 0.08 : 0.04),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: border),
                                ),
                                child: Icon(
                                  _task.starred
                                      ? Icons.star_rounded
                                      : Icons.star_border_rounded,
                                  color: _task.starred
                                      ? Colors.amber.withOpacity(isDark ? 0.98 : 0.95)
                                      : cs.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),
                      Text(
                        isTh
                            ? 'กำหนด: ${formatDate(context, _task.date, withTime: true)}'
                            : 'Due: ${formatDate(context, _task.date, withTime: true)}',
                        style: TextStyle(
                          color: cs.onSurfaceVariant.withOpacity(0.95),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
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
