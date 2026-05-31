import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../models/student.dart';
import '../services/local_profiles.dart';
import '../state/session.dart';
import '../widgets/expressive_ui.dart';

class StudentsPage extends StatefulWidget {
  final Session session;

  const StudentsPage({super.key, required this.session});

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  bool _loading = true;
  String _status = '';
  final _query = TextEditingController();
  List<Student> _items = const [];
  StreamSubscription<SessionDataChange>? _dataChangeSub;

  @override
  void initState() {
    super.initState();

    if (widget.session.preloadedData['students'] != null) {
      try {
        final raw = ((widget.session.preloadedData['students'] as Map)['items']
                as List?) ??
            [];
        _items = raw
            .map((e) => Student.fromJson((e as Map).cast<String, dynamic>()))
            .toList();
        _items.sort((a, b) => a.studentNo.compareTo(b.studentNo));
        _loading = false;
      } catch (_) {}
    }

    _dataChangeSub = widget.session
        .watchDataChanges({'students', 'classes', 'profiles'}).listen((event) {
      if (mounted) {
        _refresh(isBackground: true, forceNetwork: event.remote);
      }
    });
    _refresh();
  }

  @override
  void dispose() {
    _dataChangeSub?.cancel();
    _query.dispose();
    super.dispose();
  }

  String _lastSignature = '';

