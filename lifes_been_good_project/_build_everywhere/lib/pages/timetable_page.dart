import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;

import '../models/course.dart';
import '../models/timetable_item.dart';
import '../services/local_profiles.dart';
import '../state/session.dart';
import '../main.dart';
import 'add_course_page.dart';
import 'attendance_page.dart';
import '../widgets/expressive_ui.dart';

class TimetableController {
  Future<void> Function()? importWakeUp;
  Future<void> Function()? addCourse;
  Future<void> Function()? clearTimetable;
}

class TimetablePage extends StatefulWidget {
  final Session session;
  final VoidCallback? onLogout;
  final TimetableController? controller;
  final VoidCallback? onReady;

  const TimetablePage({
    super.key,
    required this.session,
    this.onLogout,
    this.controller,
    this.onReady,
  });

  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
  String _status = '';
  List<TimetableItem> _items = const [];
  Map<String, Course> _courses = const {};
  Map<String, Color> _courseColors = {};

  String _viewingProfileId = '';
  List<String> _teacherClasses = [];
  int _currentWeek = 1;
  late final ValueNotifier<int> _currentWeekN;
  bool _showWeekend = true;

  static const _uiPrefsFileName = 'timetable_ui_prefs.json';

  static const _expressiveColors = <Color>[
    Color(0xFFE8F5E9), // Pale Green
    Color(0xFFFFF3E0), // Soft Orange
    Color(0xFFFCE4EC), // Pastel Coral
    Color(0xFFF3E5F5), // Muted Purple
    Color(0xFFE0F7FA), // Light Aqua
    Color(0xFFFFFDE7), // Butter Yellow
    Color(0xFFE8EAF6), // Soft Indigo
    Color(0xFFFBE9E7), // Warm Beige
    Color(0xFFEFEBE9), // Muted Cocoa
    Color(0xFFF1F8E9), // Mint Cream
  ];

  Map<String, Color> _buildCourseColorMap(Iterable<String> courseIds) {
    final used = <int>{};
    final out = <String, Color>{};
    final ids = courseIds.where((e) => e.trim().isNotEmpty).toSet().toList()
      ..sort();
    for (final id in ids) {
      var start = id.hashCode.abs() % _expressiveColors.length;
      for (var step = 0; step < _expressiveColors.length; step++) {
        final idx = (start + step) % _expressiveColors.length;
        if (used.add(idx)) {
          out[id] = _expressiveColors[idx];
          break;
        }
      }
      if (!out.containsKey(id)) {
        out[id] = _expressiveColors[start];
      }
    }
    return out;
  }

  static const _coursesHeader =
      'id,course_name,teacher_profile_id,term_code,color,credits,notes';

  static const _periods = <({int period, String start, String end})>[
    (period: 1, start: '08:00', end: '08:45'),
    (period: 2, start: '08:55', end: '09:40'),
    (period: 3, start: '10:10', end: '10:55'),
    (period: 4, start: '11:05', end: '11:50'),
    (period: 5, start: '14:30', end: '15:15'),
    (period: 6, start: '15:25', end: '16:10'),
    (period: 7, start: '16:40', end: '17:25'),
    (period: 8, start: '17:35', end: '18:20'),
    (period: 9, start: '19:00', end: '19:45'),
    (period: 10, start: '19:55', end: '20:30'),
    (period: 11, start: '20:40', end: '21:25'),
    (period: 12, start: '21:35', end: '22:20'),
  ];
  static const int _maxVisiblePeriod = 10;

  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentWeek = _calculateCurrentWeek();
    _currentWeekN = ValueNotifier<int>(_currentWeek);
    _viewingProfileId = widget.session.profile.id;
    _pageController = PageController(initialPage: _currentWeek - 1);

    // Listen for global data changes for seamless refresh
    widget.session.addListener(_onGlobalDataChanged);

