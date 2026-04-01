import 'dart:ui';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import 'package:animations/animations.dart';

import '../main.dart';
import '../state/session.dart';
import '../widgets/home_drawer.dart';
import '../widgets/expressive_ui.dart';
import 'attendance_page.dart';
import 'contacts_page.dart';
import 'todos_page.dart';
import 'timetable_page.dart';
import 'class_students_page.dart';
import 'class_attendance_overview_page.dart';

import 'profile_page.dart';

class ShellPage extends StatefulWidget {
  final Session session;
  final VoidCallback onLogout;

  const ShellPage({super.key, required this.session, required this.onLogout});

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1024;
    return isDesktop
        ? _DesktopShell(session: widget.session, onLogout: widget.onLogout)
        : _MobileShell(session: widget.session, onLogout: widget.onLogout);
  }
}

class _FadeIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;

  const _FadeIndexedStack({
    Key? key,
    required this.index,
    required this.children,
  }) : super(key: key);

  @override
  _FadeIndexedStackState createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<_FadeIndexedStack>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.index;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(_FadeIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index != _currentIndex) {
      setState(() {
        _currentIndex = widget.index;
      });
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageTransitionSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> primaryAnimation,
          Animation<double> secondaryAnimation) {
        return FadeThroughTransition(
          animation: primaryAnimation,
          secondaryAnimation: secondaryAnimation,
          child: child,
        );
      },
      child: IndexedStack(
        key: ValueKey<int>(_currentIndex),
        index: _currentIndex,
        children: widget.children,
      ),
    );
  }
}

class _DesktopShell extends StatefulWidget {
  final Session session;
  final VoidCallback onLogout;

  const _DesktopShell({required this.session, required this.onLogout});

