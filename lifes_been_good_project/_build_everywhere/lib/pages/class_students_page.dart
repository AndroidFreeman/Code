import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/student.dart';
import '../main.dart';
import '../services/local_profiles.dart';
import '../services/api_config.dart';
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
  Map<String, String> _classNameByCode = const {};
  StreamSubscription<SessionDataChange>? _dataChangeSub;

  List<Map<String, String>> _myClassesWithNames = [];
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

  static const _uiPrefsFileName = 'class_students_ui_prefs.json';

  @override
  void initState() {
    super.initState();
    _dataChangeSub = widget.session
        .watchDataChanges({'students', 'classes', 'profiles'}).listen((_) {
      if (mounted) {
        unawaited(_refresh());
      }
    });
    _loadUiPrefs().then((_) {
      _refresh();
    });
  }

  @override
  void dispose() {
    _dataChangeSub?.cancel();
    super.dispose();
  }

  Future<void> _loadUiPrefs() async {
    try {
      final f = File(p.join(widget.session.dataDir, _uiPrefsFileName));
      if (!await f.exists()) return;
      final decoded = jsonDecode(await f.readAsString());
      if (decoded is Map && decoded['selectedClass'] != null) {
        _selectedClass = decoded['selectedClass'].toString();
      }
    } catch (_) {}
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
      final isTeacher = widget.session.profile.role == 'teacher';

      final allClassesMapList =
          await LocalProfiles.getAllClassesWithNames(widget.session.dataDir);

      List<String> classes = [];
      if (isTeacher) {
        classes = await LocalProfiles.getTeacherClasses(
          widget.session.dataDir,
          widget.session.profile.id,
        );
      } else {
        final code = widget.session.profile.classCode;
        if (code.isNotEmpty) classes.add(code);
      }

      final myClassesWithNames =
          allClassesMapList.where((e) => classes.contains(e['id'])).toList();
      final classNameByCode = {
        for (final row in allClassesMapList)
          (row['id'] ?? '').trim(): ((row['name'] ?? '').trim().isEmpty
              ? (row['id'] ?? '').trim()
              : (row['name'] ?? '').trim()),
      };

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

      Map<String, dynamic> profilesRes;
      if (await widget.session.features.hasFeature('profiles_list')) {
        profilesRes = await widget.session.features.listProfiles();
      } else {
        final cli = widget.session.cli;
        if (cli != null) {
          profilesRes = await cli.call('profiles.list', {});
        } else {
          profilesRes = {'ok': false};
        }
      }
      final avatarMap = <String, String>{};
      if (profilesRes['ok'] == true) {
        final pItems =
            ((profilesRes['data'] ?? const {})['items'] as List?) ?? [];
        for (final pi in pItems) {
          final row = (pi as Map).cast<String, dynamic>();
          final pid = (row['id'] ?? '').toString().trim();
          final av = (row['avatar'] ?? '').toString().trim();
          if (pid.isNotEmpty && av.isNotEmpty) avatarMap[pid] = av;
        }
      }
      final sessionAvatar = widget.session.profile.avatar.trim();
      if (sessionAvatar.isNotEmpty) {
        avatarMap[widget.session.profile.id] = sessionAvatar;
      }

      var sel = _selectedClass;
      if (sel.isEmpty || !classes.contains(sel)) {
        sel = classes.isNotEmpty ? classes.first : '';
      }

      final filtered = sel.isEmpty
          ? <Student>[]
          : all
              .where((s) => s.classCode.trim() == sel)
              .map((s) => s.copyWith(
                    className:
                        classNameByCode[s.classCode.trim()] ?? s.className,
                  ))
              .toList(growable: false);
      filtered.sort((a, b) => a.studentNo.compareTo(b.studentNo));

      if (!mounted) return;
      setState(() {
        _loading = false;
        _myClassesWithNames = myClassesWithNames;
        _myClasses = classes;
        _classNameByCode = classNameByCode;
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
    Map<String, String> classNameByCode = const {};
    try {
      allClasses = await LocalProfiles.getAllClasses(widget.session.dataDir);
      final rows =
          await LocalProfiles.getAllClassesWithNames(widget.session.dataDir);
      classNameByCode = {
        for (final row in rows)
          (row['id'] ?? '').trim(): ((row['name'] ?? '').trim().isEmpty
              ? (row['id'] ?? '').trim()
              : (row['name'] ?? '').trim()),
      };
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
              content: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 400),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: noCtrl,
                        readOnly: true,
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
                      SizedBox(
                        width: double.infinity,
                        child: ExpressiveSelector(
                          label: loc.t('班级', 'Class'),
                          value: selectedClass.isEmpty ? '' : selectedClass,
                          leadingIcon: Icons.school_rounded,
                          items: ['', ...allClasses],
                          customLabelBuilder: (value) {
                            if (value.isEmpty) {
                              return loc.t('（不指定）', '(Not specified)');
                            }
                            return classNameByCode[value] ?? value;
                          },
                          onSelected: (value) {
                            setLocal(() {
                              selectedClass = value;
                            });
                          },
                        ),
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
                        SizedBox(
                          width: double.infinity,
                          child: ExpressiveSelector(
                            label: loc.t('职位', 'Position'),
                            value: pos.isEmpty ? '' : pos,
                            leadingIcon: Icons.workspace_premium_rounded,
                            items: const [
                              '',
                              'monitor',
                              'study',
                              'publicity',
                              'life',
                              'psychological',
                              'organize',
                              'branch_secretary',
                              'cadre',
                            ],
                            customLabelBuilder: (value) =>
                                _positionLabel(value, loc),
                            onSelected: (value) {
                              setLocal(() {
                                pos = value;
                              });
                            },
                          ),
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
    final classNameByCode = {
      for (final row in _myClassesWithNames)
        (row['id'] ?? '').trim(): ((row['name'] ?? '').trim().isEmpty
            ? (row['id'] ?? '').trim()
            : (row['name'] ?? '').trim()),
    };

    final res = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            final cs = Theme.of(ctx).colorScheme;
            return AlertDialog(
              title: Text(loc.t('添加学生', 'Add Student')),
              content: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 400),
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
                      SizedBox(
                        width: double.infinity,
                        child: ExpressiveSelector(
                          label: loc.t('班级（可选）', 'Class (Optional)'),
                          value: clsSel.isEmpty ? '' : clsSel,
                          leadingIcon: Icons.school_rounded,
                          items: ['', ..._myClasses],
                          customLabelBuilder: (value) {
                            if (value.isEmpty) {
                              return loc.t('（不指定）', '(Not specified)');
                            }
                            return classNameByCode[value] ?? value;
                          },
                          onSelected: (value) {
                            setLocal(() {
                              clsSel = value.trim();
                            });
                          },
                        ),
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
                        SizedBox(
                          width: double.infinity,
                          child: ExpressiveSelector(
                            label: loc.t('职位', 'Position'),
                            value: pos.isEmpty ? '' : pos,
                            leadingIcon: Icons.workspace_premium_rounded,
                            items: const [
                              '',
                              'monitor',
                              'study',
                              'publicity',
                              'life',
                              'psychological',
                              'organize',
                              'branch_secretary',
                              'cadre',
                            ],
                            customLabelBuilder: (value) =>
                                _positionLabel(value, loc),
                            onSelected: (value) {
                              setLocal(() {
                                pos = value;
                              });
                            },
                          ),
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

    if (ApiConfig.instance.useCloud) {
      final action = await showDialog<String>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: Text(loc.t('添加班级', 'Add Class')),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.of(ctx).pop('create'),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(loc.t('创建新班级', 'Create New Class'),
                    style: const TextStyle(fontSize: 16)),
              ),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.of(ctx).pop('join'),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(loc.t('加入现有班级', 'Join Existing Class'),
                    style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      );

      if (action == null) return;
      if (!mounted) return;
      if (!mounted) return;

      final codeCtrl = TextEditingController();
      final nameCtrl = TextEditingController();
      final passCtrl = TextEditingController();

      final res = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(action == 'create'
              ? loc.t('创建新班级', 'Create New Class')
              : loc.t('加入现有班级', 'Join Existing Class')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (action == 'join')
                TextField(
                  controller: codeCtrl,
                  decoration: InputDecoration(
                      labelText: loc.t('班级代码', 'Class Code'),
                      border: const OutlineInputBorder()),
                ),
              if (action == 'create')
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                      labelText: loc.t('班级名称', 'Class Name'),
                      border: const OutlineInputBorder()),
                ),
              const SizedBox(height: 16),
              TextField(
                controller: passCtrl,
                obscureText: true,
                decoration: InputDecoration(
                    labelText: loc.t('入班密码', 'Join Password'),
                    border: const OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop('cancel'),
                child: Text(loc.t('取消', 'Cancel'))),
            FilledButton(
                onPressed: () => Navigator.of(ctx).pop('ok'),
                child: Text(loc.t('确定', 'OK'))),
          ],
        ),
      );

      final code = codeCtrl.text.trim();
      final name = nameCtrl.text.trim();
      final pass = passCtrl.text.trim();
      codeCtrl.dispose();
      nameCtrl.dispose();
      passCtrl.dispose();

      if (res != 'ok') return;

      if (!mounted) return;

      setState(() {
        _loading = true;
        _status = '';
      });

      try {
        String targetCode = code;
        if (action == 'create') {
          if (name.isEmpty || pass.isEmpty) {
            throw loc.t('名称和密码不能为空', 'Name and password cannot be empty');
          }
          final cRes = await ApiConfig.instance.post('/api/classes', {
            'className': name,
            'joinPassword': pass,
            'createdByProfileId': widget.session.profile.id,
          });
          if (cRes['ok'] != true) {
            throw cRes['error']?['message'] ?? 'Failed to create class';
          }
          targetCode = cRes['data']['id'];
        } else {
          if (code.isEmpty || pass.isEmpty) {
            throw loc.t('代码和密码不能为空', 'Code and password cannot be empty');
          }
          final vRes = await ApiConfig.instance
              .post('/api/classes/$code/verify', {'password': pass});
          if (vRes['ok'] != true) {
            throw loc.t('密码错误或班级不存在', 'Incorrect password or class not found');
          }
        }

        await LocalProfiles.addTeacherClass(
            widget.session.dataDir, widget.session.profile.id, targetCode);
        if (!mounted) return;
        setState(() {
          _selectedClass = targetCode;
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
      return;
    }

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

    if (!mounted) return;

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

    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(loc.t('班级操作', 'Class Action')),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.of(ctx).pop('remove'),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(loc.t('仅从我的列表中移除', 'Remove from my list only'),
                  style: const TextStyle(fontSize: 16)),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(ctx).pop('delete'),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                  loc.t('解散并删除该班级', 'Disband and delete class globally'),
                  style: const TextStyle(fontSize: 16, color: Colors.red)),
            ),
          ),
        ],
      ),
    );

    if (action == null) return;

    if (action == 'delete') {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(loc.t('危险操作', 'Danger Zone')),
          content: Text(loc.t(
              '确认要解散并删除班级 $_selectedClass 吗？\n所有相关课表将被删除，学生将变为无班级状态。',
              'Are you sure you want to disband and delete class $_selectedClass?\nAll related timetables will be deleted, and students will become classless.')),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(loc.t('取消', 'Cancel'))),
            FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(loc.t('删除', 'Delete'))),
          ],
        ),
      );
      if (ok != true) return;
      if (!mounted) return;
    } else {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(loc.t('移除班级', 'Remove Class')),
          content: Text(loc.t('确认从您的管理列表中移除班级 $_selectedClass？',
              'Remove class $_selectedClass from your managed list?')),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(loc.t('取消', 'Cancel'))),
            FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(loc.t('移除', 'Remove'))),
          ],
        ),
      );
      if (ok != true) return;
      if (!mounted) return;
    }

    if (!mounted) return;
    setState(() {
      _loading = true;
    });
    try {
      if (action == 'delete') {
        if (ApiConfig.instance.useCloud) {
          await ApiConfig.instance.delete('/api/classes/$_selectedClass');
        } else {
          // Fallback if local: completely disband class
          await LocalProfiles.disbandClassLocally(
              widget.session.dataDir, _selectedClass);
        }
      } else {
        await LocalProfiles.removeTeacherClass(
            widget.session.dataDir, widget.session.profile.id, _selectedClass);
      }

      if (!mounted) return;
      setState(() {
        _selectedClass = '';
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

  String? _resolveAvatarUrlOrPath(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return null;
    if (v.startsWith('data:image')) return v;
    final uri = Uri.tryParse(v);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return v;
    }
    if (uri != null && uri.scheme == 'file') {
      return uri.toFilePath();
    }
    if (p.isAbsolute(v)) return v;
    return p.join(widget.session.dataDir, v);
  }

  DecorationImage? _getAvatarImage(String path) {
    final resolved = _resolveAvatarUrlOrPath(path) ?? '';
    return AvatarImageProvider.getDecorationImage(resolved);
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
        title: Text(loc.t('学生名单', 'Students')),
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
                  if (val != loc.t('＋ 添加班级', '+ Add Class')) {
                    final match = _myClassesWithNames
                        .firstWhere((e) => e['id'] == val, orElse: () => {});
                    if (match.isNotEmpty) {
                      return match['name']!;
                    }
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
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                    width: 1,
                                  ),
                                  image:
                                      _getAvatarImage(_avatarMap[s.id] ?? ''),
                                ),
                                alignment: Alignment.center,
                                child:
                                    (_getAvatarImage(_avatarMap[s.id] ?? '') ==
                                            null)
                                        ? Text(s.fullName.substring(0, 1),
                                            style: TextStyle(color: cs.primary))
                                        : null,
                              ),
                              title: Text(s.fullName),
                              subtitle: Text(
                                _classNameByCode[s.classCode.trim()]
                                            ?.trim()
                                            .isNotEmpty ==
                                        true
                                    ? '${s.studentNo} · ${_classNameByCode[s.classCode.trim()]} · ${_positionLabel(s.position, loc)}'
                                    : '${s.studentNo} · ${_positionLabel(s.position, loc)}',
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
