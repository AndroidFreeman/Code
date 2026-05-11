import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/course.dart';
import '../models/student.dart';
import '../models/timetable_item.dart';
import '../main.dart';
import '../services/api_config.dart';
import '../services/local_profiles.dart';
import '../state/session.dart';
import '../widgets/expressive_ui.dart';
import 'student_detail_page.dart';

class AttendancePage extends StatefulWidget {
  final Session session;
  final String? courseId;
  final String? courseName;
  final VoidCallback? onReady;
  final bool isStandalone;

  const AttendancePage({
    super.key,
    required this.session,
    this.courseId,
    this.courseName,
    this.onReady,
    this.isStandalone = false,
  });

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  static const String _attendancePrefsFile = 'attendance_prefs.json';

  String _status = '';
  bool _initInFlight = false;
  bool _displayRefreshInFlight = false;
  bool _attendancePrefsLoaded = false;
  StreamSubscription<SessionDataChange>? _dataChangeSub;

  List<Course> _allCourses = [];
  List<TimetableItem> _allTimetable = [];
  List<Student> _allStudents = [];

  List<Map<String, String>> _myClassesWithNames = [];
  List<String> _myClasses = [];
  String? _selectedClass;

  List<Course> _displayCourses = [];
  Course? _selectedCourse;

  List<Student> _displayStudents = [];

  String _batchStatus = '';
  bool _batchSubmitting = false;
  bool _batchDisabled = false;

  String? _sessionId;
  final Map<String, String> _marking = {};

  TimetableItem? _activeCourse;
  TimetableItem? _nextCourse;

  List<Map<String, String>> _allSessions = [];
  final Map<String, String> _classNameById = {};
  final Map<String, String> _classIdByName = {};
  final Map<String, String> _studentClassCodeById = {};
  final Map<String, List<String>> _profileClassCodesById = {};
  Map<String, String> _sessionClassCodeById = const {};
  final Map<String, String> _preferredCourseByClass = {};
  final Map<String, String> _lastUsedCourseByClass = {};
  Map<String, String> _avatarMap = const {};

  DateTime? _parseFlexibleDateTime(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    final candidates = <String>[
      value,
      value.replaceFirst(' ', 'T'),
      value.replaceAll('/', '-').replaceFirst(' ', 'T'),
    ];
    for (final candidate in candidates) {
      try {
        return DateTime.parse(candidate).toLocal();
      } catch (_) {}
    }
    return null;
  }

  String _formatDisplayDateTime(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return '—';
    final dt = _parseFlexibleDateTime(value);
    if (dt != null) {
      final mm = dt.month.toString().padLeft(2, '0');
      final dd = dt.day.toString().padLeft(2, '0');
      final hh = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$mm-$dd $hh:$min';
    }
    return value.replaceFirst('T', ' ').replaceFirst('Z', '');
  }

  String _displayCourseName(String courseId, LocaleProvider loc) {
    final trimmed = courseId.trim();
    if (trimmed.isEmpty) return loc.t('未知课程', 'Unknown Course');
    final course = _allCourses.where((c) => c.id == trimmed).firstOrNull;
    return course?.courseName ?? trimmed;
  }

  String _resolveClassId(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return '';

    // Exact match
    if (_classNameById.containsKey(value)) return value;
    if (_classIdByName.containsKey(value)) return _classIdByName[value]!;

    // Case-insensitive match for ID
    final upperValue = value.toUpperCase();
    for (final id in _classNameById.keys) {
      if (id.toUpperCase() == upperValue) return id;
    }

    // Case-insensitive match for Name
    for (final entry in _classIdByName.entries) {
      if (entry.key.toUpperCase() == upperValue) return entry.value;
    }

    return value;
  }

