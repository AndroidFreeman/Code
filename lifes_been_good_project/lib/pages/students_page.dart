import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../models/student.dart';
import '../state/session.dart';

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

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (!widget.session.canViewStudents) {
      final loc = Provider.of<LocaleProvider>(context, listen: false);
      setState(() {
        _loading = false;
        _items = const [];
        _status = loc.t('当前角色无权限查看学生信息',
            'Your role does not have permission to view student information');
      });
      return;
    }

    final loc = Provider.of<LocaleProvider>(context, listen: false);
    setState(() {
      _loading = true;
      _status = '';
    });

    Map<String, dynamic> res;
    if (await widget.session.features.hasFeature('students_list')) {
      res = await widget.session.features.listStudents();
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
    }
    if (res['ok'] != true) {
      final msg = ((res['error'] ?? const {}) as Map)['message']?.toString() ?? 'unknown error';
      setState(() {
        _loading = false;
        _status = msg;
      });
      return;
    }

    final raw = (((res['data'] ?? const {}) as Map)['items'] ?? const []) as List;
    final all = raw.map((e) => Student.fromJson((e as Map).cast<String, dynamic>())).toList();
    all.sort((a, b) => a.studentNo.compareTo(b.studentNo));
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
    final classCode = TextEditingController(text: widget.session.profile.classCode);
    final phone = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.t('新增学生', 'Add Student')),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: id,
                  decoration:
                      InputDecoration(labelText: loc.t('ID（如 s_003）', 'ID (e.g. s_003)'))),
              TextField(
                  controller: studentNo,
                  decoration: InputDecoration(labelText: loc.t('学号', 'Student ID'))),
              TextField(
                  controller: fullName,
                  decoration: InputDecoration(labelText: loc.t('姓名', 'Name'))),
              TextField(
                  controller: classCode,
                  decoration: InputDecoration(labelText: loc.t('班级', 'Class'))),
              TextField(
                  controller: phone,
                  decoration: InputDecoration(labelText: loc.t('手机号', 'Phone'))),
            ],
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

    if (ok != true) return;

    final vId = id.text.trim();
    final vStudentNo = studentNo.text.trim();
    final vFullName = fullName.text.trim();
    final vClassCode = classCode.text.trim();
    final vPhone = phone.text.trim();

    id.dispose();
    studentNo.dispose();
    fullName.dispose();
    classCode.dispose();
    phone.dispose();

    if (!await widget.session.features.hasFeature('students_insert')) {
      setState(() {
        _status = loc.t('未找到二进制：students_insert',
            'Binary not found: students_insert');
      });
      return;
    }

    setState(() {
      _loading = true;
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
      final msg = ((res['error'] ?? const {}) as Map)['message']?.toString() ?? 'unknown error';
      setState(() {
        _loading = false;
        _status = msg;
      });
      return;
    }

    await _refresh();
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
      _loading = true;
      _status = '';
    });

    final res = await widget.session.features.deleteStudent(fullName: s.fullName, studentNo: s.studentNo);
    if (res['ok'] != true) {
      final msg = ((res['error'] ?? const {}) as Map)['message']?.toString() ?? 'unknown error';
      setState(() {
        _loading = false;
        _status = msg;
      });
      return;
    }

    await _refresh();
  }

  List<Student> get _filtered {
    final q = _query.text.trim();
    if (q.isEmpty) return _items;
    return _items.where((s) => s.studentNo.contains(q) || s.fullName.contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    final loc = Provider.of<LocaleProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.t('学生信息', 'Students')),
        actions: [
          IconButton(onPressed: _loading ? null : _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: widget.session.canDeleteStudents
          ? FloatingActionButton(
              onPressed: _loading ? null : _addStudent,
              child: const Icon(Icons.add),
            )
          : null,
      body: Padding(
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
                child: Text(_status, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            ],
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : items.isEmpty
                      ? Center(child: Text(loc.t('暂无数据', 'No data')))
                      : ListView.separated(
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final s = items[index];
                            return ListTile(
                              leading: const Icon(Icons.person),
                              title: Text(loc.t('${s.fullName}（${s.studentNo}）',
                                  '${s.fullName} (${s.studentNo})')),
                              subtitle: Text('${s.classCode} · ${s.phone}'),
                              trailing: widget.session.canDeleteStudents
                                  ? IconButton(
                                      onPressed: _loading ? null : () => _deleteStudent(s),
                                      icon: const Icon(Icons.delete_outline),
                                    )
                                  : null,
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
