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
  List<TodoItem> _items = const [];
  List<String> _folders = const ['默认'];
  String _activeFolder = '默认';

  late final TodosStore _store;
  late final TodoFoldersStore _foldersStore;

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
    _refresh();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _status = '';
    });

    try {
      final items =
          await _store.listTodos(ownerProfileId: widget.session.profile.id);
      final stored = await _foldersStore.listFolders();
      final fromItems =
          items.map((e) => e.folder.trim()).where((e) => e.isNotEmpty);
      final merged = <String>{...stored, ...fromItems}.toList()..sort();
      final hasActive = _activeFolder == '全部' || merged.contains(_activeFolder);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _items = items;
        _folders = merged.isEmpty ? const ['默认'] : merged;
        if (!hasActive) {
          _activeFolder = '默认';
        }
      });
      widget.onReady?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _status = e.toString();
        _items = const [];
      });
      widget.onReady?.call();
    }
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
    final title = _controller.text.trim();
    if (title.isEmpty) return;
    setState(() {
      _status = '';
      _loading = true;
    });

    try {
      final folder = _activeFolder == '全部' ? '默认' : _activeFolder;
      await _foldersStore.upsertFolder(folder);
      final id = await _store.addTodo(
        ownerProfileId: widget.session.profile.id,
        title: title,
        folder: folder,
      );
      final now = DateTime.now().toIso8601String();
      final newItem = TodoItem(
        id: id,
        ownerProfileId: widget.session.profile.id,
        folder: folder,
        title: title,
        isDone: false,
        dueAt: '',
        createdAt: now,
        updatedAt: now,
      );
      setState(() {
        _loading = false;
        _items = [newItem, ..._items];
        if (!_folders.contains(folder)) {
          _folders = [..._folders, folder]..sort();
        }
      });
      _controller.clear();
    } catch (e) {
      setState(() {
        _loading = false;
        _status = e.toString();
      });
    }
  }

  Future<void> _toggle(TodoItem item) async {
    final idx = _items.indexWhere((e) => e.id == item.id);
    if (idx < 0) return;
    final prev = _items[idx];
    final now = DateTime.now().toIso8601String();
    final next = TodoItem(
      id: prev.id,
      ownerProfileId: prev.ownerProfileId,
      folder: prev.folder,
      title: prev.title,
      isDone: !prev.isDone,
      dueAt: prev.dueAt,
      createdAt: prev.createdAt,
      updatedAt: now,
    );

    setState(() {
      _status = '';
      _items = [..._items]..[idx] = next;
    });

    try {
      await _store.toggleTodo(
          ownerProfileId: widget.session.profile.id, id: item.id);
    } catch (e) {
      setState(() {
        _status = e.toString();
        _items = [..._items]..[idx] = prev;
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
      _items = [..._items]..removeAt(idx);
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
        _items = [..._items]..insert(idx, prev);
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
        title: Text(loc.t('待办事项', 'Todos'),
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
                  if (val == '__new__')
                    return loc.t('新建文件夹...', 'New Folder...');
                  if (val == '__delete__')
                    return loc.t('删除当前文件夹', 'Delete Current Folder');
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
                },
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                child: _status.trim().isEmpty
                    ? const SizedBox(height: 0)
                    : Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: cs.errorContainer
                                .withValues(alpha: (0.85 * 255).round()),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            _status,
                            style: tt.bodySmall
                                ?.copyWith(color: cs.onErrorContainer),
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow
                      .withValues(alpha: (0.92 * 255).round()),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: cs.outlineVariant
                          .withValues(alpha: (0.35 * 255).round())),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        enabled: !_loading,
                        decoration: InputDecoration(
                          hintText: loc.t('输入待办内容…', 'Input todo content...'),
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
                    FilledButton.icon(
                      onPressed: _loading ? null : _add,
                      icon: const Icon(Icons.add_rounded),
                      label: Text(loc.t('添加', 'Add')),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: _loading
                        ? const SizedBox.shrink()
                        : filtered.isEmpty
                            ? ListView(
                                key: const ValueKey('empty'),
                                children: [
                                  const SizedBox(height: 120),
                                  Center(
                                      child: Text(loc.t('暂无待办', 'No todos'))),
                                ],
                              )
                            : ListView.separated(
                                key: const ValueKey('list'),
                                padding: const EdgeInsets.only(bottom: 24),
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final item = filtered[index];
                                  final done = item.isDone;
                                  return Dismissible(
                                    key: ValueKey(item.id),
                                    direction: DismissDirection.endToStart,
                                    background: Container(
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                      decoration: BoxDecoration(
                                        color: cs.errorContainer,
                                        borderRadius: BorderRadius.circular(20),
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
                                                  Navigator.of(ctx).pop(false),
                                              child:
                                                  Text(loc.t('取消', 'Cancel')),
                                            ),
                                            FilledButton(
                                              onPressed: () =>
                                                  Navigator.of(ctx).pop(true),
                                              child:
                                                  Text(loc.t('删除', 'Delete')),
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
                                          .withOpacity(0.92),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        side: BorderSide(
                                            color: cs.outlineVariant
                                                .withOpacity(0.35)),
                                      ),
                                      child: ListTile(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 6),
                                        leading: AnimatedSwitcher(
                                          duration:
                                              const Duration(milliseconds: 200),
                                          switchInCurve: Curves.easeOut,
                                          switchOutCurve: Curves.easeIn,
                                          child: Icon(
                                            done
                                                ? Icons.check_circle_rounded
                                                : Icons.circle_outlined,
                                            key: ValueKey(done),
                                            color:
                                                done ? cs.primary : cs.outline,
                                          ),
                                        ),
                                        title: AnimatedDefaultTextStyle(
                                          duration:
                                              const Duration(milliseconds: 200),
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: done
                                                ? cs.outline
                                                : cs.onSurface,
                                            decoration: done
                                                ? TextDecoration.lineThrough
                                                : TextDecoration.none,
                                          ),
                                          child: Text(item.title),
                                        ),
                                        subtitle: item.dueAt.trim().isEmpty
                                            ? (_activeFolder == '全部'
                                                ? Text(item.folder,
                                                    style: tt.bodySmall)
                                                : null)
                                            : Text(
                                                loc.t('截止：${item.dueAt}',
                                                    'Due: ${item.dueAt}'),
                                              ),
                                        trailing: PopupMenuButton<String>(
                                          icon: const Icon(Icons.more_vert),
                                          onSelected: (v) async {
                                            if (v == 'delete') {
                                              final ok = await showDialog<bool>(
                                                context: context,
                                                builder: (ctx) => AlertDialog(
                                                  title: Text(loc.t(
                                                      '删除待办', 'Delete Todo')),
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
                                              value: 'delete',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.delete_outline,
                                                      color: cs.error),
                                                  const SizedBox(width: 8),
                                                  Text(loc.t('删除', 'Delete'),
                                                      style: TextStyle(
                                                          color: cs.error)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        onTap: () => _toggle(item),
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
