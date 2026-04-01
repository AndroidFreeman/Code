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
import '../widgets/expressive_ui.dart';

class TimetableController {
  Future<void> Function()? importWakeUp;
  Future<void> Function()? addCourse;
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
  bool _loading = true;
  String _status = '';
  List<TimetableItem> _items = const [];
  Map<String, Course> _courses = const {};
  Map<String, Color> _courseColors = {};

  String _viewingProfileId = '';
  List<String> _teacherClasses = [];
  int _currentWeek = 1;
  bool _showWeekend = true;

  static const _timetableHeader =
      'id,owner_profile_id,weekday,start_period,end_period,start_time,end_time,course_id,location,created_by_profile_id,is_locked,weeks';

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

  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentWeek = _calculateCurrentWeek();
    _viewingProfileId = widget.session.profile.id;
    _pageController = PageController(initialPage: _currentWeek - 1);
    _refresh();
    widget.controller?.importWakeUp = _importWakeupSchedule;
    widget.controller?.addCourse = () => _editCell();
  }

  @override
  void dispose() {
    if (widget.controller?.importWakeUp == _importWakeupSchedule) {
      widget.controller?.importWakeUp = null;
    }
    widget.controller?.addCourse = null;
    _pageController.dispose();
    super.dispose();
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

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _status = '';
    });

    // Ensure data schema is up-to-date
    await _ensureCoursesSchema();
    await _ensureTimetableSchema();

    List<String> teacherClasses = [];
    if (widget.session.isTeacher) {
      teacherClasses = await LocalProfiles.getTeacherClasses(
        widget.session.dataDir,
        widget.session.profile.id,
      );
    }

    Map<String, dynamic> coursesRes;
    if (await widget.session.features.hasFeature('courses_list')) {
      coursesRes = await widget.session.features.listCourses();
    } else {
      final cli = widget.session.cli;
      if (cli == null) {
        final loc = Provider.of<LocaleProvider>(context, listen: false);
        setState(() {
          _loading = false;
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
      setState(() {
        _loading = false;
        _status = msg;
      });
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
      if (cli == null) {
        final loc = Provider.of<LocaleProvider>(context, listen: false);
        setState(() {
          _loading = false;
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
        _loading = false;
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
      _loading = false;
      _teacherClasses = teacherClasses;
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

  String _weekdayLabel(int w, LocaleProvider loc) {
    switch (w) {
      case 1:
        return loc.t('周一', 'Mon');
      case 2:
        return loc.t('周二', 'Tue');
      case 3:
        return loc.t('周三', 'Wed');
      case 4:
        return loc.t('周四', 'Thu');
      case 5:
        return loc.t('周五', 'Fri');
      case 6:
        return loc.t('周六', 'Sat');
      case 7:
        return loc.t('周日', 'Sun');
      default:
        return loc.t('未知', 'Unknown');
    }
  }

  Future<File> _timetableFile() async {
    return File(p.join(widget.session.dataDir, 'timetable.csv'));
  }

  Future<File> _coursesFile() async {
    return File(p.join(widget.session.dataDir, 'courses.csv'));
  }

  Future<void> _ensureCoursesSchema() async {
    final f = await _coursesFile();
    if (!await f.exists()) {
      await f.writeAsString('$_coursesHeader\n', encoding: utf8);
      return;
    }
    final content = await f.readAsString(encoding: utf8);
    final lines = const LineSplitter().convert(content);
    if (lines.isEmpty) {
      await f.writeAsString('$_coursesHeader\n', encoding: utf8);
      return;
    }
    final header = _splitCsvLine(lines.first.trim()).join(',');
    if (header == _coursesHeader) return;

    // Migration: add color, credits, notes
    if (header == 'id,course_name,teacher_profile_id,term_code') {
      final out = <String>[_coursesHeader];
      for (var i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        final parts = _splitCsvLine(line);
        if (parts.length < 4) continue;
        out.add('${parts[0]},${parts[1]},${parts[2]},${parts[3]},,,');
      }
      await f.writeAsString(out.join('\n') + '\n', encoding: utf8);
    }
  }

  Future<String> _createCourseLocal({
    required String courseName,
    required String termCode,
  }) async {
    await _ensureCoursesSchema();
    final f = await _coursesFile();
    final content = await f.readAsString(encoding: utf8);
    final lines = const LineSplitter()
        .convert(content)
        .where((e) => e.trim().isNotEmpty)
        .toList();
    final headers = (lines.isEmpty ? _coursesHeader : lines.first).split(',');
    final rows = await _readCsvRows(f);
    final id = 'c_${DateTime.now().millisecondsSinceEpoch}';
    rows.add({
      'id': id,
      'course_name': courseName.replaceAll(',', ''),
      'teacher_profile_id': widget.session.profile.id,
      'term_code': termCode.replaceAll(',', ''),
    });
    await _writeCsv(f, headers, rows);
    return id;
  }

  Future<void> _ensureTimetableSchema() async {
    final f = await _timetableFile();
    if (!await f.exists()) {
      await f.writeAsString('$_timetableHeader\n', encoding: utf8);
      return;
    }
    final content = await f.readAsString(encoding: utf8);
    final lines = const LineSplitter().convert(content);
    if (lines.isEmpty) {
      await f.writeAsString('$_timetableHeader\n', encoding: utf8);
      return;
    }
    final header = _splitCsvLine(lines.first.trim()).join(',');
    if (header == _timetableHeader) return;

    int startPeriodForStartTime(String start) {
      for (final p in _periods) {
        if (p.start == start) return p.period;
      }
      return 0;
    }

    int endPeriodForEndTime(String end) {
      for (final p in _periods) {
        if (p.end == end) return p.period;
      }
      return 0;
    }

    final out = <String>[_timetableHeader];

    if (header ==
        'id,owner_profile_id,weekday,period,start_time,end_time,course_id,location,created_by_profile_id,is_locked,weeks') {
      for (var i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        final parts = _splitCsvLine(line);
        if (parts.length < 11) continue;
        final p = parts[3];
        out.add([
          parts[0],
          parts[1],
          parts[2],
          p,
          p,
          parts[4],
          parts[5],
          parts[6],
          parts[7],
          parts[8],
          parts[9],
          parts[10]
        ].join(','));
      }
      await f.writeAsString(out.join('\n') + '\n', encoding: utf8);
      return;
    }

    if (header ==
        'id,owner_profile_id,weekday,period,start_time,end_time,course_id,location,created_by_profile_id,is_locked') {
      for (var i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        final parts = _splitCsvLine(line);
        if (parts.length < 10) continue;
        final p = parts[3];
        out.add([
          parts[0],
          parts[1],
          parts[2],
          p,
          p,
          parts[4],
          parts[5],
          parts[6],
          parts[7],
          parts[8],
          parts[9],
          '1-20',
        ].join(','));
      }
      await f.writeAsString(out.join('\n') + '\n', encoding: utf8);
      return;
    }

    if (header ==
        'id,owner_profile_id,weekday,start_time,end_time,course_id,location') {
      for (var i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        final parts = _splitCsvLine(line);
        if (parts.length >= 12) {
          out.add(parts.take(12).join(','));
          continue;
        }
        if (parts.length < 7) continue;
        final start = parts[3];
        final end = parts[4];
        var sp = startPeriodForStartTime(start);
        var ep = endPeriodForEndTime(end);
        if (sp <= 0 && ep <= 0) {
          final p = _findPeriodForTimes(start, end);
          if (p > 0) {
            sp = p;
            ep = p;
          }
        }
        if (sp <= 0) sp = 1;
        if (ep <= 0) ep = sp;
        out.add([
          parts[0],
          parts[1],
          parts[2],
          sp.toString(),
          ep.toString(),
          start,
          end,
          parts[5],
          parts[6],
          '',
          'false',
          '1-20',
        ].join(','));
      }
      await f.writeAsString(out.join('\n') + '\n', encoding: utf8);
      return;
    }
  }

  List<String> _splitCsvLine(String line) {
    final res = <String>[];
    var current = StringBuffer();
    var inQuotes = false;
    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        res.add(current.toString().trim());
        current = StringBuffer();
      } else {
        current.write(char);
      }
    }
    res.add(current.toString().trim());
    if (res.isNotEmpty && res.first.startsWith('\uFEFF')) {
      res[0] = res.first.replaceFirst('\uFEFF', '');
    }
    return res;
  }

  Future<List<Map<String, String>>> _readCsvRows(File f) async {
    final content = await f.readAsString(encoding: utf8);
    final lines = const LineSplitter()
        .convert(content)
        .where((e) => e.trim().isNotEmpty)
        .toList();
    if (lines.isEmpty) return const [];
    final headers = _splitCsvLine(lines.first);
    final rows = <Map<String, String>>[];
    for (var i = 1; i < lines.length; i++) {
      final parts = _splitCsvLine(lines[i]);
      final row = <String, String>{};
      for (var j = 0; j < headers.length && j < parts.length; j++) {
        row[headers[j]] = parts[j];
      }
      rows.add(row);
    }
    return rows;
  }

  Future<void> _writeCsv(
    File f,
    List<String> headers,
    List<Map<String, String>> rows,
  ) async {
    final out = <String>[headers.join(',')];
    for (final r in rows) {
      out.add(headers.map((h) => (r[h] ?? '').replaceAll(',', '')).join(','));
    }
    await f.writeAsString(out.join('\n') + '\n', encoding: utf8);
  }

  Future<List<String>> _studentProfileIds({String? classCode}) async {
    final pf = File(p.join(widget.session.dataDir, 'profiles.csv'));
    if (!await pf.exists()) return const [];
    final rows = await _readCsvRows(pf);
    final ids = <String>[];
    for (final r in rows) {
      final cls = (r['class_code'] ?? '').trim();
      if (classCode != null &&
          classCode.trim().isNotEmpty &&
          cls != classCode.trim()) continue;
      final role = (r['role'] ?? '').trim();
      if (role != 'student' && role != 'cadre') continue;
      final id = (r['id'] ?? '').trim();
      if (id.isNotEmpty) ids.add(id);
    }
    return ids;
  }

  Future<void> _upsertTimetable({
    required String ownerProfileId,
    required int weekday,
    required int startPeriod,
    required int endPeriod,
    required String courseId,
    required String location,
    required String createdByProfileId,
    required bool isLocked,
    required String weeks,
  }) async {
    await _ensureTimetableSchema();
    final f = await _timetableFile();
    final content = await f.readAsString(encoding: utf8);
    final lines = const LineSplitter()
        .convert(content)
        .where((e) => e.trim().isNotEmpty)
        .toList();
    if (lines.isEmpty) {
      await f.writeAsString('$_timetableHeader\n', encoding: utf8);
    }
    final headers = (lines.isEmpty ? _timetableHeader : lines.first).split(',');
    final rows = await _readCsvRows(f);

    final idx = rows.indexWhere((r) {
      if ((r['owner_profile_id'] ?? '') != ownerProfileId) return false;
      if (int.tryParse((r['weekday'] ?? '').toString()) != weekday)
        return false;
      if (int.tryParse((r['start_period'] ?? '').toString()) != startPeriod)
        return false;
      return true;
    });

    if (idx >= 0) {
      final lockedRaw = (rows[idx]['is_locked'] ?? '').toLowerCase();
      final locked =
          lockedRaw == 'true' || lockedRaw == '1' || lockedRaw == 'yes';
      if (locked) {
        final loc = Provider.of<LocaleProvider>(context, listen: false);
        throw loc.t('该课表由老师添加，学生不可更改',
            'This schedule was added by a teacher and cannot be modified by students');
      }
      rows.removeAt(idx);
    }

    final sp = _periods.firstWhere((e) => e.period == startPeriod);
    final ep = _periods.firstWhere((e) => e.period == endPeriod);
    final id = 'tt_${DateTime.now().millisecondsSinceEpoch}';
    final row = <String, String>{
      'id': id,
      'owner_profile_id': ownerProfileId,
      'weekday': weekday.toString(),
      'start_period': startPeriod.toString(),
      'end_period': endPeriod.toString(),
      'start_time': sp.start,
      'end_time': ep.end,
      'course_id': courseId,
      'location': location,
      'created_by_profile_id': createdByProfileId,
      'is_locked': isLocked ? 'true' : 'false',
      'weeks': weeks,
    };
    rows.add(row);
    await _writeCsv(f, headers, rows);
  }

  Future<void> _deleteTimetable({
    required String ownerProfileId,
    required int weekday,
    required int startPeriod,
    bool allowLocked = false,
    String? createdByProfileId,
  }) async {
    await _ensureTimetableSchema();
    final f = await _timetableFile();
    final content = await f.readAsString(encoding: utf8);
    final lines = const LineSplitter()
        .convert(content)
        .where((e) => e.trim().isNotEmpty)
        .toList();
    if (lines.isEmpty) return;
    final headers = lines.first.split(',');
    final rows = await _readCsvRows(f);
    bool isMatch(Map<String, String> r) {
      if ((r['owner_profile_id'] ?? '') != ownerProfileId) return false;
      if (int.tryParse((r['weekday'] ?? '').toString()) != weekday)
        return false;
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
        final loc = Provider.of<LocaleProvider>(context, listen: false);
        throw loc.t('该课表由老师添加，学生不可更改',
            'This schedule was added by a teacher and cannot be modified by students');
      }
    }

    rows.removeWhere(isMatch);
    await _writeCsv(f, headers, rows);
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(loc.t(
                  '无权限删除该课表项', 'No permission to delete this schedule item'))),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(loc.t('已删除课表项', 'Schedule item deleted'))),
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

    try {
      final loc = Provider.of<LocaleProvider>(context, listen: false);
      await _ensureCoursesSchema();
      await _ensureTimetableSchema();

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
        final cf = await _coursesFile();
        final rows = await _readCsvRows(cf);
        final idx = rows.indexWhere((r) => r['id'] == cid);
        if (idx >= 0) {
          rows[idx]['course_name'] = courseName;
          rows[idx]['credits'] = credits;
          rows[idx]['notes'] = notes;
          rows[idx]['color'] = color;
          await _writeCsv(cf, _coursesHeader.split(','), rows);
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
            : loc.t('我的课表', 'My Timetable');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.t('成功添加课程到：$target', 'Course added to: $target')),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Map<int, Map<int, TimetableItem>> get _cellItems {
    final byDay = <int, Map<int, TimetableItem>>{};
    for (final item in _items) {
      if (!item.isWeekIncluded(_currentWeek)) continue;
      final day = item.weekday;
      var period = item.period;
      if (period <= 0)
        period = _findPeriodForTimes(item.startTime, item.endTime);
      if (period <= 0) continue;
      byDay.putIfAbsent(day, () => {})[period] = item;
    }
    return byDay;
  }

  Future<void> _importWakeupSchedule() async {
    try {
      final loc = Provider.of<LocaleProvider>(context, listen: false);
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['wakeup_schedule', 'json', 'txt'],
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;
      final path = result.files.first.path;
      if (path == null) return;

      final content = await File(path).readAsString();

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

      final coursesJson = jsonDecode(blocks[3]) as List;
      final itemsJson = jsonDecode(blocks[4]) as List;

      setState(() {
        _loading = true;
        _status = loc.t('正在导入...', 'Importing...');
      });

      await _ensureCoursesSchema();
      await _ensureTimetableSchema();

      final owner = widget.session.profile.id;
      final base = DateTime.now().microsecondsSinceEpoch;
      var seq = 0;
      String nextTtId() => 'tt_${base}_${seq++}';

      // Keep track of mapping from old course ID to new course ID
      final courseIdMap = <int, String>{};

      // Import Courses
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.t('导入成功', 'Import succeeded'))),
        );
      }
    } catch (e) {
      if (mounted) {
        final loc = Provider.of<LocaleProvider>(context, listen: false);
        setState(() {
          _loading = false;
          _status = loc.t('导入失败: $e', 'Import failed: $e');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocaleProvider>(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              ScaffoldState? scaffold = Scaffold.maybeOf(context);
              if (scaffold != null && !scaffold.hasDrawer) {
                scaffold =
                    scaffold.context.findAncestorStateOfType<ScaffoldState>();
              }
              scaffold?.openDrawer();
            },
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              loc.t('我的课表', 'My Timetable'),
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              loc.t(
                  '${DateTime.now().year}年${DateTime.now().month}月${DateTime.now().day}日',
                  '${DateTime.now().month}/${DateTime.now().day}/${DateTime.now().year}'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          if (Platform.isWindows || Platform.isLinux || Platform.isMacOS)
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
          if (widget.session.isTeacher && _teacherClasses.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Center(
                child: ExpressiveSelector(
                  label: loc.t('班级', 'Class'),
                  value: _viewingProfileId == widget.session.profile.id
                      ? loc.t('我的课表', 'My Timetable')
                      : _viewingProfileId.replaceFirst('class_', ''),
                  items: [
                    loc.t('我的课表', 'My Timetable'),
                    ..._teacherClasses,
                  ],
                  backgroundColor:
                      Theme.of(context).colorScheme.tertiaryContainer,
                  foregroundColor:
                      Theme.of(context).colorScheme.onTertiaryContainer,
                  onSelected: (v) {
                    final target = v == loc.t('我的课表', 'My Timetable')
                        ? widget.session.profile.id
                        : 'class_$v';
                    if (target != _viewingProfileId) {
                      setState(() {
                        _viewingProfileId = target;
                      });
                      _refresh();
                    }
                  },
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
                  child: Text(
                    _showWeekend
                        ? loc.t('7日', '7 Days')
                        : loc.t('5日', '5 Days'),
                    key: ValueKey(_showWeekend),
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
        elevation: 2,
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                onPageChanged: (index) {
                  setState(() {
                    _currentWeek = index + 1;
                  });
                },
                itemCount: 20,
                itemBuilder: (context, index) {
                  final week = index + 1;
                  final visibleDays = _showWeekend
                      ? const [1, 2, 3, 4, 5, 6, 7]
                      : const [1, 2, 3, 4, 5];
                  const headerHeight = 64.0;

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final gridWidth = (constraints.maxWidth - 40)
                          .clamp(0.0, double.infinity);
                      final cellWidth = gridWidth / visibleDays.length;

                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.03),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: Column(
                          key: ValueKey(_showWeekend),
                          children: [
                            SizedBox(
                              height: headerHeight,
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 40,
                                    child: _buildMonthHeader(targetWeek: week),
                                  ),
                                  Expanded(
                                    child: SizedBox(
                                      width: gridWidth,
                                      child: _buildWeekdayHeader(
                                        targetWeek: week,
                                        visibleDays: visibleDays,
                                        cellWidth: cellWidth,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                        width: 40, child: _buildTimeColumn()),
                                    Expanded(
                                      child: SizedBox(
                                        width: gridWidth,
                                        child: AnimatedSwitcher(
                                          duration:
                                              const Duration(milliseconds: 300),
                                          child: _buildGridStack(
                                            key: ValueKey(
                                                '$_viewingProfileId-$week'),
                                            targetWeek: week,
                                            visibleDays: visibleDays,
                                            cellWidth: cellWidth,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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
    setState(() {
      _currentWeek = w;
    });
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

    return GestureDetector(
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
          child: AnimatedSwitcher(
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
              loc.t('第 $_currentWeek 周', 'Week $_currentWeek'),
              key: ValueKey(_currentWeek),
              style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthHeader({required int targetWeek}) {
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
              ? '${[
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
                ][targetMonth - 1]}'
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

  Widget _buildWeekdayHeader({
    required int targetWeek,
    required List<int> visibleDays,
    required double cellWidth,
  }) {
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
              boxShadow: isToday
                  ? [
                      BoxShadow(
                        color: cs.primary.withValues(alpha: 12),
                        blurRadius: 4,
                        offset: const Offset(0, 1.5),
                      )
                    ]
                  : null,
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
        children: _periods.map((p) {
          return Container(
            height: 100, // Height per period
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
    const double cellHeight = 100;
    final cardRadius = (cellWidth * 0.18).clamp(10.0, 14.0);
    final now = DateTime.now();
    final firstWeekStart = DateTime(now.year, 3, 9);
    final startOfTargetWeek =
        firstWeekStart.add(Duration(days: (targetWeek - 1) * 7));

    return SizedBox(
      key: key,
      width: cellWidth * visibleDays.length,
      height: _periods.length * cellHeight,
      child: Stack(
        children: [
          ...List.generate(visibleDays.length, (i) {
            final date = startOfTargetWeek.add(Duration(days: i));
            final isToday = now.year == date.year &&
                now.month == date.month &&
                now.day == date.day;
            if (!isToday) return const SizedBox.shrink();

            return Positioned(
              left: i * cellWidth,
              top: 0,
              bottom: 0,
              width: cellWidth,
              child: Container(
                color: cs.primary.withOpacity(0.05),
              ),
            );
          }),
          ...List.generate(visibleDays.length, (i) {
            return Positioned(
              left: i * cellWidth,
              top: 0,
              bottom: 0,
              width: 1,
              child: Container(color: Colors.grey.withOpacity(0.1)),
            );
          }),
          ...List.generate(_periods.length, (i) {
            return Positioned(
              left: 0,
              right: 0,
              top: i * cellHeight,
              height: 1,
              child: Container(color: Colors.grey.withOpacity(0.1)),
            );
          }),
          ..._items.where((e) => e.isWeekIncluded(targetWeek)).map((item) {
            final course = _courses[item.courseId];
            if (course == null) return const SizedBox.shrink();

            final weekdayIndex = visibleDays.indexOf(item.weekday);
            if (weekdayIndex < 0) return const SizedBox.shrink();
            final startPeriodIndex = item.startPeriod - 1;
            final periodSpan = item.endPeriod - item.startPeriod + 1;

            // Ignore explicitColor locally to force new expressiveColors theme, since user complained about old colors being stuck.
            // (If user manually sets color via UI later, it will still save to CSV, but we override it here for now to ensure the new palette is seen).
            final baseCardColor = _courseColors[item.courseId] ??
                _expressiveColors[
                    item.courseId.hashCode.abs() % _expressiveColors.length];
            final cardColor = baseCardColor;
            final cardRadius = 12.0;

            return Positioned(
              left: weekdayIndex * cellWidth,
              top: startPeriodIndex * cellHeight,
              width: cellWidth,
              height: periodSpan * cellHeight,
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.elasticOut,
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Transform.rotate(
                        angle: (1.0 - value) * 0.1,
                        child: child,
                      ),
                    );
                  },
                  child: Bounceable(
                    onTap: () => _editCell(
                      initialWeekday: item.weekday,
                      initialPeriod: item.startPeriod,
                    ),
                    onLongPress: () => _showTimetableItemActions(item),
                    behavior: HitTestBehavior.deferToChild,
                    child: Material(
                      elevation: 0,
                      color: cardColor,
                      borderRadius: BorderRadius.circular(cardRadius),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 6),
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
                                        color:
                                            Colors.black.withValues(alpha: 150),
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
                                    color: Colors.black.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    item.weeks,
                                    style: TextStyle(
                                        fontSize: 8,
                                        color: Colors.black.withOpacity(0.6),
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
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// Dashed border painter
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;

  _DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.radius = 12.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );

    final Path path = Path()..addRRect(rrect);
    final Path dashPath = _dashPath(path, dashArray: [4, 4]);
    canvas.drawPath(dashPath, paint);
  }

  Path _dashPath(Path source, {required List<double> dashArray}) {
    final Path dest = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0.0;
      bool draw = true;
      int dashIndex = 0;
      while (distance < metric.length) {
        final double len = dashArray[dashIndex % dashArray.length];
        if (draw) {
          dest.addPath(
            metric.extractPath(distance, distance + len),
            Offset.zero,
          );
        }
        distance += len;
        draw = !draw;
        dashIndex++;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.radius != radius;
  }
}
