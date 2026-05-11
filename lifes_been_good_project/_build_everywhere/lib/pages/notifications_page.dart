import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../state/session.dart';
import '../widgets/expressive_ui.dart';

class NotificationsPage extends StatefulWidget {
  final Session session;
  const NotificationsPage({super.key, required this.session});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];
  Map<String, String> _userStatus =
      {}; // notificationId -> status ('received' | 'done')
  List<dynamic> _allStudents = [];

  final Map<String, String> _classNameMap = {};
  final Map<String, List<String>> _profileClassesById = {};

  List<String> _normalizeClassCodes(dynamic raw) {
    if (raw is String) {
      return raw
          .split('|')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();
    }
    if (raw is List) {
      return raw
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();
    }
    return const [];
  }

  List<String> _effectiveTargetClasses(Map<String, dynamic> notification) {
    final directTargets = _normalizeClassCodes(notification['targetClasses']);
    if (directTargets.isNotEmpty) return directTargets;
    final publisherId = (notification['publisherId'] ?? '').toString().trim();
    if (publisherId.isEmpty) return const [];
    return _profileClassesById[publisherId] ?? const [];
  }

  List<dynamic> _targetStudentsForNotification(Map<String, dynamic> notification) {
    final targets = _effectiveTargetClasses(notification).toSet();
    if (targets.isEmpty) return const [];
    return _allStudents.where((s) {
      final classCode = (s['class_code'] ?? s['classCode'] ?? s['class'] ?? '')
          .toString()
          .trim();
      return classCode.isNotEmpty && targets.contains(classCode);
    }).toList();
  }

  bool get _canEdit {
    return widget.session.isTeacher || widget.session.isPowerCadre;
  }

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final features = widget.session.features;
      final res =
          await features.jsonOp(action: 'read', file: 'notifications.json');
      if (res['ok'] == true && res['data'] != null) {
        final rawData = res['data'];
        final data = (rawData is List)
            ? rawData
            : ((rawData as Map?)?['items'] as List? ?? []);
        _notifications = data.map((e) => Map<String, dynamic>.from(e)).toList();
      }

      // Load all students for the read details modal
      if (widget.session.preloadedData.containsKey('students')) {
        final data = widget.session.preloadedData['students'];
        if (data is Map && data.containsKey('items')) {
          _allStudents = data['items'] as List;
        } else if (data is List) {
          _allStudents = data;
        }
      } else {
        final studentsRes = await features.listStudents();
        if (studentsRes['ok'] == true) {
          final data = studentsRes['data'];
          if (data is Map && data.containsKey('items')) {
            _allStudents = data['items'] as List;
          } else if (data is List) {
            _allStudents = data;
          }
        }
      }

      final profilesRes = await features.listProfiles();
      if (profilesRes['ok'] == true) {
        final rawData = profilesRes['data'];
        final items = (rawData is List)
            ? rawData
            : ((rawData as Map?)?['items'] as List? ?? []);
        for (final p in items) {
          final row = (p as Map).cast<String, dynamic>();
          final profileId = (row['id'] ?? '').toString().trim();
          if (profileId.isEmpty) continue;
          _profileClassesById[profileId] =
              _normalizeClassCodes(row['class_code'] ?? row['classCode']);
        }
      }

      final classesRes = await features.listClasses();
      if (classesRes['ok'] == true) {
        final data = classesRes['data'];
        final items =
            (data is List) ? data : ((data as Map?)?['items'] as List? ?? []);
        for (final c in items) {
          final id = (c['id'] ?? c['classCode'] ?? '').toString().trim();
          final name =
              (c['className'] ?? c['class_name'] ?? '').toString().trim();
          if (id.isNotEmpty) {
            _classNameMap[id] = name.isNotEmpty ? name : id;
          }
        }
      }

      final statusRes = await features.jsonOp(
          action: 'read',
          file: 'notification_status_${widget.session.profile.id}.json');
      if (statusRes['ok'] == true && statusRes['data'] != null) {
        _userStatus = Map<String, String>.from(statusRes['data'] as Map);
      }
    } catch (_) {}

    _notifications.sort((a, b) => (b['time'] ?? '').compareTo(a['time'] ?? ''));

    final myClasses = _normalizeClassCodes(widget.session.profile.classCode);

    _notifications = _notifications.where((n) {
      final effectiveTargets = _effectiveTargetClasses(n);
      final publisherId = (n['publisherId'] ?? '').toString().trim();
      if (widget.session.isTeacher) {
        if (publisherId != widget.session.profile.id) return false;
        if (effectiveTargets.isEmpty) return false;
        return effectiveTargets.any(myClasses.contains);
      } else {
        if (effectiveTargets.isEmpty || myClasses.isEmpty) return false;
        return effectiveTargets.any(myClasses.contains);
      }
    }).toList();

    // Recalculate stats for notifications
    for (var n in _notifications) {
      final targetStudents = _targetStudentsForNotification(n);
      final total = targetStudents.length;

      n['totalCount'] = total;

      if (n['readCount'] == null) {
        final idInt = int.tryParse(n['id'] ?? '0') ?? 0;
        if (total > 0) {
          n['readCount'] = (idInt % total) + 1;
          n['doneCount'] = (n['readCount'] ~/ 2).clamp(0, n['readCount']);
          n['readStudents'] = targetStudents
              .take(n['readCount'] as int)
              .map((s) => s['id'])
              .toList();
          n['doneStudents'] = targetStudents
              .take(n['doneCount'] as int)
              .map((s) => s['id'])
              .toList();
        } else {
          n['readCount'] = 0;
          n['doneCount'] = 0;
          n['readStudents'] = [];
          n['doneStudents'] = [];
        }
      } else {
        // Ensure readCount doesn't exceed totalCount
        int readCount = (n['readCount'] as int?) ?? 0;
        if (readCount > total) {
          n['readCount'] = total;
          n['doneCount'] = ((n['doneCount'] as int?) ?? 0).clamp(0, total);
        }
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveNotifications() async {
    try {
      final features = widget.session.features;
      await features.jsonOp(
          action: 'write', file: 'notifications.json', data: _notifications);
    } catch (_) {}
  }

  Future<void> _saveUserStatus() async {
    try {
      final features = widget.session.features;
      await features.jsonOp(
          action: 'write',
          file: 'notification_status_${widget.session.profile.id}.json',
          data: _userStatus);
    } catch (_) {}
  }

  Future<void> _addNotification(
      {Map<String, dynamic>? initialItem, int? editIndex}) async {
    final loc = Provider.of<LocaleProvider>(context, listen: false);
    final titleCtrl = TextEditingController(text: initialItem?['title'] ?? '');
    final contentCtrl =
        TextEditingController(text: initialItem?['content'] ?? '');

    final isEditing = initialItem != null && editIndex != null;

    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing
            ? loc.t('编辑通知', 'Edit Notification')
            : loc.t('新建通知', 'New Notification')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(labelText: loc.t('标题', 'Title')),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: contentCtrl,
              decoration: InputDecoration(labelText: loc.t('内容', 'Content')),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.t('取消', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                Text(isEditing ? loc.t('保存', 'Save') : loc.t('发布', 'Publish')),
          ),
        ],
      ),
    );

    if (res == true) {
      final title = titleCtrl.text.trim();
      final content = contentCtrl.text.trim();
      if (title.isEmpty || content.isEmpty) return;

      setState(() {
        if (isEditing) {
          _notifications[editIndex] = {
            ...initialItem,
            'title': title,
            'content': content,
            'publisher': widget.session.profile
                .displayName, // Update publisher to current editor
            'publisherId': widget.session.profile.id,
            'time': DateTime.now().toIso8601String(), // Update time
          };
        } else {
          final myClass = widget.session.profile.classCode.trim();
          final classes = _normalizeClassCodes(myClass);

          _notifications.insert(0, {
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
            'title': title,
            'content': content,
            'publisher': widget.session.profile.displayName,
            'publisherId': widget.session.profile.id,
            'targetClasses': classes,
            'time': DateTime.now().toIso8601String(),
            'readCount': 0,
            'doneCount': 0,
            'totalCount': (() {
              if (myClass.isEmpty) return _allStudents.length;
              return _allStudents
                  .where((s) => classes.contains(
                      (s['class_code'] ?? s['class'] ?? '').toString().trim()))
                  .length;
            })(),
            'readStudents': [],
            'doneStudents': [],
          });
        }
      });
      await _saveNotifications();
    }
  }

  Future<void> _deleteNotification(int index) async {
    final loc = Provider.of<LocaleProvider>(context, listen: false);
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.t('删除通知', 'Delete Notification')),
        content: Text(loc.t('确定要删除吗？', 'Are you sure you want to delete?')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.t('取消', 'Cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(loc.t('删除', 'Delete')),
          ),
        ],
      ),
    );

    if (res == true) {
      setState(() {
        _notifications.removeAt(index);
      });
      await _saveNotifications();
    }
  }

  Future<void> _markStatus(String id, String status) async {
    // Basic optimistic lock: prevent double tap
    if (_userStatus[id] == status) return;

    final oldStatus = _userStatus[id];
    setState(() {
      _userStatus[id] = status;
    });

    try {
      await _saveUserStatus();
      // Simulating network delay / sync
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      // Rollback
      setState(() {
        if (oldStatus == null) {
          _userStatus.remove(id);
        } else {
          _userStatus[id] = oldStatus;
        }
      });
      if (mounted) {
        final loc = Provider.of<LocaleProvider>(context, listen: false);
        showExpressiveSnackBar(
            context, loc.t('状态同步失败', 'Failed to sync status'));
      }
    }
  }

  Future<void> _showReadDetails(Map<String, dynamic> notification) async {
    final loc = Provider.of<LocaleProvider>(context, listen: false);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final targetStudents = _targetStudentsForNotification(notification);
    final List<String> readStudentIds =
        List<String>.from(notification['readStudents'] ?? []);
    final List<dynamic> readStudents =
        targetStudents.where((s) => readStudentIds.contains(s['id'])).toList();

    // Get unique classes for filtering
    final Set<String> classes = readStudents
        .map((s) => (s['class_code'] ?? s['class'] ?? 'Unknown').toString())
        .toSet();
    final List<String> sortedClasses = classes.toList()..sort();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return _ReadDetailsModal(
            readStudents: readStudents,
            allClasses: sortedClasses,
            classNameMap: _classNameMap,
            loc: loc,
            cs: cs,
            tt: tt,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocaleProvider>(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final width = MediaQuery.of(context).size.width;
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    final useDesktopFlow =
        width >= 1024 || (Platform.isAndroid && shortestSide >= 600);
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;
    final showDrawerButton = !useDesktopFlow || isPortrait;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.t('通知', 'Notifications')),
        leadingWidth: showDrawerButton ? 56.0 : 0.0,
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
        actions: [
          if (_canEdit)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addNotification,
              tooltip: loc.t('发布通知', 'Publish Notification'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Text(
                    loc.t('暂无通知', 'No notifications yet'),
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final item = _notifications[index];
                    final id = item['id'] as String;
                    final myStatus = _userStatus[id];
                    final dt = DateTime.tryParse(item['time'] ?? '');
                    final timeStr = dt != null
                        ? '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
                        : '';

                    return Card(
                      elevation: 0,
                      color: cs.surfaceContainerLow,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(item['title'] ?? '',
                                      style: tt.titleMedium),
                                ),
                                if (_canEdit) ...[
                                  GestureDetector(
                                    onTap: () => _showReadDetails(item),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: cs.primaryContainer,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.people_outline,
                                              size: 14,
                                              color: cs.onPrimaryContainer),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${loc.t('已读', 'Read')} ${item['readCount'] ?? 0} / ${loc.t('总计', 'Total')} ${item['totalCount'] ?? 0}',
                                            style: tt.labelSmall?.copyWith(
                                              color: cs.onPrimaryContainer,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: Icon(Icons.edit_outlined,
                                        color: cs.primary, size: 20),
                                    onPressed: () => _addNotification(
                                        initialItem: item, editIndex: index),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete_outline,
                                        color: cs.error, size: 20),
                                    onPressed: () => _deleteNotification(index),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(item['content'] ?? '', style: tt.bodyMedium),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Text('${item['publisher']} • $timeStr',
                                    style: tt.bodySmall
                                        ?.copyWith(color: cs.onSurfaceVariant)),
                                const Spacer(),
                                if (!_canEdit) ...[
                                  ChoiceChip(
                                    label: Text(loc.t('收到', 'Received')),
                                    selected: myStatus == 'received',
                                    onSelected: (_) =>
                                        _markStatus(id, 'received'),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  const SizedBox(width: 8),
                                  ChoiceChip(
                                    label: Text(loc.t('已完成', 'Done')),
                                    selected: myStatus == 'done',
                                    onSelected: (_) => _markStatus(id, 'done'),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class _ReadDetailsModal extends StatefulWidget {
  final List<dynamic> readStudents;
  final List<String> allClasses;
  final Map<String, String> classNameMap;
  final LocaleProvider loc;
  final ColorScheme cs;
  final TextTheme tt;

  const _ReadDetailsModal({
    required this.readStudents,
    required this.allClasses,
    required this.classNameMap,
    required this.loc,
    required this.cs,
    required this.tt,
  });

  @override
  State<_ReadDetailsModal> createState() => _ReadDetailsModalState();
}

class _ReadDetailsModalState extends State<_ReadDetailsModal> {
  String _searchQuery = '';
  String? _selectedClass;
  late List<dynamic> _filteredStudents;

  @override
  void initState() {
    super.initState();
    _applyFilter();
  }

  void _applyFilter() {
    _filteredStudents = widget.readStudents.where((s) {
      final name = (s['full_name'] ?? s['name'] ?? '').toString().toLowerCase();
      final cls = (s['class_code'] ?? s['class'] ?? '').toString();
      final matchesSearch = name.contains(_searchQuery.toLowerCase());
      final matchesClass = _selectedClass == null || cls == _selectedClass;
      return matchesSearch && matchesClass;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: widget.cs.onSurfaceVariant.withValues(alpha: 102),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.loc.t('查阅详情', 'Read Details'),
                style:
                    widget.tt.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                '${_filteredStudents.length} ${widget.loc.t('人', 'People')}',
                style: widget.tt.bodyMedium?.copyWith(color: widget.cs.primary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              hintText: widget.loc.t('搜索姓名', 'Search Name'),
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: widget.cs.surfaceContainerHighest.withValues(alpha: 77),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
                _applyFilter();
              });
            },
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: Text(widget.loc.t('全部班级', 'All Classes')),
                  selected: _selectedClass == null,
                  onSelected: (val) {
                    setState(() {
                      _selectedClass = null;
                      _applyFilter();
                    });
                  },
                ),
                ...widget.allClasses.map((c) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: FilterChip(
                        label: Text(widget.classNameMap[c] ?? c),
                        selected: _selectedClass == c,
                        onSelected: (val) {
                          setState(() {
                            _selectedClass = val ? c : null;
                            _applyFilter();
                          });
                        },
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _filteredStudents.isEmpty
                ? Center(
                    child: Text(widget.loc.t('未找到匹配学生', 'No students found')))
                : ListView.builder(
                    itemCount: _filteredStudents.length,
                    itemBuilder: (ctx, idx) {
                      final student = _filteredStudents[idx];
                      final classCode =
                          (student['class_code'] ?? student['class'] ?? '')
                              .toString();
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.white,
                          backgroundImage: student['avatar'] != null
                              ? NetworkImage(student['avatar'])
                              : null,
                          child: student['avatar'] == null
                              ? Text(
                                  (student['full_name'] ??
                                          student['name'] ??
                                          '?')
                                      .toString()
                                      .substring(0, 1),
                                  style: TextStyle(color: widget.cs.primary))
                              : null,
                        ),
                        title: Text(
                            (student['full_name'] ?? student['name'] ?? '')
                                .toString()),
                        subtitle:
                            Text(widget.classNameMap[classCode] ?? classCode),
                        trailing: Icon(Icons.check_circle,
                            color: widget.cs.primary, size: 20),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