  Future<void> _refresh(
      {bool isBackground = false,
      bool silent = false,
      bool forceNetwork = false}) async {
    if (!widget.session.canViewStudents) {
      final loc = Provider.of<LocaleProvider>(context, listen: false);
      setState(() {
        _loading = false;
        _status = loc.t('当前角色无权限查看学生信息',
            'Your role does not have permission to view student information');
      });
      return;
    }

    final loc = Provider.of<LocaleProvider>(context, listen: false);

    Map<String, dynamic> res;
    if (!forceNetwork && widget.session.preloadedData['students'] != null) {
      res = {'ok': true, 'data': widget.session.preloadedData['students']};
    } else if (await widget.session.features.hasFeature('students_list')) {
      res = await widget.session.features.listStudents();
      if (res['ok'] == true) {
        widget.session.preloadedData['students'] = res['data'];
      }
    } else {
      final cli = widget.session.cli;
      if (cli == null) {
        setState(() {
          _loading = false;
          _status = loc.t('缺少 students_list，且未配置 campus_cli',
              'Missing students_list, and campus_cli is not configured');
        });
        return;
      }
      res = await cli.call('students.list', {});
      if (res['ok'] == true) {
        widget.session.preloadedData['students'] = res['data'];
      }
    }
    if (res['ok'] != true) {
      final msg = ((res['error'] ?? const {}) as Map)['message']?.toString() ??
          'unknown error';
      setState(() {
        _loading = false;
        _status = msg;
      });
      return;
    }

    final raw =
        (((res['data'] ?? const {}) as Map)['items'] ?? const []) as List;
    final all = raw
        .map((e) => Student.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
    all.sort((a, b) => a.studentNo.compareTo(b.studentNo));

    final signature = all
        .map((s) => '${s.id}:${s.fullName}:${s.studentNo}:${s.classCode}')
        .join('|');
    if (signature == _lastSignature) {
      setState(() {
        _loading = false;
      });
      return;
    }
    _lastSignature = signature;

    setState(() {
      _loading = false;
      _items = all;
    });
  }

  Future<void> _addStudent() async {
    if (!widget.session.canDeleteStudents) return;
    final loc = Provider.of<LocaleProvider>(context, listen: false);

    final id = TextEditingController();
    final studentNo = TextEditingController();
    final fullName = TextEditingController();
    final phone = TextEditingController();
    var selectedClass = widget.session.profile.classCode.trim();
    var classOptions = <Map<String, String>>[];
    final classNameById = <String, String>{};
    try {
      classOptions =
          await LocalProfiles.getAllClassesWithNames(widget.session.dataDir);
      for (final row in classOptions) {
        final id = (row['id'] ?? '').trim();
        if (id.isEmpty) continue;
        final name = (row['name'] ?? '').trim();
        classNameById[id] = name.isEmpty ? id : name;
      }
    } catch (_) {}
    if (selectedClass.isEmpty && classOptions.isNotEmpty) {
      selectedClass = (classOptions.first['id'] ?? '').trim();
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        InputDecoration deco(String label) => InputDecoration(
              labelText: label,
              filled: true,
              fillColor: cs.surfaceContainerHighest.withValues(alpha: 77),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: BorderSide.none,
              ),
              floatingLabelBehavior: FloatingLabelBehavior.never,
            );
        return StatefulBuilder(
          builder: (context, setLocal) => AlertDialog(
            title: Text(loc.t('新增学生', 'Add Student')),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                        controller: id,
                        decoration:
                            deco(loc.t('ID（如 s_003）', 'ID (e.g. s_003)'))),
                    const SizedBox(height: 12),
                    TextField(
                        controller: studentNo,
                        decoration: deco(loc.t('学号', 'Student ID'))),
                    const SizedBox(height: 12),
                    TextField(
                        controller: fullName,
                        decoration: deco(loc.t('姓名', 'Name'))),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ExpressiveSelector(
                        label: loc.t('班级', 'Class'),
                        value: selectedClass.isEmpty ? '' : selectedClass,
                        leadingIcon: Icons.school_rounded,
                        items: [
                          '',
                          ...classOptions
                              .map((row) => (row['id'] ?? '').trim()),
                        ],
                        customLabelBuilder: (value) {
                          if (value.isEmpty) {
                            return loc.t('（不指定）', '(Not specified)');
                          }
                          return classNameById[value] ?? value;
                        },
                        onSelected: (value) {
                          setLocal(() {
                            selectedClass = value.trim();
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                        controller: phone,
                        decoration: deco(loc.t('手机号', 'Phone'))),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(loc.t('取消', 'Cancel'))),
              FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(loc.t('保存', 'Save'))),
            ],
          ),
        );
      },
    );

    if (ok != true) return;

    final vId = id.text.trim();
    final vStudentNo = studentNo.text.trim();
    final vFullName = fullName.text.trim();
    final vClassCode = selectedClass.trim();
    final vPhone = phone.text.trim();

    id.dispose();
    studentNo.dispose();
    fullName.dispose();
    phone.dispose();

    if (!await widget.session.features.hasFeature('students_insert')) {
      setState(() {
        _status = loc.t(
            '未找到二进制：students_insert', 'Binary not found: students_insert');
      });
      return;
    }

    setState(() {
      _status = '';
    });

    final res = await widget.session.features.insertStudent(
      id: vId,
      studentNo: vStudentNo,
      fullName: vFullName,
      classCode: vClassCode,
      phone: vPhone,
      position: '',
    );
    if (res['ok'] != true) {
      final msg = ((res['error'] ?? const {}) as Map)['message']?.toString() ??
          'unknown error';
      setState(() {
        _loading = false;
        _status = msg;
      });
      return;
    }

    await _refresh(silent: true);
  }

  Future<void> _deleteStudent(Student s) async {
    if (!widget.session.canDeleteStudents) return;
    final loc = Provider.of<LocaleProvider>(context, listen: false);

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.t('删除学生', 'Delete Student')),
        content: Text(loc.t('确认删除 ${s.fullName}（${s.studentNo}）？',
            'Delete ${s.fullName} (${s.studentNo})?')),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(loc.t('取消', 'Cancel'))),
          FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(loc.t('删除', 'Delete'))),
        ],
      ),
    );

    if (ok != true) return;

    setState(() {
      _status = '';
    });

    final res = await widget.session.features
        .deleteStudent(fullName: s.fullName, studentNo: s.studentNo);
    if (res['ok'] != true) {
      final msg = ((res['error'] ?? const {}) as Map)['message']?.toString() ??
          'unknown error';
      setState(() {
        _loading = false;
        _status = msg;
      });
      return;
    }

    await _refresh(silent: true);
  }

  List<Student> get _filtered {
    final q = _query.text.trim();
    if (q.isEmpty) return _items;
    return _items
        .where((s) => s.studentNo.contains(q) || s.fullName.contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    final loc = Provider.of<LocaleProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.t('学生信息', 'Students')),
        actions: [
          IconButton(
              onPressed: _loading ? null : _refresh,
              icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: widget.session.canDeleteStudents
          ? FloatingActionButton(
              onPressed: _loading ? null : _addStudent,
              child: const Icon(Icons.add),
            )
          : null,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _query,
                  decoration: InputDecoration(
                      labelText: loc.t('搜索（姓名/学号）', 'Search (Name / ID)'),
                      border: const OutlineInputBorder()),
                  onChanged: (_) => setState(() {}),
                ),
                if (_status.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(_status,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                  ),
                ],
                const SizedBox(height: 12),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () =>
                        _refresh(silent: false, forceNetwork: true),
                    child: (items.isEmpty && !_loading)
                        ? Stack(
                            children: [
                              ListView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics()),
                              Center(child: Text(loc.t('暂无数据', 'No data'))),
                            ],
                          )
                        : (items.isEmpty && _loading)
                            ? const SizedBox.shrink()
                            : ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: items.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final s = items[index];
                                  return ListTile(
                                    key: ValueKey(s.studentNo),
                                    leading: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color: Colors.grey.shade200),
                                      ),
                                      child: const Icon(Icons.person,
                                          color: Colors.grey),
                                    ),
                                    title: Text(loc.t(
                                        '${s.fullName}（${s.studentNo}）',
                                        '${s.fullName} (${s.studentNo})')),
                                    subtitle:
                                        Text('${s.classCode} · ${s.phone}'),
                                    trailing: widget.session.canDeleteStudents
                                        ? IconButton(
                                            onPressed: _loading
                                                ? null
                                                : () => _deleteStudent(s),
                                            icon: const Icon(
                                                Icons.delete_outline),
                                          )
                                        : null,
                                  );
                                },
                              ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
