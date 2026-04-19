import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/course.dart';
import '../models/student.dart';
import '../models/timetable_item.dart';
import '../main.dart';
import '../services/local_profiles.dart';
import '../state/session.dart';
import '../widgets/expressive_ui.dart';

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
  bool _loading = true;
  String _status = '';
  bool _dataReady = true;

  List<Course> _allCourses = [];
  List<TimetableItem> _allTimetable = [];
  List<Student> _allStudents = [];

  List<String> _myClasses = [];
  String? _selectedClass;

  List<Course> _displayCourses = [];
  Course? _selectedCourse;

  List<Student> _displayStudents = [];

  String _batchStatus = '';
  bool _batchSubmitting = false;

  String? _sessionId;
  final Map<String, String> _marking = {};

  TimetableItem? _activeCourse;
  TimetableItem? _nextCourse;

  List<Map<String, String>> _allSessions = [];

  @override
  void initState() {
    super.initState();
    widget.session.addListener(_onSessionChanged);
    _initData();
  }

  @override
  void dispose() {
    widget.session.removeListener(_onSessionChanged);
    super.dispose();
  }

  void _onSessionChanged() {
    if (mounted) {
      _initData(isBackground: true);
    }
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

  Future<void> _initData({bool isBackground = false}) async {
    // Notify ShellPage that we are ready to show IMMEDIATELY to avoid transition lag
    if (widget.onReady != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onReady?.call();
      });
    }

    // Completely avoid loading state if we already have some data
    if (!isBackground && !_dataReady) {
      setState(() {
        _status = '';
      });
    }

    // Ensure data schema is up-to-date
    // Removed old schema update methods

    if (widget.session.isTeacher) {
      _myClasses = await LocalProfiles.getTeacherClasses(
        widget.session.dataDir,
        widget.session.profile.id,
      );
    } else {
      _myClasses = [widget.session.profile.classCode.trim()];
    }

    try {
      if (_myClasses.isNotEmpty && _selectedClass == null) {
        _selectedClass = _myClasses.first;
      }

      // 2. Fetch all necessary data in parallel to reduce first paint latency
      final coursesFuture = widget.session.features.listCourses();
      final ttFuture = widget.session.features.listTimetable();
      final studentsFuture = widget.session.features.listStudents();
      final coursesRes = await coursesFuture;
      final ttRes = await ttFuture;
      final studentsRes = await studentsFuture;

      if (coursesRes['ok'] == true) {
        final items = (coursesRes['data']?['items'] as List?) ?? [];
        _allCourses = items.map((e) => Course.fromJson(e)).toList();
      }

      if (ttRes['ok'] == true) {
        final items = (ttRes['data']?['items'] as List?) ?? [];
        _allTimetable = items.map((e) => TimetableItem.fromJson(e)).toList();
      }

      if (studentsRes['ok'] == true) {
        final items = (studentsRes['data']?['items'] as List?) ?? [];
        final uniqueStudents = <String, Student>{};
        for (final e in items) {
          final s = Student.fromJson(e);
          final key = s.studentNo.trim().toLowerCase();
          if (key.isNotEmpty) {
            // Keep the one that has a position if possible
            if (uniqueStudents.containsKey(key)) {
              if (s.position.isNotEmpty &&
                  uniqueStudents[key]!.position.isEmpty) {
                uniqueStudents[key] = s;
              }
            } else {
              uniqueStudents[key] = s;
            }
          } else {
            // If no student number, use ID as fallback for uniqueness
            uniqueStudents[s.id] = s;
          }
        }
        _allStudents = uniqueStudents.values.toList();
      }

      final sessionsRes = await widget.session.features
          .csvOp(action: 'read', file: 'attendance_sessions.csv');

      if (sessionsRes['ok'] == true) {
        final items =
            ((sessionsRes['data'] ?? const {})['items'] as List?) ?? [];
        _allSessions =
            items.map((e) => (e as Map).cast<String, String>()).toList();
      }

      if (!mounted) return;
      await _refreshDisplay();
      if (!mounted) return;
      setState(() {
        _loading = false; // Always clear loading after success
        _dataReady = true;
      });
      widget.onReady?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _dataReady = true;
        _status = e.toString();
      });
      widget.onReady?.call();
    }
  }

  Future<void> _refreshDisplay() async {
    if (_selectedClass == null) {
      if (mounted) setState(() => _loading = false);
      widget.onReady?.call();
      return;
    }

    // Filter students for the selected class
    _displayStudents = _allStudents
        .where((s) => s.classCode.trim() == _selectedClass)
        .toList();
    _displayStudents.sort((a, b) => a.studentNo.compareTo(b.studentNo));

    // Determine today's schedule for this class or teacher
    final today = _weekdayNow();
    final now = DateTime.now();
    final nowMin = now.hour * 60 + now.minute;

    // A course is relevant if it's assigned to this class OR this teacher
    final relevantTt = _allTimetable.where((e) {
      final isMyClass = e.ownerProfileId == 'class_$_selectedClass';
      final isMyCourse = e.createdByProfileId == widget.session.profile.id;
      // Also include courses that belong to the current class even if created by someone else
      // This allows cadres to take attendance for courses in their class.
      return isMyClass || (widget.session.isTeacher && isMyCourse);
    }).toList();

    final todayTt = relevantTt.where((e) => e.weekday == today).toList();
    todayTt.sort((a, b) =>
        _hhmmToMinutes(a.startTime).compareTo(_hhmmToMinutes(b.startTime)));

    // Smart matching
    TimetableItem? active;
    TimetableItem? next;
    for (var i = 0; i < todayTt.length; i++) {
      final it = todayTt[i];
      final s = _hhmmToMinutes(it.startTime);
      final e = _hhmmToMinutes(it.endTime);
      if (nowMin >= s && nowMin <= e) {
        active = it;
        // next is the one right after this
        if (i + 1 < todayTt.length) {
          next = todayTt[i + 1];
        }
        break;
      }
    }

    // If no course is currently happening, pick the next one today
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

    // Filter courses that appear in the relevant timetable
    final relevantCourseIds = relevantTt.map((e) => e.courseId).toSet();
    _displayCourses =
        _allCourses.where((c) => relevantCourseIds.contains(c.id)).toList();

    // Fallback if no specific course selected via widget
    if (_selectedCourse == null) {
      if (widget.courseId != null) {
        _selectedCourse =
            _allCourses.where((c) => c.id == widget.courseId).firstOrNull;
      } else if (active != null) {
        _selectedCourse =
            _allCourses.where((c) => c.id == active!.courseId).firstOrNull;
      }
    }

    // Ensure _selectedCourse is in _displayCourses, otherwise pick first
    if (_selectedCourse != null && !_displayCourses.contains(_selectedCourse)) {
      _selectedCourse = null;
    }

    if (_selectedCourse == null && _displayCourses.isNotEmpty) {
      _selectedCourse = _displayCourses.first;
    }

    // Try to restore session
    String? restoredSessionId;
    final marks = <String, String>{};
    final studentsOnLeaveToday = <String>{};

    if (_selectedCourse != null && _sessionId == null) {
      try {
        final sessionsFile =
            File('${widget.session.dataDir}/attendance_sessions.csv');
        if (await sessionsFile.exists()) {
          final sContent = await sessionsFile.readAsString();
          final sLines =
              sContent.split('\n').where((l) => l.trim().isNotEmpty).toList();

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

          if (sLines.length > 1) {
            for (var i = 1; i < sLines.length; i++) {
              final parts = sLines[i].split(',');
              if (parts.length >= 4) {
                final id = parts[0];
                final cid = parts[1];
                final startedAt = parts[3];

                if (isToday(startedAt)) {
                  todaySessionIds.add(id);
                  if (cid == _selectedCourse!.id) {
                    restoredSessionId = id;
                  }
                }
              }
            }
          }

          if (todaySessionIds.isNotEmpty) {
            final recordsFile =
                File('${widget.session.dataDir}/attendance_records.csv');
            if (await recordsFile.exists()) {
              final content = await recordsFile.readAsString();
              final lines = content
                  .split('\n')
                  .where((l) => l.trim().isNotEmpty)
                  .toList();
              if (lines.length > 1) {
                for (var i = 1; i < lines.length; i++) {
                  final parts = lines[i].split(',');
                  if (parts.length >= 4) {
                    final sid = parts[1];
                    final studentId = parts[2];
                    final status = parts[3];
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
              }
            }
          }
        }
      } catch (_) {}
    } else if (_sessionId != null) {
      // Load specific session
      restoredSessionId = _sessionId;
      try {
        final recordsFile =
            File('${widget.session.dataDir}/attendance_records.csv');
        if (await recordsFile.exists()) {
          final content = await recordsFile.readAsString();
          final lines =
              content.split('\n').where((l) => l.trim().isNotEmpty).toList();
          if (lines.length > 1) {
            for (var i = 1; i < lines.length; i++) {
              final parts = lines[i].split(',');
              if (parts.length >= 4) {
                final sid = parts[1];
                final studentId = parts[2];
                final status = parts[3];
                if (sid == restoredSessionId) {
                  marks[studentId] = status;
                }
              }
            }
          }
        }
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
      _dataReady = true;
      _sessionId = restoredSessionId;
      _marking.clear();
      for (final s in _displayStudents) {
        _marking[s.id] = marks[s.id] ??
            (studentsOnLeaveToday.contains(s.id) ? 'leave' : _batchStatus);
      }
    });
    widget.onReady?.call();

    // Auto-start session if none exists to allow direct marking
    if (_sessionId == null && _selectedCourse != null) {
      await _startSession();
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

    if (!silent) {
      if (!mounted) return;
      setState(() {
        _loading = true;
        _status = '';
      });
    }

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
          _loading = false;
        });
      } else {
        if (!mounted) return;
        final loc = Provider.of<LocaleProvider>(context, listen: false);
        throw res['error']?['message'] ??
            loc.t('启动点名失败', 'Failed to start attendance');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _status = e.toString();
      });
      widget.onReady?.call();
    }
  }

  Future<void> _submitMark(Student s, String status) async {
    if (_sessionId == null) {
      await _startSession(silent: true);
    }
    if (_sessionId == null) return;

    try {
      await widget.session.features.markAttendanceRecord(
        sessionId: _sessionId!,
        studentId: s.id,
        status: status,
        markedByProfileId: widget.session.profile.id,
      );
    } catch (e) {
      debugPrint('Mark error: $e');
    }
  }

  Future<void> _applyBatchToAll({required bool submitIfStarted}) async {
    if (_displayStudents.isEmpty) return;

    if (submitIfStarted && _sessionId == null && _selectedCourse != null) {
      await _startSession();
    }

    if (submitIfStarted && _sessionId == null) return;

    setState(() {
      _batchSubmitting = submitIfStarted;
      for (final s in _displayStudents) {
        _marking[s.id] = _batchStatus;
      }
    });

    if (!submitIfStarted) return;

    for (final s in _displayStudents) {
      if (!mounted) return;
      await _submitMark(s, _batchStatus);
    }

    if (mounted) {
      setState(() => _batchSubmitting = false);
      final loc = Provider.of<LocaleProvider>(context, listen: false);
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

    final loader = Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
        ),
      ),
    );

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
        backgroundColor: Colors.transparent,
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
                  setState(() => _loading = true);
                  try {
                    final pos = await LocalProfiles.loadStudentPosition(
                      dataDir: widget.session.dataDir,
                      profile: widget.session.profile,
                    );
                    if (!mounted) return;
                    widget.session.profile =
                        widget.session.profile.copyWith(position: pos);
                    showExpressiveSnackBar(
                        context, loc.t('已刷新权限', 'Permissions refreshed'));
                  } catch (e) {
                    if (!mounted) return;
                    showExpressiveSnackBar(context, e.toString());
                  } finally {
                    if (mounted) setState(() => _loading = false);
                  }
                },
                icon: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh_rounded),
                label: Text(loc.t('刷新职位信息', 'Refresh Position')),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
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
        title: Text(loc.t('考勤点名', 'Roll Call'),
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
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
                  onSelected: (v) {
                    setState(() {
                      _selectedClass = v;
                      _loading = true;
                    });
                    _refreshDisplay();
                  },
                ),
              ),
            ),
        ],
      ),
      body: !_dataReady
          ? loader
          : Stack(
              children: [
                CustomScrollView(
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
                            _buildBatchBar(cs, tt),
                          ],
                        ),
                      ),
                    ),
                    if (_displayStudents.isEmpty && !_loading)
                      SliverFillRemaining(
                        child: Center(
                          child: Text(
                              loc.t('该班级暂无学生', 'No students in this class'),
                              style: tt.bodyLarge),
                        ),
                      )
                    else if (_displayStudents.isEmpty && _loading)
                      SliverFillRemaining(
                        child: const SizedBox.shrink(),
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
                                onMark: (status) {
                                  _marking[s.id] = status;
                                  _submitMark(s, status);
                                },
                              );
                            },
                            childCount: _displayStudents.length,
                          ),
                        ),
                      ),
                  ],
                ),
                if (_loading)
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(),
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
      return isToday(startedAt);
    }).toList();

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
                onPressed: _showFullHistory,
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
              final course =
                  _allCourses.where((c) => c.id == s['course_id']).firstOrNull;
              final cName = course?.courseName ??
                  s['course_id'] ??
                  loc.t('未知课程', 'Unknown Course');
              final ttItem = _allTimetable
                  .where((t) => t.courseId == s['course_id'])
                  .firstOrNull;
              String className = '';
              if (ttItem != null &&
                  ttItem.ownerProfileId.startsWith('class_')) {
                className = ttItem.ownerProfileId.replaceFirst('class_', '');
              }
              String date = '';
              String time = '';
              try {
                final dt = DateTime.parse(s['started_at']!).toLocal();
                date =
                    '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
                time =
                    '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
              } catch (_) {
                date = s['started_at']?.split('T').first ?? '';
                time = s['started_at']?.split('T').last.substring(0, 5) ?? '';
              }
              final displayName = className.isNotEmpty
                  ? '$className-$cName-$date'
                  : '$cName-$date';
              return ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading:
                    Icon(Icons.history_rounded, size: 20, color: cs.primary),
                title: Text(displayName, style: tt.bodyMedium),
                subtitle: Text(time, style: tt.labelSmall),
                trailing:
                    Icon(Icons.chevron_right, size: 16, color: cs.outline),
                onTap: () {
                  setState(() {
                    _sessionId = s['id'];
                    _selectedCourse = _allCourses.firstWhere(
                        (c) => c.id == s['course_id'],
                        orElse: () => _selectedCourse!);
                  });
                  _initData();
                },
              );
            }),
        ],
      ),
    );
  }

  void _showFullHistory() {
    final loc = Provider.of<LocaleProvider>(context, listen: false);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final groupedSessions = <String, List<Map<String, String>>>{};
    for (final s in _allSessions) {
      String date = 'Unknown';
      try {
        final dt = DateTime.parse(s['started_at']!).toLocal();
        date =
            '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      } catch (_) {
        date = s['started_at']?.split('T').first ?? 'Unknown';
      }
      groupedSessions.putIfAbsent(date, () => []).add(s);
    }
    final sortedDates = groupedSessions.keys.toList()
      ..sort((a, b) => b.compareTo(a));

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
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(loc.t('全部点名记录', 'All Attendance History'),
                      style: tt.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
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
                                horizontal: 24, vertical: 8),
                            color: cs.surfaceContainerHigh,
                            child: Text(date,
                                style: tt.labelLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: cs.primary)),
                          ),
                          ...sessions.map((s) {
                            final course = _allCourses
                                .where((c) => c.id == s['course_id'])
                                .firstOrNull;
                            final cName = course?.courseName ??
                                s['course_id'] ??
                                loc.t('未知课程', 'Unknown Course');
                            final ttItem = _allTimetable
                                .where((t) => t.courseId == s['course_id'])
                                .firstOrNull;
                            String className = '';
                            if (ttItem != null &&
                                ttItem.ownerProfileId.startsWith('class_')) {
                              className = ttItem.ownerProfileId
                                  .replaceFirst('class_', '');
                            }
                            String date = '';
                            String time = '';
                            try {
                              final dt =
                                  DateTime.parse(s['started_at']!).toLocal();
                              date =
                                  '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
                              time =
                                  '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                            } catch (_) {
                              date = s['started_at']?.split('T').first ?? '';
                              time = s['started_at']
                                      ?.split('T')
                                      .last
                                      .substring(0, 5) ??
                                  '';
                            }
                            final displayName = className.isNotEmpty
                                ? '$className-$cName-$date'
                                : '$cName-$date';
                            return ListTile(
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              title: Text(displayName),
                              subtitle: Text(time),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.pop(ctx);
                                setState(() {
                                  _sessionId = s['id'];
                                  _selectedCourse = _allCourses.firstWhere(
                                      (c) => c.id == s['course_id'],
                                      orElse: () => _selectedCourse!);
                                });
                                _initData();
                              },
                            );
                          }),
                        ],
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

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
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
                        color: cs.onSurface, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                    '${loc.t('当前课程:', 'Current course:')} $activeName ${_activeCourse != null ? '(${_activeCourse!.startTime} - ${_activeCourse!.endTime})' : ''}',
                    style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                Text(
                    '${loc.t('下节课程:', 'Next course:')} $nextName ${_nextCourse != null ? '(${_nextCourse!.startTime} - ${_nextCourse!.endTime})' : ''}',
                    style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant.withValues(alpha: 204))),
              ],
            ),
          ),
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
                  _loading = true;
                });
                _refreshDisplay();
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
        color: cs.surfaceContainerHighest.withValues(alpha: 128),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 77)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FilledButton.tonal(
            onPressed: _batchSubmitting
                ? null
                : () {
                    setState(() => _batchStatus = 'present');
                    _applyBatchToAll(submitIfStarted: true);
                  },
            child: _batchSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(loc.t('全勤', 'Full attendance')),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: _batchSubmitting
                ? null
                : () {
                    setState(() {
                      _batchStatus = '';
                      for (final s in _displayStudents) {
                        _marking[s.id] = '';
                      }
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
  final Function(String) onMark;

  const _StudentCard({
    super.key,
    required this.student,
    required this.mark,
    required this.onMark,
  });

  @override
  State<_StudentCard> createState() => _StudentCardState();
}

class _StudentCardState extends State<_StudentCard> {
  late String _currentMark;

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

    Widget buildStatusButton(String value, IconData icon, String label) {
      final isSelected = mark == value;
      return Expanded(
        child: FilledButton.tonal(
          onPressed: () {
            final newMark = isSelected ? '' : value;
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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isMarked
            ? cs.primaryContainer.withValues(alpha: 77)
            : cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isMarked
              ? cs.primary.withValues(alpha: 128)
              : cs.outlineVariant.withValues(alpha: 77),
          width: isMarked ? 2 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isMarked ? cs.primary : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: isMarked ? cs.primary : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: isMarked
                              ? null
                              : Border.all(color: cs.outlineVariant, width: 1),
                        ),
                        alignment: Alignment.center,
                        child: Text(s.fullName.substring(0, 1),
                            style: tt.titleLarge?.copyWith(
                                color: isMarked
                                    ? cs.onPrimary
                                    : cs.onPrimaryContainer,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.fullName,
                              style: tt.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          Text(s.studentNo,
                              style: tt.bodyMedium
                                  ?.copyWith(color: cs.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ],
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
                    buildStatusButton('leave', Icons.event_busy_rounded,
                        loc.t('请假', 'Leave')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
