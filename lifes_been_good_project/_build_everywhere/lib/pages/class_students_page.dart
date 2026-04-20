import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/student.dart';
import '../main.dart';
import '../services/local_profiles.dart';
import '../state/session.dart';
import '../widgets/expressive_ui.dart';

class ClassStudentsPage extends StatefulWidget {
  final Session session;
  final VoidCallback? onReady;

  const ClassStudentsPage({super.key, required this.session, this.onReady});

  @override
  State<ClassStudentsPage> createState() => _ClassStudentsPageState();
}

class _ClassStudentsPageState extends State<ClassStudentsPage> {
  bool _loading = false;
  String _status = '';
  List<Student> _students = const [];
  Map<String, String> _avatarMap = const {};

  List<String> _myClasses = [];
  String _selectedClass = '';

  static const _studentsHeader =
      'id,student_no,full_name,class_code,phone,position';

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

      final studentsFuture =
          widget.session.features.hasFeature('students_list').then((has) async {
        if (has) {
          return await widget.session.features.listStudents();
        } else {
          final cli = widget.session.cli;
          if (cli == null) {
            return {
              'ok': false,
              'error': {
                'message': loc.t('缺少 students_list，且未配置 campus_cli',
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

      final profilesRes = await widget.session.features
          .csvOp(action: 'read', file: 'profiles.csv');
      final avatarMap = <String, String>{};
      if (profilesRes['ok'] == true) {
        final pItems = ((profilesRes['data'] ?? const {})['items'] as List?) ?? [];
        for (final pi in pItems) {
          final row = (pi as Map).cast<String, String>();
          final pid = (row['id'] ?? '').trim();
          final av = (row['avatar'] ?? '').trim();
          if (pid.isNotEmpty && av.isNotEmpty) avatarMap[pid] = av;
        }
      }

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
        _avatarMap = avatarMap;
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

  Future<void> _editStudent(Student s) async {
    final loc = Provider.of<LocaleProvider>(context, listen: false);
    final nameCtrl = TextEditingController(text: s.fullName);
    final noCtrl = TextEditingController(text: s.studentNo);
    final phoneCtrl = TextEditingController(text: s.phone);
    var pos = s.position.trim().isEmpty ? '' : s.position.trim();

    List<String> allClasses = [];
    try {
      allClasses = await LocalProfiles.getAllClasses(widget.session.dataDir);
    } catch (_) {}

    var selectedClass = s.classCode.trim();
    if (selectedClass.isEmpty && allClasses.isNotEmpty) {
      selectedClass = allClasses.first;
    }

    if (!mounted) return;

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
                          filled: true,
                          fillColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 77),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(28),
                            borderSide: BorderSide.none,
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.never,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: nameCtrl,
                        decoration: InputDecoration(
                          labelText: loc.t('姓名', 'Name'),
                          filled: true,
                          fillColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 77),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(28),
                            borderSide: BorderSide.none,
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.never,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: (allClasses.contains(selectedClass) ||
                                selectedClass.isEmpty)
                            ? selectedClass
                            : null,
                        decoration: InputDecoration(
                          labelText: loc.t('班级', 'Class'),
                          filled: true,
                          fillColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 77),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(28),
                            borderSide: BorderSide.none,
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.never,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: '',
                            child: Text(loc.t('（不指定）', '(Not specified)')),
                          ),
                          ...allClasses.map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)))
                        ],
                        onChanged: (v) {
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
                          filled: true,
                          fillColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 77),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(28),
                            borderSide: BorderSide.none,
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.never,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (widget.session.isTeacher)
                        DropdownButtonFormField<String>(
                          initialValue: pos.isEmpty ? '' : pos,
                          decoration: InputDecoration(
                            labelText: loc.t('职位', 'Position'),
                            filled: true,
                            fillColor: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 77),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(28),
                              borderSide: BorderSide.none,
                            ),
                            floatingLabelBehavior: FloatingLabelBehavior.never,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: '',
                              child: Text(loc.t('普通学生', 'Regular Student')),
                            ),
                            DropdownMenuItem(
                              value: 'monitor',
                              child: Text(loc.t('班长', 'Monitor')),
                            ),
                            DropdownMenuItem(
                              value: 'study',
                              child: Text(loc.t('学习委员', 'Study Comm.')),
                            ),
                            DropdownMenuItem(
                              value: 'publicity',
                              child: Text(loc.t('宣传委员', 'Publicity Comm.')),
                            ),
                            DropdownMenuItem(
                              value: 'life',
                              child: Text(loc.t('生活委员', 'Life Comm.')),
                            ),
                            DropdownMenuItem(
                              value: 'psychological',
                              child: Text(loc.t('心理委员', 'Psych Comm.')),
                            ),
                            DropdownMenuItem(
                              value: 'organize',
                              child: Text(loc.t('组织委员', 'Organize Comm.')),
                            ),
                            DropdownMenuItem(
                              value: 'branch_secretary',
                              child: Text(loc.t('团支书', 'Branch Secretary')),
                            ),
                            DropdownMenuItem(
                              value: 'cadre',
                              child: Text(loc.t('班干部', 'Class Cadre')),
                            ),
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

    noCtrl.dispose();
    nameCtrl.dispose();
    phoneCtrl.dispose();

    if (res != 'ok') return;

    if (!mounted) return;
    if (!await widget.session.features.hasFeature('students_insert')) {
      setState(() {
        _status = loc.t(
            '未找到二进制：students_insert', 'Binary not found: students_insert');
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _loading = true;
      _status = '';
    });

    final res2 = await widget.session.features.insertStudent(
      id: s.id,
      studentNo: newNo,
      fullName: newName,
      classCode: selectedClass,
      phone: newPhone,
      position: pos,
    );

    if (res2['ok'] != true) {
      final msg = ((res2['error'] ?? const {}) as Map)['message']?.toString() ??
          'unknown error';
      setState(() {
        _loading = false;
        _status = msg;
      });
      return;
    }

    await _refresh();
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
            final cs = Theme.of(ctx).colorScheme;
            return AlertDialog(
              title: Text(loc.t('添加学生', 'Add Student')),
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
                          filled: true,
                          fillColor:
                              cs.surfaceContainerHighest.withValues(alpha: 77),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(28),
                            borderSide: BorderSide.none,
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.never,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: nameCtrl,
                        decoration: InputDecoration(
                          labelText: loc.t('姓名', 'Name'),
                          filled: true,
                          fillColor:
                              cs.surfaceContainerHighest.withValues(alpha: 77),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(28),
                            borderSide: BorderSide.none,
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.never,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue:
                            (_myClasses.contains(clsSel) || clsSel.isEmpty)
                                ? clsSel
                                : null,
                        decoration: InputDecoration(
                          labelText: loc.t('班级（可选）', 'Class (Optional)'),
                          filled: true,
                          fillColor:
                              cs.surfaceContainerHighest.withValues(alpha: 77),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(28),
                            borderSide: BorderSide.none,
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.never,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: '',
                            child: Text(loc.t('（不指定）', '(Not specified)')),
                          ),
                          ..._myClasses.map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)))
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
                          filled: true,
                          fillColor:
                              cs.surfaceContainerHighest.withValues(alpha: 77),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(28),
                            borderSide: BorderSide.none,
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.never,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (widget.session.isTeacher)
                        DropdownButtonFormField<String>(
                          initialValue: pos.isEmpty ? '' : pos,
                          decoration: InputDecoration(
                            labelText: loc.t('职位', 'Position'),
                            filled: true,
                            fillColor: cs.surfaceContainerHighest
                                .withValues(alpha: 77),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(28),
                              borderSide: BorderSide.none,
                            ),
                            floatingLabelBehavior: FloatingLabelBehavior.never,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: '',
                              child: Text(loc.t('普通学生', 'Regular Student')),
                            ),
                            DropdownMenuItem(
                              value: 'monitor',
                              child: Text(loc.t('班长', 'Monitor')),
                            ),
                            DropdownMenuItem(
                              value: 'study',
                              child: Text(loc.t('学习委员', 'Study Comm.')),
                            ),
                            DropdownMenuItem(
                              value: 'publicity',
                              child: Text(loc.t('宣传委员', 'Publicity Comm.')),
                            ),
                            DropdownMenuItem(
                              value: 'life',
                              child: Text(loc.t('生活委员', 'Life Comm.')),
                            ),
                            DropdownMenuItem(
                              value: 'psychological',
                              child: Text(loc.t('心理委员', 'Psych Comm.')),
                            ),
                            DropdownMenuItem(
                              value: 'organize',
                              child: Text(loc.t('组织委员', 'Organize Comm.')),
                            ),
                            DropdownMenuItem(
                              value: 'branch_secretary',
                              child: Text(loc.t('团支书', 'Branch Secretary')),
                            ),
                            DropdownMenuItem(
                              value: 'cadre',
                              child: Text(loc.t('班干部', 'Class Cadre')),
                            ),
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
      final res = await widget.session.features
          .csvOp(action: 'read', file: 'students.csv');
      final items = ((res['data'] ?? const {})['items'] as List?) ?? const [];
      final rows = items.map((e) => (e as Map).cast<String, String>()).toList();

      final exists = rows.any((r) => (r['student_no'] ?? '').trim() == no);
      if (exists) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _status = loc.t('学号已存在', 'Student ID already exists');
        });
        return;
      }
      final newId = 's_${DateTime.now().millisecondsSinceEpoch}';
      rows.add({
        'id': newId,
        'student_no': no.replaceAll(',', ''),
        'full_name': name.replaceAll(',', ''),
        'class_code': cls.replaceAll(',', ''),
        'phone': phone.replaceAll(',', ''),
        'position': pos.replaceAll(',', ''),
      });
      final headers = _studentsHeader.split(',');
      await widget.session.features.csvOp(
          action: 'write', file: 'students.csv', headers: headers, rows: rows);
      await _refresh();
      final defaultPwd = await LocalProfiles.ensureStudentAccountByTeacher(
        dataDir: widget.session.dataDir,
        profileId: newId,
        studentNo: no,
        fullName: name,
        classCode: cls,
        phone: phone,
      );
      if (defaultPwd != null && mounted) {
        setState(() {
          _status = loc.t(
            '已创建学生账号，默认密码：$defaultPwd',
            'Student account created. Default password: $defaultPwd',
          );
        });
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
      final res = await widget.session.features
          .csvOp(action: 'read', file: 'students.csv');
      final items = ((res['data'] ?? const {})['items'] as List?) ?? const [];
      final rows = items.map((e) => (e as Map).cast<String, String>()).toList();

      rows.removeWhere((r) => (r['id'] ?? '').trim() == s.id);

      final headers = _studentsHeader.split(',');
      await widget.session.features.csvOp(
          action: 'write', file: 'students.csv', headers: headers, rows: rows);
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
        content: Text(loc.t('确认删除班级 $_selectedClass？\n此操作仅从您的管理列表中移除该班级。',
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

    final isDesktop =
        Platform.isWindows || Platform.isLinux || Platform.isMacOS;
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final showDrawerButton =
        (!isDesktop || isPortrait) && !(Platform.isAndroid && isTablet);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.t('学生名单', 'Students'),
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
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
        centerTitle: false,
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
                  if (val == '__delete__') {
                    return loc.t('删除当前班级', 'Delete Current Class');
                  }
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
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
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
                                child: (_avatarMap.containsKey(s.id) &&
                                        File(_avatarMap[s.id]!).existsSync())
                                    ? null
                                    : Text(s.fullName.substring(0, 1),
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
                              trailing: null,
                              onTap: () async {
                                final loc = Provider.of<LocaleProvider>(context,
                                    listen: false);
                                await showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (ctx) {
                                      return Container(
                                        padding: const EdgeInsets.all(24),
                                        decoration: BoxDecoration(
                                          color: cs.surfaceContainerLowest,
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                  top: Radius.circular(28)),
                                        ),
                                        child: SafeArea(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 40,
                                                height: 4,
                                                margin: const EdgeInsets.only(
                                                    bottom: 24),
                                                decoration: BoxDecoration(
                                                  color: cs.onSurfaceVariant
                                                      .withValues(alpha: 0.4),
                                                  borderRadius:
                                                      BorderRadius.circular(2),
                                                ),
                                              ),
                                              Text(
                                                loc.t(
                                                    '学生操作', 'Student Options'),
                                                style: tt.titleLarge?.copyWith(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              const SizedBox(height: 24),
                                              ListTile(
                                                leading: Icon(
                                                    Icons.edit_note_rounded,
                                                    color: cs.primary),
                                                title: Text(loc.t('编辑学生信息',
                                                    'Edit Student Info')),
                                                onTap: () {
                                                  Navigator.of(ctx).pop();
                                                  if (!_loading) {
                                                    _editStudent(s);
                                                  }
                                                },
                                              ),
                                              if (widget
                                                  .session.canDeleteStudents)
                                                ListTile(
                                                  leading: Icon(
                                                      Icons.delete_outline,
                                                      color: cs.error),
                                                  title: Text(
                                                      loc.t('删除学生',
                                                          'Delete Student'),
                                                      style: TextStyle(
                                                          color: cs.error)),
                                                  onTap: () {
                                                    Navigator.of(ctx).pop();
                                                    if (!_loading) {
                                                      _deleteStudent(s);
                                                    }
                                                  },
                                                ),
                                            ],
                                          ),
                                        ),
                                      );
                                    });
                              },
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
