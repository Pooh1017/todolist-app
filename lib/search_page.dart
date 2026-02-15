import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

import 'db/task_dao.dart';
import 'models/task.dart';
import 'utils/date_fmt.dart';

// ✅ l10n
import 'l10n/app_localizations.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  // fallback สำหรับ light gradient เดิม
  static const _bgTop = Color(0xFFF6F7FB);
  static const _bgBottom = Color(0xFFF1F3F8);

  final _ctrl = TextEditingController();
  Timer? _debounce;

  bool _loading = true;
  final List<Task> _results = [];

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
        return tr.drawerCatTodo;
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

  @override
  void initState() {
    super.initState();
    _runSearch('');

    _ctrl.addListener(() {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 220), () {
        _runSearch(_ctrl.text);
      });

      // ✅ ให้ปุ่ม X โผล่/หายทันทีตอนพิมพ์
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _runSearch(String q) async {
    if (!mounted) return;
    setState(() => _loading = true);

    final data = await TaskDao.instance.search(q);

    if (!mounted) return;
    setState(() {
      _results
        ..clear()
        ..addAll(data);
      _loading = false;
    });
  }

  void _clearSearch() {
    _ctrl.clear();
    // ✅ ให้ X หายทันที และโหลดผลใหม่
    if (mounted) setState(() {});
    _runSearch('');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final t = AppLocalizations.of(context)!;

    final bgTop = isDark ? const Color(0xFF0F1720) : _bgTop;
    final bgBottom = isDark ? const Color(0xFF0B121A) : _bgBottom;

    final card = scheme.surface;
    final muted = scheme.onSurface.withOpacity(isDark ? 0.70 : 0.60);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.searchTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
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
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: card.withOpacity(isDark ? 0.80 : 0.92),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.10)
                              : Colors.white.withOpacity(0.55),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search_rounded, color: muted),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _ctrl,
                              style: TextStyle(
                                color: scheme.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                              decoration: InputDecoration(
                                hintText: t.searchHint,
                                hintStyle: TextStyle(color: muted),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          if (_ctrl.text.isNotEmpty)
                            InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: _clearSearch,
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: Icon(Icons.close_rounded, color: muted),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _results.isEmpty
                          ? Center(
                              child: Text(
                                t.searchEmpty,
                                style: TextStyle(
                                  color: muted,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              itemCount: _results.length,
                              itemBuilder: (_, i) {
                                final task = _results[i];
                                return _TaskTile(
                                  task: task,
                                  categoryText:
                                      _catLabel(context, _catKeyOf(task)),
                                  onToggleDone: () async {
                                    await TaskDao.instance.toggleDone(task);
                                    await _runSearch(_ctrl.text);
                                  },
                                  onToggleStar: () async {
                                    await TaskDao.instance.toggleStar(task);
                                    await _runSearch(_ctrl.text);
                                  },

                                  // ✅ FIX: Dao ของคุณเป็น soft delete:
                                  // - delete(Task task)
                                  // - deleteById(int id)
                                  // ดังนั้นห้ามเรียก delete(id)
                                  onDelete: () async {
                                    if (task.id != null) {
                                      await TaskDao.instance.deleteById(task.id!);
                                      await _runSearch(_ctrl.text);
                                    }
                                  },
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
    required this.onToggleDone,
    required this.onToggleStar,
    required this.onDelete,
  });

  final Task task;
  final String categoryText;
  final VoidCallback onToggleDone;
  final VoidCallback onToggleStar;

  // ✅ FIX: ให้รองรับ async (เพราะต้อง await delete + refresh)
  final Future<void> Function() onDelete;

  static const _blue = Color(0xFF2E5E8D);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final card = scheme.surface;
    final line =
        isDark ? Colors.white.withOpacity(0.10) : Colors.black.withOpacity(0.06);
    final muted = scheme.onSurface.withOpacity(isDark ? 0.70 : 0.60);

    return Dismissible(
      key: ValueKey(
        'search_task_${task.id ?? task.title}_${task.date.millisecondsSinceEpoch}',
      ),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(isDark ? 0.20 : 0.12),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Colors.red.withOpacity(isDark ? 0.35 : 0.25),
          ),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.red),
      ),

      // ✅ FIX: ต้อง await เพื่อให้ DB update เสร็จแล้วค่อย dismiss
      confirmDismiss: (_) async {
        await onDelete();
        return true;
      },

      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {},
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
                    color: task.done ? _blue : muted,
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
                    Text(
                      // ✅ แสดงชื่อหมวดแปลได้ + วันเวลา format เดียวทั้งแอพ
                      '$categoryText • ${formatDate(context, task.date, withTime: true)}',
                      style: TextStyle(
                        color: muted,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
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
