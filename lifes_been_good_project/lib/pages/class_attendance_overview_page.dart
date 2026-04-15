import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import '../models/student.dart';
import '../main.dart';
import '../services/local_profiles.dart';
import '../state/session.dart';
import '../widgets/expressive_ui.dart';
import 'student_detail_page.dart';

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
  String _status = '';
  List<String> _myClasses = [];
  String _selectedClass = '';
  List<_Row> _rows = [];
  bool _isListExpanded = false;

  int get totalPresent {
    return _rows.fold(0, (sum, r) => sum + r.present);
  }

  int get totalLate {
    return _rows.fold(0, (sum, r) => sum + r.late);
  }

  int get totalAbsent {
    return _rows.fold(0, (sum, r) => sum + r.absent);
  }

  int get totalLeave {
    return _rows.fold(0, (sum, r) => sum + r.leave);
  }

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<List<Map<String, String>>> _readCsvRows(String filename) async {
    final res =
        await widget.session.features.csvOp(action: 'read', file: filename);
    if (res['ok'] != true) return [];
    final items = ((res['data'] ?? const {})['items'] as List?) ?? const [];
    return items.map((e) => (e as Map).cast<String, String>()).toList();
  }

  Future<List<Student>> _loadStudents() async {
    Map<String, dynamic> studentsRes;
    if (await widget.session.features.hasFeature('students_list')) {
      studentsRes = await widget.session.features.listStudents();
    } else {
      final cli = widget.session.cli;
      if (cli == null) return const [];
      studentsRes = await cli.call('students.list', {});
    }
    if (studentsRes['ok'] != true) return const [];

    final raw = (((studentsRes['data'] ?? const {}) as Map)['items'] ??
        const []) as List;
    final uniqueStudents = <String, Student>{};
    for (final e in raw) {
      final s = Student.fromJson((e as Map).cast<String, dynamic>());
      uniqueStudents[s.studentNo] = s;
    }
    return uniqueStudents.values.toList();
  }

  Future<void> _refresh() async {
    if (!widget.session.canViewStudents) {
      final loc = Provider.of<LocaleProvider>(context, listen: false);
      setState(() {
        _loading = false;
        _status = loc.t('当前角色无查看班级考勤权限',
            'Your role does not have permission to view class attendance');
      });
      widget.onReady?.call();
      return;
    }

    setState(() {
      _loading = true;
      _status = '';
    });

    try {
      final classes = await LocalProfiles.getTeacherClasses(
        widget.session.dataDir,
        widget.session.profile.id,
      );

      final students = await _loadStudents();
      var sel = _selectedClass;
      if (sel.isEmpty || !classes.contains(sel)) {
        sel = classes.isNotEmpty ? classes.first : '';
      }

      final filtered = sel.isEmpty
          ? <Student>[]
          : students
              .where((s) => s.classCode.trim() == sel)
              .toList(growable: false);

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

      final sessions = await _readCsvRows('attendance_sessions.csv');
      final records = await _readCsvRows('attendance_records.csv');

      // Find all students on leave today across ALL sessions
      final allTodaySessionIds = sessions
          .where((s) => isToday(s['started_at'] ?? ''))
          .map((s) => (s['id'] ?? '').trim())
          .toSet();

      final studentsOnLeaveToday = <String>{};
      for (final r in records) {
        final sid = (r['session_id'] ?? '').trim();
        final studentId = (r['student_id'] ?? '').trim();
        final status = (r['status'] ?? '').trim();
        if (allTodaySessionIds.contains(sid) && status == 'leave') {
          studentsOnLeaveToday.add(studentId);
        }
      }

      // Keep only the latest record for each (course_id, student_id) in CURRENT sessions
      final sessionToCourse = <String, String>{};
      for (final s in sessions) {
        if (isToday(s['started_at'] ?? '')) {
          final sId = (s['id'] ?? '').trim();
          sessionToCourse[sId] = (s['course_id'] ?? '').trim();
        }
      }

      final latestRecords = <String, Map<String, String>>{};
      for (final r in records) {
        final sessionId = (r['session_id'] ?? '').trim();
        final studentId = (r['student_id'] ?? '').trim();
        if (sessionId.isNotEmpty &&
            studentId.isNotEmpty &&
            sessionToCourse.containsKey(sessionId)) {
          final courseId = sessionToCourse[sessionId];
          latestRecords['$courseId-$studentId'] = r;
        }
      }

      final counts = <String, Map<String, int>>{};
      for (final r in latestRecords.values) {
        final sid = (r['student_id'] ?? '').trim();
        if (sid.isEmpty) continue;
        final st = (r['status'] ?? '').trim();
        final m = counts.putIfAbsent(
            sid, () => {'present': 0, 'late': 0, 'absent': 0, 'leave': 0});
        if (st == 'present' ||
            st == 'late' ||
            st == 'absent' ||
            st == 'leave') {
          m[st] = (m[st] ?? 0) + 1;
        }
      }

      final rows = filtered.map((s) {
        final m =
            counts[s.id] ?? {'present': 0, 'late': 0, 'absent': 0, 'leave': 0};

        return _Row(
          student: s,
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
        _myClasses = classes;
        _selectedClass = sel;
        _rows = rows;
      });
      widget.onReady?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _status = e.toString();
      });
      widget.onReady?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final loc = Provider.of<LocaleProvider>(context);
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final showDrawerButton =
        (!isDesktop || isPortrait) && !(Platform.isAndroid && isTablet);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          loc.t('班级考勤', 'Class Attendance'),
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        leadingWidth: showDrawerButton ? 56.0 : 16.0,
        leading: showDrawerButton
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
          Column(
            children: [
              Expanded(
                child: _loading
                    ? const SizedBox.shrink()
                    : _status.trim().isNotEmpty
                        ? Center(
                            child: Text(
                              _status,
                              style: TextStyle(color: cs.error),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : _rows.isEmpty
                            ? Center(child: Text(loc.t('暂无数据', 'No data')))
                            : ListView(
                                padding: const EdgeInsets.all(16),
                                children: [
                                  // Pie Chart
                                  SizedBox(
                                    height: 250,
                                    child: (totalPresent == 0 &&
                                            totalLate == 0 &&
                                            totalAbsent == 0 &&
                                            totalLeave == 0)
                                        ? Center(
                                            child: Text(loc.t('今日暂无考勤记录',
                                                'No attendance records today')))
                                        : Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              PieChart(
                                                PieChartData(
                                                  sectionsSpace: 2,
                                                  centerSpaceRadius: 75,
                                                  sections: [
                                                    if (totalPresent > 0)
                                                      PieChartSectionData(
                                                        gradient:
                                                            LinearGradient(
                                                          colors: [
                                                            cs.primary
                                                                .withValues(
                                                                    alpha: 0.7),
                                                            cs.primary
                                                          ],
                                                        ),
                                                        value: totalPresent
                                                            .toDouble(),
                                                        title:
                                                            '${loc.t('到勤', 'Present')}\n$totalPresent',
                                                        radius: 30,
                                                        titlePositionPercentageOffset:
                                                            1.6,
                                                        titleStyle: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color:
                                                                cs.onSurface),
                                                      ),
                                                    if (totalLate > 0)
                                                      PieChartSectionData(
                                                        gradient:
                                                            LinearGradient(
                                                          colors: [
                                                            cs.tertiary
                                                                .withValues(
                                                                    alpha: 0.7),
                                                            cs.tertiary
                                                          ],
                                                        ),
                                                        value: totalLate
                                                            .toDouble(),
                                                        title:
                                                            '${loc.t('迟到', 'Late')}\n$totalLate',
                                                        radius: 30,
                                                        titlePositionPercentageOffset:
                                                            1.6,
                                                        titleStyle: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color:
                                                                cs.onSurface),
                                                      ),
                                                    if (totalAbsent > 0)
                                                      PieChartSectionData(
                                                        gradient:
                                                            LinearGradient(
                                                          colors: [
                                                            cs.error.withValues(
                                                                alpha: 0.7),
                                                            cs.error
                                                          ],
                                                        ),
                                                        value: totalAbsent
                                                            .toDouble(),
                                                        title:
                                                            '${loc.t('缺勤', 'Absent')}\n$totalAbsent',
                                                        radius: 30,
                                                        titlePositionPercentageOffset:
                                                            1.6,
                                                        titleStyle: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color:
                                                                cs.onSurface),
                                                      ),
                                                    if (totalLeave > 0)
                                                      PieChartSectionData(
                                                        gradient:
                                                            LinearGradient(
                                                          colors: [
                                                            cs.secondary
                                                                .withValues(
                                                                    alpha: 0.7),
                                                            cs.secondary
                                                          ],
                                                        ),
                                                        value: totalLeave
                                                            .toDouble(),
                                                        title:
                                                            '${loc.t('请假', 'Leave')}\n$totalLeave',
                                                        radius: 30,
                                                        titlePositionPercentageOffset:
                                                            1.6,
                                                        titleStyle: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color:
                                                                cs.onSurface),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    '${((totalPresent / (totalPresent + totalLate + totalAbsent + totalLeave)) * 100).toStringAsFixed(1)}%',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .headlineMedium
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: cs.onSurface,
                                                        ),
                                                  ),
                                                  Text(
                                                    '${loc.t('出勤率', 'Attendance')}\n${loc.t('总人数:', 'Total:')} ${totalPresent + totalLate + totalAbsent + totalLeave}',
                                                    textAlign: TextAlign.center,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .labelSmall
                                                        ?.copyWith(
                                                          color: cs
                                                              .onSurfaceVariant,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                  ),
                                  const SizedBox(height: 14),
                                  Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Align(
                                              alignment: Alignment.centerRight,
                                              child: _LegendChip(
                                                color: cs.primary,
                                                label: loc.t('到勤', 'Present'),
                                                value: totalPresent,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: _LegendChip(
                                                color: cs.tertiary,
                                                label: loc.t('迟到', 'Late'),
                                                value: totalLate,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Align(
                                              alignment: Alignment.centerRight,
                                              child: _LegendChip(
                                                color: cs.error,
                                                label: loc.t('缺勤', 'Absent'),
                                                value: totalAbsent,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: _LegendChip(
                                                color: cs.secondary,
                                                label: loc.t('请假', 'Leave'),
                                                value: totalLeave,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 32),

                                  // Expandable List
                                  Card(
                                    elevation: 0,
                                    color: cs.surfaceContainerLow,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                    child: ExpansionTile(
                                      initiallyExpanded: _isListExpanded,
                                      onExpansionChanged: (v) =>
                                          setState(() => _isListExpanded = v),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(28)),
                                      collapsedShape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(28)),
                                      title: Text(
                                          loc.t('学生详细名单',
                                              'Detailed Student List'),
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                  fontWeight: FontWeight.bold)),
                                      children: _rows.map((r) {
                                        return Column(
                                          children: [
                                            const Divider(height: 1),
                                            ListTile(
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 10),
                                              title: Text(
                                                r.student.fullName,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              subtitle: Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 4),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      r.student.studentNo,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall
                                                          ?.copyWith(
                                                              color: cs
                                                                  .onSurfaceVariant),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      r.student.classCode,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall
                                                          ?.copyWith(
                                                              color: cs
                                                                  .onSurfaceVariant),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Wrap(
                                                      spacing: 10,
                                                      runSpacing: 6,
                                                      children: [
                                                        _MiniBadge(
                                                            label:
                                                                loc.t('到', 'P'),
                                                            value: r.present,
                                                            color: cs.primary),
                                                        _MiniBadge(
                                                            label:
                                                                loc.t('迟', 'L'),
                                                            value: r.late,
                                                            color: cs.tertiary),
                                                        _MiniBadge(
                                                            label:
                                                                loc.t('缺', 'A'),
                                                            value: r.absent,
                                                            color: cs.error),
                                                        _MiniBadge(
                                                            label: loc.t(
                                                                '假', 'Lv'),
                                                            value: r.leave,
                                                            color:
                                                                cs.secondary),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              trailing: const Icon(
                                                  Icons.chevron_right),
                                              onTap: () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        StudentDetailPage(
                                                      session: widget.session,
                                                      student: r.student,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                  const SizedBox(height: 80),
                                ],
                              ),
              ),
            ],
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              heroTag: 'fab_attendance_overview_refresh',
              onPressed: _loading ? null : _refresh,
              backgroundColor: cs.primaryContainer,
              foregroundColor: cs.onPrimaryContainer,
              child: const Icon(Icons.refresh),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _MiniBadge(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 16),
        border: Border.all(color: color.withValues(alpha: 38)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$label $value',
        style: tt.labelSmall?.copyWith(fontSize: 10, height: 1.0),
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  final Color color;
  final String label;
  final int value;

  const _LegendChip(
      {required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(label, style: tt.labelLarge),
          const SizedBox(width: 8),
          Text(
            value.toString(),
            style: tt.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
