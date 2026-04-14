import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../main.dart';
import '../models/course.dart';
import '../models/student.dart';
import '../state/session.dart';
import 'attendance_page.dart';
import 'course_detail_page.dart';
import '../widgets/expressive_ui.dart';

class CoursesPage extends StatefulWidget {
  final Session session;

  const CoursesPage({super.key, required this.session});

  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  bool _loading = true;
  String _status = '';

  List<Course> _visibleCourses = const [];
  Map<String, Set<String>> _membersByCourse = const {};
  String? _myStudentId;

  static const _coursesHeader = 'id,course_name,teacher_profile_id,term_code';
  static const _courseMembersHeader = 'id,course_id,student_id';

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

  Future<void> _writeCsv(
    String filename,
    List<String> headers,
    List<Map<String, String>> rows,
  ) async {
    await widget.session.features
        .csvOp(action: 'write', file: filename, headers: headers, rows: rows);
  }

  Future<String?> _findMyStudentId() async {
    final role = widget.session.profile.role;
    if (role != 'student' && role != 'cadre') return null;
    final myNo = widget.session.profile.studentNo.trim();
    if (myNo.isEmpty) return null;

    Map<String, dynamic> studentsRes;
    if (await widget.session.features.hasFeature('students_list')) {
      studentsRes = await widget.session.features.listStudents();
    } else {
      final cli = widget.session.cli;
      if (cli == null) return null;
      studentsRes = await cli.call('students.list', {});
    }
    if (studentsRes['ok'] != true) return null;
    final raw = (((studentsRes['data'] ?? const {}) as Map)['items'] ??
        const []) as List;
    for (final e in raw) {
      final s = Student.fromJson((e as Map).cast<String, dynamic>());
      if (s.studentNo.trim() == myNo) return s.id;
    }
    return null;
  }

  Future<Map<String, Set<String>>> _loadMembersByCourse() async {
    final rows = await _readCsvRows('course_members.csv');
    final map = <String, Set<String>>{};
    for (final r in rows) {
      final courseId = (r['course_id'] ?? '').trim();
      final studentId = (r['student_id'] ?? '').trim();
      if (courseId.isEmpty || studentId.isEmpty) continue;
      map.putIfAbsent(courseId, () => <String>{}).add(studentId);
    }
    return map;
  }

  List<Course> _filterVisibleCourses({
    required List<Course> all,
    required Map<String, Set<String>> membersByCourse,
    required String? myStudentId,
  }) {
    final role = widget.session.profile.role;
    final me = widget.session.profile.id;
    if (role == 'teacher') {
      return all.where((c) => c.teacherProfileId == me).toList();
    }
    final mineCreated = all.where((c) => c.teacherProfileId == me).toList();
    final enrolled = myStudentId == null
        ? const <Course>[]
        : all
            .where(
              (c) => (membersByCourse[c.id] ?? const <String>{}).contains(
                myStudentId,
              ),
            )
            .toList();

    final map = <String, Course>{};
    for (final c in enrolled) {
      map[c.id] = c;
    }
    for (final c in mineCreated) {
      map[c.id] = c;
    }
    final out = map.values.toList();
    out.sort((a, b) => a.courseName.compareTo(b.courseName));
    return out;
  }

