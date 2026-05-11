import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/todo_item.dart';
import '../services/todo_folders_store.dart';
import '../services/todos_store.dart';
import '../state/session.dart';
import '../main.dart';
import '../widgets/expressive_ui.dart';

class TodosPage extends StatefulWidget {
  final Session session;
  final VoidCallback? onReady;

  const TodosPage({super.key, required this.session, this.onReady});

  @override
  State<TodosPage> createState() => _TodosPageState();
}

class _TodosPageState extends State<TodosPage> {
  bool _loading = true;
  String _status = '';
  final _controller = TextEditingController();
  final _contentController = TextEditingController();
  bool _showDetailedAdd = false;
  DateTime _startTime = DateTime.now();
  DateTime _endTime = DateTime.now().add(const Duration(hours: 1));
  bool _dataReady = true;
  List<TodoItem> _items = const [];
  List<String> _folders = const ['默认'];
  String _activeFolder = '默认';

  late final TodosStore _store;
  late final TodoFoldersStore _foldersStore;
  StreamSubscription<SessionDataChange>? _dataChangeSub;

  @override
  void initState() {
    super.initState();
    _store = TodosStore(
      dataDir: widget.session.dataDir,
    );
    _foldersStore = TodoFoldersStore(
      dataDir: widget.session.dataDir,
      nativeLibDir: widget.session.features.nativeLibDir,
    );
    _loadActiveFolder();

    // Load from preloaded data if available
    if (widget.session.preloadedData['todos'] != null) {
      try {
        final itemsRaw = ((widget.session.preloadedData['todos']
                as Map)['items'] as List?) ??
            [];
        final items = itemsRaw
            .map((e) => TodoItem.fromJson((e as Map).cast<String, dynamic>()))
            .toList();
        _items = List<TodoItem>.from(
            items.where((e) => e.ownerProfileId == widget.session.profile.id));
        _loading = false;
      } catch (_) {}
    }

    _dataChangeSub = widget.session.watchDataChanges({'todos'}).listen((_) {
      if (mounted) {
        _refresh();
      }
    });
    _refresh();
  }

