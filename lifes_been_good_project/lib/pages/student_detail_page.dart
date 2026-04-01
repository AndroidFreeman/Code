import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../main.dart';
import '../models/course.dart';
import '../models/student.dart';
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
  bool _loading = true;
  String _status = '';

  Map<String, int> _counts = const {};
  List<Map<String, String>> _recent = const [];

  @override
  void initState() {
    super.initState();
    _student = widget.student;
    _refresh();
  }

  String _positionLabel(String v, LocaleProvider loc) {
    final s = v.trim();
    if (s.isEmpty) return loc.t('普通学生', 'Regular Student');
    if (s == 'cadre') return loc.t('班干部', 'Class Cadre');
    return s;
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
    if (!await f.exists()) return const [];
    final content = await f.readAsString(encoding: utf8);
    final lines = const LineSplitter()
        .convert(content)
        .where((e) => e.trim().isNotEmpty)
        .toList();
    if (lines.length <= 1) return const [];
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

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _status = '';
    });

    try {
      // Reload student data from CSV to get latest role/position
      final f = File(p.join(widget.session.dataDir, 'students.csv'));
      if (await f.exists()) {
        final rows = await _readCsvRows(f);
        final current = rows.where((r) => r['id'] == _student.id).firstOrNull;
        if (current != null) {
          setState(() {
            _student = Student.fromJson(current);
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

      final sessionsFile =
          File(p.join(widget.session.dataDir, 'attendance_sessions.csv'));
      final recordsFile =
          File(p.join(widget.session.dataDir, 'attendance_records.csv'));
      final sessions = await _readCsvRows(sessionsFile);
      final records = await _readCsvRows(recordsFile);

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
          'course_id': courseId,
          'course_name': (courseMap[courseId] ?? '').trim(),
          'session_id': sessionId,
        });
      }

      mine.sort(
          (a, b) => (b['marked_at'] ?? '').compareTo(a['marked_at'] ?? ''));
      final recent = mine.take(20).toList(growable: false);

      if (!mounted) return;
      setState(() {
        _loading = false;
        _counts = counts;
        _recent = recent;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _status = e.toString();
      });
    }
  }

  Future<void> _editStudent() async {
    final loc = Provider.of<LocaleProvider>(context, listen: false);
    final nameCtrl = TextEditingController(text: _student.fullName);
    final noCtrl = TextEditingController(text: _student.studentNo);
    final phoneCtrl = TextEditingController(text: _student.phone);
    var pos = _student.position.trim().isEmpty ? '' : _student.position.trim();

    List<String> allClasses = [];
    try {
      allClasses = await LocalProfiles.getAllClasses(widget.session.dataDir);
    } catch (_) {}

    var selectedClass = _student.classCode.trim();
    if (selectedClass.isEmpty && allClasses.isNotEmpty) {
      selectedClass = allClasses.first;
    }

    final res = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: Text(loc.t('编辑学生信息', 'Edit Student Info')),
              content: SizedBox(
                width: 460,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: noCtrl,
                        decoration: InputDecoration(
                          labelText: loc.t('学号', 'Student ID'),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: nameCtrl,
                        decoration: InputDecoration(
                          labelText: loc.t('姓名', 'Name'),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownMenu<String>(
                        label: Text(loc.t('班级', 'Class')),
                        initialSelection: selectedClass,
                        expandedInsets: EdgeInsets.zero,
                        dropdownMenuEntries: allClasses
                            .map((c) => DropdownMenuEntry(value: c, label: c))
                            .toList(),
                        onSelected: (v) {
                          setLocal(() {
                            selectedClass = v ?? '';
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: phoneCtrl,
                        decoration: InputDecoration(
                          labelText: loc.t('电话', 'Phone'),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (widget.session.isTeacher)
                        DropdownMenu<String>(
                          label: Text(loc.t('职位', 'Position')),
                          initialSelection: pos,
                          expandedInsets: EdgeInsets.zero,
                          dropdownMenuEntries: [
                            DropdownMenuEntry(
                                value: '',
                                label: loc.t('普通学生', 'Regular Student')),
                            DropdownMenuEntry(
                                value: 'cadre',
                                label: loc.t('班干部', 'Class Cadre')),
                          ],
                          onSelected: (v) {
                            setLocal(() {
                              pos = v ?? '';
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop('cancel'),
                  child: Text(loc.t('取消', 'Cancel')),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop('ok'),
                  child: Text(loc.t('保存', 'Save')),
                ),
              ],
            );
          },
        );
      },
    );

    final newNo = noCtrl.text.trim();
    final newName = nameCtrl.text.trim();
    final newPhone = phoneCtrl.text.trim();
    final newClass = selectedClass;
    noCtrl.dispose();
    nameCtrl.dispose();
    phoneCtrl.dispose();

    if (res != 'ok') return;
    if (newNo.isEmpty || !newNo.startsWith('S')) {
      setState(() {
        _status = loc.t('学号必须以 S 开头', 'Student ID must start with "S"');
      });
      return;
    }
    if (newName.isEmpty) {
      setState(() {
        _status = loc.t('姓名不能为空', 'Name cannot be empty');
      });
      return;
    }

    setState(() {
      _loading = true;
      _status = '';
    });

    try {
      final f = File(p.join(widget.session.dataDir, 'students.csv'));
      if (!await f.exists()) throw loc.t('文件不存在', 'File not found');

      final content = await f.readAsString(encoding: utf8);
      final lines = const LineSplitter()
          .convert(content)
          .where((e) => e.trim().isNotEmpty)
          .toList();
      if (lines.isEmpty) throw loc.t('文件格式错误', 'Invalid file format');

      final headers = lines.first.split(',');
      final rows = await _readCsvRows(f);

      for (final r in rows) {
        if ((r['id'] ?? '').trim() == _student.id) {
          r['student_no'] = newNo.replaceAll(',', '');
          r['full_name'] = newName.replaceAll(',', '');
          r['class_code'] = newClass.replaceAll(',', '');
          r['phone'] = newPhone.replaceAll(',', '');
          r['position'] = pos.replaceAll(',', '');
          break;
        }
      }

      final out = <String>[headers.join(',')];
      for (final r in rows) {
        out.add(headers.map((h) => (r[h] ?? '').replaceAll(',', '')).join(','));
      }
      await f.writeAsString(out.join('\n') + '\n', encoding: utf8);

      await _refresh();
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
          if (widget.session.canViewStudents)
            IconButton(
              onPressed: _loading ? null : _editStudent,
              icon: const Icon(Icons.edit_note_rounded),
              tooltip: loc.t('编辑', 'Edit'),
            ),
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
                          boxShadow: [
                            BoxShadow(
                              color: cs.shadow.withOpacity(0.04),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: cs.primaryContainer,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                s.fullName.substring(0, 1),
                                style: tt.displaySmall?.copyWith(
                                  color: cs.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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
                                    s.studentNo,
                                    style: tt.titleMedium
                                        ?.copyWith(color: cs.onSurfaceVariant),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      _buildBadge(
                                          context,
                                          s.classCode,
                                          cs.secondaryContainer,
                                          cs.onSecondaryContainer),
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
                          Text(loc.t('最近记录', 'Recent Records'),
                              style: tt.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          if (_recent.isNotEmpty)
                            TextButton(
                                onPressed: () {},
                                child: Text(loc.t('查看全部', 'View All'))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_recent.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 48),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                                color: cs.outlineVariant.withOpacity(0.5)),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.inbox_outlined,
                                  size: 48,
                                  color: cs.onSurfaceVariant.withOpacity(0.5)),
                              const SizedBox(height: 16),
                              Text(loc.t('暂无记录', 'No Records'),
                                  style: TextStyle(color: cs.onSurfaceVariant)),
                            ],
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _recent.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final r = _recent[index];
                            final status = (r['status'] ?? '').trim();
                            final courseName = (r['course_name'] ?? '').trim();
                            final courseId = (r['course_id'] ?? '').trim();
                            final title = courseName.isNotEmpty
                                ? courseName
                                : (courseId.isNotEmpty
                                    ? courseId
                                    : loc.t('未命名课程', 'Unnamed Course'));
                            final markedAt = (r['marked_at'] ?? '').trim();

                            Color statusColor = cs.primary;
                            if (status == 'late') statusColor = cs.tertiary;
                            if (status == 'absent') statusColor = cs.error;

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: cs.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: cs.outlineVariant.withOpacity(0.5)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      status == 'present'
                                          ? Icons.check_circle_rounded
                                          : status == 'late'
                                              ? Icons.access_time_filled_rounded
                                              : Icons.cancel_rounded,
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
                                            style: tt.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 2),
                                        Text(markedAt.isEmpty ? '—' : markedAt,
                                            style: tt.bodySmall?.copyWith(
                                                color: cs.onSurfaceVariant)),
                                      ],
                                    ),
                                  ),
                                  _buildBadge(
                                      context,
                                      _statusLabel(status, loc),
                                      statusColor.withOpacity(0.1),
                                      statusColor),
                                ],
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 40),
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
          border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
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