  Future<void> _refresh() async {
    final loc = Provider.of<LocaleProvider>(context, listen: false);
    setState(() {
      _loading = true;
      _status = '';
    });

    Map<String, dynamic> coursesRes;
    if (await widget.session.features.hasFeature('courses_list')) {
      coursesRes = await widget.session.features.listCourses();
    } else {
      final cli = widget.session.cli;
      if (cli == null) {
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
      return;
    }

    final courseRaw = (((coursesRes['data'] ?? const {}) as Map)['items'] ??
        const []) as List;
    final all = courseRaw
        .map((e) => Course.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
    final membersByCourse = await _loadMembersByCourse();
    final myStudentId = await _findMyStudentId();
    final visible = _filterVisibleCourses(
      all: all,
      membersByCourse: membersByCourse,
      myStudentId: myStudentId,
    );

    setState(() {
      _loading = false;
      _membersByCourse = membersByCourse;
      _myStudentId = myStudentId;
      _visibleCourses = visible;
    });
  }

  Future<void> _createCourse() async {
    final loc = Provider.of<LocaleProvider>(context, listen: false);
    final nameCtrl = TextEditingController();
    final termCtrl = TextEditingController(text: '2026S');

    final res = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        final inputTheme = InputDecoration(
          filled: true,
          fillColor: cs.surfaceContainerHighest.withValues(alpha: 77),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide.none,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.never,
        );

        return AlertDialog(
          title: Text(loc.t('创建课程', 'Create Course')),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: inputTheme.copyWith(
                      labelText: loc.t('课程名', 'Course Name')),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: termCtrl,
                  decoration: inputTheme.copyWith(
                      labelText: loc.t('学期代码', 'Term Code')),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('cancel'),
              child: Text(loc.t('取消', 'Cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop('ok'),
              child: Text(loc.t('创建', 'Create')),
            ),
          ],
        );
      },
    );

    final name = nameCtrl.text.trim();
    final term = termCtrl.text.trim();
    nameCtrl.dispose();
    termCtrl.dispose();

    if (res != 'ok') return;
    if (name.isEmpty) {
      if (!mounted) return;
      showExpressiveSnackBar(
        context,
        loc.t('请输入课程名', 'Please enter course name'),
      );
      return;
    }

    setState(() {
      _loading = true;
      _status = '';
    });

    try {
      final courseId = 'c_${DateTime.now().millisecondsSinceEpoch}';
      final row = <String, String>{
        'id': courseId,
        'course_name': name.replaceAll(',', ''),
        'teacher_profile_id': widget.session.profile.id,
        'term_code': term.replaceAll(',', ''),
      };

      final rows = await _readCsvRows('courses.csv');
      final headers = _coursesHeader.split(',');
      rows.add(row);
      await _writeCsv('courses.csv', headers, rows);

      if (_myStudentId != null) {
        final mRows = await _readCsvRows('course_members.csv');
        final mHeaders = _courseMembersHeader.split(',');
        final exists = mRows.any(
          (r) =>
              (r['course_id'] ?? '').trim() == courseId &&
              (r['student_id'] ?? '').trim() == _myStudentId,
        );
        if (!exists) {
          mRows.add({
            'id': 'cm_${DateTime.now().millisecondsSinceEpoch}',
            'course_id': courseId,
            'student_id': _myStudentId!,
          });
          await _writeCsv('course_members.csv', mHeaders, mRows);
        }
      }

      await _refresh();
    } catch (e) {
      setState(() {
        _loading = false;
        _status = e.toString();
      });
    }
  }

  void _openCourse(Course c) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CourseDetailPage(
          session: widget.session,
          course: c,
          membersByCourse: _membersByCourse,
          onStartAttendance: widget.session.canTakeAttendance
              ? () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AttendancePage(
                        session: widget.session,
                        courseId: c.id,
                        courseName: c.courseName,
                        isStandalone: true,
                      ),
                    ),
                  );
                }
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canCreate = !_loading;
    final loc = Provider.of<LocaleProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.t('课程', 'Courses')),
        actions: [
          IconButton(
            onPressed: _loading ? null : _refresh,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: canCreate ? _createCourse : null,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_status.trim().isNotEmpty)
              Text(
                _status,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            if (_status.trim().isNotEmpty) const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _visibleCourses.isEmpty
                      ? Center(child: Text(loc.t('暂无课程', 'No courses')))
                      : AnimationLimiter(
                          child: ListView.separated(
                            itemCount: _visibleCourses.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final c = _visibleCourses[index];
                              final members =
                                  _membersByCourse[c.id]?.length ?? 0;
                              final subtitle = widget.session.profile.role ==
                                      'teacher'
                                  ? loc.t('成员 $members 人', 'Members: $members')
                                  : loc.t('点击查看详情', 'Tap to view details');
                              return AnimationConfiguration.staggeredList(
                                position: index,
                                duration: const Duration(milliseconds: 375),
                                child: SlideAnimation(
                                  verticalOffset: 50.0,
                                  child: FadeInAnimation(
                                    child: Material(
                                      color:
                                          Theme.of(context).colorScheme.surface,
                                      borderRadius: BorderRadius.circular(16),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(16),
                                        onTap: () => _openCourse(c),
                                        child: Padding(
                                          padding: const EdgeInsets.all(14),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 40,
                                                height: 40,
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primaryContainer,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                alignment: Alignment.center,
                                                child: Text(
                                                  c.courseName.isEmpty
                                                      ? '?'
                                                      : c.courseName.characters
                                                          .first,
                                                  style: TextStyle(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onPrimaryContainer,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      c.courseName,
                                                      style: Theme.of(
                                                        context,
                                                      ).textTheme.titleMedium,
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      subtitle,
                                                      style: Theme.of(
                                                        context,
                                                      ).textTheme.bodySmall,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const Icon(Icons.chevron_right),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