  @override
  State<_DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<_DesktopShell> {
  bool _isExtended = true;
  String _targetPageId = 'timetable';
  String _visiblePageId = 'timetable';
  final Set<String> _mountedPageIds = {'timetable'};
  final Set<String> _readyPageIds = {};
  final Map<String, Widget> _pageCache = {};

  void _onPageReady(String id) {
    if (!mounted) return;
    setState(() {
      _readyPageIds.add(id);
      if (_targetPageId == id && _visiblePageId != id) {
        _visiblePageId = id;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    widget.session.addListener(_onSessionChanged);
  }

  @override
  void dispose() {
    widget.session.removeListener(_onSessionChanged);
    super.dispose();
  }

  void _onSessionChanged() {
    if (mounted) setState(() {});
  }

  Widget _getPage(String id) {
    final cached = _pageCache[id];
    if (cached != null) return cached;
    final w = switch (id) {
      'timetable' => TimetablePage(
          session: widget.session,
          onLogout: widget.onLogout,
          onReady: () => _onPageReady(id)),
      'todo' =>
        TodosPage(session: widget.session, onReady: () => _onPageReady(id)),
      'contact' =>
        ContactsPage(session: widget.session, onReady: () => _onPageReady(id)),
      'attendance' => AttendancePage(
          session: widget.session, onReady: () => _onPageReady(id)),
      'students' => ClassStudentsPage(
          session: widget.session, onReady: () => _onPageReady(id)),
      'class_attendance' => ClassAttendanceOverviewPage(
          session: widget.session, onReady: () => _onPageReady(id)),
      _ => TimetablePage(
          session: widget.session,
          onLogout: widget.onLogout,
          onReady: () => _onPageReady(id)),
    };
    _pageCache[id] = w;
    return w;
  }

  List<({NavigationRailDestination destination, String id})> _items(
      LocaleProvider loc) {
    final out = <({NavigationRailDestination destination, String id})>[
      (
        destination: NavigationRailDestination(
          icon: const Icon(Icons.calendar_today_outlined),
          selectedIcon: const Icon(Icons.calendar_today),
          label: Text(loc.t('周课表', 'Timetable')),
        ),
        id: 'timetable',
      ),
      (
        destination: NavigationRailDestination(
          icon: const Icon(Icons.checklist_rtl_outlined),
          selectedIcon: const Icon(Icons.checklist_rtl),
          label: Text(loc.t('待办', 'Todos')),
        ),
        id: 'todo',
      ),
      (
        destination: NavigationRailDestination(
          icon: const Icon(Icons.contacts_outlined),
          selectedIcon: const Icon(Icons.contacts),
          label: Text(loc.t('通讯录', 'Contacts')),
        ),
        id: 'contact',
      ),
    ];

    if (widget.session.canTakeAttendance) {
      out.add(
        (
          destination: NavigationRailDestination(
            icon: const Icon(Icons.emoji_people_outlined),
            selectedIcon: const Icon(Icons.emoji_people_rounded),
            label: Text(loc.t('点名', 'Roll Call')),
          ),
          id: 'attendance',
        ),
      );
    }

    if (widget.session.canViewStudents) {
      out.addAll([
        (
          destination: NavigationRailDestination(
            icon: const Icon(Icons.people_outline),
            selectedIcon: const Icon(Icons.people),
            label: Text(loc.t('学生', 'Students')),
          ),
          id: 'students',
        ),
        (
          destination: NavigationRailDestination(
            icon: const Icon(Icons.assessment_outlined),
            selectedIcon: const Icon(Icons.assessment),
            label: Text(loc.t('考勤', 'Attendance')),
          ),
          id: 'class_attendance',
        ),
      ]);
    }

    return out;
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocaleProvider>(context);
    final items = _items(loc);
    final pageIds = items.map((e) => e.id).toList();

    if (!pageIds.contains(_targetPageId) && pageIds.isNotEmpty) {
      _targetPageId = pageIds.first;
      _visiblePageId = pageIds.first;
    }

    _mountedPageIds.add(_targetPageId);
    if (_readyPageIds.contains(_targetPageId)) {
      _visiblePageId = _targetPageId;
    }

    final pages = pageIds
        .map((id) => _mountedPageIds.contains(id)
            ? _getPage(id)
            : const SizedBox.shrink())
        .toList(growable: false);
    final activeIdx = pageIds.indexOf(_visiblePageId);
    final actualActiveIdx = activeIdx >= 0 ? activeIdx : 0;

    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Row(
        children: [
          // Custom Desktop Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            width: _isExtended ? 240 : 80,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black.withValues(alpha: 204)
                  : Colors.white.withValues(alpha: 204),
              border: Border(
                  right: BorderSide(color: cs.outlineVariant, width: 0.5)),
            ),
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    // Toggle Button & Logo
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: _isExtended
                            ? MainAxisAlignment.spaceBetween
                            : MainAxisAlignment.center,
                        children: [
                          if (_isExtended)
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const NeverScrollableScrollPhysics(),
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle_outline_rounded,
                                        color: cs.primary),
                                    const SizedBox(width: 8),
                                    Text('Functions',
                                        style: tt.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          IconButton(
                            icon: Icon(
                                _isExtended ? Icons.menu_open : Icons.menu),
                            onPressed: () =>
                                setState(() => _isExtended = !_isExtended),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Profile Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Bounceable(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) =>
                                    ProfilePage(session: widget.session)),
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.all(_isExtended ? 12 : 0),
                          alignment: _isExtended
                              ? Alignment.centerLeft
                              : Alignment.center,
                          decoration: BoxDecoration(
                            color: _isExtended
                                ? cs.surfaceContainerHigh
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const NeverScrollableScrollPhysics(),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Container(
                                  width: _isExtended ? 48 : 46,
                                  height: _isExtended ? 48 : 46,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(
                                        _isExtended ? 16 : 14),
                                    border: Border.all(
                                        color: cs.outlineVariant, width: 1),
                                    image: widget.session.profile.avatar
                                                .isNotEmpty &&
                                            File(widget.session.profile.avatar)
                                                .existsSync()
                                        ? DecorationImage(
                                            image: FileImage(File(
                                                widget.session.profile.avatar)),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  alignment: Alignment.center,
                                  child: (widget
                                              .session.profile.avatar.isEmpty ||
                                          !File(widget.session.profile.avatar)
                                              .existsSync())
                                      ? Text(
                                          widget.session.profile.displayName
                                                  .isNotEmpty
                                              ? widget
                                                  .session.profile.displayName
                                                  .substring(0, 1)
                                                  .toUpperCase()
                                              : '?',
                                          style: TextStyle(
                                              color: cs.onPrimaryContainer,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20),
                                        )
                                      : null,
                                ),
                                if (_isExtended) ...[
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.session.profile.displayName,
                                        style: tt.titleSmall?.copyWith(
                                            fontWeight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        widget.session.isTeacher
                                            ? loc.t('教师', 'Teacher')
                                            : loc.t('学生', 'Student'),
                                        style: tt.labelSmall?.copyWith(
                                            color: cs.onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Nav Items
                    Expanded(
                      child: ListView.builder(
                        itemCount: items.length,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemBuilder: (context, index) {
                          final targetIdx = pageIds.indexOf(_targetPageId);
                          final isSelected =
                              (targetIdx >= 0 ? targetIdx : 0) == index;
                          final dest = items[index].destination;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Bounceable(
                              onTap: () {
                                setState(() {
                                  _targetPageId = items[index].id;
                                  _mountedPageIds.add(_targetPageId);
                                  if (_readyPageIds.contains(_targetPageId)) {
                                    _visiblePageId = _targetPageId;
                                  }
                                });
                              },
                              child: Container(
                                height: 56,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? cs.primaryContainer
                                          .withValues(alpha: 128)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    // The Highlighting Line
                                    AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      width: 4,
                                      height: isSelected ? 24 : 0,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? cs.primary
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        child: Row(
                                          mainAxisAlignment: _isExtended
                                              ? MainAxisAlignment.start
                                              : MainAxisAlignment.center,
                                          children: [
                                            Theme(
                                              data: Theme.of(context).copyWith(
                                                iconTheme: IconThemeData(
                                                  color: isSelected
                                                      ? cs.primary
                                                      : cs.onSurfaceVariant,
                                                ),
                                              ),
                                              child: isSelected
                                                  ? (dest.selectedIcon ??
                                                      dest.icon)
                                                  : dest.icon,
                                            ),
                                            if (_isExtended) ...[
                                              const SizedBox(width: 12),
                                              Text(
                                                (dest.label as Text).data ?? '',
                                                style: tt.titleSmall?.copyWith(
                                                  color: isSelected
                                                      ? cs.primary
                                                      : cs.onSurfaceVariant,
                                                  fontWeight: isSelected
                                                      ? FontWeight.bold
                                                      : null,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Logout
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Bounceable(
                        onTap: widget.onLogout,
                        child: Container(
                          height: 56,
                          alignment: _isExtended
                              ? Alignment.centerLeft
                              : Alignment.center,
                          decoration: BoxDecoration(
                            color: cs.errorContainer.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const NeverScrollableScrollPhysics(),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                if (_isExtended) const SizedBox(width: 16),
                                Icon(Icons.logout, color: cs.error),
                                if (_isExtended) ...[
                                  const SizedBox(width: 12),
                                  Text(loc.t('退出登录', 'Sign out'),
                                      style: tt.titleSmall?.copyWith(
                                          color: cs.error,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: Container(
              color: Colors.transparent,
              child: _FadeIndexedStack(
                index: actualActiveIdx,
                children: pages,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileShell extends StatefulWidget {
  final Session session;
  final VoidCallback onLogout;

  const _MobileShell({required this.session, required this.onLogout});

  @override
  State<_MobileShell> createState() => _MobileShellState();
}

class _MobileShellState extends State<_MobileShell> {
  String _activePageId = 'timetable';
  List<String>? _bottomNavIds;
  bool _navPrefsLoaded = false;
  final Map<String, Widget> _pageCache = {};
  final TimetableController _timetableController = TimetableController();

  String _targetPageId = 'timetable';
  String _visiblePageId = 'timetable';
  final Set<String> _mountedPageIds = {'timetable'};
  final Set<String> _readyPageIds = {};

  void _onPageReady(String id) {
    if (!mounted) return;
    setState(() {
      _readyPageIds.add(id);
      if (_targetPageId == id && _visiblePageId != id) {
        _visiblePageId = id;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    widget.session.addListener(_onSessionChanged);
    _loadNavPrefs();
  }

  @override
  void dispose() {
    widget.session.removeListener(_onSessionChanged);
    super.dispose();
  }

  void _onSessionChanged() {
    if (mounted) setState(() {});
  }

  File _navPrefsFile() {
    return File(p.join(widget.session.dataDir, 'nav_prefs.json'));
  }

  List<String> _defaultBottomNav() {
    final out = <String>[];
    final loc = Provider.of<LocaleProvider>(context, listen: false);
    final avail = _availablePageOptions(loc).map((e) => e.id).toSet();
    void addIf(String id) {
      if (out.length >= 3) return;
      if (avail.contains(id) && !out.contains(id)) out.add(id);
    }

    addIf('timetable');
    if (widget.session.canViewStudents) {
      addIf('students');
      addIf('class_attendance');
    } else {
      addIf('contact');
      addIf('todo');
      addIf('attendance');
    }
    return out;
  }

  Future<void> _loadNavPrefs() async {
    try {
      final f = _navPrefsFile();
      if (await f.exists()) {
        final raw = jsonDecode(await f.readAsString(encoding: utf8));
        if (raw is Map && raw['bottom'] is List) {
          final ids = (raw['bottom'] as List).map((e) => e.toString()).toList();
          if (mounted) {
            setState(() {
              _bottomNavIds = ids;
              _navPrefsLoaded = true;
            });
          }
          return;
        }
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        _bottomNavIds = _defaultBottomNav();
        _navPrefsLoaded = true;
      });
    }
  }

  Future<void> _saveNavPrefs(List<String> ids) async {
    try {
      final f = _navPrefsFile();
      final payload = <String, dynamic>{
        'bottom': ids.take(3).toList(),
        'saved_at': DateTime.now().toIso8601String(),
      };
      await f.writeAsString(jsonEncode(payload), encoding: utf8);
    } catch (_) {}
  }

  List<({String id, String label, IconData icon})> _availablePageOptions(
      LocaleProvider loc) {
    final out = <({String id, String label, IconData icon})>[
      (
        id: 'timetable',
        label: loc.t('周课表', 'Timetable'),
        icon: Icons.calendar_month
      ),
      (
        id: 'contact',
        label: loc.t('通讯录', 'Contacts'),
        icon: Icons.contact_page_rounded
      ),
    ];
    if (widget.session.isTeacher) {
      out.insert(1, (
        id: 'todo',
        label: loc.t('待办', 'Todos'),
        icon: Icons.checklist_rtl_rounded
      ));
    }
    if (widget.session.isTeacher && widget.session.canTakeAttendance) {
      out.add((
        id: 'attendance',
        label: loc.t('点名', 'Roll Call'),
        icon: Icons.emoji_people_rounded
      ));
    }
    if (widget.session.canViewStudents) {
      out.add(
          (id: 'students', label: loc.t('学生', 'Students'), icon: Icons.people));
      out.add((
        id: 'class_attendance',
        label: loc.t('考勤', 'Attendance'),
        icon: Icons.assessment
      ));
    }
    return out;
  }

  Future<void> _openNavSettings() async {
    final loc = Provider.of<LocaleProvider>(context, listen: false);
    final options = _availablePageOptions(loc);
    final current = (_bottomNavIds ?? _defaultBottomNav())
        .where((id) => options.any((o) => o.id == id))
        .toList();
    final res = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(
        builder: (_) => _NavSettingsPage(
          options: options,
          initialSelected: current.take(3).toList(),
          onImportWakeUp: _timetableController.importWakeUp,
        ),
      ),
    );
    if (res == null) return;
    final normalized = res
        .where((id) => options.any((o) => o.id == id))
        .toList()
        .take(3)
        .toList();
    setState(() {
      _bottomNavIds = normalized;
    });
    await _saveNavPrefs(normalized);
  }

  Widget _pageForId(String id) {
    final cached = _pageCache[id];
    if (cached != null) return cached;
    final w = switch (id) {
      'timetable' => TimetablePage(
          session: widget.session,
          onLogout: widget.onLogout,
          controller: _timetableController,
          onReady: () => _onPageReady(id),
        ),
      'todo' =>
        TodosPage(session: widget.session, onReady: () => _onPageReady(id)),
      'contact' =>
        ContactsPage(session: widget.session, onReady: () => _onPageReady(id)),
      'attendance' => AttendancePage(
          session: widget.session, onReady: () => _onPageReady(id)),
      'students' => ClassStudentsPage(
          session: widget.session, onReady: () => _onPageReady(id)),
      'class_attendance' => ClassAttendanceOverviewPage(
          session: widget.session, onReady: () => _onPageReady(id)),
      _ => TimetablePage(
          session: widget.session,
          onLogout: widget.onLogout,
          controller: _timetableController,
          onReady: () => _onPageReady(id),
        ),
    };
    _pageCache[id] = w;
    return w;
  }

  List<({NavigationDestination destination, String id})> _navItems() {
    final loc = Provider.of<LocaleProvider>(context, listen: false);
    final options = _availablePageOptions(loc);
    final selected = (_bottomNavIds ?? _defaultBottomNav())
        .where((id) => options.any((o) => o.id == id))
        .toList()
        .take(3)
        .toList();
    final out = <({NavigationDestination destination, String id})>[];
    for (final id in selected) {
      final opt = options.where((o) => o.id == id).firstOrNull;
      if (opt == null) continue;
      out.add(
        (
          destination: NavigationDestination(
            icon: Icon(opt.icon),
            label: opt.label,
          ),
          id: opt.id,
        ),
      );
    }
    if (out.isEmpty) {
      out.add(
        (
          destination: NavigationDestination(
            icon: const Icon(Icons.calendar_month),
            label: loc.t('周课表', 'Timetable'),
          ),
          id: 'timetable',
        ),
      );
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocaleProvider>(context);
    final navItems = _navItems();
    final navIndex = navItems.indexWhere((e) => e.id == _activePageId);

    // Use an index of 0 if the active page is not in the NavigationBar
    // to prevent crashes, but ideally we style it so it doesn't look selected
    // if it's not. However, NavigationBar requires a selectedIndex >= 0.
    // If it's not in the bottom bar, we can hide the bottom bar or just keep the last index.
    // Actually, NavigationBar allows selectedIndex to be out of bounds if there's an indicator?
    // No, it throws. Let's make it 0 but we can't easily deselect all.
    // A trick is to use an IndicatorColor of transparent if navIndex is -1.
    final actualNavIndex = navIndex >= 0 ? navIndex : 0;

    final pageIds = _availablePageOptions(loc).map((e) => e.id).toList();
    if (!pageIds.contains(_targetPageId) && pageIds.isNotEmpty) {
      _targetPageId = pageIds.first;
      _visiblePageId = pageIds.first;
    }

    _mountedPageIds.add(_targetPageId);
    if (_readyPageIds.contains(_targetPageId)) {
      _visiblePageId = _targetPageId;
    }

    final children = pageIds
        .map((id) => _mountedPageIds.contains(id)
            ? _pageForId(id)
            : const SizedBox.shrink())
        .toList(growable: false);
    final activeIdx = pageIds.indexOf(_visiblePageId);
    final actualActiveIdx = activeIdx >= 0 ? activeIdx : 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      drawerEdgeDragWidth: 100, // Make it easier to swipe from edge
      drawer: HomeDrawer(
        session: widget.session,
        activePage: _activePageId,
        hiddenPageIds: _navPrefsLoaded
            ? _navItems().map((e) => e.id).toSet()
            : const <String>{},
        onNavigate: (pageId) {
          if (pageId == 'profile') {
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => ProfilePage(session: widget.session)),
            );
            return;
          }
          if (pageId == 'settings') {
            _openNavSettings();
            return;
          }
          setState(() {
            _activePageId = pageId;
            _targetPageId = pageId;
            _mountedPageIds.add(_targetPageId);
            if (_readyPageIds.contains(_targetPageId)) {
              _visiblePageId = _targetPageId;
            }
          });
        },
        onLogout: widget.onLogout,
      ),
      body: Builder(
        builder: (context) {
          return _FadeIndexedStack(
            index: actualActiveIdx,
            children: children,
          );
        },
      ),
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: NavigationBar(
            selectedIndex: actualNavIndex,
            indicatorShape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            indicatorColor: navIndex >= 0
                ? Theme.of(context).colorScheme.secondaryContainer
                : Colors.transparent,
            onDestinationSelected: (i) {
              setState(() {
                _activePageId = navItems[i].id;
                _targetPageId = navItems[i].id;
                _mountedPageIds.add(_targetPageId);
                if (_readyPageIds.contains(_targetPageId)) {
                  _visiblePageId = _targetPageId;
                }
              });
            },
            destinations: navItems.map((e) => e.destination).toList(),
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 204)
                : Colors.white.withValues(alpha: 204),
          ),
        ),
      ),
    );
  }
}

class _NavSettingsPage extends StatefulWidget {
  final List<({String id, String label, IconData icon})> options;
  final List<String> initialSelected;
  final Future<void> Function()? onImportWakeUp;

  const _NavSettingsPage({
    required this.options,
    required this.initialSelected,
    required this.onImportWakeUp,
  });

  @override
  State<_NavSettingsPage> createState() => _NavSettingsPageState();
}

class _NavSettingsPageState extends State<_NavSettingsPage> {
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialSelected.toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDesktop =
        Platform.isWindows || Platform.isLinux || Platform.isMacOS;

    final selectedOpts = _selected
        .map((id) => widget.options.where((o) => o.id == id).firstOrNull)
        .whereType<({String id, String label, IconData icon})>()
        .toList(growable: false);

    final remaining = widget.options
        .where((o) => !_selected.contains(o.id))
        .toList(growable: false);

    final localeProvider = Provider.of<LocaleProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localeProvider.t('设置', 'Settings')),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(_selected.take(3).toList()),
            child: Text(localeProvider.t('保存', 'Save')),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            localeProvider.t('导航栏', 'Navigation Bar'),
            style: tt.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(24),
              border:
                  Border.all(color: cs.outlineVariant.withValues(alpha: 128)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localeProvider.t('底栏元素（最多 3 个）', 'Bottom Bar Items (Max 3)'),
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  localeProvider.t('拖动排序；未选中的功能将出现在 Drawer 里。',
                      'Drag to reorder; unselected items will appear in the Drawer.'),
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (selectedOpts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(localeProvider.t('当前未选择', 'None selected'),
                  style: tt.bodyMedium),
            )
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: selectedOpts.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final id = _selected.removeAt(oldIndex);
                  _selected.insert(newIndex, id);
                });
              },
              itemBuilder: (context, index) {
                final o = selectedOpts[index];
                return Container(
                  key: ValueKey(o.id),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: cs.outlineVariant.withValues(alpha: 128)),
                  ),
                  child: ListTile(
                    leading: Icon(o.icon),
                    title: Text(o.label),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _selected.remove(o.id);
                            });
                          },
                          icon: const Icon(Icons.close_rounded),
                          tooltip: localeProvider.t('移除', 'Remove'),
                        ),
                        ReorderableDragStartListener(
                          index: index,
                          child: const Icon(Icons.drag_handle_rounded),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 16),
          Text(
            localeProvider.t('主题与语言', 'Theme & Language'),
            style: tt.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(24),
              border:
                  Border.all(color: cs.outlineVariant.withValues(alpha: 128)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  title: Text(localeProvider.t('暗黑模式', 'Dark Mode')),
                  subtitle: Text(localeProvider.t(
                      '切换应用的颜色主题', 'Toggle application color theme')),
                  value: localeProvider.themeMode == ThemeMode.dark,
                  onChanged: (bool value) {
                    localeProvider
                        .setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
                  },
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('English'),
                  subtitle: Text(localeProvider.t(
                      '切换应用语言', 'Toggle Application Language')),
                  value: localeProvider.locale.languageCode == 'en',
                  onChanged: (bool value) {
                    localeProvider.setLocale(value
                        ? const Locale('en', 'US')
                        : const Locale('zh', 'CN'));
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
