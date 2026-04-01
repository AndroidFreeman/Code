import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

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

  Future<List<Map<String, String>>> _readCsvRows(File f) async {
    if (!await f.exists()) return const [];
    final content = await f.readAsString(encoding: utf8);
    final lines = const LineSplitter()
        .convert(content)
        .where((e) => e.trim().isNotEmpty)
        .toList();
    if (lines.length <= 1) return const [];
    final headers = lines.first.split(',').map((e) => e.trim()).toList();
    final rows = <Map<String, String>>[];
    for (var i = 1; i < lines.length; i++) {
      final parts = lines[i].split(',');
      final row = <String, String>{};
      for (var j = 0; j < headers.length && j < parts.length; j++) {
        row[headers[j]] = parts[j];
      }
      rows.add(row);
    }
    return rows;
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
    return raw
        .map((e) => Student.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
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

      final todayStr = DateTime.now().toIso8601String().substring(0, 10);

      final sessionsFile =
          File(p.join(widget.session.dataDir, 'attendance_sessions.csv'));
      final sessions = await _readCsvRows(sessionsFile);
      final todaySessionIds = sessions
          .where((s) => (s['started_at'] ?? '').startsWith(todayStr))
          .map((s) => s['id'])
          .toSet();

      final recordsFile =
          File(p.join(widget.session.dataDir, 'attendance_records.csv'));
      final records = await _readCsvRows(recordsFile);

      // Find all students on leave today across ALL sessions
      final allTodaySessionIds = sessions
          .where((s) => (s['started_at'] ?? '').startsWith(todayStr))
          .map((s) => s['id'])
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

      // Keep only the latest record for each (session_id, student_id) in CURRENT sessions
      final latestRecords = <String, Map<String, String>>{};
      for (final r in records) {
        final sessionId = (r['session_id'] ?? '').trim();
        final studentId = (r['student_id'] ?? '').trim();
        if (sessionId.isNotEmpty &&
            studentId.isNotEmpty &&
            todaySessionIds.contains(sessionId)) {
          latestRecords['$sessionId-$studentId'] = r;
        }
      }

      final counts = <String, Map<String, int>>{};
      for (final r in latestRecords.values) {
        final sid = (r['student_id'] ?? '').trim();
        if (sid.isEmpty) continue;
        final st = (r['status'] ?? '').trim();
        if (st != 'present' && st != 'late' && st != 'absent' && st != 'leave')
          continue;
        final m = counts.putIfAbsent(
            sid, () => {'present': 0, 'late': 0, 'absent': 0, 'leave': 0});
        m[st] = (m[st] ?? 0) + 1;
      }

      final rows = filtered.map((s) {
        final m =
            counts[s.id] ?? {'present': 0, 'late': 0, 'absent': 0, 'leave': 0};

        // If no records in current sessions but student is on leave today, count it
        var leaveCount = m['leave'] ?? 0;
        if (leaveCount == 0 && studentsOnLeaveToday.contains(s.id)) {
          leaveCount = 1;
        }

        return _Row(
          student: s,
          present: m['present'] ?? 0,
          late: m['late'] ?? 0,
          absent: m['absent'] ?? 0,
          leave: leaveCount,
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

    return Scaffold(
      appBar: AppBar(
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
        title: Text(loc.t('考勤', 'Attendance')),
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
                                                        titleStyle:
                                                            const TextStyle(
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .normal,
                                                                color: Colors
                                                                    .white),
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
                                                        titleStyle:
                                                            const TextStyle(
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .normal,
                                                                color: Colors
                                                                    .white),
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
                                                        titleStyle:
                                                            const TextStyle(
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .normal,
                                                                color: Colors
                                                                    .white),
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
                                                        titleStyle:
                                                            const TextStyle(
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .normal,
                                                                color: Colors
                                                                    .white),
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
                                              title: Text(
                                                  '${r.student.fullName}（${r.student.studentNo}）'),
                                              subtitle:
                                                  Text(r.student.classCode),
                                              trailing: SingleChildScrollView(
                                                scrollDirection:
                                                    Axis.horizontal,
                                                child: Wrap(
                                                  spacing: 10,
                                                  children: [
                                                    _MiniBadge(
                                                        label: loc.t('到', 'P'),
                                                        value: r.present,
                                                        color: cs.primary),
                                                    _MiniBadge(
                                                        label: loc.t('迟', 'L'),
                                                        value: r.late,
                                                        color: cs.tertiary),
                                                    _MiniBadge(
                                                        label: loc.t('缺', 'A'),
                                                        value: r.absent,
                                                        color: cs.error),
                                                    _MiniBadge(
                                                        label: loc.t('假', 'Lv'),
                                                        value: r.leave,
                                                        color: cs.secondary),
                                                    const Icon(
                                                        Icons.chevron_right),
                                                  ],
                                                ),
                                              ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 16),
        border: Border.all(color: color.withValues(alpha: 38)),
        borderRadius: BorderRadius.circular(12),
      ),
      child:
          Text('$label $value', style: Theme.of(context).textTheme.bodySmall),
    );
  }
}
