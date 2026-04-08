import re

f_shell = 'lib/pages/shell_page.dart'
with open(f_shell, 'r', encoding='utf-8') as file:
    content = file.read()
content = content.replace("if (widget.session.isTeacher && widget.session.canTakeAttendance)", "if (widget.session.canTakeAttendance)")
with open(f_shell, 'w', encoding='utf-8') as file:
    file.write(content)

f_drawer = 'lib/widgets/home_drawer.dart'
with open(f_drawer, 'r', encoding='utf-8') as file:
    content = file.read()
content = content.replace("if (show('attendance') &&\n                              session.isTeacher &&\n                              session.canTakeAttendance)", "if (show('attendance') &&\n                              session.canTakeAttendance)")
with open(f_drawer, 'w', encoding='utf-8') as file:
    file.write(content)

f_attendance = 'lib/pages/attendance_page.dart'
with open(f_attendance, 'r', encoding='utf-8') as file:
    content = file.read()

replacement = """
      if (studentsRes['ok'] == true) {
        final items = (studentsRes['data']?['items'] as List?) ?? [];
        final uniqueStudents = <String, Student>{};
        for (final e in items) {
          final s = Student.fromJson(e);
          uniqueStudents[s.studentNo] = s;
        }
        _allStudents = uniqueStudents.values.toList();
      }
"""
content = re.sub(r"if \(studentsRes\['ok'\] == true\) \{[^}]*final items = \(studentsRes\['data'\]\?\['items'\] as List\?\) \?\? \[\];[^}]*_allStudents = items\.map\(\(e\) => Student\.fromJson\(e\)\)\.toList\(\);[^}]*\}", replacement, content)
with open(f_attendance, 'w', encoding='utf-8') as file:
    file.write(content)

f_overview = 'lib/pages/class_attendance_overview_page.dart'
with open(f_overview, 'r', encoding='utf-8') as file:
    content = file.read()

replacement2 = """
    final raw = (((studentsRes['data'] ?? const {}) as Map)['items'] ??
        const []) as List;
    final uniqueStudents = <String, Student>{};
    for (final e in raw) {
      final s = Student.fromJson((e as Map).cast<String, dynamic>());
      uniqueStudents[s.studentNo] = s;
    }
    return uniqueStudents.values.toList();
"""
content = re.sub(r"final raw = \(\(\(studentsRes\['data'\] \?\? const \{\}\) as Map\)\['items'\] \?\?[^\]]+\]\) as List;[^r]+return raw[^.]+\.map\(\(e\) => Student\.fromJson\(\(e as Map\)\.cast<String, dynamic>\(\)\)\)[^.]+\.toList\(\);", replacement2, content)
with open(f_overview, 'w', encoding='utf-8') as file:
    file.write(content)

f_students = 'lib/pages/class_students_page.dart'
with open(f_students, 'r', encoding='utf-8') as file:
    content = file.read()

content = content.replace("List<Student> _students = const [];", "List<Student> _students = const [];\n  Map<String, String> _avatars = {};")

load_profiles = """
      final profilesRes = await widget.session.features.hasFeature('profiles_list').then((has) async {
        if (has) return await widget.session.features.listProfiles();
        return widget.session.cli?.call('profiles.list', {}) ?? {'ok': false};
      });
      final avatarsMap = <String, String>{};
      if (profilesRes['ok'] == true) {
        final items = ((profilesRes['data'] ?? const {}) as Map)['items'] as List? ?? [];
        for (final e in items) {
          final m = (e as Map).cast<String, dynamic>();
          final sNo = (m['student_no'] ?? '').toString().trim();
          final av = (m['avatar'] ?? '').toString().trim();
          if (sNo.isNotEmpty && av.isNotEmpty) {
            avatarsMap[sNo] = av;
          }
        }
      }
"""

refresh_state = """
      if (!mounted) return;
      setState(() {
        _loading = false;
        _myClasses = classes;
        _selectedClass = sel;
        _students = filtered;
        _avatars = avatarsMap;
      });
"""

content = re.sub(r"final studentsRes = await studentsFuture;", load_profiles + "\n      final studentsRes = await studentsFuture;", content)

content = re.sub(r"if \(!mounted\) return;\s*setState\(\(\) \{\s*_loading = false;\s*_myClasses = classes;\s*_selectedClass = sel;\s*_students = filtered;\s*\}\);", refresh_state, content)

card_ui = """
                          final s = _students[index];
                          final avatarPath = _avatars[s.studentNo] ?? '';
                          final cs = Theme.of(context).colorScheme;
                          final tt = Theme.of(context).textTheme;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 0,
                            color: cs.surfaceContainerLow,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: cs.secondaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                  image: avatarPath.isNotEmpty && File(avatarPath).existsSync()
                                      ? DecorationImage(image: FileImage(File(avatarPath)), fit: BoxFit.cover)
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: (avatarPath.isEmpty || !File(avatarPath).existsSync())
                                    ? Text(s.fullName.isNotEmpty ? s.fullName.substring(0, 1) : '?',
                                        style: TextStyle(
                                            color: cs.onSecondaryContainer,
                                            fontWeight: FontWeight.bold))
                                    : null,
                              ),
"""

content = re.sub(r"final s = _students\[index\];\s*final cs = Theme\.of\(context\)\.colorScheme;\s*final tt = Theme\.of\(context\)\.textTheme;\s*return Card\([^C]+child: ListTile\([^l]+leading: Container\([^T]+Text\(s\.fullName\.substring\(0, 1\),[^)]+\)\),[^)]+\),", card_ui, content)

with open(f_students, 'w', encoding='utf-8') as file:
    file.write(content)
