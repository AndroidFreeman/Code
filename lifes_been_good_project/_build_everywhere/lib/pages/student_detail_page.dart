import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../models/course.dart';
import '../models/student.dart';
import '../services/api_config.dart';
import '../services/local_profiles.dart';
import '../state/session.dart';
import '../widgets/expressive_ui.dart';

class StudentDetailPage extends StatefulWidget {
  final Session session;
  final Student student;

  const StudentDetailPage({
    super.key,
    required this.session,
    required this.student,
  });

  @override
  State<StudentDetailPage> createState() => _StudentDetailPageState();
}

class _StudentDetailPageState extends State<StudentDetailPage> {
  late Student _student;
  bool _loading = false;
  String _status = '';

  Map<String, int> _counts = const {};
  List<Map<String, String>> _recent = const [];
  Map<String, String> _avatarMap = const {};

  DateTime? _startDate;
  DateTime? _endDate;
  int _currentPage = 0;
  static const int _pageSize = 10;

  Map<String, String> _classNameByCode = const {};

  @override
  void initState() {
    super.initState();
    _student = widget.student;
    _refresh();
  }

  String _positionLabel(String v, LocaleProvider loc) {
    final s = v.trim();
    if (s.isEmpty) return loc.t('普通学生', 'Regular Student');
    switch (s) {
      case 'monitor':
        return loc.t('班长', 'Monitor');
      case 'study':
        return loc.t('学习委员', 'Study Comm.');
      case 'publicity':
        return loc.t('宣传委员', 'Publicity Comm.');
      case 'life':
        return loc.t('生活委员', 'Life Comm.');
      case 'psychological':
        return loc.t('心理委员', 'Psych Comm.');
      case 'organize':
        return loc.t('组织委员', 'Organize Comm.');
      case 'branch_secretary':
        return loc.t('团支书', 'Branch Secretary');
      case 'cadre':
        return loc.t('班干部', 'Class Cadre');
      default:
        return s;
    }
  }