  String _resolveSessionClassCode(Map<String, String> session) {
    final sessionId = (session['id'] ?? '').trim();
    final mappedClassCode = _sessionClassCodeById[sessionId]?.trim() ?? '';
    final selectedClass = (_selectedClass ?? '').trim();
    final createdByProfileId = (session['created_by_profile_id'] ?? '').trim();
    final creatorClasses =
        _profileClassCodesById[createdByProfileId] ?? const <String>[];
    if (selectedClass.isNotEmpty) {
      if (creatorClasses.contains(selectedClass)) return selectedClass;
    }

    if (mappedClassCode.isNotEmpty) return mappedClassCode;
    final courseId = (session['course_id'] ?? '').trim();
    if (courseId.isEmpty) return '';
    final timetableClassCodes = _allTimetable
        .where((item) =>
            item.courseId == courseId &&
            item.ownerProfileId.startsWith('class_'))
        .map((item) => item.ownerProfileId.replaceFirst('class_', '').trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
    if (selectedClass.isNotEmpty &&
        timetableClassCodes.contains(selectedClass)) {
      return selectedClass;
    }
    if (timetableClassCodes.length == 1) {
      return timetableClassCodes.first;
    }
    if (creatorClasses.length == 1) {
      return creatorClasses.first;
    }
    return mappedClassCode;
  }

  Future<Map<String, String>> _loadAvatarMap() async {
    final avatarMap = <String, String>{};
    try {
      if (widget.session.preloadedData['profiles'] != null) {
        final data = widget.session.preloadedData['profiles'];
        final items = (data is Map ? data['items'] : data) as List? ?? [];
        for (final item in items) {
          final row = (item as Map).cast<String, dynamic>();
          final id = (row['id'] ?? '').toString().trim();
          final avatar = (row['avatar'] ?? '').toString().trim();
          if (id.isNotEmpty && avatar.isNotEmpty) {
            avatarMap[id] = avatar;
          }
        }
        return avatarMap;
      }

      if (ApiConfig.instance.useCloud) {
        final profilesRes = await widget.session.features.listProfiles();
        if (profilesRes['ok'] == true) {
          final rawData = profilesRes['data'];
          final items = (rawData is List)
              ? rawData
              : ((rawData as Map?)?['items'] as List? ?? []);
          for (final item in items) {
            final row = (item as Map).cast<String, dynamic>();
            final id = (row['id'] ?? '').toString().trim();
            final avatar = (row['avatar'] ?? '').toString().trim();
            if (id.isNotEmpty && avatar.isNotEmpty) {
              avatarMap[id] = avatar;
            }
          }
        }
        return avatarMap;
      }

      if (await widget.session.features.hasFeature('profiles_list')) {
        final profilesRes = await widget.session.features.listProfiles();
        if (profilesRes['ok'] == true) {
          final items = (((profilesRes['data'] ?? const {}) as Map)['items'] ??
              const []) as List;
          for (final item in items) {
            final row = (item as Map).cast<String, dynamic>();
            final id = (row['id'] ?? '').toString().trim();
            final avatar = (row['avatar'] ?? '').toString().trim();
            if (id.isNotEmpty && avatar.isNotEmpty) {
              avatarMap[id] = avatar;
            }
          }
          return avatarMap;
        }
      }

      final profilesRes = await widget.session.features
          .csvOp(action: 'read', file: 'profiles.csv');
      if (profilesRes['ok'] == true) {
        final items =
            ((profilesRes['data'] ?? const {})['items'] as List?) ?? const [];
        for (final item in items) {
          final row = (item as Map).cast<String, String>();
          final id = (row['id'] ?? '').trim();
          final avatar = (row['avatar'] ?? '').trim();
          if (id.isNotEmpty && avatar.isNotEmpty) {
            avatarMap[id] = avatar;
          }
        }
      }
    } catch (_) {}
    final sessionAvatar = widget.session.profile.avatar.trim();
    if (sessionAvatar.isNotEmpty) {
      avatarMap[widget.session.profile.id] = sessionAvatar;
    }
    return avatarMap;
  }

  Future<void> _loadProfileClassCodes() async {
    _profileClassCodesById.clear();
    try {
      final data = widget.session.preloadedData['profiles'];
      if (data != null) {
        final items = (data is Map ? data['items'] : data) as List? ?? [];
        for (final item in items) {
          final row = (item as Map).cast<String, dynamic>();
          final id = (row['id'] ?? '').toString().trim();
          if (id.isEmpty) continue;
          _profileClassCodesById[id] =
              _splitClassCodes(row['class_code'] ?? row['classCode']);
        }
        return;
      }

      final profilesRes = await widget.session.features.listProfiles();
      if (profilesRes['ok'] == true) {
        final rawData = profilesRes['data'];
        final items = (rawData is List)
            ? rawData
            : ((rawData as Map?)?['items'] as List? ?? []);
        for (final item in items) {
          final row = (item as Map).cast<String, dynamic>();
          final id = (row['id'] ?? '').toString().trim();
          if (id.isEmpty) continue;
          _profileClassCodesById[id] =
              _splitClassCodes(row['class_code'] ?? row['classCode']);
        }
      }
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _dataChangeSub = widget.session.watchDataChanges({
      'attendance',
      'students',
      'timetable',
      'classes',
      'profiles'
    }).listen((_) {
      if (mounted) {
        unawaited(_initData(isBackground: true));
      }
    });
    _initData();
  }

  @override
  void dispose() {
    _dataChangeSub?.cancel();
    super.dispose();
  }

  static int _hhmmToMinutes(String hhmm) {
    final s = hhmm.trim();
    final parts = s.split(':');
    if (parts.length != 2) return 0;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return h * 60 + m;
  }

  static int _weekdayNow() {
    final w = DateTime.now().weekday;
    if (w == DateTime.sunday) return 7;
    return w;
  }

  Map<String, String> _toStringMap(dynamic value) {
    if (value is! Map) return const {};
    return value.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
  }

  List<String> _splitClassCodes(dynamic value) {
    if (value is String) {
      return value
          .split('|')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (value is List) {
      return value
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const [];
  }

  Future<void> _ensureAttendancePrefsLoaded() async {
    if (_attendancePrefsLoaded) return;
    try {
      final res = await widget.session.features
          .jsonOp(action: 'read', file: _attendancePrefsFile);
      if (res['ok'] == true && res['data'] is Map) {
        final raw = res['data'] as Map;
        _preferredCourseByClass
          ..clear()
          ..addAll(_toStringMap(raw['preferred_course_by_class']));
        _lastUsedCourseByClass
          ..clear()
          ..addAll(_toStringMap(raw['last_used_course_by_class']));
      }
    } catch (_) {
      // Fall back to empty local preferences.
    } finally {
      _attendancePrefsLoaded = true;
    }
  }

  Future<void> _persistAttendancePrefs() async {
    if (!_attendancePrefsLoaded) return;
    try {
      await widget.session.features.jsonOp(
        action: 'write',
        file: _attendancePrefsFile,
        data: <String, dynamic>{
          'preferred_course_by_class': _preferredCourseByClass,
          'last_used_course_by_class': _lastUsedCourseByClass,
          'saved_at': DateTime.now().toIso8601String(),
        },
      );
    } catch (_) {}
  }

  Future<void> _rememberCourseSelection(
    String courseId, {
    bool manual = false,
  }) async {
    final classId = _selectedClass?.trim() ?? '';
    final normalizedCourseId = courseId.trim();
    if (classId.isEmpty || normalizedCourseId.isEmpty) return;
    await _ensureAttendancePrefsLoaded();
    _lastUsedCourseByClass[classId] = normalizedCourseId;
    if (manual) {
      _preferredCourseByClass[classId] = normalizedCourseId;
    }
    await _persistAttendancePrefs();
  }

  DateTime? _tryParseSessionTime(Map<String, String> session) {
    final raw = (session['started_at'] ?? '').trim();
    if (raw.isEmpty) return null;
    try {
      return DateTime.parse(raw).toLocal();
    } catch (_) {
      return null;
    }
  }

  Map<String, String> _buildSessionClassCodeMap(
      List<Map<String, String>> records) {
    final counts = <String, Map<String, int>>{};
    for (final row in records) {
      final sessionId = (row['session_id'] ?? '').trim();
      final studentId = (row['student_id'] ?? '').trim();
      if (sessionId.isEmpty || studentId.isEmpty) continue;
      final classCode = _studentClassCodeById[studentId]?.trim() ?? '';
      if (classCode.isEmpty) continue;
      final sessionCounts =
          counts.putIfAbsent(sessionId, () => <String, int>{});
      sessionCounts[classCode] = (sessionCounts[classCode] ?? 0) + 1;
    }

    final resolved = <String, String>{};
    counts.forEach((sessionId, classCounts) {
      final sorted = classCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      if (sorted.isNotEmpty) {
        resolved[sessionId] = sorted.first.key;
      }
    });
    return resolved;
  }

  int _courseStartMinutes(String courseId, List<TimetableItem> items) {
    var best = 1 << 30;
    for (final item in items) {
      if (item.courseId != courseId) continue;
      final value = _hhmmToMinutes(item.startTime);
      if (value < best) best = value;
    }
    return best == (1 << 30) ? 24 * 60 : best;
  }

  String? _latestSessionCourseIdFor(Set<String> candidateCourseIds) {
    if (candidateCourseIds.isEmpty || _allSessions.isEmpty) return null;
    final sorted = [..._allSessions];
    sorted.sort((a, b) {
      final at = _tryParseSessionTime(a);
      final bt = _tryParseSessionTime(b);
      if (at == null && bt == null) return 0;
      if (at == null) return 1;
      if (bt == null) return -1;
      return bt.compareTo(at);
    });
    for (final session in sorted) {
      final courseId = (session['course_id'] ?? '').trim();
      if (candidateCourseIds.contains(courseId)) {
        return courseId;
      }
    }
    return null;
  }

  Course? _pickAutoCourse({
    required List<Course> candidates,
    required List<TimetableItem> relevantTt,
    required List<TimetableItem> todayTt,
    required TimetableItem? active,
    required TimetableItem? next,
    required int nowMin,
  }) {
    if (candidates.isEmpty) return null;

    final classId = _selectedClass?.trim() ?? '';
    final preferredCourseId =
        classId.isEmpty ? null : _preferredCourseByClass[classId];
    final lastUsedCourseId =
        classId.isEmpty ? null : _lastUsedCourseByClass[classId];
    final latestSessionCourseId =
        _latestSessionCourseIdFor(relevantTt.map((e) => e.courseId).toSet());

    final scored = [...candidates];
    scored.sort((a, b) {
      int score(Course course) {
        var total = 0;
        if (widget.courseId != null && widget.courseId == course.id) {
          total += 5000;
        }
        if (_selectedCourse?.id == course.id) {
          total += 300;
        }
        if (active != null && course.id == active.courseId) {
          total += 3200;
        }
        if (next != null && course.id == next.courseId) {
          final minutesToNext = _hhmmToMinutes(next.startTime) - nowMin;
          final bounded = minutesToNext < 0
              ? 0
              : (minutesToNext > 180 ? 180 : minutesToNext);
          total += 1700 - bounded * 6;
        }
        if (todayTt.any((item) => item.courseId == course.id)) {
          total += 650;
        }
        if (preferredCourseId == course.id) {
          total += 950;
        }
        if (lastUsedCourseId == course.id) {
          total += 720;
        }
        if (latestSessionCourseId == course.id) {
          total += 520;
        }
        if (course.teacherProfileId == widget.session.profile.id) {
          total += 120;
        }
        total += ((24 * 60 - _courseStartMinutes(course.id, todayTt)) ~/ 24);
        return total;
      }

      final byScore = score(b).compareTo(score(a));
      if (byScore != 0) return byScore;
      final byStart = _courseStartMinutes(a.id, todayTt)
          .compareTo(_courseStartMinutes(b.id, todayTt));
      if (byStart != 0) return byStart;
      return a.courseName.compareTo(b.courseName);
    });
    return scored.first;
  }

  Future<void> _applyHistorySession(
    Map<String, String> session, {
    bool manualPreference = true,
  }) async {
    final courseId = (session['course_id'] ?? '').trim();
    final selected = _allCourses.where((c) => c.id == courseId).firstOrNull;
    if (selected == null) return;
    final sessionClassCode = _resolveSessionClassCode(session);
    if (!mounted) return;
    setState(() {
      if (sessionClassCode.isNotEmpty) {
        _selectedClass = sessionClassCode;
      }
      _sessionId = session['id'];
      _selectedCourse = selected;
    });
    if (manualPreference) {
      unawaited(_rememberCourseSelection(selected.id, manual: true));
    }
    unawaited(_initData(isBackground: true));
  }

  Future<List<Map<String, String>>> _readCsvRows(String filename) async {
    if (ApiConfig.instance.useCloud) {
      if (filename == 'attendance_sessions.csv') {
        final res = await ApiConfig.instance.get('/api/attendance/sessions');
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
      } else if (filename == 'attendance_records.csv') {
        final res = await ApiConfig.instance.get('/api/attendance/records');
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

  Future<void> _initData({bool isBackground = false}) async {
    if (_initInFlight) return;
    _initInFlight = true;

    debugPrint(
        'AttendancePage: _initData(isBackground: $isBackground) started');

    if (!isBackground && mounted && _displayStudents.isEmpty) {
      setState(() {
        _status = '';
      });
    }

    try {
      await _ensureAttendancePrefsLoaded();
      final allClassesFuture =
          LocalProfiles.getAllClassesWithNames(widget.session.dataDir);
      final myClassesFuture = widget.session.isTeacher
          ? LocalProfiles.getTeacherClasses(
              widget.session.dataDir,
              widget.session.profile.id,
            )
          : Future<List<String>>.value([
              widget.session.profile.classCode.trim(),
            ]);

      final coursesFuture = widget.session.features.listCourses();
      final ttFuture = widget.session.features.listTimetable();
      final studentsFuture = widget.session.features.listStudents();
      final avatarMapFuture = _loadAvatarMap();
      final profileClassCodesFuture = _loadProfileClassCodes();
      final sessionsFuture = _readCsvRows('attendance_sessions.csv');

      final allClassesMapList = await allClassesFuture;
      debugPrint(
          'AttendancePage: Loaded ${allClassesMapList.length} total classes');

      if (allClassesMapList.isEmpty && ApiConfig.instance.useCloud) {
        debugPrint(
            'AttendancePage: classes list empty, retrying direct fetch...');
        try {
          final retryRes = await ApiConfig.instance.get('/api/classes');
          if (retryRes['ok'] == true && retryRes['data'] != null) {
            final raw = retryRes['data'];
            final items = (raw is List)
                ? raw
                : (raw is Map ? (raw['items'] as List? ?? []) : []);
            for (final item in items) {
              if (item is Map) {
                allClassesMapList.add({
                  'id': (item['id'] ?? item['classCode'] ?? '').toString(),
                  'name': (item['className'] ??
                          item['class_name'] ??
                          item['id'] ??
                          '')
                      .toString(),
                });
              } else if (item is String) {
                allClassesMapList.add({'id': item, 'name': item});
              }
            }
          }
        } catch (e) {
          debugPrint('AttendancePage: Retry classes fetch failed: $e');
        }
      }

      _classNameById
        ..clear()
        ..addEntries(allClassesMapList.map(
          (e) => MapEntry(e['id'] ?? '', e['name'] ?? e['id'] ?? ''),
        ));
      _classIdByName
        ..clear()
        ..addEntries(allClassesMapList
            .where((e) =>
                (e['id'] ?? '').isNotEmpty && (e['name'] ?? '').isNotEmpty)
            .map((e) => MapEntry(e['name']!, e['id']!)));

      _myClasses =
          (await myClassesFuture).map(_resolveClassId).toSet().toList();
      debugPrint('AttendancePage: Profile classes (resolved): $_myClasses');

      // Always check timetable for teachers to ensure they see all their classes
      if (widget.session.isTeacher) {
        debugPrint(
            'AttendancePage: Teacher detected, merging timetable classes...');
        final derivedClasses = <String>{};
        for (final item in _allTimetable) {
          final owner = item.ownerProfileId.trim();
          if (!owner.startsWith('class_')) continue;
          final classId = owner.replaceFirst('class_', '').trim();
          if (classId.isEmpty) continue;

          // If teacher created the item or is the teacher for the course
          if (item.createdByProfileId.trim() == widget.session.profile.id) {
            derivedClasses.add(_resolveClassId(classId));
            continue;
          }
          final course =
              _allCourses.where((c) => c.id == item.courseId).firstOrNull;
          if (course?.teacherProfileId.trim() == widget.session.profile.id) {
            derivedClasses.add(_resolveClassId(classId));
          }
        }

        final combined = <String>{..._myClasses, ...derivedClasses}.toList()
          ..sort();
        if (combined.length > _myClasses.length) {
          debugPrint(
              'AttendancePage: Expanded teacher classes from ${_myClasses.length} to ${combined.length}. New classes: ${combined.where((e) => !_myClasses.contains(e)).toList()}');
          _myClasses = combined;
        }
      }

      _myClassesWithNames =
          allClassesMapList.where((e) => _myClasses.contains(e['id'])).toList();

      if (_myClasses.isNotEmpty && _selectedClass == null) {
        _selectedClass = _myClasses.first;
        debugPrint(
            'AttendancePage: Auto-selected first class: $_selectedClass');
      }

      final coursesRes = (widget.session.preloadedData['courses'] is Map &&
              (widget.session.preloadedData['courses']['items'] as List)
                  .isNotEmpty)
          ? {'ok': true, 'data': widget.session.preloadedData['courses']}
          : await coursesFuture;
      final ttRes = (widget.session.preloadedData['timetable'] is Map &&
              (widget.session.preloadedData['timetable']['items'] as List)
                  .isNotEmpty)
          ? {'ok': true, 'data': widget.session.preloadedData['timetable']}
          : await ttFuture;
      final studentsRes = await studentsFuture;

      if (coursesRes['ok'] == true) {
        final rawData = coursesRes['data'];
        final items = (rawData is List)
            ? rawData
            : ((rawData as Map?)?['items'] as List? ?? []);
        _allCourses = items
            .map((e) => Course.fromJson(Map<String, dynamic>.from(
                e is Map ? e : (e as Map<String, dynamic>))))
            .toList();
        debugPrint('AttendancePage: Loaded ${_allCourses.length} courses');
      }

      if (ttRes['ok'] == true) {
        final rawData = ttRes['data'];
        final items = (rawData is List)
            ? rawData
            : ((rawData as Map?)?['items'] as List? ?? []);
        _allTimetable = items
            .map((e) => TimetableItem.fromJson(Map<String, dynamic>.from(
                e is Map ? e : (e as Map<String, dynamic>))))
            .toList();
        debugPrint(
            'AttendancePage: Loaded ${_allTimetable.length} timetable items');
      }

      if (studentsRes['ok'] == true) {
        final rawData = studentsRes['data'];
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
        _allStudents = uniqueStudents.values
            .map((s) => s.copyWith(
                  className: (_classNameById[s.classCode.trim()] ?? '').trim(),
                ))
            .toList();
        _studentClassCodeById
          ..clear()
          ..addEntries(_allStudents.map(
            (student) => MapEntry(student.id.trim(), student.classCode.trim()),
          ));
        debugPrint(
            'AttendancePage: Loaded ${_allStudents.length} unique students');
      }

      _avatarMap = await avatarMapFuture;
      await profileClassCodesFuture;
      _allSessions = await sessionsFuture;
      debugPrint(
          'AttendancePage: Loaded ${_allSessions.length} attendance sessions');

      if (!mounted) return;
      await _refreshDisplay();
      if (!mounted) return;
      setState(() {});
      widget.onReady?.call();
    } catch (e, stack) {
      debugPrint('AttendancePage: Error in _initData: $e\n$stack');
      if (!mounted) return;
      setState(() {
        _status = e.toString();
      });
      widget.onReady?.call();
    } finally {
      _initInFlight = false;
      debugPrint('AttendancePage: _initData finished');
    }
  }

  Future<void> _refreshDisplay() async {
    if (_displayRefreshInFlight) return;
    _displayRefreshInFlight = true;
    debugPrint(
        'AttendancePage: _refreshDisplay started. _selectedClass: $_selectedClass');

    try {
      if (_myClasses.isNotEmpty &&
          (_selectedClass == null || !_myClasses.contains(_selectedClass))) {
        final old = _selectedClass;
        _selectedClass = _myClasses.first;
        debugPrint(
            'AttendancePage: Correcting _selectedClass from $old to $_selectedClass');
      }

      final selectedClassId = _resolveClassId(_selectedClass ?? '');
      debugPrint('AttendancePage: resolved selectedClassId: $selectedClassId');

      if (selectedClassId.isEmpty) {
        debugPrint(
            'AttendancePage: No class selected, clearing display students');
        _displayStudents = [];
        if (mounted) {
          setState(() {});
        }
        widget.onReady?.call();
        return;
      }

      // Filter students for the selected class
      _displayStudents = _allStudents.where((s) {
        final studentClassId = _resolveClassId(s.classCode);
        final matches =
            studentClassId.toUpperCase() == selectedClassId.toUpperCase();
        if (!matches) {
          // Additional check: maybe s.classCode is a name and selectedClassId is an ID, or vice versa
          final resolvedStudentClass = _resolveClassId(s.classCode);
          return resolvedStudentClass.toUpperCase() ==
              selectedClassId.toUpperCase();
        }
        return matches;
      }).toList();
      debugPrint(
          'AttendancePage: Filtered ${_displayStudents.length} students for class $selectedClassId');

      if (_displayStudents.isEmpty && _allStudents.isNotEmpty) {
        debugPrint(
            'AttendancePage: WARNING: No students match selected class! Sample student class codes: ${_allStudents.take(5).map((s) => s.classCode).toList()}');
      }

      _displayStudents.sort((a, b) => a.studentNo.compareTo(b.studentNo));

      // Determine today's schedule for this class or teacher
      final today = _weekdayNow();
      final now = DateTime.now();
      final nowMin = now.hour * 60 + now.minute;
      final currentWeek = _calculateCurrentWeek();

      // Attendance should follow the currently selected class first.
      final classOwnedTt = _allTimetable.where((e) {
        final isSelectedClass = e.ownerProfileId == 'class_$selectedClassId';
        return isSelectedClass && e.isWeekIncluded(currentWeek);
      }).toList();
      final relevantTt = classOwnedTt.isNotEmpty
          ? classOwnedTt
          : _allTimetable.where((e) {
              final isTeacherOwned =
                  e.ownerProfileId == widget.session.profile.id;
              return isTeacherOwned && e.isWeekIncluded(currentWeek);
            }).toList();

      final todayTt = relevantTt.where((e) => e.weekday == today).toList();
      todayTt.sort((a, b) =>
          _hhmmToMinutes(a.startTime).compareTo(_hhmmToMinutes(b.startTime)));

      TimetableItem? active;
      TimetableItem? next;
      for (var i = 0; i < todayTt.length; i++) {
        final it = todayTt[i];
        final s = _hhmmToMinutes(it.startTime);
        final e = _hhmmToMinutes(it.endTime);
        if (nowMin >= s && nowMin <= e) {
          active = it;
          if (i + 1 < todayTt.length) {
            next = todayTt[i + 1];
          }
          break;
        }
      }

      if (active == null) {
        for (final it in todayTt) {
          if (_hhmmToMinutes(it.startTime) > nowMin) {
            next = it;
            break;
          }
        }
      }

      _activeCourse = active;
      _nextCourse = next;

      final relevantCourseIds = relevantTt.map((e) => e.courseId).toSet();
      _displayCourses =
          _allCourses.where((c) => relevantCourseIds.contains(c.id)).toList();

      final selectedCourseStillVisible = _selectedCourse != null &&
          _displayCourses.any((course) => course.id == _selectedCourse!.id);
      if (!selectedCourseStillVisible) {
        _selectedCourse = _pickAutoCourse(
          candidates: _displayCourses,
          relevantTt: relevantTt,
          todayTt: todayTt,
          active: active,
          next: next,
          nowMin: nowMin,
        );
      }

      // Try to restore session
      String? restoredSessionId;
      final marks = <String, String>{};
      final studentsOnLeaveToday = <String>{};
      final records = await _readCsvRows('attendance_records.csv');
      _sessionClassCodeById = _buildSessionClassCodeMap(records);

      if (_selectedCourse != null && _sessionId == null) {
        try {
          final now = DateTime.now();
          bool isToday(String dateStr) {
            final s = dateStr.trim();
            if (s.isEmpty) return false;
            try {
              final dt = DateTime.parse(s).toLocal();
              return dt.year == now.year &&
                  dt.month == now.month &&
                  dt.day == now.day;
            } catch (_) {
              return s.startsWith(now.toIso8601String().substring(0, 10));
            }
          }

          final todaySessionIds = <String>{};
          for (final s in _allSessions) {
            final id = s['id'] ?? '';
            final cid = s['course_id'] ?? '';
            final startedAt = s['started_at'] ?? '';
            if (isToday(startedAt)) {
              todaySessionIds.add(id);
              final sessionClassCode = _resolveSessionClassCode(s);
              if (cid == _selectedCourse!.id &&
                  (sessionClassCode.isEmpty ||
                      _resolveClassId(sessionClassCode) == selectedClassId)) {
                restoredSessionId = id;
              }
            }
          }

          if (todaySessionIds.isNotEmpty) {
            for (final r in records) {
              final sid = r['session_id'] ?? '';
              final studentId = r['student_id'] ?? '';
              final status = r['status'] ?? '';
              if (todaySessionIds.contains(sid)) {
                if (status == 'leave') {
                  studentsOnLeaveToday.add(studentId);
                }
                if (sid == restoredSessionId) {
                  marks[studentId] = status;
                }
              }
            }
          }
        } catch (_) {}
      } else if (_sessionId != null) {
        // Load specific session
        final existingSession = _allSessions
            .where((session) => (session['id'] ?? '').trim() == _sessionId)
            .firstOrNull;
        final existingClassCode = existingSession == null
            ? ''
            : _resolveSessionClassCode(existingSession);
        if (existingClassCode.isEmpty ||
            _resolveClassId(existingClassCode) == selectedClassId) {
          restoredSessionId = _sessionId;
        }
        try {
          for (final r in records) {
            final sid = r['session_id'] ?? '';
            final studentId = r['student_id'] ?? '';
            final status = r['status'] ?? '';
            if (sid == restoredSessionId) {
              marks[studentId] = status;
            }
          }
        } catch (_) {}
      }

      if (!mounted) return;
      setState(() {
        _sessionId = restoredSessionId;
        _marking.clear();
        for (final s in _displayStudents) {
          _marking[s.id] = marks[s.id] ??
              (studentsOnLeaveToday.contains(s.id) ? 'leave' : _batchStatus);
        }
        _selectedClass = selectedClassId;
      });
      widget.onReady?.call();

      if (_sessionId == null && _selectedCourse != null) {
        unawaited(_rememberCourseSelection(_selectedCourse!.id));
      }
    } finally {
      _displayRefreshInFlight = false;
    }
  }

  int _calculateCurrentWeek() {
    final now = DateTime.now();
    final firstWeekStart = DateTime(now.year, 3, 9);
    final diff = now.difference(firstWeekStart).inDays;
    if (diff < 0) return 1;
    final week = (diff / 7).floor() + 1;
    return week.clamp(1, 20);
  }

  Future<void> _startSession({bool silent = false}) async {
    if (_selectedCourse == null) return;

    try {
      int? period;
      if (_selectedCourse!.id == _activeCourse?.courseId) {
        period = _activeCourse!.startPeriod;
      } else if (_selectedCourse!.id == _nextCourse?.courseId) {
        period = _nextCourse!.startPeriod;
      }

      final res = await widget.session.features.startAttendanceSession(
        courseId: _selectedCourse!.id,
        createdByProfileId: widget.session.profile.id,
        week: _calculateCurrentWeek(),
        period: period,
      );

      if (res['ok'] == true) {
        final sessionId = res['data']?['session_id']?.toString();
        if (!mounted) return;
        setState(() {
          _sessionId = sessionId;
        });
        unawaited(_rememberCourseSelection(_selectedCourse!.id));
        widget.session.notifyDataChanged(modules: const ['attendance']);
      } else {
        if (!mounted) return;
        final loc = Provider.of<LocaleProvider>(context, listen: false);
        throw res['error']?['message'] ??
            loc.t('启动点名失败', 'Failed to start attendance');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = e.toString();
      });
      widget.onReady?.call();
    }
  }

  Future<void> _submitMark(Student s, String status,
      {bool throwOnError = false, bool notify = true}) async {
    if (_sessionId == null) {
      await _startSession(silent: true);
    }
    if (_sessionId == null) {
      if (throwOnError) throw Exception('Session not started');
      return;
    }

    try {
      final res = await widget.session.features.markAttendanceRecord(
        sessionId: _sessionId!,
        studentId: s.id,
        status: status,
        markedByProfileId: widget.session.profile.id,
      );
      if (res['ok'] != true) {
        throw Exception(
            res['error']?['message'] ?? 'Failed to mark attendance');
      }
      // Trigger a silent sync to the server after local write
      unawaited(widget.session.features.systemInit(seed: false));
      if (notify) {
        widget.session.notifyDataChanged(modules: const ['attendance']);
      }
    } catch (e) {
      debugPrint('Mark error: $e');
      if (throwOnError) rethrow;
    }
  }

  Future<void> _applyBatchToAll({required bool submitIfStarted}) async {
    if (_displayStudents.isEmpty) return;

    if (submitIfStarted && _sessionId == null && _selectedCourse != null) {
      await _startSession(silent: true);
    }

    if (submitIfStarted && _sessionId == null) return;

    final backup = Map<String, String>.from(_marking);

    setState(() {
      _batchSubmitting = submitIfStarted;
      for (final s in _displayStudents) {
        _marking[s.id] = _batchStatus;
      }
    });

    if (!submitIfStarted) return;

    final futures = _displayStudents.map((s) async {
      for (int i = 0; i < 3; i++) {
        try {
          await _submitMark(s, _batchStatus, throwOnError: true, notify: false);
          return true;
        } catch (e) {
          if (i == 2) return false;
          await Future.delayed(Duration(milliseconds: 500 * (i + 1)));
        }
      }
      return false;
    });

    final results = await Future.wait(futures);
    final anyFailed = results.contains(false);

    // Notify once after all batch updates
    widget.session.notifyDataChanged(modules: const ['attendance']);

    if (!mounted) return;
    final loc = Provider.of<LocaleProvider>(context, listen: false);
    setState(() {
      _batchSubmitting = false;
      if (anyFailed) {
        for (int i = 0; i < _displayStudents.length; i++) {
          if (!results[i]) {
            _marking[_displayStudents[i].id] =
                backup[_displayStudents[i].id] ?? '';
          }
        }
      }
    });

    if (anyFailed) {
      showExpressiveSnackBar(
        context,
        loc.t('部分提交失败，已回滚状态', 'Some failed, state rolled back'),
      );
    } else {
      showExpressiveSnackBar(
        context,
        loc.t('已批量提交全班为：', 'Batch submitted class as: ') +
            _statusLabel(_batchStatus, loc),
      );
    }
  }

  String _statusLabel(String s, LocaleProvider loc) {
    switch (s) {
      case 'present':
        return loc.t('到', 'Present');
      case 'late':
        return loc.t('迟到', 'Late');
      case 'absent':
        return loc.t('缺勤', 'Absent');
      case 'leave':
        return loc.t('请假', 'Leave');
      default:
        return loc.t('未标记', 'Unmarked');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final loc = Provider.of<LocaleProvider>(context);

    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;
    final isPushed = widget.isStandalone;
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final showDrawerButton = (!isDesktop || isPortrait) &&
        !isPushed &&
        !(Platform.isAndroid && isTablet);

    if (!widget.session.canTakeAttendance) {
      return Scaffold(
        backgroundColor: cs.surface,
        appBar: AppBar(
          title: Text(loc.t('点名', 'Roll Call')),
          leading: isPushed
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                )
              : null,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_person_outlined, size: 64, color: cs.error),
              const SizedBox(height: 16),
              Text(
                loc.t('当前角色无点名权限',
                    'Your role does not have permission to take attendance'),
                style: tt.titleMedium?.copyWith(color: cs.error),
              ),
              const SizedBox(height: 8),
              Text(
                '${loc.t('当前职位', 'Current Position')}: ${widget.session.studentPosition.isEmpty ? loc.t('无', 'None') : widget.session.studentPosition}',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Text(
                '${loc.t('账号信息', 'Account Info')}: ${widget.session.profile.studentNo.isNotEmpty ? widget.session.profile.studentNo : widget.session.profile.staffNo} (${widget.session.profile.role})',
                style: tt.bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant, fontSize: 10),
              ),
              const SizedBox(height: 4),
              Text(
                '${loc.t('真实姓名', 'Real Name')}: ${widget.session.profile.realName}',
                style: tt.bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant, fontSize: 10),
              ),
              const SizedBox(height: 24),
              FilledButton.tonalIcon(
                onPressed: () async {
                  try {
                    final pos = await LocalProfiles.loadStudentPosition(
                      dataDir: widget.session.dataDir,
                      profile: widget.session.profile,
                    );
                    if (!context.mounted) return;
                    final currentLoc =
                        Provider.of<LocaleProvider>(context, listen: false);
                    widget.session.profile =
                        widget.session.profile.copyWith(position: pos);
                    showExpressiveSnackBar(context,
                        currentLoc.t('已刷新权限', 'Permissions refreshed'));
                  } catch (e) {
                    if (!context.mounted) return;
                    showExpressiveSnackBar(context, e.toString());
                  }
                },
                icon: const Icon(Icons.refresh_rounded),
                label: Text(loc.t('刷新职位信息', 'Refresh Position')),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        titleSpacing: (showDrawerButton || isPushed) ? 0 : 16.0,
        leadingWidth: (showDrawerButton || isPushed) ? 56.0 : 16.0,
        leading: isPushed
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
            : showDrawerButton
                ? Builder(
                    builder: (context) {
                      return IconButton(
                        icon: const Icon(Icons.menu),
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
        title: Text(loc.t('考勤点名', 'Roll Call')),
        backgroundColor: cs.surface,
        elevation: 0,
        centerTitle: false,
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
                    if (match.isNotEmpty) {
                      return match['name']!;
                    }
                    return val;
                  },
                  onSelected: (v) {
                    setState(() {
                      _selectedClass = v;
                      _selectedCourse = null;
                      _sessionId = null;
                      _batchStatus = '';
                    });
                    unawaited(_refreshDisplay());
                  },
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_initInFlight || _displayRefreshInFlight)
            const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: CustomScrollView(
              key: const ValueKey('content'),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_status.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Text(_status,
                                style: TextStyle(color: cs.error)),
                          ),
                        _buildDashboardGroup(cs, tt),
                        if (_sessionId != null) _buildBatchBar(cs, tt),
                      ],
                    ),
                  ),
                ),
                if (_displayStudents.isEmpty &&
                    !_initInFlight &&
                    !_displayRefreshInFlight)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline_rounded,
                                size: 64, color: cs.outlineVariant),
                            const SizedBox(height: 16),
                            Text(
                              loc.t('该班级暂无学生', 'No students in this class'),
                              style: tt.bodyLarge
                                  ?.copyWith(color: cs.onSurfaceVariant),
                            ),
                            if (_allStudents.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                '${loc.t('系统内共有', 'Total students in system')}: ${_allStudents.length} ${loc.t('名学生', 'students')}',
                                style: tt.labelMedium
                                    ?.copyWith(color: cs.onSurfaceVariant),
                              ),
                              Text(
                                '${loc.t('当前选中班级', 'Selected class')}: ${_selectedClass ?? 'None'} (ID: ${_resolveClassId(_selectedClass ?? '')})',
                                style: tt.labelSmall
                                    ?.copyWith(color: cs.onSurfaceVariant),
                              ),
                            ],
                            const SizedBox(height: 24),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              alignment: WrapAlignment.center,
                              children: [
                                FilledButton.tonalIcon(
                                  onPressed: () => unawaited(_initData()),
                                  icon: const Icon(Icons.refresh_rounded),
                                  label: Text(loc.t('刷新数据', 'Refresh Data')),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _selectedClass = null;
                                      _sessionId = null;
                                      _myClasses = [];
                                    });
                                    unawaited(_initData());
                                  },
                                  icon: const Icon(Icons.restart_alt_rounded),
                                  label: Text(loc.t('重置班级', 'Reset Class')),
                                ),
                              ],
                            ),
                            if (_allStudents.isNotEmpty &&
                                _displayStudents.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 32),
                                child: Text(
                                  loc.t('提示：请检查上方班级选择器是否正确',
                                      'Hint: Please check if the class selector above is correct'),
                                  style: tt.labelSmall
                                      ?.copyWith(color: cs.secondary),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  )
                else if (_displayStudents.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final s = _displayStudents[index];
                          return _StudentCard(
                            key: ValueKey(s.id),
                            student: s,
                            mark: _marking[s.id] ?? '',
                            avatarPath: _avatarMap[s.id] ?? '',
                            onMark: (status) {
                              _marking[s.id] = status;
                              unawaited(_submitMark(s, status));
                            },
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => StudentDetailPage(
                                    session: widget.session,
                                    student: s,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        childCount: _displayStudents.length,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardGroup(ColorScheme cs, TextTheme tt) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(32), // MD3 large shape
      ),
      child: Column(
        children: [
          _buildTimeInfoSection(cs, tt),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildHeaderSection(cs, tt),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildRecentHistorySection(cs, tt),
        ],
      ),
    );
  }

