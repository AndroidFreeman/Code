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
  bool _dataReady = false;

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

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
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

  Future<void> _initData() async {
    if (!widget.session.canTakeAttendance) {
      final loc = Provider.of<LocaleProvider>(context, listen: false);
      setState(() {
        _loading = false;
        _status = loc.t('当前角色无点名权限',
            'Your role does not have permission to take attendance');
      });
      widget.onReady?.call();
      return;
    }

    setState(() {
      _loading = true;
      _status = '';
    });

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
          uniqueStudents[s.studentNo] = s;
        }
        _allStudents = uniqueStudents.values.toList();
      }

      if (!mounted) return;
      await _refreshDisplay();
      if (!mounted) return;
      setState(() {
        _dataReady = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
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

    if (_selectedCourse != null) {
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
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
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

  Future<void> _startSession() async {
    if (_selectedCourse == null) return;

    if (!mounted) return;
    setState(() {
      _loading = true;
      _status = '';
    });

    try {
      final res = await widget.session.features.startAttendanceSession(
        courseId: _selectedCourse!.id,
        createdByProfileId: widget.session.profile.id,
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
      await _startSession();
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
      body: (!_dataReady || _loading)
          ? loader
          : CustomScrollView(
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
                if (_displayStudents.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Text(loc.t('该班级暂无学生', 'No students in this class'),
                          style: tt.bodyLarge),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            _buildStudentCard(_displayStudents[index], cs, tt),
                        childCount: _displayStudents.length,
                      ),
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
        ],
      ),
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

  Widget _buildStudentCard(Student s, ColorScheme cs, TextTheme tt) {
    final mark = _marking[s.id] ?? '';
    final isMarked = mark.isNotEmpty;
    final loc = Provider.of<LocaleProvider>(context);
    final isDesktop = MediaQuery.of(context).size.width >= 600;

    Widget buildStatusButton(String value, IconData icon, String label) {
      final isSelected = mark == value;
      return Expanded(
        child: FilledButton.tonal(
          onPressed: () {
            final newMark = isSelected ? '' : value;
            setState(() {
              _marking[s.id] = newMark;
            });
            if (newMark.isNotEmpty) {
              _submitMark(s, newMark);
            }
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
      duration: const Duration(milliseconds: 600),
      curve: Curves.fastOutSlowIn,
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
                    _buildStatusChip(mark, cs, loc),
                  ],
                ),
                const SizedBox(height: 20),
                if (isDesktop)
                  Row(
                    children: [
                      buildStatusButton('present', Icons.check_circle_rounded,
                          loc.t('出勤', 'Present')),
                      const SizedBox(width: 8),
                      buildStatusButton(
                          'late', Icons.schedule_rounded, loc.t('迟到', 'Late')),
                      const SizedBox(width: 8),
                      buildStatusButton('absent', Icons.cancel_rounded,
                          loc.t('缺勤', 'Absent')),
                      const SizedBox(width: 8),
                      buildStatusButton('leave', Icons.beach_access_rounded,
                          loc.t('请假', 'Leave')),
                    ],
                  )
                else
                  Column(
                    children: [
                      Row(
                        children: [
                          buildStatusButton(
                              'present',
                              Icons.check_circle_rounded,
                              loc.t('出勤', 'Present')),
                          const SizedBox(width: 8),
                          buildStatusButton('late', Icons.schedule_rounded,
                              loc.t('迟到', 'Late')),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          buildStatusButton('absent', Icons.cancel_rounded,
                              loc.t('缺勤', 'Absent')),
                          const SizedBox(width: 8),
                          buildStatusButton('leave', Icons.beach_access_rounded,
                              loc.t('请假', 'Leave')),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String mark, ColorScheme cs, LocaleProvider loc) {
    Color color;
    String label;
    switch (mark) {
      case 'present':
        color = Colors.green;
        label = loc.t('已到', 'Present');
        break;
      case 'late':
        color = Colors.orange;
        label = loc.t('迟到', 'Late');
        break;
      case 'absent':
        color = Colors.red;
        label = loc.t('缺勤', 'Absent');
        break;
      case 'leave':
        color = Colors.blue;
        label = loc.t('请假', 'Leave');
        break;
      default:
        color = cs.outline;
        label = loc.t('未记', 'Unmarked');
    }

    final textColor = Color.lerp(color, cs.onSurface, 0.75) ?? cs.onSurface;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 26),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 128)),
      ),
      child: Text(label,
          style: TextStyle(
              color: textColor, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}