  Map<String, String> _normalizeStringMap(Map raw) {
    return raw.map(
      (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
    );
  }

  Future<Map<String, String>> _loadClassNameMap() async {
    final rows =
        await LocalProfiles.getAllClassesWithNames(widget.session.dataDir);
    final out = <String, String>{};
    for (final row in rows) {
      final id = (row['id'] ?? '').trim();
      final name = (row['name'] ?? '').trim();
      if (id.isEmpty) continue;
      out[id] = name.isNotEmpty ? name : id;
    }
    return out;
  }

  String _displayClassLabel(Student student) {
    final code = student.classCode.trim();
    final directName = student.className.trim();
    if (directName.isNotEmpty) return directName;
    if (code.isEmpty) return '';
    return (_classNameByCode[code] ?? code).trim();
  }

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

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _status = '';
    });

    try {
      // Reload student data from CSV to get latest role/position
      final classNames = await _loadClassNameMap();
      Map<String, dynamic> res;
      if (ApiConfig.instance.useCloud) {
        res = await ApiConfig.instance.get('/api/students');
      } else {
        res = await widget.session.features
            .csvOp(action: 'read', file: 'students.csv');
      }
      if (res['ok'] == true) {
        final items = ((res['data'] ?? const {})['items'] as List?) ?? const [];
        final rows = items
            .whereType<Map>()
            .map(_normalizeStringMap)
            .toList(growable: false);
        final current = rows.where((r) => r['id'] == _student.id).firstOrNull;
        if (current != null) {
          final latestStudent = Student.fromJson(current);
          setState(() {
            _student = latestStudent.copyWith(
              className: classNames[latestStudent.classCode.trim()] ??
                  latestStudent.className,
            );
          });
        }
      }

      Map<String, dynamic> coursesRes;
      if (await widget.session.features.hasFeature('courses_list')) {
        coursesRes = await widget.session.features.listCourses();
      } else {
        final cli = widget.session.cli;
        if (cli == null) {
          coursesRes = {
            'ok': true,
            'data': {'items': const []}
          };
        } else {
          coursesRes = await cli.call('courses.list', {});
        }
      }
      final courseMap = <String, String>{};
      if (coursesRes['ok'] == true) {
        final courseRaw = (((coursesRes['data'] ?? const {}) as Map)['items'] ??
            const []) as List;
        for (final e in courseRaw) {
          final c = Course.fromJson((e as Map).cast<String, dynamic>());
          courseMap[c.id] = c.courseName;
        }
      }

      Map<String, dynamic> sessRes;
      Map<String, dynamic> recRes;
      if (ApiConfig.instance.useCloud) {
        sessRes = await ApiConfig.instance.get('/api/attendance/sessions');
        recRes = await ApiConfig.instance.get('/api/attendance/records');
      } else {
        sessRes = await widget.session.features
            .csvOp(action: 'read', file: 'attendance_sessions.csv');
        recRes = await widget.session.features
            .csvOp(action: 'read', file: 'attendance_records.csv');
      }

      final sessions =
          (((sessRes['data'] ?? const {})['items'] as List?) ?? const [])
              .whereType<Map>()
              .map(_normalizeStringMap)
              .toList(growable: false);
      final records =
          (((recRes['data'] ?? const {})['items'] as List?) ?? const [])
              .whereType<Map>()
              .map(_normalizeStringMap)
              .toList(growable: false);

      final sessionsById = <String, Map<String, String>>{};
      for (final s in sessions) {
        final id = (s['id'] ?? '').trim();
        if (id.isEmpty) continue;
        sessionsById[id] = s;
      }

      // Keep only the latest record for each (session_id, student_id)
      final latestRecords = <String, Map<String, String>>{};
      for (final r in records) {
        final sessionId = (r['session_id'] ?? '').trim();
        final studentId = (r['student_id'] ?? '').trim();
        if (sessionId.isNotEmpty && studentId.isNotEmpty) {
          latestRecords['$sessionId-$studentId'] = r;
        }
      }

      final counts = <String, int>{'present': 0, 'late': 0, 'absent': 0};
      final mine = <Map<String, String>>[];
      for (final r in latestRecords.values) {
        if ((r['student_id'] ?? '').trim() != _student.id) continue;
        final st = (r['status'] ?? '').trim();
        if (counts.containsKey(st)) counts[st] = (counts[st] ?? 0) + 1;
        final sessionId = (r['session_id'] ?? '').trim();
        final session = sessionsById[sessionId] ?? const {};
        final courseId = (session['course_id'] ?? '').trim();
        mine.add({
          'status': st,
          'marked_at': (r['marked_at'] ?? '').trim(),
          'started_at': (session['started_at'] ?? '').trim(),
          'course_id': courseId,
          'course_name': (courseMap[courseId] ?? '').trim(),
          'session_id': sessionId,
          'week': (session['week'] ?? '').trim(),
          'period': (session['period'] ?? '').trim(),
        });
      }

      mine.sort(
          (a, b) => (b['marked_at'] ?? '').compareTo(a['marked_at'] ?? ''));

      Map<String, dynamic> profilesRes;
      if (ApiConfig.instance.useCloud) {
        profilesRes = await ApiConfig.instance.get('/api/profiles');
      } else {
        profilesRes = await widget.session.features
            .csvOp(action: 'read', file: 'profiles.csv');
      }
      final avatarMap = <String, String>{};
      if (profilesRes['ok'] == true) {
        final pItems =
            ((profilesRes['data'] ?? const {})['items'] as List?) ?? [];
        for (final pi in pItems) {
          if (pi is! Map) continue;
          final row = _normalizeStringMap(pi);
          final pid = (row['id'] ?? '').trim();
          final av = (row['avatar'] ?? '').trim();
          if (pid.isNotEmpty && av.isNotEmpty) avatarMap[pid] = av;
        }
      }

      if (!mounted) return;
      setState(() {
        _loading = false;
        _counts = counts;
        _recent = mine;
        _avatarMap = avatarMap;
        _classNameByCode = classNames;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _status = e.toString();
      });
    }
  }

  String _statusLabel(String s, LocaleProvider loc) {
    switch (s) {
      case 'present':
        return loc.t('出勤', 'Present');
      case 'late':
        return loc.t('迟到', 'Late');
      case 'absent':
        return loc.t('缺勤', 'Absent');
      case 'leave':
        return loc.t('请假', 'Leave');
      default:
        return s;
    }
  }

  Future<void> _updateRecentRecordStatus(
      {required String sessionId, required String status}) async {
    if (sessionId.trim().isEmpty) return;
    try {
      await widget.session.features.markAttendanceRecord(
        sessionId: sessionId,
        studentId: _student.id,
        status: status,
        markedByProfileId: widget.session.profile.id,
      );
      widget.session.notifyDataChanged(modules: const ['attendance']);
      await _refresh();
    } catch (_) {}
  }

  void _openRecentRecordStatusPicker(
      BuildContext context, Map<String, String> r) {
    final loc = Provider.of<LocaleProvider>(context, listen: false);
    final cs = Theme.of(context).colorScheme;
    final sessionId = (r['session_id'] ?? '').trim();
    final current = (r['status'] ?? '').trim();
    final options = <({String id, String label, IconData icon, Color color})>[
      (
        id: 'present',
        label: loc.t('出勤', 'Present'),
        icon: Icons.check_circle_rounded,
        color: cs.primary
      ),
      (
        id: 'late',
        label: loc.t('迟到', 'Late'),
        icon: Icons.access_time_filled_rounded,
        color: cs.tertiary
      ),
      (
        id: 'absent',
        label: loc.t('缺勤', 'Absent'),
        icon: Icons.cancel_rounded,
        color: cs.error
      ),
      (
        id: 'leave',
        label: loc.t('请假', 'Leave'),
        icon: Icons.beach_access_rounded,
        color: cs.secondary
      ),
    ];

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (ctx) {
        return ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                loc.t('更改考勤状态', 'Change Attendance Status'),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            ...options.map((o) {
              final selected = o.id == current;
              return ListTile(
                leading: Icon(o.icon, color: o.color),
                title: Text(o.label),
                trailing: selected
                    ? Icon(Icons.check_rounded, color: cs.primary)
                    : null,
                onTap: () {
                  Navigator.of(ctx).pop();
                  _updateRecentRecordStatus(sessionId: sessionId, status: o.id);
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final loc = Provider.of<LocaleProvider>(context);
    final s = _student;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(loc.t('学生详情', 'Student Details')),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: _loading ? null : _refresh,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: loc.t('刷新', 'Refresh'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading && _counts.isEmpty
          ? const SizedBox.shrink()
          : _status.trim().isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline_rounded,
                            size: 48, color: cs.error),
                        const SizedBox(height: 16),
                        Text(_status,
                            style: TextStyle(color: cs.error),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: _refresh,
                          icon: const Icon(Icons.refresh),
                          label: Text(loc.t('重试', 'Retry')),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.grey.shade200,
                                  width: 1,
                                ),
                                image: _avatarMap.containsKey(s.id) &&
                                        File(_avatarMap[s.id]!).existsSync()
                                    ? DecorationImage(
                                        image:
                                            FileImage(File(_avatarMap[s.id]!)),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: !_avatarMap.containsKey(s.id) ||
                                      !File(_avatarMap[s.id]!).existsSync()
                                  ? Text(
                                      s.fullName.substring(0, 1),
                                      style: tt.headlineMedium?.copyWith(
                                        color: cs.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.fullName,
                                    style: tt.headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _displayClassLabel(s).isNotEmpty
                                        ? '${s.studentNo} · ${_displayClassLabel(s)}'
                                        : s.studentNo,
                                    style: tt.titleMedium
                                        ?.copyWith(color: cs.onSurfaceVariant),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      if (s.position.isNotEmpty)
                                        _buildBadge(
                                            context,
                                            _positionLabel(s.position, loc),
                                            cs.tertiaryContainer,
                                            cs.onTertiaryContainer),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Statistics Section
                      Text(loc.t('考勤统计', 'Attendance Stats'),
                          style: tt.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildStatCard(context, loc.t('出勤', 'Present'),
                              _counts['present'] ?? 0, cs.primary),
                          const SizedBox(width: 12),
                          _buildStatCard(context, loc.t('迟到', 'Late'),
                              _counts['late'] ?? 0, cs.tertiary),
                          const SizedBox(width: 12),
                          _buildStatCard(context, loc.t('缺勤', 'Absent'),
                              _counts['absent'] ?? 0, cs.error),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Recent Records Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(loc.t('考勤记录', 'Attendance Records'),
                              style: tt.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.date_range_rounded),
                                onPressed: () async {
                                  final picked = await showDateRangePicker(
                                    context: context,
                                    firstDate: DateTime(2025),
                                    lastDate: DateTime(2027),
                                    initialDateRange:
                                        _startDate != null && _endDate != null
                                            ? DateTimeRange(
                                                start: _startDate!,
                                                end: _endDate!)
                                            : null,
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      _startDate = picked.start;
                                      _endDate = picked.end;
                                      _currentPage = 0;
                                    });
                                  }
                                },
                              ),
                              if (_startDate != null)
                                IconButton(
                                  icon: const Icon(Icons.clear_rounded),
                                  onPressed: () {
                                    setState(() {
                                      _startDate = null;
                                      _endDate = null;
                                      _currentPage = 0;
                                    });
                                  },
                                ),
                            ],
                          ),
                        ],
                      ),
                      if (_startDate != null && _endDate != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            '${_startDate!.toString().substring(0, 10)} ~ ${_endDate!.toString().substring(0, 10)}',
                            style: tt.bodySmall?.copyWith(
                                color: cs.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Builder(builder: (context) {
                        var filtered = _recent;
                        if (_startDate != null && _endDate != null) {
                          filtered = _recent.where((r) {
                            final eventAt =
                                (r['marked_at'] ?? '').trim().isNotEmpty
                                    ? (r['marked_at'] ?? '').trim()
                                    : (r['started_at'] ?? '').trim();
                            final date = _parseFlexibleDateTime(eventAt);
                            if (date == null) return false;
                            return date.isAfter(_startDate!
                                    .subtract(const Duration(days: 1))) &&
                                date.isBefore(
                                    _endDate!.add(const Duration(days: 1)));
                          }).toList();
                        }

                        if (filtered.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 48),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                  color:
                                      cs.outlineVariant.withValues(alpha: 0.5)),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.inbox_outlined,
                                    size: 48,
                                    color: cs.onSurfaceVariant
                                        .withValues(alpha: 0.5)),
                                const SizedBox(height: 16),
                                Text(loc.t('暂无记录', 'No Records'),
                                    style:
                                        TextStyle(color: cs.onSurfaceVariant)),
                              ],
                            ),
                          );
                        }

                        final totalPages = (filtered.length / _pageSize).ceil();
                        final startIdx = _currentPage * _pageSize;
                        final endIdx =
                            (startIdx + _pageSize).clamp(0, filtered.length);
                        final pageItems = filtered.sublist(startIdx, endIdx);

                        return Column(
                          children: [
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: pageItems.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final r = pageItems[index];
                                final status = (r['status'] ?? '').trim();
                                final courseName =
                                    (r['course_name'] ?? '').trim();
                                final courseId = (r['course_id'] ?? '').trim();

                                final week = (r['week'] ?? '').trim();
                                final period = (r['period'] ?? '').trim();
                                final weekStr =
                                    week.isNotEmpty ? ' 第$week周' : '';
                                final periodStr =
                                    period.isNotEmpty ? ' 第$period节' : '';

                                final title = courseName.isNotEmpty
                                    ? '$courseName$weekStr$periodStr'
                                    : (courseId.isNotEmpty
                                        ? '$courseId$weekStr$periodStr'
                                        : loc.t('未命名课程', 'Unnamed Course'));
                                final markedAt = (r['marked_at'] ?? '').trim();
                                final startedAt =
                                    (r['started_at'] ?? '').trim();
                                final displayTime = markedAt.isNotEmpty
                                    ? _formatDisplayDateTime(markedAt)
                                    : _formatDisplayDateTime(startedAt);

                                Color statusColor = cs.primary;
                                if (status == 'late') statusColor = cs.tertiary;
                                if (status == 'absent') statusColor = cs.error;
                                if (status == 'leave')
                                  statusColor = cs.secondary;

                                return Bounceable(
                                    onTap: () => _openRecentRecordStatusPicker(
                                        context, r),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: cs.surface,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                            color: cs.outlineVariant
                                                .withValues(alpha: 0.5)),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: statusColor.withValues(
                                                  alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              status == 'present'
                                                  ? Icons.check_circle_rounded
                                                  : status == 'late'
                                                      ? Icons
                                                          .access_time_filled_rounded
                                                      : status == 'leave'
                                                          ? Icons
                                                              .beach_access_rounded
                                                          : Icons
                                                              .cancel_rounded,
                                              color: statusColor,
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(title,
                                                    style: tt.titleMedium
                                                        ?.copyWith(
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold)),
                                                const SizedBox(height: 2),
                                                Text(displayTime,
                                                    style: tt.bodySmall?.copyWith(
                                                        color: cs
                                                            .onSurfaceVariant)),
                                              ],
                                            ),
                                          ),
                                          _buildBadge(
                                              context,
                                              _statusLabel(status, loc),
                                              statusColor.withValues(
                                                  alpha: 0.15),
                                              statusColor),
                                        ],
                                      ),
                                    ));
                              },
                            ),
                            if (totalPages > 1)
                              Padding(
                                padding: const EdgeInsets.only(top: 24),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      onPressed: _currentPage > 0
                                          ? () => setState(() => _currentPage--)
                                          : null,
                                      icon: const Icon(
                                          Icons.chevron_left_rounded),
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      '${_currentPage + 1} / $totalPages',
                                      style: tt.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 16),
                                    IconButton(
                                      onPressed: _currentPage < totalPages - 1
                                          ? () => setState(() => _currentPage++)
                                          : null,
                                      icon: const Icon(
                                          Icons.chevron_right_rounded),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        );
                      }),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
    );
  }

  Widget _buildBadge(BuildContext context, String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildStatCard(
      BuildContext context, String label, int value, Color color) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            Text(
              value.toString(),
              style: tt.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
