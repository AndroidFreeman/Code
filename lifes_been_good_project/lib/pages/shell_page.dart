import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../state/session.dart';
import '../services/native_features.dart';
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
    required this.index,
    required this.children,
  });

  @override
  _FadeIndexedStackState createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<_FadeIndexedStack>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late int _currentIndex;
  int? _previousIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.index;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _previousIndex = null;
        });
      }
    });
    _controller.forward();
  }

  @override
  void didUpdateWidget(_FadeIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index != _currentIndex) {
      setState(() {
        _previousIndex = _currentIndex;
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
    return Stack(
      children: widget.children.asMap().entries.map((entry) {
        final index = entry.key;
        final child = entry.value;

        final isCurrent = index == _currentIndex;
        final isPrevious = index == _previousIndex;

        if (!isCurrent && !isPrevious) {
          return const SizedBox.shrink();
        }

        return FadeTransition(
          opacity: isCurrent
              ? _controller.drive(CurveTween(curve: Curves.easeOut))
              : _controller.drive(Tween<double>(begin: 1.0, end: 0.0)
                  .chain(CurveTween(curve: Curves.easeIn))),
          child: SlideTransition(
            position: isCurrent
                ? _controller.drive(Tween<Offset>(
                        begin: const Offset(0, 0.02), end: Offset.zero)
                    .chain(CurveTween(curve: Curves.easeOutCubic)))
                : const AlwaysStoppedAnimation(Offset.zero),
            child: IgnorePointer(
              ignoring: !isCurrent,
              child: child,
            ),
          ),
        );
      }).toList(),
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
  final TimetableController _timetableController = TimetableController();
  LocaleProvider? _localeProvider;

  void _onPageReady(String id) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _readyPageIds.add(id);
        });
      }
    });
  }

  void _changePage(String id) {
    setState(() {
      _targetPageId = id;
      _visiblePageId = id;
      _mountedPageIds.add(id);
    });
  }

  @override
  void initState() {
    super.initState();
    widget.session.addListener(_onSessionChanged);
    _localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    _localeProvider?.addListener(_onLocaleChanged);
  }

  @override
  void dispose() {
    widget.session.removeListener(_onSessionChanged);
    _localeProvider?.removeListener(_onLocaleChanged);
    super.dispose();
  }

  void _onSessionChanged() {
    // Only rebuild if actual profile/state that affects Shell changes
    // This listener is often too broad.
    if (mounted) setState(() {});
  }

  void _onLocaleChanged() {
    // Force refresh all cached pages when language changes
    _pageCache.clear();
    if (mounted) setState(() {});
  }

  Widget _getPage(String id) {
    final cached = _pageCache[id];
    if (cached != null) return cached;
    final w = switch (id) {
      'timetable' => TimetablePage(
          session: widget.session,
          onLogout: widget.onLogout,
          controller: _timetableController,
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
          controller: _timetableController,
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
            decoration: const BoxDecoration(
              color: Colors.transparent,
            ),
            child: SafeArea(
              bottom: false,
              right: false,
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // Toggle Button & Logo
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_isExtended)
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const NeverScrollableScrollPhysics(),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.asset(
                                      'assets/images/logo.png',
                                      width: 24,
                                      height: 24,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(loc.t('更多工具', 'More Tools'),
                                      style: tt.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        IconButton(
                          icon:
                              Icon(_isExtended ? Icons.menu_open : Icons.menu),
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
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOutCubic,
                        padding: EdgeInsets.symmetric(
                            vertical: _isExtended ? 12 : 0,
                            horizontal: _isExtended ? 12 : 0),
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
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 48,
                                height: 48,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
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
                              ),
                              if (_isExtended)
                                Flexible(
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOutCubic,
                                    width: _isExtended ? 124 : 0,
                                    child: ClipRect(
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Opacity(
                                          opacity: _isExtended ? 1.0 : 0.0,
                                          child: Padding(
                                            padding:
                                                const EdgeInsets.only(left: 12),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  widget.session.profile
                                                      .displayName,
                                                  style: tt.titleSmall
                                                      ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.bold),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                                Text(
                                                  widget.session.isTeacher
                                                      ? loc.t('教师', 'Teacher')
                                                      : loc.t('学生', 'Student'),
                                                  style: tt.labelSmall?.copyWith(
                                                      color:
                                                          cs.onSurfaceVariant),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                              ],
                                            ),
                                          ),
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
                              _changePage(items[index].id);
                            },
                            child: Container(
                              height: 56,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? cs.primaryContainer.withValues(alpha: 128)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  // The Highlighting Line
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
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
                                      child: AnimatedAlign(
                                        duration:
                                            const Duration(milliseconds: 300),
                                        curve: Curves.easeInOutCubic,
                                        alignment: _isExtended
                                            ? Alignment.centerLeft
                                            : Alignment.center,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
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
                                                  ? dest.selectedIcon
                                                  : dest.icon,
                                            ),
                                            AnimatedContainer(
                                              duration: const Duration(
                                                  milliseconds: 300),
                                              curve: Curves.easeInOutCubic,
                                              width:
                                                  0, // removed width: _isExtended ? 12 : 0, as it's fixed below
                                            ),
                                            if (_isExtended)
                                              const SizedBox(width: 12),
                                            AnimatedContainer(
                                              duration: const Duration(
                                                  milliseconds: 300),
                                              curve: Curves.easeInOutCubic,
                                              width: _isExtended ? 140 : 0,
                                              child: ClipRect(
                                                child: Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Opacity(
                                                    opacity:
                                                        _isExtended ? 1.0 : 0.0,
                                                    child: Text(
                                                      (dest.label as Text)
                                                              .data ??
                                                          '',
                                                      style: tt.titleSmall
                                                          ?.copyWith(
                                                        color: isSelected
                                                            ? cs.primary
                                                            : cs.onSurfaceVariant,
                                                        fontWeight: isSelected
                                                            ? FontWeight.bold
                                                            : null,
                                                      ),
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
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Settings
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Bounceable(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => _NavSettingsPage(
                              options: const [],
                              initialOrder: const [],
                              onImportWakeUp: _timetableController.importWakeUp,
                              onClearTimetable:
                                  _timetableController.clearTimetable,
                              isTeacher: widget.session.isTeacher,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        height: 56,
                        alignment: _isExtended
                            ? Alignment.centerLeft
                            : Alignment.center,
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHigh.withValues(alpha: 128),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const NeverScrollableScrollPhysics(),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOutCubic,
                                width: _isExtended ? 16 : 0,
                              ),
                              Icon(Icons.settings, color: cs.onSurfaceVariant),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOutCubic,
                                width: _isExtended ? 12 : 0,
                              ),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOutCubic,
                                width: _isExtended ? 140 : 0,
                                child: ClipRect(
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Opacity(
                                      opacity: _isExtended ? 1.0 : 0.0,
                                      child: Text(
                                        loc.t('设置', 'Settings'),
                                        style: tt.titleSmall?.copyWith(
                                            color: cs.onSurfaceVariant,
                                            fontWeight: FontWeight.bold),
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
                  ),
                  const SizedBox(height: 8),
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
                          color: cs.errorContainer.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const NeverScrollableScrollPhysics(),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOutCubic,
                                width: _isExtended ? 16 : 0,
                              ),
                              Icon(Icons.logout, color: cs.error),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOutCubic,
                                width: _isExtended ? 12 : 0,
                              ),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOutCubic,
                                width: _isExtended ? 140 : 0,
                                child: ClipRect(
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Opacity(
                                      opacity: _isExtended ? 1.0 : 0.0,
                                      child: Text(
                                        loc.t('退出登录', 'Sign out'),
                                        style: tt.titleSmall?.copyWith(
                                            color: cs.error,
                                            fontWeight: FontWeight.bold),
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
                  ),
                ],
              ),
            ),
          ),
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
  LocaleProvider? _localeProvider;

  String _targetPageId = 'timetable';
  String _visiblePageId = 'timetable';
  final Set<String> _mountedPageIds = {'timetable'};
  final Set<String> _readyPageIds = {};
  DateTime? _lastBackAt;

  void _onPageReady(String id) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _readyPageIds.add(id);
        });
      }
    });
  }

  void _changePage(String id) {
    setState(() {
      _activePageId = id;
      _targetPageId = id;
      _visiblePageId = id;
      _mountedPageIds.add(id);
    });
  }

  @override
  void initState() {
    super.initState();
    widget.session.addListener(_onSessionChanged);
    _localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    _localeProvider?.addListener(_onLocaleChanged);
    _loadNavPrefs();
  }

  @override
  void dispose() {
    widget.session.removeListener(_onSessionChanged);
    _localeProvider?.removeListener(_onLocaleChanged);
    super.dispose();
  }

  void _onSessionChanged() {
    // Only rebuild if actual profile/state that affects Shell changes
    if (mounted) setState(() {});
  }

  void _onLocaleChanged() {
    // Force refresh all cached pages when language changes
    _pageCache.clear();
    if (mounted) setState(() {});
  }

  List<String> _defaultBottomNav() {
    final loc = Provider.of<LocaleProvider>(context, listen: false);
    final options = _availablePageOptions(loc);
    final optionIds = options.map((e) => e.id).toList(growable: false);

    final preferred = <String>[];
    void addFirst(String id) {
      if (!optionIds.contains(id)) return;
      if (!preferred.contains(id)) preferred.add(id);
    }

    addFirst('timetable');
    if (widget.session.canViewStudents) {
      addFirst('students');
      addFirst('class_attendance');
    } else {
      addFirst('contact');
      if (widget.session.canTakeAttendance) {
        addFirst('attendance');
      }
    }

    final out = <String>[...preferred];
    for (final id in optionIds) {
      if (!out.contains(id)) out.add(id);
    }
    return out;
  }

  Future<void> _loadNavPrefs() async {
    final loc = Provider.of<LocaleProvider>(context, listen: false);
    try {
      final features = NativeFeatures(
          dataDir: widget.session.dataDir,
          nativeLibDir: widget.session.features.nativeLibDir);
      final res = await features.jsonOp(action: 'read', file: 'nav_prefs.json');
      if (res['ok'] == true && res['data'] != null) {
        final raw = res['data'];
        if (raw is Map) {
          final options = _availablePageOptions(loc);
          final optionIds = options.map((e) => e.id).toList(growable: false);

          final dynamic stored =
              raw['order'] is List ? raw['order'] : raw['bottom'];
          if (stored is List) {
            final ids = stored.map((e) => e.toString()).toList();
            final normalized =
                ids.where((id) => optionIds.contains(id)).toList();
            for (final id in optionIds) {
              if (!normalized.contains(id)) normalized.add(id);
            }
            if (mounted) {
              setState(() {
                _bottomNavIds = normalized;
                _navPrefsLoaded = true;
              });
            }
            return;
          }
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
      final payload = <String, dynamic>{
        'order': ids.toList(),
        'bottom': ids.take(3).toList(),
        'saved_at': DateTime.now().toIso8601String(),
      };
      final features = NativeFeatures(
          dataDir: widget.session.dataDir,
          nativeLibDir: widget.session.features.nativeLibDir);
      await features.jsonOp(
          action: 'write', file: 'nav_prefs.json', data: payload);
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
    if (widget.session.canTakeAttendance) {
      out.add((
        id: 'attendance',
        label: loc.t('点名', 'Roll Call'),
        icon: Icons.emoji_people_rounded
      ));
    }

    out.insert(1, (
      id: 'todo',
      label: loc.t('待办', 'Todos'),
      icon: Icons.checklist_rtl_rounded
    ));

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
    final optionIds = options.map((e) => e.id).toList(growable: false);
    final current = (_bottomNavIds ?? _defaultBottomNav())
        .where((id) => optionIds.contains(id))
        .toList();
    final normalizedCurrent = <String>[...current];
    for (final id in optionIds) {
      if (!normalizedCurrent.contains(id)) normalizedCurrent.add(id);
    }
    final res = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(
        builder: (_) => _NavSettingsPage(
          options: options,
          initialOrder: normalizedCurrent,
          onImportWakeUp: _timetableController.importWakeUp,
          onClearTimetable: _timetableController.clearTimetable,
          isTeacher: widget.session.isTeacher,
        ),
      ),
    );
    if (res == null) return;
    final normalized = res.where((id) => optionIds.contains(id)).toList();
    for (final id in optionIds) {
      if (!normalized.contains(id)) normalized.add(id);
    }
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
            icon: const Icon(Icons.menu),
            label: loc.t('菜单', 'Menu'),
          ),
          id: 'menu_fallback',
        ),
      );
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocaleProvider>(context);
    final navItems = _navItems();
    final barItems = navItems.length == 1
        ? [
            navItems[0],
            (
              destination: NavigationDestination(
                icon: const Icon(Icons.more_horiz),
                label: loc.t('更多', 'More'),
              ),
              id: 'more',
            ),
          ]
        : navItems;
    final navIndex = barItems.indexWhere((e) => e.id == _activePageId);

    // Use an index of 0 if the active page is not in the NavigationBar
    // to prevent crashes, but ideally we style it so it doesn't look selected
    // if it's not. However, NavigationBar requires a selectedIndex >= 0.
    // If it's not in the bottom bar, we can hide the bottom bar or just keep the last index.
    // Actually, NavigationBar allows selectedIndex to be out of bounds if there's an indicator?
    // No, it throws. Let's make it 0 but we can't easily deselect all.
    // A trick is to use an IndicatorColor of transparent if navIndex is -1.
    final actualNavIndex = navIndex >= 0 ? navIndex : 0;
    final showIndicator = navIndex >= 0 &&
        barItems[navIndex].id != 'menu_fallback' &&
        barItems[navIndex].id != 'more';

    final pageIds = _availablePageOptions(loc).map((e) => e.id).toList();
    if (!pageIds.contains(_targetPageId) && pageIds.isNotEmpty) {
      _targetPageId = pageIds.first;
      _visiblePageId = pageIds.first;
    }

    _mountedPageIds.add(_targetPageId);
    final children = pageIds
        .map((id) => _mountedPageIds.contains(id)
            ? _pageForId(id)
            : const SizedBox.shrink())
        .toList(growable: false);
    final activeIdx = pageIds.indexOf(_visiblePageId);
    final actualActiveIdx = activeIdx >= 0 ? activeIdx : 0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_activePageId != 'timetable') {
          setState(() {
            _activePageId = 'timetable';
            _targetPageId = 'timetable';
            _visiblePageId = 'timetable';
            _mountedPageIds.add('timetable');
          });
          return;
        }
        if (!Platform.isAndroid) return;
        final now = DateTime.now();
        final last = _lastBackAt;
        _lastBackAt = now;
        if (last == null || now.difference(last) > const Duration(seconds: 2)) {
          showExpressiveSnackBar(
            context,
            loc.t('再按一次退出', 'Press back again to exit'),
          );
          return;
        }
        SystemNavigator.pop();
      },
      child: Scaffold(
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
            _changePage(pageId);
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
        bottomNavigationBar: Builder(
          builder: (context) {
            final key = ValueKey(barItems.map((e) => e.id).join('|'));
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: NavigationBar(
                key: key,
                selectedIndex: actualNavIndex,
                indicatorColor: showIndicator ? null : Colors.transparent,
                onDestinationSelected: (i) {
                  final id = barItems[i].id;
                  if (id == 'menu_fallback') {
                    Scaffold.of(context).openDrawer();
                    return;
                  }
                  if (id == 'more') {
                    _openNavSettings();
                    return;
                  }
                  _changePage(id);
                },
                destinations: barItems.map((e) => e.destination).toList(),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NavSettingsPage extends StatefulWidget {
  final List<({String id, String label, IconData icon})> options;
  final List<String> initialOrder;
  final Future<void> Function()? onImportWakeUp;
  final Future<void> Function()? onClearTimetable;
  final bool isTeacher;

  const _NavSettingsPage({
    required this.options,
    required this.initialOrder,
    required this.onImportWakeUp,
    required this.onClearTimetable,
    required this.isTeacher,
  });

  @override
  State<_NavSettingsPage> createState() => _NavSettingsPageState();
}

class _NavSettingsPageState extends State<_NavSettingsPage> {
  late List<String> _order;

  @override
  void initState() {
    super.initState();
    final optionIds = widget.options.map((e) => e.id).toList(growable: false);
    _order = widget.initialOrder.where((id) => optionIds.contains(id)).toList();
    for (final id in optionIds) {
      if (!_order.contains(id)) _order.add(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDesktop =
        Platform.isWindows || Platform.isLinux || Platform.isMacOS;
    final optionsById = {
      for (final o in widget.options) o.id: o,
    };
    final orderedOpts = _order
        .map((id) => optionsById[id])
        .whereType<({String id, String label, IconData icon})>()
        .toList(growable: false);

    final localeProvider = Provider.of<LocaleProvider>(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(_order.toList());
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(localeProvider.t('设置', 'Settings')),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!isDesktop) ...[
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
                  border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 128)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localeProvider.t('底栏元素', 'Bottom Bar Items'),
                      style:
                          tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      localeProvider.t('拖动排序；底栏显示前 3 个，其余在 Drawer 里。',
                          'Drag to reorder; the bottom bar shows the first 3, the rest stay in the Drawer.'),
                      style:
                          tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ReorderableListView.builder(
                buildDefaultDragHandles: false,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: orderedOpts.length,
                proxyDecorator: (child, index, animation) {
                  final id = _order[index];
                  final o = optionsById[id];
                  if (o == null) return child;
                  return Material(
                    elevation: 6,
                    color: cs.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(0),
                      side: BorderSide(
                          color: cs.outlineVariant.withValues(alpha: 128)),
                    ),
                    child: ListTile(
                      leading: Icon(o.icon),
                      title: Text(o.label),
                      trailing: const Icon(Icons.drag_indicator),
                    ),
                  );
                },
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final id = _order.removeAt(oldIndex);
                    _order.insert(newIndex, id);
                  });
                },
                itemBuilder: (context, index) {
                  final o = orderedOpts[index];
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
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
                      trailing: ReorderableDragStartListener(
                        index: index,
                        child: const Icon(Icons.drag_indicator),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
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
                      localeProvider.setThemeMode(
                          value ? ThemeMode.dark : ThemeMode.light);
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
                  ListTile(
                    leading: const Icon(Icons.file_upload_outlined),
                    title: Text(localeProvider.t(
                        '导入 WakeUp 课程表', 'Import WakeUp Schedule')),
                    onTap: () async {
                      await widget.onImportWakeUp?.call();
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(Icons.delete_sweep_outlined, color: cs.error),
                    title: Text(localeProvider.t('清空课表', 'Clear Timetable'),
                        style: TextStyle(color: cs.error)),
                    subtitle: Text(localeProvider.t(
                        '删除当前展示的课表', 'Clear current timetable')),
                    onTap: () async {
                      await widget.onClearTimetable?.call();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