  Widget _buildRecentHistorySection(ColorScheme cs, TextTheme tt) {
    final loc = Provider.of<LocaleProvider>(context);
    final now = DateTime.now();
    bool isToday(String dateStr) {
      final s = dateStr.trim();
      if (s.isEmpty) return false;
      try {
        final dt = DateTime.parse(s).toLocal();
        return dt.year == now.year &&
            dt.month == now.month &&
            dt.day == now.day;
      } catch (_) {
        return s.startsWith(now.toIso8601String().substring(0, 10));
      }
    }

    final todaySessions = _allSessions.where((s) {
      final startedAt = s['started_at'] ?? '';
      if (!isToday(startedAt)) return false;
      final selectedClass = (_selectedClass ?? '').trim();
      if (selectedClass.isEmpty) return true;
      final sessionClassCode = _resolveSessionClassCode(s);
      return sessionClassCode.isEmpty || sessionClassCode == selectedClass;
    }).toList()
      ..sort((a, b) {
        final at = _parseFlexibleDateTime(a['started_at'] ?? '');
        final bt = _parseFlexibleDateTime(b['started_at'] ?? '');
        if (at == null && bt == null) return 0;
        if (at == null) return 1;
        if (bt == null) return -1;
        return bt.compareTo(at);
      });

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(loc.t('今日点名记录', 'Today\'s Attendance'),
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: _showHistorySheet,
                child: Text(loc.t('查看全部', 'View All')),
              ),
            ],
          ),
          if (todaySessions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(loc.t('今日暂无记录', 'No records today'),
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            )
          else
            ...todaySessions.take(3).map((s) {
              final displayTime = _formatDisplayDateTime(s['started_at'] ?? '');
              final isSelected = _sessionId == s['id'];

              final classCode = _resolveSessionClassCode(s);
              final className = classCode.isEmpty
                  ? ''
                  : (_classNameById[classCode] ?? classCode).trim();
              final courseName = _displayCourseName(s['course_id'] ?? '', loc);

              final shortDisplayName = className.isNotEmpty
                  ? '$className · $courseName'
                  : courseName;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SoftPressable(
                  duration: const Duration(milliseconds: 120),
                  pressedScale: 0.998,
                  pressedColor: cs.secondaryContainer.withValues(alpha: 96),
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => unawaited(_applyHistorySession(s)),
                  child: AnimatedContainer(
                    duration: kAppMotionDuration,
                    curve: kAppMotionCurve,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? cs.secondaryContainer.withValues(alpha: 214)
                          : cs.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12),
                      dense: true,
                      leading: Icon(
                        Icons.history_rounded,
                        size: 20,
                        color: isSelected
                            ? cs.onSecondaryContainer
                            : cs.onSurfaceVariant,
                      ),
                      title: Text(shortDisplayName, style: tt.bodyMedium),
                      subtitle: Text(displayTime, style: tt.labelSmall),
                      trailing: Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.chevron_right,
                        size: 16,
                        color:
                            isSelected ? cs.onSecondaryContainer : cs.outline,
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

  void _showHistorySheet({String? initialSessionId}) {
    final loc = Provider.of<LocaleProvider>(context, listen: false);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final groupedSessions = <String, List<Map<String, String>>>{};
    for (final s in _allSessions) {
      String date = 'Unknown';
      final dt = _parseFlexibleDateTime(s['started_at'] ?? '');
      if (dt != null) {
        date =
            '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      } else {
        date = s['started_at']?.split('T').first ?? 'Unknown';
      }
      groupedSessions.putIfAbsent(date, () => []).add(s);
    }
    for (final sessions in groupedSessions.values) {
      sessions.sort((a, b) {
        final at = _parseFlexibleDateTime(a['started_at'] ?? '');
        final bt = _parseFlexibleDateTime(b['started_at'] ?? '');
        if (at == null && bt == null) return 0;
        if (at == null) return 1;
        if (bt == null) return -1;
        return bt.compareTo(at);
      });
    }
    final sortedDates = groupedSessions.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    // Use a full-screen Dialog instead of BottomSheet to avoid black background issues
    showDialog(
      context: context,
      useSafeArea: false,
      builder: (ctx) {
        return Scaffold(
          backgroundColor: cs.surface,
          appBar: AppBar(
            backgroundColor: cs.surface,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(ctx),
            ),
            title: Text(
              loc.t('全部点名记录', 'All Attendance History'),
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
          ),
          body: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Text(
                  loc.t(
                    '选择一条记录后会同步切换当前课程与点名会话',
                    'Selecting a record switches the current course and session',
                  ),
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: sortedDates.length,
                  itemBuilder: (context, index) {
                    final date = sortedDates[index];
                    final sessions = groupedSessions[date]!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          color: cs.surfaceContainerHigh,
                          child: Text(date,
                              style: tt.labelLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: cs.primary)),
                        ),
                        ...sessions.map((s) {
                          final classCode = _resolveSessionClassCode(s);
                          final className = classCode.isEmpty
                              ? ''
                              : (_classNameById[classCode] ?? classCode).trim();
                          final courseName =
                              _displayCourseName(s['course_id'] ?? '', loc);
                          final shortDisplayName = className.isNotEmpty
                              ? '$className · $courseName'
                              : courseName;

                          final displayTime =
                              _formatDisplayDateTime(s['started_at'] ?? '');

                          final isSelected = initialSessionId == s['id'] ||
                              _sessionId == s['id'];
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                            child: Material(
                              color: isSelected
                                  ? cs.primaryContainer.withValues(alpha: 140)
                                  : cs.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(22),
                              child: ListTile(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(22)),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 4,
                                ),
                                title: Text(shortDisplayName,
                                    style: tt.bodyLarge?.copyWith(
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal)),
                                subtitle: Text(displayTime),
                                trailing: Icon(
                                  isSelected
                                      ? Icons.check_circle_rounded
                                      : Icons.chevron_right_rounded,
                                  color: isSelected
                                      ? cs.primary
                                      : cs.onSurfaceVariant,
                                ),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  unawaited(_applyHistorySession(s));
                                },
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimeInfoSection(ColorScheme cs, TextTheme tt) {
    final loc = Provider.of<LocaleProvider>(context);
    final activeName = _activeCourse != null
        ? (_allCourses
                .where((c) => c.id == _activeCourse!.courseId)
                .firstOrNull
                ?.courseName ??
            loc.t('未知', 'Unknown'))
        : loc.t('无', 'None');
    final nextName = _nextCourse != null
        ? (_allCourses
                .where((c) => c.id == _nextCourse!.courseId)
                .firstOrNull
                ?.courseName ??
            loc.t('未知', 'Unknown'))
        : loc.t('无', 'None');

    final nowStr =
        '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}';

    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: isDesktop
          ? Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(Icons.schedule_rounded,
                      size: 32, color: cs.onPrimaryContainer),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${loc.t('当前时间', 'Current time')} $nowStr',
                          style: tt.titleMedium?.copyWith(
                              color: cs.onSurface,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('${loc.t('当前课程:', 'Current course:')} $activeName',
                          style: tt.bodyMedium
                              ?.copyWith(color: cs.onSurfaceVariant)),
                      Text('${loc.t('下节课程:', 'Next course:')} $nextName',
                          style: tt.bodySmall?.copyWith(
                              color:
                                  cs.onSurfaceVariant.withValues(alpha: 204))),
                    ],
                  ),
                ),
                if (_sessionId == null)
                  FilledButton.icon(
                    onPressed: () async {
                      if (_selectedCourse == null) {
                        showExpressiveSnackBar(context,
                            loc.t('请先选择课程', 'Please select a course first'));
                        return;
                      }
                      final oldSessionId = _sessionId;
                      try {
                        await _startSession(silent: false);
                        await _refreshDisplay();
                        if (mounted) {
                          showExpressiveSnackBar(
                              context,
                              loc.t(
                                  '已生成新点名记录', 'New attendance record created'));
                        }
                      } catch (e) {
                        if (mounted) {
                          setState(() => _sessionId = oldSessionId);
                          showExpressiveSnackBar(context,
                              '${loc.t('创建失败', 'Failed to create')}: $e');
                        }
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: Text(loc.t('新建点名', 'Start Roll Call')),
                  ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(Icons.schedule_rounded,
                          size: 24, color: cs.onPrimaryContainer),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${loc.t('当前时间', 'Current time')} $nowStr',
                              style: tt.titleSmall?.copyWith(
                                  color: cs.onSurface,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(
                              '${loc.t('当前课程:', 'Current course:')} $activeName',
                              style: tt.bodySmall
                                  ?.copyWith(color: cs.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('${loc.t('下节课程:', 'Next course:')} $nextName',
                    style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant.withValues(alpha: 204))),
                if (_sessionId == null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        if (_selectedCourse == null) {
                          showExpressiveSnackBar(context,
                              loc.t('请先选择课程', 'Please select a course first'));
                          return;
                        }
                        final oldSessionId = _sessionId;
                        try {
                          await _startSession(silent: false);
                          await _refreshDisplay();
                          if (mounted) {
                            showExpressiveSnackBar(
                                context,
                                loc.t('已生成新点名记录',
                                    'New attendance record created'));
                          }
                        } catch (e) {
                          if (mounted) {
                            setState(() => _sessionId = oldSessionId);
                            showExpressiveSnackBar(context,
                                '${loc.t('创建失败', 'Failed to create')}: $e');
                          }
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: Text(loc.t('新建点名', 'Start Roll Call')),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildHeaderSection(ColorScheme cs, TextTheme tt) {
    final loc = Provider.of<LocaleProvider>(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          ExpressiveSelector(
            label: loc.t('课程', 'Course'),
            value: _selectedCourse?.courseName,
            items: _displayCourses.map((c) => c.courseName).toList(),
            backgroundColor: cs.tertiaryContainer,
            foregroundColor: cs.onTertiaryContainer,
            onSelected: (v) {
              final course =
                  _displayCourses.where((c) => c.courseName == v).firstOrNull;
              if (course != null) {
                setState(() {
                  _selectedCourse = course;
                  _sessionId = null; // Reset session when changing course
                });
                unawaited(_rememberCourseSelection(course.id, manual: true));
                unawaited(_refreshDisplay());
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBatchBar(ColorScheme cs, TextTheme tt) {
    final loc = Provider.of<LocaleProvider>(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FilledButton.tonal(
            onPressed: (_batchSubmitting || _batchDisabled)
                ? null
                : () async {
                    setState(() {
                      _batchDisabled = true;
                      _batchStatus = 'present';
                    });
                    await _applyBatchToAll(submitIfStarted: true);
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (mounted) setState(() => _batchDisabled = false);
                    });
                  },
            child: Text(
              _batchSubmitting
                  ? loc.t('提交中', 'Submitting')
                  : loc.t('全勤', 'Full attendance'),
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: (_batchSubmitting || _batchDisabled)
                ? null
                : () async {
                    setState(() {
                      _batchDisabled = true;
                      _batchStatus = '';
                      for (final s in _displayStudents) {
                        _marking[s.id] = '';
                      }
                    });
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (mounted) setState(() => _batchDisabled = false);
                    });
                  },
            child: Text(loc.t('全部重置', 'Reset all')),
          ),
        ],
      ),
    );
  }
}

class _StudentCard extends StatefulWidget {
  final Student student;
  final String mark;
  final String avatarPath;
  final Function(String) onMark;
  final VoidCallback? onTap;

  const _StudentCard({
    super.key,
    required this.student,
    required this.mark,
    required this.avatarPath,
    required this.onMark,
    this.onTap,
  });

  @override
  State<_StudentCard> createState() => _StudentCardState();
}

class _StudentCardState extends State<_StudentCard> {
  late String _currentMark;

  DecorationImage? _getAvatarImage(String path) {
    final provider = AvatarImageProvider.get(path);
    if (provider == null) return null;
    return DecorationImage(
      image: provider,
      fit: BoxFit.cover,
    );
  }

  @override
  void initState() {
    super.initState();
    _currentMark = widget.mark;
  }

  @override
  void didUpdateWidget(_StudentCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mark != oldWidget.mark) {
      _currentMark = widget.mark;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.student;
    final mark = _currentMark;
    final isMarked = mark.isNotEmpty;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final loc = Provider.of<LocaleProvider>(context);
    final isDesktop = MediaQuery.of(context).size.width >= 600;
    final avatarImage = _getAvatarImage(widget.avatarPath);

    Widget buildStatusButton(String value, IconData icon, String label) {
      final isSelected = mark == value;
      return Expanded(
        child: FilledButton.tonal(
          onPressed: () {
            final newMark = isSelected ? '' : value;

            // To prevent state bouncing, optimistically update UI
            setState(() {
              _currentMark = newMark;
            });
            widget.onMark(newMark);
          },
          style: FilledButton.styleFrom(
            backgroundColor:
                isSelected ? cs.primary : cs.surfaceContainerHighest,
            foregroundColor: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
            padding: EdgeInsets.symmetric(vertical: isDesktop ? 12 : 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: isDesktop ? 20 : 24),
              if (isDesktop) ...[
                const SizedBox(width: 8),
                Text(label,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ]
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isMarked
            ? cs.primaryContainer.withValues(alpha: 77)
            : cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border:
                              Border.all(color: Colors.grey.shade200, width: 1),
                          image: avatarImage,
                        ),
                        alignment: Alignment.center,
                        child: avatarImage == null
                            ? Text(s.fullName.substring(0, 1),
                                style:
                                    tt.titleLarge?.copyWith(color: cs.primary))
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.fullName, style: tt.titleLarge),
                          Text(
                            s.displayClassLabel.isNotEmpty
                                ? '${s.studentNo} · ${s.displayClassLabel}'
                                : s.studentNo,
                            style: tt.bodyMedium
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  buildStatusButton('present', Icons.check_circle_rounded,
                      loc.t('已到', 'Present')),
                  const SizedBox(width: 8),
                  buildStatusButton('late', Icons.access_time_filled_rounded,
                      loc.t('迟到', 'Late')),
                  const SizedBox(width: 8),
                  buildStatusButton(
                      'absent', Icons.cancel_rounded, loc.t('缺勤', 'Absent')),
                  const SizedBox(width: 8),
                  buildStatusButton(
                      'leave', Icons.event_busy_rounded, loc.t('请假', 'Leave')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
