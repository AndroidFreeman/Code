import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import '../models/student.dart';
import '../main.dart';
import '../services/local_profiles.dart';
import '../services/api_config.dart';
import '../state/session.dart';
import '../widgets/expressive_ui.dart';
import 'student_detail_page.dart';
import 'attendance_page.dart';

class ClassAttendanceOverviewPage extends StatefulWidget {
  final Session session;
  final VoidCallback? onReady;

  const ClassAttendanceOverviewPage(
      {super.key, required this.session, this.onReady});

  @override
  State<ClassAttendanceOverviewPage> createState() =>
      _ClassAttendanceOverviewPageState();
}

class _Row {
  final Student student;
  final int present;
  final int late;
  final int absent;
  final int leave;

  const _Row(
      {required this.student,
      required this.present,
      required this.late,
      required this.absent,
      required this.leave});
}

class _ClassAttendanceOverviewPageState
    extends State<ClassAttendanceOverviewPage> {
  bool _loading = true;
  bool _dataReady = true;
  String _status = '';
  List<String> _myClasses = [];
  List<Map<String, String>> _myClassesWithNames = [];
  String _selectedClass = '';
  String _selectedRange = 'day';
  List<_Row> _rows = [];
  List<Map<String, String>> _allSessions = [];
  List<Map<String, String>> _allRecords = [];
  List<Map<String, dynamic>> _allCourses = [];
  List<Map<String, dynamic>> _allTimetable = [];
  Map<String, String> _classNameByCode = {};
  StreamSubscription? _dataChangeSub;

  int _totalSessionsInRange = 0;

  int get totalPresent => _rows.fold(0, (sum, r) => sum + r.present);
  int get totalLate => _rows.fold(0, (sum, r) => sum + r.late);
  int get totalAbsent => _rows.fold(0, (sum, r) => sum + r.absent);
  int get totalLeave => _rows.fold(0, (sum, r) => sum + r.leave);

  @override
  void initState() {
    super.initState();
    widget.session.addListener(_onSessionChanged);
    _dataChangeSub = widget.session.watchDataChanges(
        {'attendance', 'students', 'classes', 'courses'}).listen((_) {
      if (mounted) {
        _refresh(isBackground: true);
      }
    });
    _refresh();
  }

  @override
  void dispose() {
    widget.session.removeListener(_onSessionChanged);
    _dataChangeSub?.cancel();
    super.dispose();
  }

  void _onSessionChanged() {
    if (mounted) {
      _refresh(isBackground: true);
    }
  }

  Future<List<Map<String, String>>> _readCsvRows(String filename) async {
    if (ApiConfig.instance.useCloud) {
      String path = '';
      if (filename == 'attendance_sessions.csv') {
        path = '/api/attendance/sessions';
      } else if (filename == 'attendance_records.csv') {
        path = '/api/attendance/records';
      }

      if (path.isNotEmpty) {
        final res = await ApiConfig.instance.get(path);
        if (res['ok'] == true) {
          final rawData = res['data'];
          final items = (rawData is List)
              ? rawData
              : ((rawData as Map?)?['items'] as List? ?? []);
          return items
              .map((e) => (e as Map)
                  .map((k, v) => MapEntry(k.toString(), v?.toString() ?? '')))
              .toList();
        }
      }
      return [];
    }

    final res =
        await widget.session.features.csvOp(action: 'read', file: filename);
    if (res['ok'] != true) return [];
    final items = ((res['data'] ?? const {})['items'] as List?) ?? const [];
    return items.map((e) => (e as Map).cast<String, String>()).toList();
  }

  Future<List<Student>> _loadStudents() async {
    try {
      final res = await widget.session.features.listStudents();
      if (res['ok'] == true) {
        final rawData = res['data'];
        final items = (rawData is List)
            ? rawData
            : ((rawData as Map?)?['items'] as List? ?? []);

        final uniqueStudents = <String, Student>{};
        for (final e in items) {
          final map = e is Map ? e : (e as Map<String, dynamic>);
          try {
            final s = Student.fromJson(Map<String, dynamic>.from(map));
            final key = s.studentNo.trim().toLowerCase();
            if (key.isNotEmpty) {
              if (uniqueStudents.containsKey(key)) {
                if (s.position.isNotEmpty &&
                    uniqueStudents[key]!.position.isEmpty) {
                  uniqueStudents[key] = s;
                }
              } else {
                uniqueStudents[key] = s;
              }
            } else {
              uniqueStudents[s.id] = s;
            }
          } catch (_) {}
        }
        return uniqueStudents.values.toList();
      }
    } catch (e) {
      debugPrint('Error loading students in overview: $e');
    }
    return const [];
  }

  DateTime? _parseFlexibleDateTime(String s) {
    s = s.trim();
    if (s.isEmpty) return null;
    try {
      return DateTime.parse(s).toLocal();
    } catch (_) {
      try {
        final parts = s.split('T');
        if (parts.length == 2) {
          final dateParts = parts[0].split('-');
          final timeParts = parts[1].split(':');
          if (dateParts.length == 3 && timeParts.length >= 2) {
            return DateTime(
              int.parse(dateParts[0]),
              int.parse(dateParts[1]),
              int.parse(dateParts[2]),
              int.parse(timeParts[0]),
              int.parse(timeParts[1]),
            );
          }
        }
      } catch (_) {}
    }
    return null;
  }

  bool _isInRange(DateTime dt, String range) {
    final now = DateTime.now();
    if (range == 'day') {
      return dt.year == now.year && dt.month == now.month && dt.day == now.day;
    } else if (range == 'week') {
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfRange =
          DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      return dt.isAfter(startOfRange.subtract(const Duration(seconds: 1)));
    } else if (range == 'month') {
      return dt.year == now.year && dt.month == now.month;
    } else if (range == 'term') {
      final month = now.month;
      final year = now.year;
      DateTime startOfTerm;
      if (month >= 8) {
        startOfTerm = DateTime(year, 8, 1);
      } else if (month >= 2) {
        startOfTerm = DateTime(year, 2, 1);
      } else {
        startOfTerm = DateTime(year - 1, 8, 1);
      }
      return dt.isAfter(startOfTerm.subtract(const Duration(seconds: 1)));
    }
    return false;
  }

  String _resolveClassId(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return '';
    if (_classNameByCode.containsKey(value)) return value;
    for (final entry in _classNameByCode.entries) {
      if (entry.value == value) return entry.key;
    }
    final upperValue = value.toUpperCase();
    for (final id in _classNameByCode.keys) {
      if (id.toUpperCase() == upperValue) return id;
    }
    for (final entry in _classNameByCode.entries) {
      if (entry.value.toUpperCase() == upperValue) return entry.key;
    }
    return value;
  }

  Future<void> _refresh(
      {bool isBackground = false, bool forceNetwork = false}) async {
    if (widget.onReady != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onReady?.call();
      });
    }

    if (!widget.session.canViewStudents) {
      final loc = Provider.of<LocaleProvider>(context, listen: false);
      setState(() {
        _loading = false;
        _dataReady = true;
        _status = loc.t('当前角色无查看班级考勤权限',
            'Your role does not have permission to view class attendance');
      });
      return;
    }

    if (!isBackground && _rows.isEmpty) {
      setState(() {
        _loading = true;
        _status = '';
      });
    }

    try {
      final allClassesMapList =
          await LocalProfiles.getAllClassesWithNames(widget.session.dataDir);

      if (allClassesMapList.isEmpty && ApiConfig.instance.useCloud) {
        try {
          final retryRes = await ApiConfig.instance.get('/api/classes');
          if (retryRes['ok'] == true && retryRes['data'] != null) {
            final raw = retryRes['data'];
            final items = (raw is List)
                ? raw
                : (raw is Map ? (raw['items'] as List? ?? []) : []);
            for (final item in items) {
              if (item is Map) {
                final classId =
                    (item['id'] ?? item['classCode'] ?? '').toString().trim();
                final className = (item['className'] ??
                        item['class_name'] ??
                        item['name'] ??
                        classId)
                    .toString()
                    .trim();
                if (classId.isNotEmpty) {
                  allClassesMapList.add({'id': classId, 'name': className});
                }
              }
            }
          }
        } catch (_) {}
      }

      _classNameByCode = {
        for (final row in allClassesMapList)
          if ((row['id'] ?? '').trim().isNotEmpty)
            row['id']!.trim(): row['name']?.trim() ?? row['id']!.trim()
      };

      final profileClasses = await LocalProfiles.getTeacherClasses(
        widget.session.dataDir,
        widget.session.profile.id,
      );

      final ttRes = await widget.session.features.listTimetable();
      final coursesRes = await widget.session.features.listCourses();

      List<Map<String, dynamic>> timetable = [];
      if (ttRes['ok'] == true) {
        final data = ttRes['data'];
        final items = (data is List) ? data : (data['items'] as List? ?? []);
        timetable = List<Map<String, dynamic>>.from(items);
      }

      List<Map<String, dynamic>> courses = [];
      if (coursesRes['ok'] == true) {
        final data = coursesRes['data'];
        final items = (data is List) ? data : (data['items'] as List? ?? []);
        courses = List<Map<String, dynamic>>.from(items);
      }

      final derivedClasses = <String>{};
      if (widget.session.isTeacher) {
        for (final item in timetable) {
          final owner =
              (item['owner_profile_id'] ?? item['ownerProfileId'] ?? '')
                  .toString()
                  .trim();
          if (!owner.startsWith('class_')) continue;
          final classId = owner.replaceFirst('class_', '').trim();
          if (classId.isEmpty) continue;

          if ((item['created_by_profile_id'] ??
                  item['createdByProfileId'] ??
                  '') ==
              widget.session.profile.id) {
            derivedClasses.add(_resolveClassId(classId));
            continue;
          }
          final courseId =
              (item['course_id'] ?? item['courseId'] ?? '').toString();
          final course = courses.where((c) => c['id'] == courseId).firstOrNull;
          if ((course?['teacher_profile_id'] ??
                  course?['teacherProfileId'] ??
                  '') ==
              widget.session.profile.id) {
            derivedClasses.add(_resolveClassId(classId));
          }
        }
      }

      final classes = <String>{
        ...profileClasses.map(_resolveClassId),
        ...derivedClasses
      }.where((e) => e.isNotEmpty).toList()
        ..sort();

      final myClassesWithNames =
          allClassesMapList.where((e) => classes.contains(e['id'])).toList();

      var sel = _selectedClass;
      if (sel.isEmpty || !classes.contains(sel)) {
        sel = classes.isNotEmpty ? classes.first : '';
      }

      final students = await _loadStudents();
      final resolvedSel = _resolveClassId(sel);
      final filtered = sel.isEmpty
          ? <Student>[]
          : students
              .where((s) => _resolveClassId(s.classCode) == resolvedSel)
              .toList(growable: false);

      final sessions = await _readCsvRows('attendance_sessions.csv');
      final records = await _readCsvRows('attendance_records.csv');

      final sessionToCourse = <String, String>{};
      int sessionsInRange = 0;
      for (final s in sessions) {
        final dt = _parseFlexibleDateTime(s['started_at'] ?? '');
        if (dt != null && _isInRange(dt, _selectedRange)) {
          final courseId = (s['course_id'] ?? '').trim();
          final belongsToClass = timetable.any((item) {
            final owner =
                (item['owner_profile_id'] ?? item['ownerProfileId'] ?? '')
                    .toString()
                    .trim();
            return owner == 'class_$resolvedSel' &&
                (item['course_id'] ?? item['courseId'] ?? '') == courseId;
          });

          if (belongsToClass) {
            final sId = (s['id'] ?? '').trim();
            sessionToCourse[sId] = courseId;
            sessionsInRange++;
          }
        }
      }

      final counts = <String, Map<String, int>>{};
      final processedRecords = <String>{};

      for (final r in records) {
        final sessionId = (r['session_id'] ?? '').trim();
        final studentId = (r['student_id'] ?? '').trim();
        final st = (r['status'] ?? '').trim();

        if (sessionId.isNotEmpty &&
            studentId.isNotEmpty &&
            sessionToCourse.containsKey(sessionId)) {
          final recordKey = '$sessionId-$studentId';
          if (processedRecords.contains(recordKey)) continue;
          processedRecords.add(recordKey);

          final m = counts.putIfAbsent(studentId,
              () => {'present': 0, 'late': 0, 'absent': 0, 'leave': 0});
          if (st == 'present' ||
              st == 'late' ||
              st == 'absent' ||
              st == 'leave') {
            m[st] = (m[st] ?? 0) + 1;
          }
        }
      }

      final rows = filtered.map((s) {
        final m =
            counts[s.id] ?? {'present': 0, 'late': 0, 'absent': 0, 'leave': 0};
        return _Row(
          student: s.copyWith(
            className: _classNameByCode[s.classCode.trim()] ?? s.className,
          ),
          present: m['present'] ?? 0,
          late: m['late'] ?? 0,
          absent: m['absent'] ?? 0,
          leave: m['leave'] ?? 0,
        );
      }).toList(growable: false);
      rows.sort((a, b) => a.student.studentNo.compareTo(b.student.studentNo));

      if (!mounted) return;
      setState(() {
        _loading = false;
        _dataReady = true;
        _myClassesWithNames = myClassesWithNames;
        _myClasses = classes;
        _selectedClass = sel;
        _rows = rows;
        _allSessions = sessions;
        _allRecords = records;
        _allCourses = courses;
        _allTimetable = timetable;
        _totalSessionsInRange = sessionsInRange;
      });
      widget.onReady?.call();
    } catch (e, stack) {
      debugPrint('ClassAttendanceOverviewPage Error: $e\n$stack');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _dataReady = true;
        _status = e.toString();
      });
      widget.onReady?.call();
    }
  }

  void _showStatusStudents(
      BuildContext context, String statusKey, String statusLabel) {
    final loc = Provider.of<LocaleProvider>(context, listen: false);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final resolvedSel = _resolveClassId(_selectedClass);
    final sessionToCourse = <String, String>{};
    for (final s in _allSessions) {
      final dt = _parseFlexibleDateTime(s['started_at'] ?? '');
      if (dt != null && _isInRange(dt, _selectedRange)) {
        final courseId = (s['course_id'] ?? '').trim();
        final belongsToClass = _allTimetable.any((item) {
          final owner =
              (item['owner_profile_id'] ?? item['ownerProfileId'] ?? '')
                  .toString()
                  .trim();
          return owner == 'class_$resolvedSel' &&
              (item['course_id'] ?? item['courseId'] ?? '') == courseId;
        });
        if (belongsToClass) {
          sessionToCourse[(s['id'] ?? '').trim()] = courseId;
        }
      }
    }

    final latestRecords = <String, Map<String, String>>{};
    for (final r in _allRecords) {
      final sessionId = (r['session_id'] ?? '').trim();
      final studentId = (r['student_id'] ?? '').trim();
      if (sessionId.isNotEmpty &&
          studentId.isNotEmpty &&
          sessionToCourse.containsKey(sessionId)) {
        latestRecords['$sessionId-$studentId'] = r;
      }
    }

    final validStudentIds = _rows.map((r) => r.student.id).toSet();
    final statusRecords = latestRecords.values.where((r) {
      return (r['status'] ?? '').trim() == statusKey &&
          validStudentIds.contains((r['student_id'] ?? '').trim());
    }).toList();

    final studentRecords = <String, List<Map<String, String>>>{};
    for (final r in statusRecords) {
      final sid = (r['student_id'] ?? '').trim();
      studentRecords.putIfAbsent(sid, () => []).add(r);
    }

    if (studentRecords.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(loc.t(
                '没有$statusLabel的学生', 'No students with $statusLabel status'))),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('$statusLabel ${loc.t('名单', 'List')}',
                      style: tt.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: studentRecords.length,
                    itemBuilder: (context, index) {
                      final sid = studentRecords.keys.elementAt(index);
                      final records = studentRecords[sid]!;
                      final studentRow =
                          _rows.firstWhere((r) => r.student.id == sid);

                      return Theme(
                        data: Theme.of(context)
                            .copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          title: Text(studentRow.student.fullName,
                              style: tt.titleMedium),
                          subtitle: Text(
                              '${records.length} ${loc.t('次', 'times')}',
                              style: tt.bodySmall
                                  ?.copyWith(color: cs.onSurfaceVariant)),
                          children: records.map((r) {
                            final sessionId = r['session_id'] ?? '';
                            final session = _allSessions.firstWhere(
                                (s) => s['id'] == sessionId,
                                orElse: () => {});
                            if (session.isEmpty) return const SizedBox.shrink();

                            final course = _allCourses
                                .where((c) => c['id'] == session['course_id'])
                                .firstOrNull;
                            final cName = course?['course_name'] ??
                                session['course_id'] ??
                                loc.t('未知课程', 'Unknown Course');

                            String date = '';
                            String time = '';
                            try {
                              final dt = DateTime.parse(session['started_at']!)
                                  .toLocal();
                              date =
                                  '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
                              time =
                                  '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                            } catch (_) {
                              date =
                                  session['started_at']?.split('T').first ?? '';
                              time = session['started_at']
                                      ?.split('T')
                                      .last
                                      .substring(0, 5) ??
                                  '';
                            }

                            return ListTile(
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 32),
                              leading: Icon(Icons.access_time,
                                  size: 16, color: cs.outline),
                              title: Text('$cName-$date', style: tt.bodyMedium),
                              subtitle: Text(time, style: tt.bodySmall),
                              trailing:
                                  const Icon(Icons.chevron_right, size: 16),
                              onTap: () {
                                Navigator.pop(ctx);
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (ctx2) => AttendancePage(
                                        session: widget.session,
                                        courseId: session['course_id'],
                                        isStandalone: true,
                                      ),
                                    ));
                              },
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  bool _sessionBelongsToSelectedClass(Map<String, String> session) {
    final resolvedSel = _resolveClassId(_selectedClass);
    if (resolvedSel.isEmpty) return false;
    final courseId = (session['course_id'] ?? '').trim();
    return _allTimetable.any((item) {
      final owner = (item['owner_profile_id'] ?? item['ownerProfileId'] ?? '')
          .toString()
          .trim();
      return owner == 'class_$resolvedSel' &&
          (item['course_id'] ?? item['courseId'] ?? '') == courseId;
    });
  }

  List<Map<String, String>> _sessionsForCurrentClass({bool todayOnly = false}) {
    final now = DateTime.now();
    bool isToday(DateTime dt) =>
        dt.year == now.year && dt.month == now.month && dt.day == now.day;

    final sessions = _allSessions.where((session) {
      if (!_sessionBelongsToSelectedClass(session)) return false;
      final dt = _parseFlexibleDateTime(session['started_at'] ?? '');
      if (dt == null) return false;
      if (todayOnly) return isToday(dt);
      return _isInRange(dt, _selectedRange);
    }).toList();

    sessions.sort((a, b) {
      final ad = _parseFlexibleDateTime(a['started_at'] ?? '');
      final bd = _parseFlexibleDateTime(b['started_at'] ?? '');
      if (ad == null && bd == null) return 0;
      if (ad == null) return 1;
      if (bd == null) return -1;
      return bd.compareTo(ad);
    });
    return sessions;
  }

  String _displayClassName(String classCode) {
    final resolved = _resolveClassId(classCode);
    return _classNameByCode[resolved]?.trim().isNotEmpty == true
        ? _classNameByCode[resolved]!.trim()
        : resolved;
  }

  String _courseName(String courseId, LocaleProvider loc) {
    final course = _allCourses.where((c) => c['id'] == courseId).firstOrNull;
    return (course?['course_name'] ?? course?['name'] ?? courseId).toString();
  }

  String _sessionTitle(Map<String, String> session, LocaleProvider loc) {
    final dt = _parseFlexibleDateTime(session['started_at'] ?? '');
    final date = dt == null
        ? (session['started_at']?.split('T').first ?? '')
        : '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    final className = _displayClassName(_selectedClass);
    final courseName = _courseName(session['course_id'] ?? '', loc);
    return className.isNotEmpty
        ? '$className-$courseName-$date'
        : '$courseName-$date';
  }

  String _sessionTime(Map<String, String> session) {
    final dt = _parseFlexibleDateTime(session['started_at'] ?? '');
    if (dt == null) return '';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _openSession(Map<String, String> session) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AttendancePage(
          session: widget.session,
          courseId: session['course_id'],
          isStandalone: true,
        ),
      ),
    );
  }

  void _showFullHistory() {
    final loc = Provider.of<LocaleProvider>(context, listen: false);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final sessions = _sessionsForCurrentClass();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return ListView.separated(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              itemCount: sessions.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      loc.t('全部点名记录', 'All Attendance History'),
                      style: tt.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  );
                }
                final session = sessions[index - 1];
                return Material(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                  child: ListTile(
                    leading: Icon(Icons.history_rounded, color: cs.primary),
                    title: Text(_sessionTitle(session, loc)),
                    subtitle: Text(_sessionTime(session)),
                    trailing: Icon(Icons.chevron_right_rounded,
                        color: cs.onSurfaceVariant),
                    onTap: () {
                      Navigator.pop(ctx);
                      _openSession(session);
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildChartLabel({
    required String label,
    required int count,
    required Color color,
    required Alignment alignment,
    required TextTheme tt,
    EdgeInsets padding = EdgeInsets.zero,
  }) {
    if (count <= 0) return const SizedBox.shrink();

    final isTop = alignment == Alignment.topCenter;
    final isBottom = alignment == Alignment.bottomCenter;
    final isLeft = alignment == Alignment.centerLeft;
    final isRight = alignment == Alignment.centerRight;

    Widget textBlock = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: tt.labelLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$count',
          style: tt.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );

    Widget line;
    if (isTop || isBottom) {
      line = Container(
        width: 2,
        height: 18,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(999),
        ),
      );
      return Align(
        alignment: alignment,
        child: Padding(
          padding: padding.add(
            EdgeInsets.only(top: isTop ? 8 : 0, bottom: isBottom ? 8 : 0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: isTop
                ? [textBlock, const SizedBox(height: 6), line]
                : [line, const SizedBox(height: 6), textBlock],
          ),
        ),
      );
    }

    line = Container(
      width: 18,
      height: 2,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
      ),
    );
    return Align(
      alignment: alignment,
      child: Padding(
        padding: padding.add(
          EdgeInsets.only(left: isLeft ? 8 : 0, right: isRight ? 8 : 0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: isLeft
              ? [textBlock, const SizedBox(width: 6), line]
              : [line, const SizedBox(width: 6), textBlock],
        ),
      ),
    );
  }

  Widget _buildTodayRecordCard(
      LocaleProvider loc, ColorScheme cs, TextTheme tt) {
    final sessions = _sessionsForCurrentClass(todayOnly: true);
    if (sessions.isEmpty) return const SizedBox.shrink();
    final session = sessions.first;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                loc.t('今日点名记录', 'Today Attendance'),
                style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton(
                onPressed: _showFullHistory,
                child: Text(loc.t('查看全部', 'View All')),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _openSession(session),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(Icons.history_rounded, color: cs.primary, size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _sessionTitle(session, loc),
                          style: tt.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _sessionTime(session),
                          style: tt.bodyMedium
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill({
    required String label,
    required int value,
    required Color color,
    required VoidCallback onTap,
    required TextTheme tt,
  }) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Text(
              '$label  $value',
              style: tt.titleSmall?.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentListCard(
      LocaleProvider loc, ColorScheme cs, TextTheme tt) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: cs.outlineVariant),
        child: ExpansionTile(
          initiallyExpanded: true,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          collapsedShape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Text(
            loc.t('学生详细名单', 'Detailed Student List'),
            style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          children: [
            for (int index = 0; index < _rows.length; index++) ...[
              if (index != 0)
                Divider(
                    height: 1, color: cs.outlineVariant.withValues(alpha: 0.6)),
              _OverviewStudentTile(
                row: _rows[index],
                className:
                    _displayClassName(_rows[index].student.classCode.trim()),
                cs: cs,
                tt: tt,
                loc: loc,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => StudentDetailPage(
                        session: widget.session,
                        student: _rows[index].student,
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final loc = Provider.of<LocaleProvider>(context);
    final tt = Theme.of(context).textTheme;
    final totalRecords = totalPresent + totalLate + totalAbsent + totalLeave;
    final hasRecords = totalRecords > 0;
    final hasDrawer = Scaffold.maybeOf(context)?.hasDrawer ?? false;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        leading: hasDrawer
            ? Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu_rounded),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              )
            : null,
        title: Text(loc.t('班级考勤', 'Class Attendance'),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: cs.surface,
        elevation: 0,
        actions: [
          if (_myClasses.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: ExpressiveSelector(
                  label: loc.t('班级', 'Class'),
                  value: _selectedClass,
                  items: _myClasses,
                  customLabelBuilder: (val) {
                    final match = _myClassesWithNames
                        .firstWhere((e) => e['id'] == val, orElse: () => {});
                    return match.isNotEmpty ? match['name']! : val;
                  },
                  onSelected: (v) {
                    setState(() {
                      _selectedClass = v;
                    });
                    _refresh();
                  },
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => _refresh(forceNetwork: true),
            child: CustomScrollView(
              slivers: [
                if (!_dataReady)
                  const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()))
                else if (_status.trim().isNotEmpty)
                  SliverFillRemaining(
                      child: Center(
                          child: Text(_status,
                              style: TextStyle(color: cs.error),
                              textAlign: TextAlign.center)))
                else if (_rows.isEmpty && !_loading)
                  SliverFillRemaining(
                      child: Center(child: Text(loc.t('暂无数据', 'No data'))))
                else ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Center(
                        child: SegmentedButton<String>(
                          segments: [
                            ButtonSegment(
                                value: 'day', label: Text(loc.t('本日', 'Day'))),
                            ButtonSegment(
                                value: 'week',
                                label: Text(loc.t('本周', 'Week'))),
                            ButtonSegment(
                                value: 'month',
                                label: Text(loc.t('本月', 'Month'))),
                            ButtonSegment(
                                value: 'term',
                                label: Text(loc.t('本学期', 'Term'))),
                          ],
                          selected: {_selectedRange},
                          onSelectionChanged: (Set<String> newSelection) {
                            setState(() => _selectedRange = newSelection.first);
                            _refresh();
                          },
                          showSelectedIcon: false,
                          style: SegmentedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            backgroundColor: cs.surfaceContainerLow,
                            foregroundColor: cs.onSurfaceVariant,
                            selectedBackgroundColor: cs.secondaryContainer,
                            selectedForegroundColor: cs.onSecondaryContainer,
                            side: BorderSide(color: cs.outlineVariant),
                            textStyle: tt.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: Card(
                        elevation: 0,
                        color: cs.surfaceContainerLow,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24)),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: cs.primary.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.analytics_rounded,
                                        color: cs.primary, size: 24),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(loc.t('周期内点名次数', 'Total Sessions'),
                                          style: tt.labelLarge?.copyWith(
                                              color: cs.onSurfaceVariant)),
                                      Text('$_totalSessionsInRange',
                                          style: tt.headlineSmall?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: cs.onSurface)),
                                    ],
                                  ),
                                  const Spacer(),
                                  _buildAttendanceRateBadge(cs, tt),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: Container(
                        height: 320,
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                              color: cs.outlineVariant.withValues(alpha: 0.5)),
                        ),
                        child: !hasRecords
                            ? Center(
                                child: Text(loc.t('该时段暂无考勤记录', 'No Records')))
                            : Stack(
                                alignment: Alignment.center,
                                children: [
                                  _buildChartLabel(
                                    label: loc.t('迟到', 'Late'),
                                    count: totalLate,
                                    color: cs.tertiary,
                                    alignment: Alignment.topCenter,
                                    tt: tt,
                                  ),
                                  _buildChartLabel(
                                    label: loc.t('到勤', 'Present'),
                                    count: totalPresent,
                                    color: cs.primary,
                                    alignment: Alignment.bottomCenter,
                                    tt: tt,
                                  ),
                                  _buildChartLabel(
                                    label: loc.t('缺勤', 'Absent'),
                                    count: totalAbsent,
                                    color: cs.error,
                                    alignment: const Alignment(-0.96, 0.0),
                                    tt: tt,
                                    padding: const EdgeInsets.only(right: 6),
                                  ),
                                  _buildChartLabel(
                                    label: loc.t('请假', 'Leave'),
                                    count: totalLeave,
                                    color: cs.secondary,
                                    alignment: const Alignment(0.96, 0.0),
                                    tt: tt,
                                    padding: const EdgeInsets.only(left: 6),
                                  ),
                                  PieChart(
                                    PieChartData(
                                      sectionsSpace: 4,
                                      centerSpaceRadius: 72,
                                      sections: [
                                        _buildSection(
                                            totalPresent.toDouble(),
                                            cs.primary,
                                            loc.t('到', 'P'),
                                            totalPresent),
                                        _buildSection(
                                            totalLate.toDouble(),
                                            cs.tertiary,
                                            loc.t('迟', 'L'),
                                            totalLate),
                                        _buildSection(
                                            totalAbsent.toDouble(),
                                            cs.error,
                                            loc.t('缺', 'A'),
                                            totalAbsent),
                                        _buildSection(
                                            totalLeave.toDouble(),
                                            cs.secondary,
                                            loc.t('假', 'Lv'),
                                            totalLeave),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${((totalPresent / totalRecords) * 100).toStringAsFixed(1)}%',
                                        style: tt.headlineMedium?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: cs.onSurface,
                                        ),
                                      ),
                                      Text(loc.t('总出勤率', 'Attendance'),
                                          style: tt.labelMedium?.copyWith(
                                              color: cs.onSurfaceVariant,
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${loc.t('总人数', 'Total')}: ${_rows.length}',
                                        style: tt.bodyMedium?.copyWith(
                                            color: cs.onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _buildTodayRecordCard(loc, cs, tt),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                      child: Wrap(
                        spacing: 18,
                        runSpacing: 18,
                        alignment: WrapAlignment.center,
                        children: [
                          _buildStatPill(
                            label: loc.t('到勤', 'Present'),
                            value: totalPresent,
                            color: cs.primary,
                            tt: tt,
                            onTap: () => _showStatusStudents(
                                context, 'present', loc.t('到勤', 'Present')),
                          ),
                          _buildStatPill(
                            label: loc.t('迟到', 'Late'),
                            value: totalLate,
                            color: cs.tertiary,
                            tt: tt,
                            onTap: () => _showStatusStudents(
                                context, 'late', loc.t('迟到', 'Late')),
                          ),
                          _buildStatPill(
                            label: loc.t('缺勤', 'Absent'),
                            value: totalAbsent,
                            color: cs.error,
                            tt: tt,
                            onTap: () => _showStatusStudents(
                                context, 'absent', loc.t('缺勤', 'Absent')),
                          ),
                          _buildStatPill(
                            label: loc.t('请假', 'Leave'),
                            value: totalLeave,
                            color: cs.secondary,
                            tt: tt,
                            onTap: () => _showStatusStudents(
                                context, 'leave', loc.t('请假', 'Leave')),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _buildStudentListCard(loc, cs, tt),
                  ),
                ],
              ],
            ),
          ),
          if (_loading && _dataReady)
            const Positioned(
                top: 0, left: 0, right: 0, child: LinearProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildAttendanceRateBadge(ColorScheme cs, TextTheme tt) {
    final total = totalPresent + totalLate + totalAbsent + totalLeave;
    if (total == 0) return const SizedBox.shrink();
    final rate = (totalPresent / total) * 100;
    Color rateColor = cs.primary;
    if (rate < 80) {
      rateColor = cs.error;
    } else if (rate < 95) {
      rateColor = cs.tertiary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: rateColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: rateColor.withValues(alpha: 0.2)),
      ),
      child: Text('${rate.toStringAsFixed(1)}%',
          style: tt.labelLarge
              ?.copyWith(color: rateColor, fontWeight: FontWeight.bold)),
    );
  }

  PieChartSectionData _buildSection(
      double value, Color color, String label, int count) {
    if (value <= 0) {
      return PieChartSectionData(value: 0, showTitle: false, radius: 0);
    }
    return PieChartSectionData(
      color: color,
      value: value,
      title: '',
      radius: 26,
    );
  }
}

class _OverviewStudentTile extends StatelessWidget {
  final _Row row;
  final String className;
  final ColorScheme cs;
  final TextTheme tt;
  final LocaleProvider loc;
  final VoidCallback onTap;
  const _OverviewStudentTile(
      {required this.row,
      required this.className,
      required this.cs,
      required this.tt,
      required this.loc,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.student.fullName,
                    style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    row.student.studentNo,
                    style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    className,
                    style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _CompactBadge(
                          label: loc.t('到', 'P'),
                          value: row.present,
                          color: cs.primary),
                      _CompactBadge(
                          label: loc.t('迟', 'L'),
                          value: row.late,
                          color: cs.tertiary),
                      _CompactBadge(
                          label: loc.t('缺', 'A'),
                          value: row.absent,
                          color: cs.error),
                      _CompactBadge(
                          label: loc.t('假', 'Lv'),
                          value: row.leave,
                          color: cs.secondary),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.chevron_right_rounded,
                size: 28, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _CompactBadge extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _CompactBadge(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: RichText(
        text: TextSpan(
          style: tt.labelMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
          children: [
            TextSpan(text: label),
            TextSpan(
              text: '$value',
              style: tt.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
