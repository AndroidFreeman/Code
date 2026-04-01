import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../models/student.dart';
import '../main.dart';
import '../services/local_profiles.dart';
import '../state/session.dart';
import 'student_detail_page.dart';
import '../widgets/expressive_ui.dart';

class ClassStudentsPage extends StatefulWidget {
  final Session session;
  final VoidCallback? onReady;

  const ClassStudentsPage({super.key, required this.session, this.onReady});

  @override
  State<ClassStudentsPage> createState() => _ClassStudentsPageState();
}

class _ClassStudentsPageState extends State<ClassStudentsPage> {
  bool _loading = true;
  String _status = '';
  List<Student> _students = const [];

  List<String> _myClasses = [];
  String _selectedClass = '';

  static const _studentsHeader =
      'id,student_no,full_name,class_code,phone,position';

  Future<File> _studentsFile() async {
    return File(p.join(widget.session.dataDir, 'students.csv'));
  }

  Future<void> _ensureStudentsSchema() async {
    final f = await _studentsFile();
    if (!await f.exists()) {
      await f.writeAsString('$_studentsHeader\n', encoding: utf8);
      return;
    }
    final content = await f.readAsString(encoding: utf8);
    final lines = const LineSplitter().convert(content);
    if (lines.isEmpty) {
      await f.writeAsString('$_studentsHeader\n', encoding: utf8);
      return;
    }
    final header = lines.first.trim();
    if (header == _studentsHeader) return;
    if (header == 'id,student_no,full_name,class_code,phone') {
      final out = <String>[_studentsHeader];
      for (var i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        final parts = line.split(',');
        if (parts.length < 5) continue;
        out.add('${parts[0]},${parts[1]},${parts[2]},${parts[3]},${parts[4]},');
      }
      await f.writeAsString(out.join('\n') + '\n', encoding: utf8);
    }
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

  Future<void> _writeCsv(
      File f, List<String> headers, List<Map<String, String>> rows) async {
    final out = <String>[headers.join(',')];
    for (final r in rows) {
      out.add(headers.map((h) => (r[h] ?? '').replaceAll(',', '')).join(','));
    }
    await f.writeAsString(out.join('\n') + '\n', encoding: utf8);
  }

  String _positionLabel(String v, LocaleProvider loc) {
    final s = v.trim();
    if (s.isEmpty) return loc.t('普通学生', 'Regular Student');
    if (s == 'cadre') return loc.t('班干部', 'Class Cadre');
    return s;
  }

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final loc = Provider.of<LocaleProvider>(context, listen: false);
    if (!widget.session.canViewStudents) {
      setState(() {
        _loading = false;
        _status = loc.t('当前角色无查看班级学生权限',
            'Your role does not have permission to view students');
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

      final studentsFuture = widget.session.features.hasFeature('students_list').then((has) async {
        if (has) {
          return await widget.session.features.listStudents();
        } else {
          final cli = widget.session.cli;
          if (cli == null) {
            return {
              'ok': false,
              'error': {
                'message': loc.t(
                    '缺少 students_list，且未配置 campus_cli',
                    'Missing students_list, and campus_cli is not configured')
              }
            };
          }
          return await cli.call('students.list', {});
        }
      });

      final studentsRes = await studentsFuture;

      if (studentsRes['ok'] != true) {
        setState(() {
          _loading = false;
          _status = ((studentsRes['error'] ?? const {}) as Map)['message']
                  ?.toString() ??
              'unknown error';
        });
        widget.onReady?.call();
        return;
      }

      final raw = (((studentsRes['data'] ?? const {}) as Map)['items'] ??
          const []) as List;
      final studentMap = <String, Student>{};
      for (final e in raw) {
        final s = Student.fromJson((e as Map).cast<String, dynamic>());
        studentMap[s.id] = s;
      }
      final all = studentMap.values.toList();

      var sel = _selectedClass;
      if (sel.isEmpty || !classes.contains(sel)) {
        sel = classes.isNotEmpty ? classes.first : '';
      }

      final filtered = sel.isEmpty
          ? <Student>[]
          : all.where((s) => s.classCode.trim() == sel).toList(growable: false);
      filtered.sort((a, b) => a.studentNo.compareTo(b.studentNo));

      if (!mounted) return;
      setState(() {
        _loading = false;
        _myClasses = classes;
        _selectedClass = sel;
        _students = filtered;
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

  Future<void> _addStudent() async {
    if (!widget.session.canDeleteStudents) return;
    final loc = Provider.of<LocaleProvider>(context, listen: false);
    final noCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    var clsSel = _selectedClass;
    var pos = '';

    final res = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: Text(loc.t('新增学生', 'Add Student')),
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
                            border: const OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: nameCtrl,
                        decoration: InputDecoration(
                            labelText: loc.t('姓名', 'Name'),
                            border: const OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: (_myClasses.contains(clsSel) || clsSel.isEmpty)
                            ? clsSel
                            : '',
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: loc.t('班级（可选）', 'Class (Optional)'),
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: '',
                            child: Text(loc.t('（不指定）', '(Not specified)')),
                          ),
                          ..._myClasses.map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(c),
                            ),
                          ),
                        ],
                        onChanged: (v) {
                          setLocal(() {
                            clsSel = (v ?? '').trim();
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: phoneCtrl,
                        decoration: InputDecoration(
                            labelText: loc.t('电话', 'Phone'),
                            border: const OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      if (widget.session.isTeacher)
                        DropdownButtonFormField<String>(
                          value: pos,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: loc.t('职位', 'Position'),
                            border: const OutlineInputBorder(),
                          ),
                          items: [
                            DropdownMenuItem(
                                value: '',
                                child: Text(
                                    loc.t('普通学生', 'Regular Student'))),
                            DropdownMenuItem(
                                value: 'cadre',
                                child: Text(loc.t('班干部', 'Class Cadre'))),
                          ],
                          onChanged: (v) {
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
                    child: Text(loc.t('取消', 'Cancel'))),
                FilledButton(
                    onPressed: () => Navigator.of(ctx).pop('ok'),
                    child: Text(loc.t('保存', 'Save'))),
              ],
            );
          },
        );
      },
    );

    final no = noCtrl.text.trim();
    final name = nameCtrl.text.trim();
    final phone = phoneCtrl.text.trim();
    final cls = clsSel.trim().isEmpty ? _selectedClass.trim() : clsSel.trim();
    Future.microtask(() {
      noCtrl.dispose();
      nameCtrl.dispose();
      phoneCtrl.dispose();
    });
    if (res != 'ok') return;
    if (no.isEmpty || !no.startsWith('S')) {
      setState(() {
        _status = loc.t('学号必须以 S 开头', 'Student ID must start with "S"');
      });
      return;
    }
    if (name.isEmpty) {
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
      await _ensureStudentsSchema();
      final f = await _studentsFile();
      final content = await f.readAsString(encoding: utf8);
      final lines = const LineSplitter()
          .convert(content)
          .where((e) => e.trim().isNotEmpty)
          .toList();
      final header = (lines.isEmpty ? _studentsHeader : lines.first).trim();
      final headers = header.split(',');
      final rows = await _readCsvRows(f);
      final exists = rows.any((r) => (r['student_no'] ?? '').trim() == no);
      if (exists) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _status = loc.t('学号已存在', 'Student ID already exists');
        });
        return;
      }
      rows.add({
        'id': 's_${DateTime.now().millisecondsSinceEpoch}',
        'student_no': no.replaceAll(',', ''),
        'full_name': name.replaceAll(',', ''),
        'class_code': cls.replaceAll(',', ''),
        'phone': phone.replaceAll(',', ''),
        'position': pos.replaceAll(',', ''),
      });
      await _writeCsv(f, headers, rows);
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _status = e.toString();
      });
      widget.onReady?.call();
    }
  }

  Future<void> _deleteStudent(Student s) async {
    if (!widget.session.canDeleteStudents) return;
    final loc = Provider.of<LocaleProvider>(context, listen: false);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(loc.t('删除学生', 'Delete Student')),
          content: Text(loc.t('确认删除 ${s.fullName}（${s.studentNo}）？',
              'Delete ${s.fullName} (${s.studentNo})?')),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(loc.t('取消', 'Cancel'))),
            FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(loc.t('删除', 'Delete'))),
          ],
        );
      },
    );
    if (ok != true) return;

    setState(() {
      _loading = true;
      _status = '';
    });

    try {
      await _ensureStudentsSchema();
      final f = await _studentsFile();
      final content = await f.readAsString(encoding: utf8);
      final lines = const LineSplitter()
          .convert(content)
          .where((e) => e.trim().isNotEmpty)
          .toList();
      if (lines.isEmpty) {
        await _refresh();
        return;
      }
      final headers = lines.first.split(',');
      final rows = await _readCsvRows(f);
      rows.removeWhere((r) => (r['id'] ?? '').trim() == s.id);
      await _writeCsv(f, headers, rows);
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _status = e.toString();
      });
      widget.onReady?.call();
    }
  }

  Future<void> _addClass() async {
    final loc = Provider.of<LocaleProvider>(context, listen: false);
    final ctrl = TextEditingController();
    final res = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.t('添加班级', 'Add Class')),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
              labelText: loc.t('班级代码', 'Class Code'),
              border: const OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop('cancel'),
              child: Text(loc.t('取消', 'Cancel'))),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop('ok'),
              child: Text(loc.t('添加', 'Add'))),
        ],
      ),
    );
    final val = ctrl.text.trim();
    ctrl.dispose();
    if (res != 'ok' || val.isEmpty) return;

    setState(() {
      _loading = true;
    });
    try {
      await LocalProfiles.addTeacherClass(
          widget.session.dataDir, widget.session.profile.id, val);
      if (!mounted) return;
      setState(() {
        _selectedClass = val;
      });
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _status = e.toString();
      });
      widget.onReady?.call();
    }
  }

  Future<void> _deleteClass() async {
    if (_selectedClass.isEmpty) return;
    final loc = Provider.of<LocaleProvider>(context, listen: false);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.t('删除班级', 'Delete Class')),
        content: Text(loc.t(
            '确认删除班级 $_selectedClass？\n此操作仅从您的管理列表中移除该班级。',
            'Delete class $_selectedClass?\nThis will only remove it from your managed list.')),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(loc.t('取消', 'Cancel'))),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(loc.t('删除', 'Delete'))),
        ],
      ),
    );
    if (ok != true) return;

    setState(() {
      _loading = true;
    });
    try {
      await LocalProfiles.removeTeacherClass(
          widget.session.dataDir, widget.session.profile.id, _selectedClass);
      _selectedClass = '';
      await _refresh();
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
    final loc = Provider.of<LocaleProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.t('学生管理', 'Students')),
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: ExpressiveSelector(
                label: loc.t('班级', 'Class'),
                value: _selectedClass.isEmpty ? null : _selectedClass,
                items: [
                  ..._myClasses,
                  loc.t('＋ 添加班级', '+ Add Class'),
                  if (_selectedClass.isNotEmpty) '__delete__',
                ],
                customLabelBuilder: (val) {
                  if (val == '__delete__')
                    return loc.t('删除当前班级', 'Delete Current Class');
                  return val;
                },
                onSelected: (v) async {
                  if (v == loc.t('＋ 添加班级', '+ Add Class')) {
                    await _addClass();
                    return;
                  }
                  if (v == '__delete__') {
                    await _deleteClass();
                    return;
                  }
                  setState(() {
                    _selectedClass = v;
                    _loading = true;
                  });
                  _refresh();
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: widget.session.canDeleteStudents
          ? FloatingActionButton(
              heroTag: 'fab_add_student',
              onPressed: _loading ? null : _addStudent,
              elevation: 2,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
              shape: const CircleBorder(),
              child: const Icon(Icons.person_add_alt_1_rounded),
            )
          : null,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: _status.trim().isNotEmpty
                ? Center(
                    child: Text(
                      _status,
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                  )
                : _loading
                    ? const SizedBox.shrink()
                    : _students.isEmpty
                        ? Center(child: Text(loc.t('暂无学生', 'No students')))
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 80),
                        itemCount: _students.length,
                        itemBuilder: (context, index) {
                          final s = _students[index];
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
                                ),
                                alignment: Alignment.center,
                                child: Text(s.fullName.substring(0, 1),
                                    style: TextStyle(
                                        color: cs.onSecondaryContainer,
                                        fontWeight: FontWeight.bold)),
                              ),
                              title: Text(s.fullName,
                                  style: tt.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                '${s.studentNo} · ${_positionLabel(s.position, loc)}',
                                style: tt.bodySmall,
                              ),
                              trailing: widget.session.canDeleteStudents
                                  ? IconButton(
                                      onPressed: _loading
                                          ? null
                                          : () => _deleteStudent(s),
                                      icon: Icon(Icons.delete_outline,
                                          color: cs.error),
                                    )
                                  : Icon(Icons.chevron_right,
                                      color: cs.outline),
                              onTap: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => StudentDetailPage(
                                      session: widget.session,
                                      student: s,
                                    ),
                                  ),
                                );
                                if (mounted) {
                                  _refresh();
                                }
                              },
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