    Future.microtask(() async {
      await _loadUiPrefs();
      if (!mounted) return;
      await _refresh();
    });
    widget.controller?.importWakeUp = _importWakeupSchedule;
    widget.controller?.addCourse = () => _editCell();
    widget.controller?.clearTimetable = _clearTimetable;
  }

  @override
  void dispose() {
    widget.session.removeListener(_onGlobalDataChanged);
    if (widget.controller?.importWakeUp == _importWakeupSchedule) {
      widget.controller?.importWakeUp = null;
    }
    if (widget.controller?.clearTimetable == _clearTimetable) {
      widget.controller?.clearTimetable = null;
    }
    widget.controller?.addCourse = null;
    _currentWeekN.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _clearTimetable() async {
    final loc = Provider.of<LocaleProvider>(context, listen: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.t('清空课表', 'Clear Timetable')),
        content: Text(loc.t('确定要清空当前展示的课表吗？此操作不可撤销。',
            'Are you sure you want to clear the currently displayed timetable? This action cannot be undone.')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(loc.t('取消', 'Cancel')),
          ),
          TextButton(
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(loc.t('清空', 'Clear')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    setState(() {
      _status = loc.t('正在清空...', 'Clearing...');
    });

    try {
      final rows = await _readCsvRows('timetable.csv');
      final originalCount = rows.length;
      rows.removeWhere((r) => r['owner_profile_id'] == _viewingProfileId);

      if (rows.length != originalCount) {
        final headers = [
          'id',
          'owner_profile_id',
          'weekday',
          'start_period',
          'end_period',
          'start_time',
          'end_time',
          'course_id',
          'location',
          'created_by_profile_id',
          'is_locked',
          'weeks'
        ];
        await _writeCsv('timetable.csv', headers, rows);
      }

      await _refresh();
      if (mounted) {
        showExpressiveSnackBar(
          context,
          loc.t('课表已清空', 'Timetable cleared'),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = loc.t('清空失败: $e', 'Clear failed: $e');
        });
      }
    }
  }

  int _calculateCurrentWeek() {
    final now = DateTime.now();
    // Use the same reference date as in _buildWeekdayHeader
    final firstWeekStart = DateTime(now.year, 3, 9);
    final diff = now.difference(firstWeekStart).inDays;
    if (diff < 0) return 1;
    final week = (diff / 7).floor() + 1;
    return week.clamp(1, 20);
  }

  File _uiPrefsFile() {
    return File(p.join(widget.session.dataDir, _uiPrefsFileName));
  }

  Future<void> _loadUiPrefs() async {
    try {
      final f = _uiPrefsFile();
      if (!await f.exists()) return;
      final decoded = jsonDecode(await f.readAsString(encoding: utf8));
      if (decoded is! Map) return;
      final showWeekend = decoded['show_weekend'];
      final viewing = decoded['viewing_profile_id']?.toString().trim();
      if (!mounted) return;
      setState(() {
        if (showWeekend is bool) _showWeekend = showWeekend;
        if (viewing != null && viewing.isNotEmpty) {
          if (viewing == widget.session.profile.id) {
            _viewingProfileId = viewing;
          } else if (widget.session.isTeacher && viewing.startsWith('class_')) {
            _viewingProfileId = viewing;
          }
        }
      });
    } catch (_) {}
  }

  Future<void> _saveUiPrefs() async {
    try {
      final f = _uiPrefsFile();
      final payload = <String, dynamic>{
        'show_weekend': _showWeekend,
        'viewing_profile_id': _viewingProfileId,
        'saved_at': DateTime.now().toIso8601String(),
      };
      await f.writeAsString(jsonEncode(payload), encoding: utf8);
    } catch (_) {}
  }

  void _onGlobalDataChanged() {
    if (mounted) {
      _refresh(isBackground: true);
    }
  }

  Future<void> _refresh({bool isBackground = false}) async {
    if (!isBackground) {
      setState(() {
        _status = '';
      });
    }

    if (widget.session.isTeacher) {
      _teacherClasses = await LocalProfiles.getTeacherClasses(
        widget.session.dataDir,
        widget.session.profile.id,
      );
    }

    Map<String, dynamic> coursesRes;
    if (await widget.session.features.hasFeature('courses_list')) {
      coursesRes = await widget.session.features.listCourses();
    } else {
      final cli = widget.session.cli;
      if (!mounted) return;
      final loc = Provider.of<LocaleProvider>(context, listen: false);
      if (cli == null) {
        setState(() {
          _status = loc.t('缺少 courses_list，且未配置 campus_cli',
              'Missing courses_list, and campus_cli is not configured');
        });
        return;
      }
      coursesRes = await cli.call('courses.list', {});
    }
    if (coursesRes['ok'] != true) {
      final msg =
          ((coursesRes['error'] ?? const {}) as Map)['message']?.toString() ??
              'unknown error';
      if (mounted) {
        setState(() {
          _status = msg;
        });
      }
      widget.onReady?.call();
      return;
    }

    final List courseRaw = (coursesRes['data'] as Map?)?['items'] ?? const [];
    final courses = <String, Course>{};
    for (final e in courseRaw) {
      final course = Course.fromJson((e as Map).cast<String, dynamic>());
      courses[course.id] = course;
    }

    Map<String, dynamic> res;
    if (await widget.session.features.hasFeature('timetable_list')) {
      res = await widget.session.features.listTimetable();
    } else {
      final cli = widget.session.cli;
      if (!mounted) return;
      final loc = Provider.of<LocaleProvider>(context, listen: false);
      if (cli == null) {
        setState(() {
          _status = loc.t('缺少 timetable_list，且未配置 campus_cli',
              'Missing timetable_list, and campus_cli is not configured');
        });
        return;
      }
      res = await cli.call('timetable.list', {});
    }
    if (res['ok'] != true) {
      final msg = ((res['error'] ?? const {}) as Map)['message']?.toString() ??
          'unknown error';
      setState(() {
        _status = msg;
      });
      widget.onReady?.call();
      return;
    }

    final raw =
        (((res['data'] ?? const {}) as Map)['items'] ?? const []) as List;
    final ttMap = <String, TimetableItem>{};
    for (final e in raw) {
      final item = TimetableItem.fromJson((e as Map).cast<String, dynamic>());
      ttMap[item.id] = item;
    }
    final all = ttMap.values.toList();
    final items = all.where((e) {
      if (e.ownerProfileId == _viewingProfileId) return true;
      // If student, also show class schedule
      if (!widget.session.isTeacher &&
          e.ownerProfileId == 'class_${widget.session.profile.classCode}') {
        return true;
      }
      return false;
    }).toList();
    items.sort((a, b) {
      final w = a.weekday.compareTo(b.weekday);
      if (w != 0) return w;
      return a.startTime.compareTo(b.startTime);
    });

    if (!mounted) return;
    setState(() {
      _status = ''; // Clear error on success
      _courses = courses;
      _items = items;
      // Force rebuild the color map to discard any cached explicit colors from older sessions if they were removed
      _courseColors.clear();
      _courseColors = _buildCourseColorMap(items.map((e) => e.courseId));
    });
    widget.onReady?.call();
  }

  int _findPeriodForTimes(String startTime, String endTime) {
    final s = startTime.trim();
    final e = endTime.trim();
    for (final p in _periods) {
      if (p.start == s && p.end == e) return p.period;
    }
    return 0;
  }

  Future<List<Map<String, String>>> _readCsvRows(String filename) async {
    final res =
        await widget.session.features.csvOp(action: 'read', file: filename);
    if (res['ok'] != true) return [];
    final items = ((res['data'] ?? const {})['items'] as List?) ?? const [];
    return items.map((e) => (e as Map).cast<String, String>()).toList();
  }

  Future<void> _writeCsv(
    String filename,
    List<String> headers,
    List<Map<String, String>> rows,
  ) async {
    await widget.session.features
        .csvOp(action: 'write', file: filename, headers: headers, rows: rows);
  }

  Future<List<String>> _studentProfileIds({String? classCode}) async {
    final rows = await _readCsvRows('profiles.csv');
    final ids = <String>[];
    for (final r in rows) {
      final cls = (r['class_code'] ?? '').trim();
      if (classCode != null &&
          classCode.trim().isNotEmpty &&
          cls != classCode.trim()) {
        continue;
      }
      final role = (r['role'] ?? '').trim();
      if (role != 'student' && role != 'cadre') {
        continue;
      }
      final id = (r['id'] ?? '').trim();
      if (id.isNotEmpty) {
        ids.add(id);
      }
    }
    return ids;
  }

  Future<void> _deleteTimetable({
    required String ownerProfileId,
    required int weekday,
    required int startPeriod,
    bool allowLocked = false,
    String? createdByProfileId,
  }) async {
    final rows = await _readCsvRows('timetable.csv');
    if (rows.isEmpty) return;
    final headers = [
      'id',
      'owner_profile_id',
      'weekday',
      'start_period',
      'end_period',
      'start_time',
      'end_time',
      'course_id',
      'location',
      'created_by_profile_id',
      'is_locked',
      'weeks'
    ];
    bool isMatch(Map<String, String> r) {
      if ((r['owner_profile_id'] ?? '') != ownerProfileId) return false;
      if (int.tryParse((r['weekday'] ?? '').toString()) != weekday) {
        return false;
      }
      if (int.tryParse((r['start_period'] ?? '').toString()) != startPeriod) {
        return false;
      }
      if (createdByProfileId != null &&
          (r['created_by_profile_id'] ?? '') != createdByProfileId) {
        return false;
      }
      return true;
    }

    final matches = rows.where(isMatch).toList(growable: false);
    if (matches.isEmpty) return;

    for (final r in matches) {
      final lockedRaw = (r['is_locked'] ?? '').toLowerCase();
      final locked =
          lockedRaw == 'true' || lockedRaw == '1' || lockedRaw == 'yes';
      if (locked && !allowLocked) {
        if (!mounted) throw Exception('locked');
        final loc = Provider.of<LocaleProvider>(context, listen: false);
        throw loc.t('该课表由老师添加，学生不可更改',
            'This schedule was added by a teacher and cannot be modified by students');
      }
    }

    rows.removeWhere(isMatch);
    await _writeCsv('timetable.csv', headers, rows);
  }

  Future<void> _deleteTimetableForItem(TimetableItem item,
      {bool skipConfirm = false}) async {
    final loc = Provider.of<LocaleProvider>(context, listen: false);
    if (!skipConfirm) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(loc.t('删除课表', 'Delete Schedule')),
          content: Text(loc.t('确认删除该课表项？',
              'Are you sure you want to delete this schedule item?')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(loc.t('取消', 'Cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(loc.t('删除', 'Delete')),
            ),
          ],
        ),
      );
      if (ok != true) return;
      if (!mounted) return;
    }

    final teacherId = widget.session.profile.id;
    final isTeacher = widget.session.isTeacher;
    final allowLocked = isTeacher;

    if (isTeacher && _viewingProfileId.startsWith('class_')) {
      final targetClass = _viewingProfileId.substring('class_'.length);
      final ids = await _studentProfileIds(classCode: targetClass);
      for (final id in ids) {
        await _deleteTimetable(
          ownerProfileId: id,
          weekday: item.weekday,
          startPeriod: item.startPeriod,
          allowLocked: allowLocked,
          createdByProfileId: teacherId,
        );
      }
      await _deleteTimetable(
        ownerProfileId: _viewingProfileId,
        weekday: item.weekday,
        startPeriod: item.startPeriod,
        allowLocked: allowLocked,
        createdByProfileId: teacherId,
      );
    } else {
      final canDelete = isTeacher ||
          (!item.isLocked &&
              item.createdByProfileId == widget.session.profile.id);
      if (!canDelete) {
        if (!mounted) return;
        showExpressiveSnackBar(
          context,
          loc.t('无权限删除该课表项', 'No permission to delete this schedule item'),
        );
        return;
      }
      await _deleteTimetable(
        ownerProfileId: _viewingProfileId,
        weekday: item.weekday,
        startPeriod: item.startPeriod,
        allowLocked: allowLocked,
        createdByProfileId: isTeacher ? teacherId : widget.session.profile.id,
      );
    }

    await _refresh();
    if (!mounted) return;
    showExpressiveSnackBar(
      context,
      loc.t('已删除课表项', 'Schedule item deleted'),
    );
  }

  Future<void> _showTimetableItemActions(TimetableItem item) async {
    final isTeacher = widget.session.isTeacher;
    final canDelete = isTeacher ||
        (!item.isLocked &&
            item.createdByProfileId == widget.session.profile.id);

    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        final tt = Theme.of(ctx).textTheme;
        final loc = Provider.of<LocaleProvider>(ctx);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    loc.t('课程操作', 'Course Actions'),
                    style:
                        tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:
                        Icon(Icons.edit_outlined, color: cs.onPrimaryContainer),
                  ),
                  title: Text(loc.t('编辑课程详情', 'Edit Course Details')),
                  subtitle: Text(
                      loc.t('修改时间、地点或备注', 'Change time, location, or notes')),
                  onTap: () => Navigator.of(ctx).pop('edit'),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const SizedBox(height: 8),
                if (canDelete)
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cs.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.delete_outline,
                          color: cs.onErrorContainer),
                    ),
                    title: Text(
                      loc.t('删除课程', 'Delete Course'),
                      style: TextStyle(
                          color: cs.error, fontWeight: FontWeight.bold),
                    ),
                    subtitle:
                        Text(loc.t('此操作不可撤销', 'This action cannot be undone')),
                    onTap: () => Navigator.of(ctx).pop('delete'),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );

    if (action == 'edit') {
      await _editCell(
        initialWeekday: item.weekday,
        initialPeriod: item.startPeriod,
      );
      return;
    }
    if (action == 'delete') {
      await _deleteTimetableForItem(item, skipConfirm: true);
    }
  }

  Future<void> _editCell({int? initialWeekday, int? initialPeriod}) async {
    final owner = widget.session.profile.id;

    TimetableItem? keyItem;
    if (initialWeekday != null && initialPeriod != null) {
      final dayMap = _cellItems[initialWeekday];
      if (dayMap != null) {
        keyItem = dayMap[initialPeriod];
      }
    }

    final initialCourse = keyItem != null ? _courses[keyItem.courseId] : null;

    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (ctx) => AddCoursePage(
          initialCourse: initialCourse,
          initialItem: keyItem,
          availableCourses: _courses.values.toList(),
          isTeacher: widget.session.isTeacher,
          teacherClasses: _teacherClasses,
        ),
      ),
    );

    if (result == null) return;
    if (!mounted) return;
    final loc = Provider.of<LocaleProvider>(context, listen: false);

    try {
      final action = (result['action'] ?? '').toString();
      if (action == 'delete' && keyItem != null) {
        await _deleteTimetableForItem(keyItem, skipConfirm: true);
        return;
      }

      final base = DateTime.now().microsecondsSinceEpoch;
      var seq = 0;
      String nextTtId() => 'tt_${base}_${seq++}';

      final courseName = result['courseName'] as String;
      final credits = result['credits'] as String;
      final notes = result['notes'] as String;
      final color = result['color'] as String;
      final location = result['location'] as String;
      final timeSlots = result['timeSlots'] as List<Map<String, dynamic>>;

      if (courseName.trim().isEmpty) {
        throw loc.t('请输入课程名', 'Please enter a course name');
      }

      // 1. Save/Update Course
      String cid;
      if (initialCourse != null) {
        cid = initialCourse.id;
        // For updates, we still use direct CSV for now as we don't have an update feature
        // but adding new courses will use the native feature
        final rows = await _readCsvRows('courses.csv');
        final idx = rows.indexWhere((r) => r['id'] == cid);
        if (idx >= 0) {
          rows[idx]['course_name'] = courseName;
          rows[idx]['credits'] = credits;
          rows[idx]['notes'] = notes;
          rows[idx]['color'] = color;
          await _writeCsv('courses.csv', _coursesHeader.split(','), rows);
        }
      } else {
        // Check if course with same name exists
        final existing = _courses.values
            .where((c) => c.courseName == courseName)
            .firstOrNull;
        if (existing != null) {
          cid = existing.id;
        } else {
          // Create new course using native feature
          cid = 'c_${DateTime.now().millisecondsSinceEpoch}';
          final res = await widget.session.features.insertCourse(
            id: cid,
            name: courseName,
            teacherId: owner,
            term: '2026S',
            color: color,
            credits: credits,
            notes: notes,
          );
          if (res['ok'] != true) {
            throw ((res['error'] ?? const {}) as Map)['message'] ??
                loc.t('保存课程失败', 'Failed to save course');
          }
        }
      }

      // 2. Save Timetable Items using native feature
      for (final slot in timeSlots) {
        final weekday = slot['weekday'] as int;
        final start = slot['startPeriod'] as int;
        final end = slot['endPeriod'] as int;
        final weeks = slot['weeks'] as String;

        final sp = _periods.firstWhere((e) => e.period == start);
        final ep = _periods.firstWhere((e) => e.period == end);

        if (widget.session.isTeacher &&
            _viewingProfileId.startsWith('class_')) {
          final targetClass = _viewingProfileId.substring('class_'.length);
          final ids = await _studentProfileIds(classCode: targetClass);
          for (final id in ids) {
            final r = await widget.session.features.insertTimetableItem(
              id: nextTtId(),
              owner: id,
              weekday: weekday,
              startPeriod: start,
              endPeriod: end,
              startTime: sp.start,
              endTime: ep.end,
              courseId: cid,
              location: location,
              creator: owner,
              isLocked: true,
              weeks: weeks,
            );
            if (r['ok'] != true) {
              throw ((r['error'] ?? const {}) as Map)['message'] ??
                  loc.t('保存课表失败', 'Failed to save schedule');
            }
          }
          // Also add to class viewing profile
          final r2 = await widget.session.features.insertTimetableItem(
            id: nextTtId(),
            owner: _viewingProfileId,
            weekday: weekday,
            startPeriod: start,
            endPeriod: end,
            startTime: sp.start,
            endTime: ep.end,
            courseId: cid,
            location: location,
            creator: owner,
            isLocked: true,
            weeks: weeks,
          );
          if (r2['ok'] != true) {
            throw ((r2['error'] ?? const {}) as Map)['message'] ??
                loc.t('保存课表失败', 'Failed to save schedule');
          }
        } else {
          final r = await widget.session.features.insertTimetableItem(
            id: nextTtId(),
            owner: _viewingProfileId,
            weekday: weekday,
            startPeriod: start,
            endPeriod: end,
            startTime: sp.start,
            endTime: ep.end,
            courseId: cid,
            location: location,
            creator: owner,
            isLocked: false,
            weeks: weeks,
          );
          if (r['ok'] != true) {
            throw ((r['error'] ?? const {}) as Map)['message'] ??
                loc.t('保存课表失败', 'Failed to save schedule');
          }
        }
      }

      await _refresh();
      if (mounted) {
        final target = _viewingProfileId.startsWith('class_')
            ? '${loc.t('班级', 'Class')} ${_viewingProfileId.substring('class_'.length)}'
            : loc.t('我的课表', 'Timetable');
        showExpressiveSnackBar(
          context,
          loc.t('成功添加课程到：$target', 'Course added to: $target'),
        );
      }
    } catch (e) {
      if (!mounted) return;
      showExpressiveSnackBar(context, e.toString());
    }
  }

  Map<int, Map<int, TimetableItem>> get _cellItems {
    final byDay = <int, Map<int, TimetableItem>>{};
    for (final item in _items) {
      if (!item.isWeekIncluded(_currentWeek)) continue;
      final day = item.weekday;
      var period = item.period;
      if (period <= 0) {
        period = _findPeriodForTimes(item.startTime, item.endTime);
      }
      if (period <= 0) {
        continue;
      }
      byDay.putIfAbsent(day, () => {})[period] = item;
    }
    return byDay;
  }

  Future<void> _importWakeupSchedule() async {
    final loc = Provider.of<LocaleProvider>(context, listen: false);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['wakeup_schedule', 'json', 'txt'],
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;
      if (!mounted) return;
      final path = result.files.first.path;
      if (path == null) return;

      final content = await File(path).readAsString();
      if (!mounted) return;

      // Parse the 5 JSON blocks
      // A simple way to split them is by finding the top-level structures
      final blocks = <String>[];
      int braceDepth = 0;
      int bracketDepth = 0;
      int start = -1;
      bool inString = false;

      for (int i = 0; i < content.length; i++) {
        final c = content[i];
        if (c == '"' && (i == 0 || content[i - 1] != '\\')) {
          inString = !inString;
        }
        if (!inString) {
          if (c == '{') braceDepth++;
          if (c == '}') braceDepth--;
          if (c == '[') bracketDepth++;
          if (c == ']') bracketDepth--;
        }

        if (start == -1 && !inString && (c == '{' || c == '[')) {
          start = i;
        }

        if (start != -1 && braceDepth == 0 && bracketDepth == 0) {
          blocks.add(content.substring(start, i + 1));
          start = -1;
        }
      }

      if (blocks.length < 5) {
        throw loc.t(
            '无效的 wakeup_schedule 文件格式', 'Invalid wakeup_schedule file format');
      }

      final itemsJson = jsonDecode(blocks[4]) as List;

      setState(() {
        _status = loc.t('正在导入...', 'Importing...');
      });

      final owner = widget.session.profile.id;
      final base = DateTime.now().microsecondsSinceEpoch;
      var seq = 0;
      String nextTtId() => 'tt_${base}_${seq++}';

      // Import Courses
      final coursesJson = jsonDecode(blocks[3]) as List;
      final courseIdMap = <int, String>{};
      for (final c in coursesJson) {
        final map = c as Map<String, dynamic>;
        final oldId = map['id'] as int;
        final name = (map['courseName'] ?? '').toString();
        final credit = (map['credit'] ?? 0).toString();
        final note = (map['note'] ?? '').toString();
        final colorStr = (map['color'] ?? '').toString();
        String parsedColor = '';
        if (colorStr.startsWith('#') && colorStr.length == 9) {
          parsedColor = int.parse(colorStr.substring(1), radix: 16).toString();
        }

        final newCid = 'c_${base}_${seq++}';
        courseIdMap[oldId] = newCid;

        final res = await widget.session.features.insertCourse(
          id: newCid,
          name: name,
          teacherId: owner,
          term: '2026S',
          color: parsedColor,
          credits: credit,
          notes: note,
        );
        if (res['ok'] != true) throw loc.t('保存课程失败', 'Failed to save course');
      }

      // Import Timetable Items
      for (final item in itemsJson) {
        final map = item as Map<String, dynamic>;
        final oldCid = map['id'] as int;
        final newCid = courseIdMap[oldCid];
        if (newCid == null) continue;

        final day = map['day'] as int;
        final startNode = map['startNode'] as int;
        final step = map['step'] as int;
        final endNode = startNode + step - 1;
        final room = (map['room'] ?? '').toString();
        final startWeek = map['startWeek'] ?? 1;
        final endWeek = map['endWeek'] ?? 20;
        final type = map['type'] ?? 0; // 0=all, 1=odd, 2=even

        String weeksStr = '';
        if (type == 0) {
          weeksStr = '$startWeek-$endWeek';
        } else {
          final wList = <int>[];
          for (var w = startWeek as int; w <= (endWeek as int); w++) {
            if (type == 1 && w % 2 != 0) wList.add(w);
            if (type == 2 && w % 2 == 0) wList.add(w);
          }
          weeksStr = wList.join(',');
        }

        // Find start/end time roughly based on period
        final sp = _periods.firstWhere((e) => e.period == startNode,
            orElse: () => _periods.first);
        final ep = _periods.firstWhere((e) => e.period == endNode,
            orElse: () => _periods.first);

        if (widget.session.isTeacher &&
            _viewingProfileId.startsWith('class_')) {
          final targetClass = _viewingProfileId.substring('class_'.length);
          final ids = await _studentProfileIds(classCode: targetClass);
          for (final id in ids) {
            await widget.session.features.insertTimetableItem(
              id: nextTtId(),
              owner: id,
              weekday: day,
              startPeriod: startNode,
              endPeriod: endNode,
              startTime: sp.start,
              endTime: ep.end,
              courseId: newCid,
              location: room,
              creator: owner,
              isLocked: true,
              weeks: weeksStr,
            );
          }
          await widget.session.features.insertTimetableItem(
            id: nextTtId(),
            owner: _viewingProfileId,
            weekday: day,
            startPeriod: startNode,
            endPeriod: endNode,
            startTime: sp.start,
            endTime: ep.end,
            courseId: newCid,
            location: room,
            creator: owner,
            isLocked: true,
            weeks: weeksStr,
          );
        } else {
          await widget.session.features.insertTimetableItem(
            id: nextTtId(),
            owner: _viewingProfileId,
            weekday: day,
            startPeriod: startNode,
            endPeriod: endNode,
            startTime: sp.start,
            endTime: ep.end,
            courseId: newCid,
            location: room,
            creator: owner,
            isLocked: false,
            weeks: weeksStr,
          );
        }
      }

      await _refresh();
      if (mounted) {
        showExpressiveSnackBar(
          context,
          loc.t('导入成功', 'Import succeeded'),
        );
      }
    } catch (e) {
      if (mounted) {
        final loc = Provider.of<LocaleProvider>(context, listen: false);
        setState(() {
          _status = loc.t('导入失败: $e', 'Import failed: $e');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only rebuild parts that need it.
    // The main Scaffold should be stable.
    final loc = Provider.of<LocaleProvider>(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDesktop =
        Platform.isWindows || Platform.isLinux || Platform.isMacOS;
    final isAndroid = Platform.isAndroid;
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final showDrawerButton =
        (!isDesktop || isPortrait) && !(Platform.isAndroid && isTablet);
    final scrollPhysics = isAndroid
        ? const ClampingScrollPhysics()
        : const BouncingScrollPhysics();
    final pagePhysics = const PageScrollPhysics().applyTo(scrollPhysics);
    final titleStyle = Theme.of(context)
        .textTheme
        .titleLarge
        ?.copyWith(fontWeight: FontWeight.bold);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: showDrawerButton ? 0 : 0,
        leadingWidth: showDrawerButton ? 56.0 : 16.0,
        leading: showDrawerButton
            ? Builder(
                builder: (context) {
                  return IconButton(
                    icon: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 24,
                        height: 24,
                        fit: BoxFit.cover,
                      ),
                    ),
                    onPressed: () {
                      ScaffoldState? scaffold = Scaffold.maybeOf(context);
                      if (scaffold != null && !scaffold.hasDrawer) {
                        scaffold = scaffold.context
                            .findAncestorStateOfType<ScaffoldState>();
                      }
                      scaffold?.openDrawer();
                    },
                  );
                },
              )
            : const SizedBox.shrink(),
        title: widget.session.isTeacher && _teacherClasses.isNotEmpty
            ? Transform.translate(
                offset: Offset(showDrawerButton ? -8.0 : 0.0, 0.0),
                child: isDesktop
                    ? ExpressiveSelector(
                        label: loc.t('班级', 'Class'),
                        value: _viewingProfileId == widget.session.profile.id
                            ? loc.t('我的课表', 'Timetable')
                            : _viewingProfileId.replaceFirst('class_', ''),
                        items: [
                          loc.t('我的课表', 'Timetable'),
                          ..._teacherClasses,
                        ],
                        backgroundColor: cs.tertiaryContainer,
                        foregroundColor: cs.onTertiaryContainer,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        labelTextStyle: tt.labelSmall?.copyWith(
                          color: cs.onTertiaryContainer.withValues(alpha: 179),
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                        ),
                        valueTextStyle: tt.bodyMedium?.copyWith(
                          fontSize: 13,
                          color: cs.onTertiaryContainer,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ),
                        onSelected: (v) {
                          final target = v == loc.t('我的课表', 'Timetable')
                              ? widget.session.profile.id
                              : 'class_$v';
                          if (target != _viewingProfileId) {
                            setState(() {
                              _viewingProfileId = target;
                            });
                            unawaited(_saveUiPrefs());
                            _refresh();
                          }
                        },
                      )
                    : PopupMenuButton<String>(
                        tooltip: loc.t('选择班级', 'Select class'),
                        initialValue:
                            _viewingProfileId == widget.session.profile.id
                                ? loc.t('我的课表', 'Timetable')
                                : _viewingProfileId.replaceFirst('class_', ''),
                        onSelected: (v) {
                          final target = v == loc.t('我的课表', 'Timetable')
                              ? widget.session.profile.id
                              : 'class_$v';
                          if (target != _viewingProfileId) {
                            setState(() {
                              _viewingProfileId = target;
                            });
                            unawaited(_saveUiPrefs());
                            _refresh();
                          }
                        },
                        itemBuilder: (context) {
                          final items = [
                            loc.t('我的课表', 'Timetable'),
                            ..._teacherClasses,
                          ];
                          return items
                              .map(
                                (e) => PopupMenuItem<String>(
                                  value: e,
                                  child: Text(e),
                                ),
                              )
                              .toList(growable: false);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: cs.tertiaryContainer,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: cs.outlineVariant.withValues(alpha: 96),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _viewingProfileId == widget.session.profile.id
                                    ? loc.t('我的课表', 'Timetable')
                                    : _viewingProfileId.replaceFirst(
                                        'class_', ''),
                                style: TextStyle(
                                  color: cs.onTertiaryContainer,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 20,
                                color: cs.onTertiaryContainer,
                              ),
                            ],
                          ),
                        ),
                      ),
              )
            : isDesktop
                ? Text(
                    loc.t('我的课表', 'Timetable'),
                    style: titleStyle,
                  )
                : ValueListenableBuilder<int>(
                    valueListenable: _currentWeekN,
                    builder: (context, week, _) {
                      return Text(
                        loc.t('第$week周', 'Week $week'),
                        style: titleStyle,
                      );
                    },
                  ),
        actions: [
          if (isDesktop)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Center(
                child: IconButton(
                  tooltip: loc.t('导入 WakeUp 课程表', 'Import WakeUp Schedule'),
                  onPressed: _importWakeupSchedule,
                  icon: const Icon(Icons.file_upload_outlined),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: FilledButton.tonal(
                onPressed: () {
                  setState(() {
                    _showWeekend = !_showWeekend;
                  });
                  unawaited(_saveUiPrefs());
                },
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(scale: animation, child: child),
                    );
                  },
                  child: ValueListenableBuilder<int>(
                    valueListenable: _currentWeekN,
                    builder: (context, week, _) {
                      return Text(
                        _showWeekend
                            ? loc.t('7日（第$week周）', '7 Days (Week $week)')
                            : loc.t('5日（第$week周）', '5 Days (Week $week)'),
                        key: ValueKey(_showWeekend),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_timetable_add',
        onPressed: () => _editCell(),
        elevation: 1,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        shape: const CircleBorder(),
        tooltip: loc.t('添加课程', 'Add Course'),
        child: const Icon(Icons.add),
      ),
      body: Container(
        color: Theme.of(context).colorScheme.surface,
        child: Column(
          children: [
            if (isDesktop)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: _buildWeekControl(),
              ),
            if (_status.isNotEmpty)
              Container(
                width: double.infinity,
                color: Theme.of(context).colorScheme.errorContainer,
                padding: const EdgeInsets.all(8),
                child: Text(_status,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                        fontSize: 12)),
              ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: pagePhysics,
                onPageChanged: (index) {
                  final w = (index + 1).clamp(1, 20);
                  _currentWeek = w;
                  _currentWeekN.value = w;
                },
                itemCount: 20,
                itemBuilder: (context, index) {
                  return _TimetableWeekView(
                    week: index + 1,
                    viewingProfileId: _viewingProfileId,
                    showWeekend: _showWeekend,
                    items: _items,
                    courses: _courses,
                    courseColors: _courseColors,
                    onEditCell: _editCell,
                    onShowActions: _showTimetableItemActions,
                    onShowQuickMenu: _showCourseQuickMenu,
                    isTeacher: widget.session.isTeacher,
                    canTakeAttendance: widget.session.canTakeAttendance,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goToWeek(int week) {
    final w = week.clamp(1, 20);
    if (w == _currentWeek) return;
    _currentWeek = w;
    _currentWeekN.value = w;
    _pageController.animateToPage(
      w - 1,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Widget _buildWeekControl() {
    final loc = Provider.of<LocaleProvider>(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final isDesktop =
        Platform.isWindows || Platform.isLinux || Platform.isMacOS;

    return isDesktop
        ? GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragEnd: (details) {
              final v = details.primaryVelocity ?? 0;
              if (v < -150) _goToWeek(_currentWeek + 1);
              if (v > 150) _goToWeek(_currentWeek - 1);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 128),
                ),
              ),
              child: Center(
                child: ValueListenableBuilder<int>(
                  valueListenable: _currentWeekN,
                  builder: (context, week, _) {
                    return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.15),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: Text(
                          loc.t('第 $week 周', 'Week $week'),
                          key: ValueKey(week),
                          style: tt.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ));
                  },
                ),
              ),
            ),
          )
        : const SizedBox.shrink();
  }

  // Removed unused internal build methods

  Widget _buildWeekdayHeader({
    required int targetWeek,
    required List<int> visibleDays,
    required double cellWidth,
  }) {
    final loc = Provider.of<LocaleProvider>(context);
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    // Assuming 2026 spring semester start date for date calculation
    final firstWeekStart = DateTime(now.year, 3, 9);
    final startOfTargetWeek =
        firstWeekStart.add(Duration(days: (targetWeek - 1) * 7));
    final labelFontSize = (cellWidth * 0.22).clamp(10.0, 12.0);
    final dayFontSize = (cellWidth * 0.28).clamp(12.0, 15.0);

    final dayLabels = <int, String>{
      1: loc.t('一', 'Mon'),
      2: loc.t('二', 'Tue'),
      3: loc.t('三', 'Wed'),
      4: loc.t('四', 'Thu'),
      5: loc.t('五', 'Fri'),
      6: loc.t('六', 'Sat'),
      7: loc.t('日', 'Sun'),
    };

    return Row(
      children: List.generate(visibleDays.length, (i) {
        final date = startOfTargetWeek.add(Duration(days: i));
        final isToday = now.year == date.year &&
            now.month == date.month &&
            now.day == date.day;
        final label = dayLabels[visibleDays[i]] ?? '';

        return SizedBox(
          width: cellWidth,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            decoration: BoxDecoration(
              color: isToday ? cs.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: labelFontSize,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    color: isToday ? cs.onPrimary : cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: dayFontSize,
                    fontWeight: FontWeight.bold,
                    color: isToday ? cs.onPrimary : cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTimeColumn() {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 40,
      child: Column(
        children: _periods.take(_maxVisiblePeriod).map((p) {
          return SizedBox(
            height: 60, // Height per period
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${p.period}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: cs.onSurface)),
                Text(p.start,
                    style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
                Text(p.end,
                    style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGridStack({
    Key? key,
    required int targetWeek,
    required List<int> visibleDays,
    required double cellWidth,
  }) {
    final cs = Theme.of(context).colorScheme;
    const double cellHeight = 60;

    // Use a ValueKey for the stack that doesn't change on data refresh to avoid rebuild blinks
    // But we still want to filter items for the correct week
    final weekItems =
        _items.where((e) => e.isWeekIncluded(targetWeek)).toList();

    return SizedBox(
      key: key,
      width: cellWidth * visibleDays.length,
      height: _maxVisiblePeriod * cellHeight,
      child: Stack(
        children: [
          ...List.generate(visibleDays.length, (i) {
            return Positioned(
              left: i * cellWidth,
              top: 0,
              bottom: 0,
              width: cellWidth,
              child: Container(
                color: cs.primary.withValues(alpha: 0.05),
              ),
            );
          }),
          ...List.generate(visibleDays.length, (i) {
            return Positioned(
              left: i * cellWidth,
              top: 0,
              bottom: 0,
              width: 1,
              child: Container(color: Colors.grey.withValues(alpha: 0.1)),
            );
          }),
          ...List.generate(_maxVisiblePeriod, (i) {
            return Positioned(
              left: 0,
              right: 0,
              top: i * cellHeight,
              height: 1,
              child: Container(color: Colors.grey.withValues(alpha: 0.1)),
            );
          }),
          ...weekItems.map((item) {
            final course = _courses[item.courseId];
            if (course == null) return const SizedBox.shrink();

            final weekdayIndex = visibleDays.indexOf(item.weekday);
            if (weekdayIndex < 0) return const SizedBox.shrink();
            if (item.startPeriod > _maxVisiblePeriod) {
              return const SizedBox.shrink();
            }
            final startPeriodIndex = item.startPeriod - 1;
            final effectiveEndPeriod =
                item.endPeriod.clamp(1, _maxVisiblePeriod);
            final periodSpan = effectiveEndPeriod - item.startPeriod + 1;
            if (periodSpan <= 0) return const SizedBox.shrink();

            // Ignore explicitColor locally to force new expressiveColors theme, since user complained about old colors being stuck.
            // (If user manually sets color via UI later, it will still save to CSV, but we override it here for now to ensure the new palette is seen).
            final baseCardColor = _courseColors[item.courseId] ??
                _expressiveColors[
                    item.courseId.hashCode.abs() % _expressiveColors.length];
            final cardColor = baseCardColor;
            const cardRadius = 12.0;

            return Positioned(
              left: weekdayIndex * cellWidth,
              top: startPeriodIndex * cellHeight,
              width: cellWidth,
              height: periodSpan * cellHeight,
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: _TimetableCourseBlock(
                  key: ValueKey(item.id),
                  onTapDown: (details) {
                    final enableQuickRollCall =
                        Provider.of<LocaleProvider>(context, listen: false)
                            .enableQuickRollCall;
                    if (widget.session.canTakeAttendance &&
                        enableQuickRollCall) {
                      _showCourseQuickMenu(
                        details: details,
                        item: item,
                        course: course,
                      );
                    } else {
                      _editCell(
                        initialWeekday: item.weekday,
                        initialPeriod: item.startPeriod,
                      );
                    }
                  },
                  onTap: () {},
                  onLongPress: () => _showTimetableItemActions(item),
                  color: cardColor,
                  radius: cardRadius,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.courseName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.black.withValues(alpha: 220),
                            height: 1.5,
                          ),
                          maxLines: 4,
                          overflow: TextOverflow.fade,
                        ),
                        const Spacer(),
                        if (item.location.isNotEmpty)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 10,
                                color: Colors.black.withValues(alpha: 150),
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  item.location,
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.black.withValues(alpha: 150),
                                    fontWeight: FontWeight.w500,
                                    height: 1.15,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        if (item.weeks.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.weeks,
                                style: TextStyle(
                                    fontSize: 8,
                                    color: Colors.black.withValues(alpha: 0.6),
                                    fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _showCourseQuickMenu({
    required TapDownDetails details,
    required TimetableItem item,
    required Course course,
  }) async {
    final loc = Provider.of<LocaleProvider>(context, listen: false);
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final pos = details.globalPosition;
    final r = RelativeRect.fromRect(
      Rect.fromLTWH(pos.dx, pos.dy, 0, 0),
      Offset.zero & overlay.size,
    );
    final selected = await showMenu<String>(
      context: context,
      position: r,
      items: [
        PopupMenuItem(
          value: 'edit',
          child: Text(loc.t('修改课表', 'Edit Timetable')),
        ),
        PopupMenuItem(
          value: 'roll',
          child: Text(loc.t('点名', 'Roll Call')),
        ),
      ],
    );
    if (!mounted) return;
    if (selected == 'edit') {
      _editCell(
        initialWeekday: item.weekday,
        initialPeriod: item.startPeriod,
      );
    }
    if (selected == 'roll') {
      _pushAttendanceAnimated(
        courseId: item.courseId,
        courseName: course.courseName,
      );
    }
  }

  void _pushAttendanceAnimated({String? courseId, String? courseName}) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return AttendancePage(
            session: widget.session,
            courseId: courseId,
            courseName: courseName,
            isStandalone: true,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;
          final tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          final offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }
}

class _TimetableWeekView extends StatefulWidget {
  final int week;
  final String viewingProfileId;
  final bool showWeekend;
  final List<TimetableItem> items;
  final Map<String, Course> courses;
  final Map<String, Color> courseColors;
  final Function({int? initialWeekday, int? initialPeriod}) onEditCell;
  final Function(TimetableItem) onShowActions;
  final Function({
    required TapDownDetails details,
    required TimetableItem item,
    required Course course,
  }) onShowQuickMenu;
  final bool isTeacher;
  final bool canTakeAttendance;

  const _TimetableWeekView({
    required this.week,
    required this.viewingProfileId,
    required this.showWeekend,
    required this.items,
    required this.courses,
    required this.courseColors,
    required this.onEditCell,
    required this.onShowActions,
    required this.onShowQuickMenu,
    required this.isTeacher,
    required this.canTakeAttendance,
  });

  @override
  State<_TimetableWeekView> createState() => _TimetableWeekViewState();
}

class _TimetableWeekViewState extends State<_TimetableWeekView> {
  final ScrollController _gridScrollController = ScrollController();

  @override
  void dispose() {
    _gridScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleDays = widget.showWeekend
        ? const [1, 2, 3, 4, 5, 6, 7]
        : const [1, 2, 3, 4, 5];
    final isDesktop =
        Platform.isWindows || Platform.isLinux || Platform.isMacOS;
    final isAndroid = Platform.isAndroid;
    final scrollPhysics = isAndroid
        ? const ClampingScrollPhysics()
        : const BouncingScrollPhysics();

    return LayoutBuilder(
      builder: (context, constraints) {
        final gridWidth =
            (constraints.maxWidth - 40).clamp(0.0, double.infinity);
        final cellWidth = gridWidth / visibleDays.length;

        return Column(
          children: [
            SizedBox(
              height: 64,
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: _buildMonthHeader(context, widget.week),
                  ),
                  Expanded(
                    child: SizedBox(
                      width: gridWidth,
                      child: _buildWeekdayHeader(
                          context, widget.week, visibleDays, cellWidth),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Scrollbar(
                controller: _gridScrollController,
                thumbVisibility: isDesktop,
                child: SingleChildScrollView(
                  controller: _gridScrollController,
                  physics: scrollPhysics,
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + 12,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(width: 40, child: _TimeColumn()),
                      Expanded(
                        child: SizedBox(
                          width: gridWidth,
                          child: _GridStack(
                            key: ValueKey(
                                '${widget.viewingProfileId}-${widget.week}'),
                            targetWeek: widget.week,
                            visibleDays: visibleDays,
                            cellWidth: cellWidth,
                            items: widget.items,
                            courses: widget.courses,
                            courseColors: widget.courseColors,
                            onEditCell: widget.onEditCell,
                            onShowActions: widget.onShowActions,
                            onShowQuickMenu: widget.onShowQuickMenu,
                            isTeacher: widget.isTeacher,
                            canTakeAttendance: widget.canTakeAttendance,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMonthHeader(BuildContext context, int targetWeek) {
    final loc = Provider.of<LocaleProvider>(context);
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final firstWeekStart = DateTime(now.year, 3, 9);
    final startOfTargetWeek =
        firstWeekStart.add(Duration(days: (targetWeek - 1) * 7));
    final targetMonth = startOfTargetWeek.month;

    return SizedBox(
      height: 64,
      child: Center(
        child: Text(
          loc.locale.languageCode == 'en'
              ? [
                  'Jan',
                  'Feb',
                  'Mar',
                  'Apr',
                  'May',
                  'Jun',
                  'Jul',
                  'Aug',
                  'Sep',
                  'Oct',
                  'Nov',
                  'Dec'
                ][targetMonth - 1]
              : '$targetMonth\n月',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: cs.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildWeekdayHeader(
    BuildContext context,
    int targetWeek,
    List<int> visibleDays,
    double cellWidth,
  ) {
    final loc = Provider.of<LocaleProvider>(context);
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final firstWeekStart = DateTime(now.year, 3, 9);
    final startOfTargetWeek =
        firstWeekStart.add(Duration(days: (targetWeek - 1) * 7));
    final labelFontSize = (cellWidth * 0.22).clamp(10.0, 12.0);
    final dayFontSize = (cellWidth * 0.28).clamp(12.0, 15.0);

    final dayLabels = <int, String>{
      1: loc.t('一', 'Mon'),
      2: loc.t('二', 'Tue'),
      3: loc.t('三', 'Wed'),
      4: loc.t('四', 'Thu'),
      5: loc.t('五', 'Fri'),
      6: loc.t('六', 'Sat'),
      7: loc.t('日', 'Sun'),
    };

    return Row(
      children: List.generate(visibleDays.length, (i) {
        final date = startOfTargetWeek.add(Duration(days: i));
        final isToday = now.year == date.year &&
            now.month == date.month &&
            now.day == date.day;
        final label = dayLabels[visibleDays[i]] ?? '';

        return SizedBox(
          width: cellWidth,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            decoration: BoxDecoration(
              color: isToday ? cs.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: labelFontSize,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    color: isToday ? cs.onPrimary : cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: dayFontSize,
                    fontWeight: FontWeight.bold,
                    color: isToday ? cs.onPrimary : cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _TimeColumn extends StatelessWidget {
  const _TimeColumn();

  static const _periods = <({int period, String start, String end})>[
    (period: 1, start: '08:00', end: '08:45'),
    (period: 2, start: '08:55', end: '09:40'),
    (period: 3, start: '10:10', end: '10:55'),
    (period: 4, start: '11:05', end: '11:50'),
    (period: 5, start: '14:30', end: '15:15'),
    (period: 6, start: '15:25', end: '16:10'),
    (period: 7, start: '16:40', end: '17:25'),
    (period: 8, start: '17:35', end: '18:20'),
    (period: 9, start: '19:00', end: '19:45'),
    (period: 10, start: '19:55', end: '20:30'),
    (period: 11, start: '20:40', end: '21:25'),
    (period: 12, start: '21:35', end: '22:20'),
  ];
  static const int _maxVisiblePeriod = 10;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: _periods.take(_maxVisiblePeriod).map((p) {
        return SizedBox(
          height: 60,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${p.period}',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: cs.onSurface)),
              Text(p.start,
                  style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
              Text(p.end,
                  style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _GridStack extends StatelessWidget {
  final int targetWeek;
  final List<int> visibleDays;
  final double cellWidth;
  final List<TimetableItem> items;
  final Map<String, Course> courses;
  final Map<String, Color> courseColors;
  final Function({int? initialWeekday, int? initialPeriod}) onEditCell;
  final Function(TimetableItem) onShowActions;
  final Function({
    required TapDownDetails details,
    required TimetableItem item,
    required Course course,
  }) onShowQuickMenu;
  final bool isTeacher;
  final bool canTakeAttendance;

  const _GridStack({
    super.key,
    required this.targetWeek,
    required this.visibleDays,
    required this.cellWidth,
    required this.items,
    required this.courses,
    required this.courseColors,
    required this.onEditCell,
    required this.onShowActions,
    required this.onShowQuickMenu,
    required this.isTeacher,
    required this.canTakeAttendance,
  });

  static const int _maxVisiblePeriod = 10;
  static const _expressiveColors = <Color>[
    Color(0xFFE8F5E9),
    Color(0xFFFFF3E0),
    Color(0xFFFCE4EC),
    Color(0xFFF3E5F5),
    Color(0xFFE0F7FA),
    Color(0xFFFFFDE7),
    Color(0xFFE8EAF6),
    Color(0xFFFBE9E7),
    Color(0xFFEFEBE9),
    Color(0xFFF1F8E9),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const double cellHeight = 60;
    final weekItems = items.where((e) => e.isWeekIncluded(targetWeek)).toList();

    return SizedBox(
      width: cellWidth * visibleDays.length,
      height: _maxVisiblePeriod * cellHeight,
      child: Stack(
        children: [
          ...List.generate(visibleDays.length, (i) {
            return Positioned(
              left: i * cellWidth,
              top: 0,
              bottom: 0,
              width: cellWidth,
              child: Container(color: cs.primary.withValues(alpha: 0.05)),
            );
          }),
          ...List.generate(visibleDays.length, (i) {
            return Positioned(
              left: i * cellWidth,
              top: 0,
              bottom: 0,
              width: 1,
              child: Container(color: Colors.grey.withValues(alpha: 0.1)),
            );
          }),
          ...List.generate(_maxVisiblePeriod, (i) {
            return Positioned(
              left: 0,
              right: 0,
              top: i * cellHeight,
              height: 1,
              child: Container(color: Colors.grey.withValues(alpha: 0.1)),
            );
          }),
          ...weekItems.map((item) {
            final course = courses[item.courseId];
            if (course == null) return const SizedBox.shrink();

            final weekdayIndex = visibleDays.indexOf(item.weekday);
            if (weekdayIndex < 0) return const SizedBox.shrink();
            if (item.startPeriod > _maxVisiblePeriod) {
              return const SizedBox.shrink();
            }

            final startPeriodIndex = item.startPeriod - 1;
            final effectiveEndPeriod =
                item.endPeriod.clamp(1, _maxVisiblePeriod);
            final periodSpan = effectiveEndPeriod - item.startPeriod + 1;
            if (periodSpan <= 0) return const SizedBox.shrink();

            final cardColor = courseColors[item.courseId] ??
                _expressiveColors[
                    item.hashCode.abs() % _expressiveColors.length];

            return Positioned(
              left: weekdayIndex * cellWidth,
              top: startPeriodIndex * cellHeight,
              width: cellWidth,
              height: periodSpan * cellHeight,
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: _TimetableCourseBlock(
                  key: ValueKey(item.id),
                  onTapDown: (details) {
                    final enableQuickRollCall =
                        Provider.of<LocaleProvider>(context, listen: false)
                            .enableQuickRollCall;
                    if (canTakeAttendance && enableQuickRollCall) {
                      onShowQuickMenu(
                          details: details, item: item, course: course);
                    } else {
                      onEditCell(
                          initialWeekday: item.weekday,
                          initialPeriod: item.startPeriod);
                    }
                  },
                  onTap: () {},
                  onLongPress: () => onShowActions(item),
                  color: cardColor,
                  radius: 12.0,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.courseName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.black.withValues(alpha: 220),
                            height: 1.5,
                          ),
                          maxLines: 4,
                          overflow: TextOverflow.fade,
                        ),
                        const Spacer(),
                        if (item.location.isNotEmpty)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.location_on_outlined,
                                  size: 10,
                                  color: Colors.black.withValues(alpha: 150)),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  item.location,
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.black.withValues(alpha: 150),
                                    fontWeight: FontWeight.w500,
                                    height: 1.15,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        if (item.weeks.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.weeks,
                                style: TextStyle(
                                  fontSize: 8,
                                  color: Colors.black.withValues(alpha: 120),
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _TimetableCourseBlock extends StatelessWidget {
  final VoidCallback onTap;
  final GestureTapDownCallback? onTapDown;
  final VoidCallback onLongPress;
  final Color color;
  final double radius;
  final Widget child;

  const _TimetableCourseBlock({
    super.key,
    required this.onTap,
    this.onTapDown,
    required this.onLongPress,
    required this.color,
    required this.radius,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Bounceable(
      onTap: onTap,
      onTapDown: onTapDown,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.deferToChild,
      child: Material(
        elevation: 0,
        color: color,
        borderRadius: BorderRadius.circular(radius),
        child: child,
      ),
    );
  }
}
