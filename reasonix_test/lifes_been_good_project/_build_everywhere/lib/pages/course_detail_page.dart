import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../models/course.dart';
import '../state/session.dart';

class CourseDetailPage extends StatelessWidget {
  final Session session;
  final Course course;
  final Map<String, Set<String>> membersByCourse;
  final VoidCallback? onStartAttendance;

  const CourseDetailPage({
    super.key,
    required this.session,
    required this.course,
    required this.membersByCourse,
    required this.onStartAttendance,
  });

  @override
  Widget build(BuildContext context) {
    final isTeacher = session.profile.role == 'teacher';
    final members = membersByCourse[course.id]?.length ?? 0;
    final loc = Provider.of<LocaleProvider>(context);

    final header = Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                course.courseName.isEmpty
                    ? '?'
                    : course.courseName.characters.first,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.courseName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    loc.t('学期：${course.termCode}', 'Term: ${course.termCode}'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (isTeacher)
              FilledButton.icon(
                onPressed: onStartAttendance,
                icon: const Icon(Icons.how_to_reg),
                label: Text(loc.t('开始点名', 'Start Roll Call')),
              ),
          ],
        ),
      ),
    );

    final meta = Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.t('课程信息', 'Course Info'),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            _kv(context, loc.t('课程ID', 'Course ID'), course.id),
            _kv(context, loc.t('教师/创建者', 'Teacher / Creator'),
                course.teacherProfileId),
            if (isTeacher) _kv(context, loc.t('成员数', 'Members'), '$members'),
            if (!isTeacher)
              _kv(
                context,
                loc.t('说明', 'Note'),
                loc.t('点名记录与课程绑定，教师从课程详情发起点名',
                    'Attendance records are tied to the course. Teachers start roll call from the course details page.'),
              ),
          ],
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(loc.t('课程详情', 'Course Details'))),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(children: [header, const SizedBox(height: 12), meta]),
      ),
    );
  }

  Widget _kv(BuildContext context, String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(k, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Text(v, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