  @override
  void dispose() {
    _dataChangeSub?.cancel();
    _controller.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadActiveFolder() async {
    try {
      final features = widget.session.features;
      final res =
          await features.jsonOp(action: 'read', file: 'todo_prefs.json');
      if (res['ok'] == true && res['data'] != null) {
        final data = res['data'] as Map;
        final folder = data['activeFolder']?.toString() ?? '默认';
        if (mounted) {
          setState(() {
            _activeFolder = folder;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _saveActiveFolder(String folder) async {
    try {
      final features = widget.session.features;
      await features.jsonOp(
        action: 'write',
        file: 'todo_prefs.json',
        data: {'activeFolder': folder},
      );
    } catch (_) {}
  }

  String _lastSignature = '';

  Future<void> _refresh() async {
    try {
      final items =
          await _store.listTodos(ownerProfileId: widget.session.profile.id);
      final stored = await _foldersStore.listFolders();
      final fromItems =
          items.map((e) => e.folder.trim()).where((e) => e.isNotEmpty);
      final merged = <String>{...stored, ...fromItems}.toList()..sort();
      final hasActive = _activeFolder == '全部' || merged.contains(_activeFolder);

      // Smart diff detection
      final itemsSignature = items
          .map((e) => '${e.id}:${e.isDone}:${e.title}:${e.folder}:${e.dueAt}')
          .join('|');
      final foldersSignature = merged.join('|');
      final currentSignature = '$itemsSignature||$foldersSignature';

      if (currentSignature == _lastSignature && _dataReady) {
        setState(() {
          _loading = false;
        });
        widget.onReady?.call();
        return;
      }
      _lastSignature = currentSignature;

      if (!mounted) return;
      setState(() {
        _loading = false;
        _items = List<TodoItem>.from(items);
        _sortItems();
        _folders = merged.isEmpty ? const ['默认'] : merged;
        if (!hasActive) {
          _activeFolder = '默认';
          _saveActiveFolder('默认');
          showExpressiveSnackBar(
            context,
            Provider.of<LocaleProvider>(context, listen: false).t(
                '上次选中的文件夹已被删除，已回退到默认文件夹',
                'The previously selected folder was deleted, reverted to Default folder'),
          );
        }
        _dataReady = true;
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

  void _sortItems() {
    _items.sort((a, b) {
      if (a.isDone != b.isDone) {
        return a.isDone ? 1 : -1;
      }
      final aDue = a.dueAt.trim().isEmpty ? '9999-12-31' : a.dueAt;
      final bDue = b.dueAt.trim().isEmpty ? '9999-12-31' : b.dueAt;
      final timeCmp = aDue.compareTo(bDue);
      if (timeCmp != 0) return timeCmp;
      return b.createdAt.compareTo(a.createdAt);
    });
  }

  Future<void> _createFolder() async {
    final loc = Provider.of<LocaleProvider>(context, listen: false);
    final ctrl = TextEditingController();
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.t('新建文件夹', 'New Folder')),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
              labelText: loc.t('名称', 'Name'),
              border: const OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(loc.t('取消', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(loc.t('创建', 'Create')),
          ),
        ],
      ),
    );
    final name = ctrl.text.trim();
    ctrl.dispose();
    if (res != true || name.isEmpty) {
      return;
    }
    await _foldersStore.upsertFolder(name);
    if (!mounted) return;
    setState(() {
      _activeFolder = name;
    });
    await _refresh();
  }

  Future<void> _deleteFolder() async {
    if (_activeFolder == '全部' || _activeFolder == '默认') return;

    final loc = Provider.of<LocaleProvider>(context, listen: false);
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.t('删除文件夹', 'Delete Folder')),
        content: Text(loc.t(
            '确定要删除文件夹 "$_activeFolder" 吗？该操作只会移除文件夹，不会删除其中的待办事项。',
            'Are you sure you want to delete folder "$_activeFolder"? This operation will only remove the folder, not the todos in it.')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(loc.t('取消', 'Cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(loc.t('删除', 'Delete')),
          ),
        ],
      ),
    );

    if (res != true) return;

    await _foldersStore.deleteFolder(_activeFolder);
    if (!mounted) return;
    setState(() {
      _activeFolder = '默认';
    });
    await _refresh();
  }

  Future<void> _add() async {
    final loc = Provider.of<LocaleProvider>(context, listen: false);

    final title = _controller.text.trim();
    if (title.isEmpty) return;

    setState(() {
      _status = '';
      _loading = true;
    });

    try {
      final folder = _activeFolder == '全部' ? '默认' : _activeFolder;
      await _foldersStore.upsertFolder(folder);

      String startStr = '';
      String endStr = '';
      String content = '';

      if (_showDetailedAdd) {
        startStr = _startTime
            .toIso8601String()
            .substring(0, 16)
            .replaceFirst('T', ' ');
        endStr =
            _endTime.toIso8601String().substring(0, 16).replaceFirst('T', ' ');
        content = _contentController.text.trim();
      } else {
        // Simple add uses empty times
        startStr = '';
        endStr = '';
      }

      final id = await _store.addTodo(
        ownerProfileId: widget.session.profile.id,
        title: title,
        folder: folder,
        content: content,
        startAt: startStr,
        endAt: endStr,
        dueAt: startStr,
      );

      final nowIso = DateTime.now().toIso8601String();
      final newItem = TodoItem(
        id: id,
        ownerProfileId: widget.session.profile.id,
        folder: folder,
        title: title,
        content: content,
        isDone: false,
        dueAt: startStr,
        startAt: startStr,
        endAt: endStr,
        createdAt: nowIso,
        updatedAt: nowIso,
      );

      setState(() {
        _loading = false;
        _items = List<TodoItem>.from(_items)..insert(0, newItem);
        _sortItems();
        if (!_folders.contains(folder)) {
          _folders = List<String>.from(_folders)
            ..add(folder)
            ..sort();
        }
        _controller.clear();
        _contentController.clear();
        _showDetailedAdd = false;
      });

      if (mounted) {
        showExpressiveSnackBar(context, loc.t('新建成功', 'Created successfully'));
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _status = e.toString();
      });
    }
  }

  Future<void> _edit(TodoItem initialItem) async {
    final loc = Provider.of<LocaleProvider>(context, listen: false);
    final tt = Theme.of(context).textTheme;

    final titleCtrl = TextEditingController(text: initialItem.title);
    final contentCtrl = TextEditingController(text: initialItem.content);

    // Try to parse existing times
    DateTime start =
        DateTime.tryParse(initialItem.startAt.replaceFirst(' ', 'T')) ??
            DateTime.now();
    DateTime end =
        DateTime.tryParse(initialItem.endAt.replaceFirst(' ', 'T')) ??
            DateTime.now().add(const Duration(hours: 1));

    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text(loc.t('修改待办', 'Edit Todo')),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    maxLength: 50,
                    decoration: InputDecoration(
                      labelText: loc.t('主题', 'Theme'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: contentCtrl,
                    maxLength: 500,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: loc.t('内容', 'Content'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(loc.t('开始时间', 'Start Time'),
                        style: tt.labelMedium),
                    subtitle: Text(
                        '${start.year}-${start.month}-${start.day} ${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}'),
                    trailing: const Icon(Icons.calendar_today, size: 18),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: ctx,
                        initialDate: start,
                        firstDate:
                            DateTime.now().subtract(const Duration(days: 365)),
                        lastDate:
                            DateTime.now().add(const Duration(days: 365 * 2)),
                      );
                      if (date == null) return;
                      final time = await showTimePicker(
                        context: ctx,
                        initialTime: TimeOfDay.fromDateTime(start),
                      );
                      if (time == null) return;
                      setDialogState(() {
                        start = DateTime(date.year, date.month, date.day,
                            time.hour, time.minute);
                        if (end.isBefore(start)) {
                          end = start.add(const Duration(hours: 1));
                        }
                      });
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title:
                        Text(loc.t('结束时间', 'End Time'), style: tt.labelMedium),
                    subtitle: Text(
                        '${end.year}-${end.month}-${end.day} ${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}'),
                    trailing: const Icon(Icons.event, size: 18),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: ctx,
                        initialDate: end,
                        firstDate: start,
                        lastDate:
                            DateTime.now().add(const Duration(days: 365 * 2)),
                      );
                      if (date == null) return;
                      final time = await showTimePicker(
                        context: ctx,
                        initialTime: TimeOfDay.fromDateTime(end),
                      );
                      if (time == null) return;
                      final newEnd = DateTime(date.year, date.month, date.day,
                          time.hour, time.minute);
                      if (newEnd.isBefore(start)) {
                        showExpressiveSnackBar(
                            ctx,
                            loc.t('结束时间不能早于开始时间',
                                'End time cannot be earlier than start time'));
                        return;
                      }
                      setDialogState(() {
                        end = newEnd;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(loc.t('取消', 'Cancel')),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(loc.t('确定', 'Confirm')),
              ),
            ],
          );
        },
      ),
    );

    if (res == true) {
      final startStr =
          start.toIso8601String().substring(0, 16).replaceFirst('T', ' ');
      final endStr =
          end.toIso8601String().substring(0, 16).replaceFirst('T', ' ');

      final updated = initialItem.copyWith(
        title: titleCtrl.text.trim(),
        content: contentCtrl.text.trim(),
        startAt: startStr,
        endAt: endStr,
        dueAt: startStr,
      );
      await _store.upsertTodo(updated);
      await _refresh();
    }
  }

  Future<void> _toggle(TodoItem item) async {
    final idx = _items.indexWhere((e) => e.id == item.id);
    if (idx < 0) return;
    final prev = _items[idx];
    final next = prev.copyWith(
        isDone: !prev.isDone, updatedAt: DateTime.now().toIso8601String());

    setState(() {
      _status = '';
      _items = List<TodoItem>.from(_items)..[idx] = next;
    });

    try {
      await _store.upsertTodo(next);
    } catch (e) {
      setState(() {
        _status = e.toString();
        _items = List<TodoItem>.from(_items)..[idx] = prev;
      });
    }
  }

  Future<void> _delete(TodoItem item) async {
    final loc = Provider.of<LocaleProvider>(context, listen: false);
    final idx = _items.indexWhere((e) => e.id == item.id);
    if (idx < 0) return;
    final prev = _items[idx];
    setState(() {
      _status = '';
      _items = List<TodoItem>.from(_items)..removeAt(idx);
    });
    try {
      await _store.deleteTodo(
          ownerProfileId: widget.session.profile.id, id: item.id);
      if (!mounted) return;
      showExpressiveSnackBar(
        context,
        loc.t('已删除待办', 'Todo deleted'),
      );
    } catch (e) {
      setState(() {
        _status = e.toString();
        _items = List<TodoItem>.from(_items)..insert(idx, prev);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final loc = Provider.of<LocaleProvider>(context);

    final filtered =
        _activeFolder == '全部' || _activeFolder == loc.t('全部', 'All')
            ? _items
            : _items.where((e) => e.folder == _activeFolder).toList();

    final isDesktop =
        Platform.isWindows || Platform.isLinux || Platform.isMacOS;
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final showDrawerButton =
        (!isDesktop || isPortrait) && !(Platform.isAndroid && isTablet);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.t('待办事项', 'Todos')),
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
                        scaffold = scaffold.context.findAncestorStateOfType<ScaffoldState>();
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
                label: loc.t('文件夹', 'Folder'),
                value: _activeFolder == '全部'
                    ? loc.t('全部', 'All')
                    : _activeFolder == '默认'
                        ? loc.t('默认', 'Default')
                        : _activeFolder,
                items: [
                  loc.t('全部', 'All'),
                  ..._folders
                      .map((f) => f == '默认' ? loc.t('默认', 'Default') : f),
                  '__new__',
                  if (_activeFolder != '全部' &&
                      _activeFolder != '默认' &&
                      _activeFolder != loc.t('全部', 'All') &&
                      _activeFolder != loc.t('默认', 'Default'))
                    '__delete__'
                ],
                customLabelBuilder: (val) {
                  if (val == '__new__') {
                    return loc.t('新建文件夹...', 'New Folder...');
                  }
                  if (val == '__delete__') {
                    return loc.t('删除当前文件夹', 'Delete Current Folder');
                  }
                  return val;
                },
                onSelected: (v) async {
                  if (v == '__new__') {
                    await _createFolder();
                    return;
                  }
                  if (v == '__delete__') {
                    await _deleteFolder();
                    return;
                  }
                  setState(() {
                    if (v == loc.t('全部', 'All')) {
                      _activeFolder = '全部';
                    } else if (v == loc.t('默认', 'Default')) {
                      _activeFolder = '默认';
                    } else {
                      _activeFolder = v;
                    }
                  });
                  await _saveActiveFolder(_activeFolder);
                },
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                children: [
                  if (_status.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: cs.errorContainer.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          _status,
                          style: tt.bodySmall
                              ?.copyWith(color: cs.onErrorContainer),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLow.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: cs.outlineVariant.withValues(alpha: 0.35)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                enabled: !_loading,
                                decoration: InputDecoration(
                                  hintText:
                                      loc.t('输入待办主题…', 'Input todo theme...'),
                                  isDense: true,
                                  filled: false,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onSubmitted: (_) => _add(),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(loc.t('详细', 'Detailed'),
                                    style: tt.labelSmall),
                                Checkbox(
                                  value: _showDetailedAdd,
                                  onChanged: (v) {
                                    setState(() {
                                      _showDetailedAdd = v ?? false;
                                    });
                                  },
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                            const SizedBox(width: 4),
                            FilledButton(
                              onPressed: _loading ? null : _add,
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                minimumSize: Size.zero,
                              ),
                              child: Text(loc.t('添加', 'Add')),
                            ),
                          ],
                        ),
                        if (_showDetailedAdd) ...[
                          const Divider(height: 24),
                          TextField(
                            controller: _contentController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText: loc.t(
                                  '详细内容 (可选)', 'Detailed content (Optional)'),
                              isDense: true,
                              filled: false,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: _startTime,
                                      firstDate: DateTime.now()
                                          .subtract(const Duration(days: 365)),
                                      lastDate: DateTime.now()
                                          .add(const Duration(days: 365 * 2)),
                                    );
                                    if (date == null) return;
                                    final time = await showTimePicker(
                                      context: context,
                                      initialTime:
                                          TimeOfDay.fromDateTime(_startTime),
                                    );
                                    if (time == null) return;
                                    setState(() {
                                      _startTime = DateTime(
                                          date.year,
                                          date.month,
                                          date.day,
                                          time.hour,
                                          time.minute);
                                      if (_endTime.isBefore(_startTime)) {
                                        _endTime = _startTime
                                            .add(const Duration(hours: 1));
                                      }
                                    });
                                  },
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(loc.t('开始时间', 'Start Time'),
                                          style: tt.labelSmall),
                                      Text(
                                        '${_startTime.year}-${_startTime.month}-${_startTime.day} ${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
                                        style: tt.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: _endTime,
                                      firstDate: _startTime,
                                      lastDate: DateTime.now()
                                          .add(const Duration(days: 365 * 2)),
                                    );
                                    if (date == null) return;
                                    final time = await showTimePicker(
                                      context: context,
                                      initialTime:
                                          TimeOfDay.fromDateTime(_endTime),
                                    );
                                    if (time == null) return;
                                    final newEnd = DateTime(
                                        date.year,
                                        date.month,
                                        date.day,
                                        time.hour,
                                        time.minute);
                                    if (newEnd.isBefore(_startTime)) {
                                      showExpressiveSnackBar(
                                          context,
                                          loc.t('结束时间不能早于开始时间',
                                              'End time cannot be earlier than start time'));
                                      return;
                                    }
                                    setState(() {
                                      _endTime = newEnd;
                                    });
                                  },
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(loc.t('结束时间', 'End Time'),
                                          style: tt.labelSmall),
                                      Text(
                                        '${_endTime.year}-${_endTime.month}-${_endTime.day} ${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
                                        style: tt.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _refresh,
                      child: (filtered.isEmpty && !_loading)
                          ? ListView(
                              key: const ValueKey('empty'),
                              children: [
                                const SizedBox(height: 120),
                                Center(child: Text(loc.t('暂无待办', 'No todos'))),
                              ],
                            )
                          : (filtered.isEmpty && _loading)
                              ? const SizedBox.shrink()
                              : ListView.separated(
                                  key: const ValueKey('list'),
                                  padding: const EdgeInsets.only(bottom: 24),
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final item = filtered[index];
                                    final done = item.isDone;
                                    return _AnimatedListItem(
                                      key: ValueKey(item.id),
                                      child: Dismissible(
                                        key: ValueKey('dismiss_${item.id}'),
                                        direction: DismissDirection.endToStart,
                                        background: Container(
                                          alignment: Alignment.centerRight,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16),
                                          decoration: BoxDecoration(
                                            color: cs.errorContainer,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Icon(Icons.delete_outline,
                                              color: cs.onErrorContainer),
                                        ),
                                        confirmDismiss: (_) async {
                                          final ok = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: Text(
                                                  loc.t('删除待办', 'Delete Todo')),
                                              content: Text(loc.t(
                                                  '确认删除“${item.title}”？',
                                                  'Delete “${item.title}”?')),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.of(ctx)
                                                          .pop(false),
                                                  child: Text(
                                                      loc.t('取消', 'Cancel')),
                                                ),
                                                FilledButton(
                                                  style: FilledButton.styleFrom(
                                                    backgroundColor:
                                                        Theme.of(ctx)
                                                            .colorScheme
                                                            .error,
                                                    foregroundColor:
                                                        Theme.of(ctx)
                                                            .colorScheme
                                                            .onError,
                                                  ),
                                                  onPressed: () =>
                                                      Navigator.of(ctx)
                                                          .pop(true),
                                                  child: Text(
                                                      loc.t('删除', 'Delete')),
                                                ),
                                              ],
                                            ),
                                          );
                                          return ok == true;
                                        },
                                        onDismissed: (_) => _delete(item),
                                        child: Card(
                                          elevation: 0,
                                          color: cs.surfaceContainerLow
                                              .withValues(alpha: 0.92),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            side: BorderSide(
                                                color: cs.outlineVariant
                                                    .withValues(alpha: 0.35)),
                                          ),
                                          child: ListTile(
                                            onTap: () => _toggle(item),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 6),
                                            leading: IconButton(
                                              onPressed: () => _toggle(item),
                                              icon: AnimatedSwitcher(
                                                duration: const Duration(
                                                    milliseconds: 200),
                                                switchInCurve: Curves.easeOut,
                                                switchOutCurve: Curves.easeIn,
                                                child: Icon(
                                                  done
                                                      ? Icons
                                                          .check_circle_rounded
                                                      : Icons.circle_outlined,
                                                  key: ValueKey(done),
                                                  color: done
                                                      ? cs.primary
                                                      : cs.outline,
                                                ),
                                              ),
                                            ),
                                            title: AnimatedDefaultTextStyle(
                                              duration: const Duration(
                                                  milliseconds: 200),
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: done
                                                    ? cs.outline
                                                    : cs.onSurface,
                                                decoration: done
                                                    ? TextDecoration.lineThrough
                                                    : TextDecoration.none,
                                              ),
                                              child: Text(item.title),
                                            ),
                                            subtitle: (item
                                                        .content.isNotEmpty ||
                                                    item.startAt.isNotEmpty)
                                                ? Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      if (item
                                                          .content.isNotEmpty)
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(top: 4),
                                                          child: Text(
                                                            item.content,
                                                            style: tt.bodySmall
                                                                ?.copyWith(
                                                              color: cs
                                                                  .onSurfaceVariant,
                                                            ),
                                                            maxLines: 2,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      if (item
                                                          .startAt.isNotEmpty)
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(top: 4),
                                                          child: Row(
                                                            children: [
                                                              Icon(
                                                                  Icons
                                                                      .access_time,
                                                                  size: 14,
                                                                  color: cs
                                                                      .primary),
                                                              const SizedBox(
                                                                  width: 4),
                                                              Text(
                                                                '${item.startAt} ~ ${item.endAt}',
                                                                style: tt
                                                                    .labelSmall
                                                                    ?.copyWith(
                                                                        color: cs
                                                                            .primary),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      if (_activeFolder == '全部')
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(top: 4),
                                                          child: Text(
                                                              item.folder,
                                                              style:
                                                                  tt.bodySmall),
                                                        ),
                                                    ],
                                                  )
                                                : (_activeFolder == '全部'
                                                    ? Text(item.folder,
                                                        style: tt.bodySmall)
                                                    : null),
                                            trailing: PopupMenuButton<String>(
                                              icon: const Icon(Icons.more_vert),
                                              onSelected: (v) async {
                                                if (v == 'edit') {
                                                  await _edit(item);
                                                } else if (v == 'delete') {
                                                  final ok =
                                                      await showDialog<bool>(
                                                    context: context,
                                                    builder: (ctx) =>
                                                        AlertDialog(
                                                      title: Text(loc.t('删除待办',
                                                          'Delete Todo')),
                                                      content: Text(loc.t(
                                                          '确认删除“${item.title}”？',
                                                          'Delete “${item.title}”?')),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.of(ctx)
                                                                  .pop(false),
                                                          child: Text(loc.t(
                                                              '取消', 'Cancel')),
                                                        ),
                                                        FilledButton(
                                                          style: FilledButton
                                                              .styleFrom(
                                                            backgroundColor:
                                                                Theme.of(ctx)
                                                                    .colorScheme
                                                                    .error,
                                                            foregroundColor:
                                                                Theme.of(ctx)
                                                                    .colorScheme
                                                                    .onError,
                                                          ),
                                                          onPressed: () =>
                                                              Navigator.of(ctx)
                                                                  .pop(true),
                                                          child: Text(loc.t(
                                                              '删除', 'Delete')),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                  if (ok == true) {
                                                    await _delete(item);
                                                  }
                                                }
                                              },
                                              itemBuilder: (ctx) => [
                                                PopupMenuItem(
                                                  value: 'edit',
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                          Icons
                                                              .edit_note_rounded,
                                                          color: cs.onSurface),
                                                      const SizedBox(width: 8),
                                                      Text(loc.t(
                                                          '修改待办', 'Edit Todo')),
                                                    ],
                                                  ),
                                                ),
                                                PopupMenuItem(
                                                  value: 'delete',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.delete_outline,
                                                          color: cs.error),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                          loc.t('删除', 'Delete'),
                                                          style: TextStyle(
                                                              color: cs.error)),
                                                    ],
                                                  ),
                                                ),
                                              ],
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
          ),
          if (_loading)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SizedBox(
                  height:
                      2), // Removed LinearProgressIndicator to avoid UI flash
            ),
        ],
      ),
    );
  }
}

class _AnimatedListItem extends StatefulWidget {
  final Widget child;
  const _AnimatedListItem({super.key, required this.child});
  @override
  State<_AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<_AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _anim,
      child: FadeTransition(
        opacity: _anim,
        child: widget.child,
      ),
    );
  }
}
