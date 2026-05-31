import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../state/locale_provider.dart';
import '../state/session.dart';
import '../services/native_features.dart';
import '../services/api_config.dart';
import '../widgets/home_drawer.dart';
import '../widgets/expressive_ui.dart';
import 'attendance_page.dart';
import 'contacts_page.dart';
import 'todos_page.dart';
import 'timetable_page.dart';
import 'class_students_page.dart';
import 'class_attendance_overview_page.dart';
import 'login_page.dart';
import 'qrcode_page.dart';
import 'weblinks_page.dart';
import 'notifications_page.dart';
import 'schedule_page.dart';

import 'profile_page.dart';
import '../services/silent_sync.dart';

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
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    final useDesktopFlow =
        width >= 1024 || (Platform.isAndroid && shortestSide >= 600);
    return useDesktopFlow
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
  int _direction = 1;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.index;
    _controller = AnimationController(
      vsync: this,
      duration: kAppRouteTransitionDuration,
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
        _direction = widget.index >= _currentIndex ? 1 : -1;
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

        final incoming = Tween<Offset>(
          begin: Offset(_direction.toDouble(), 0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: _controller, curve: kAppMotionCurve),
        );
        final outgoing = Tween<Offset>(
          begin: Offset.zero,
          end: Offset(-_direction.toDouble(), 0),
        ).animate(
          CurvedAnimation(parent: _controller, curve: kAppMotionCurve),
        );

        return ClipRect(
          child: SlideTransition(
            position: isCurrent ? incoming : outgoing,
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

class _AppScrollBehavior extends MaterialScrollBehavior {
  const _AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
        PointerDeviceKind.unknown,
      };
}

class _PagedShellViewport extends StatefulWidget {
  final Axis scrollDirection;
  final List<String> pageIds;
  final int activeIndex;
  final Widget Function(BuildContext context, int index) pageBuilder;
  final ValueChanged<String> onPageChanged;

  const _PagedShellViewport({
    required this.scrollDirection,
    required this.pageIds,
    required this.activeIndex,
    required this.pageBuilder,
    required this.onPageChanged,
  });

  @override
  State<_PagedShellViewport> createState() => _PagedShellViewportState();
}

class _PagedShellViewportState extends State<_PagedShellViewport>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  DateTime? _lastWheelAt;
  int _currentIndex = 0;
  int? _previousIndex;
  int? _targetIndex;
  int? _queuedTargetIndex;

  bool get _isAnimating => _targetIndex != null;

  int _normalizedIndex(int index) {
    if (widget.pageIds.isEmpty) return 0;
    return index.clamp(0, widget.pageIds.length - 1);
  }

  Offset _beginOffset(int direction) {
    if (widget.scrollDirection == Axis.vertical) {
      return Offset(0, direction.toDouble());
    }
    return Offset(direction.toDouble(), 0);
  }

  Future<void> _startTransition(int targetIndex) async {
    if (!mounted || widget.pageIds.isEmpty) return;
    targetIndex = _normalizedIndex(targetIndex);
    if (_isAnimating) {
      if (targetIndex != _targetIndex) {
        _queuedTargetIndex = targetIndex;
      }
      return;
    }
    if (targetIndex == _currentIndex) return;

    final duration = const Duration(milliseconds: 300);

    setState(() {
      _previousIndex = _currentIndex;
      _currentIndex = targetIndex;
      _targetIndex = targetIndex;
      _queuedTargetIndex = null;
      _controller.duration = duration;
    });

    // Notify parent immediately to sync highlight for the intermediate page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onPageChanged(widget.pageIds[targetIndex]);
      }
    });

    await _controller.forward(from: 0.0);
    if (!mounted) return;
    final queuedTargetIndex = _queuedTargetIndex;
    setState(() {
      _previousIndex = null;
      _targetIndex = null;
    });

    if (queuedTargetIndex != null && queuedTargetIndex != _currentIndex) {
      // Continue to the next step
      Future.microtask(() {
        if (mounted) {
          unawaited(_startTransition(queuedTargetIndex));
        }
      });
    }
  }

  Future<void> _handlePointerSignal(PointerSignalEvent signal) async {
    if (signal is! PointerScrollEvent || widget.pageIds.length <= 1) return;
    final delta = widget.scrollDirection == Axis.vertical
        ? signal.scrollDelta.dy
        : (signal.scrollDelta.dx.abs() > signal.scrollDelta.dy.abs()
            ? signal.scrollDelta.dx
            : signal.scrollDelta.dy);
    if (delta.abs() < 8) return;

    final now = DateTime.now();
    if (_lastWheelAt != null &&
        now.difference(_lastWheelAt!) < const Duration(milliseconds: 120)) {
      return;
    }
    _lastWheelAt = now;
    final nextIndex = (_currentIndex + (delta > 0 ? 1 : -1))
        .clamp(0, widget.pageIds.length - 1);
    if (nextIndex == _currentIndex) return;
    await _startTransition(nextIndex);
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = _normalizedIndex(widget.activeIndex);
    _controller = AnimationController(
      vsync: this,
      duration: kAppRouteTransitionDuration,
    );
  }

  @override
  void didUpdateWidget(covariant _PagedShellViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    final normalizedActive = _normalizedIndex(widget.activeIndex);
    if (_isAnimating) {
      if (normalizedActive != _targetIndex) {
        _queuedTargetIndex = normalizedActive;
      }
      return;
    }
    if (normalizedActive != _currentIndex) {
      unawaited(_startTransition(normalizedActive));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pageIds.isEmpty) {
      return const SizedBox.shrink();
    }
    final previousIndex = _previousIndex;
    final targetIndex = _targetIndex;
    final direction = targetIndex == null
        ? 1
        : (targetIndex >= (previousIndex ?? _currentIndex) ? 1 : -1);
    final forward =
        CurvedAnimation(parent: _controller, curve: kAppMotionCurve);
    final incoming = Tween<Offset>(
      begin: _beginOffset(direction),
      end: Offset.zero,
    ).animate(forward);
    final outgoing = Tween<Offset>(
      begin: Offset.zero,
      end: _beginOffset(-direction),
    ).animate(forward);

    return ScrollConfiguration(
      behavior: const _AppScrollBehavior(),
      child: Listener(
        onPointerSignal: _handlePointerSignal,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragEnd: widget.scrollDirection == Axis.horizontal
              ? (details) {
                  final velocity = details.primaryVelocity ?? 0;
                  if (velocity.abs() < 180 || _isAnimating) return;
                  final nextIndex = (_currentIndex + (velocity < 0 ? 1 : -1))
                      .clamp(0, widget.pageIds.length - 1);
                  if (nextIndex == _currentIndex) return;
                  unawaited(_startTransition(nextIndex));
                }
              : null,
          onVerticalDragEnd: widget.scrollDirection == Axis.vertical
              ? (details) {
                  final velocity = details.primaryVelocity ?? 0;
                  if (velocity.abs() < 180 || _isAnimating) return;
                  final nextIndex = (_currentIndex + (velocity < 0 ? 1 : -1))
                      .clamp(0, widget.pageIds.length - 1);
                  if (nextIndex == _currentIndex) return;
                  unawaited(_startTransition(nextIndex));
                }
              : null,
          child: Stack(
            fit: StackFit.expand,
            children: List<Widget>.generate(widget.pageIds.length, (index) {
              final pageId = widget.pageIds[index];
              final page = RepaintBoundary(
                key: PageStorageKey<String>('shell_$pageId'),
                child: widget.pageBuilder(context, index),
              );
              final isCurrent = index == _currentIndex;
              final isPrevious =
                  previousIndex != null && index == previousIndex;
              final isVisible = isCurrent || isPrevious;

              final position = !isVisible
                  ? const AlwaysStoppedAnimation(Offset.zero)
                  : (isPrevious && targetIndex != null)
                      ? outgoing
                      : (isPrevious
                          ? const AlwaysStoppedAnimation(Offset.zero)
                          : (previousIndex != null
                              ? incoming
                              : const AlwaysStoppedAnimation(Offset.zero)));

              return Offstage(
                offstage: !isVisible,
                child: TickerMode(
                  enabled: isVisible,
                  child: SlideTransition(
                    position: position,
                    child: IgnorePointer(
                      ignoring: !isCurrent,
                      child: page,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
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
  String _currentPageId = 'timetable';
  String? _targetPageId;
  final Map<String, Widget> _pageCache = {};
  final TimetableController _timetableController = TimetableController();
  final Set<String> _readyPageIds = {};
  LocaleProvider? _localeProvider;

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
    if (v.contains(':\\') || v.startsWith('/')) return v;
    return '${widget.session.dataDir}/$v';
  }

  DecorationImage? _getAvatarImage(String path) {
    final resolved = _resolveAvatarUrlOrPath(path) ?? '';
    return AvatarImageProvider.getDecorationImage(resolved);
  }

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
    if (id == _currentPageId && _targetPageId == null) return;
    setState(() {
      _targetPageId = id;
    });
  }

  @override
  void initState() {
    super.initState();
    widget.session.addListener(_onSessionChanged);
    _localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    _localeProvider?.addListener(_onLocaleChanged);

    // Start background sync
    IncrementalSync.startSync(context, () {
      if (mounted) setState(() {});
    });
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
      'schedule' =>
        SchedulePage(session: widget.session, onReady: () => _onPageReady(id)),
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
      'qrcode' => QrCodePage(session: widget.session),
      'weblinks' => WeblinksPage(session: widget.session),
      'notifications' => NotificationsPage(session: widget.session),
      _ => TimetablePage(
          session: widget.session,
          onLogout: widget.onLogout,
          controller: _timetableController,
          onReady: () => _onPageReady(id)),
    };
    _pageCache[id] = w;
    return w;
  }

  List<({String id, String label, IconData icon})> _availablePageOptions(
      LocaleProvider loc) {
    final out = <({String id, String label, IconData icon})>[
      (
        id: 'timetable',
        label: loc.t('周课表', 'Timetable'),
        icon: Icons.calendar_month
      ),
      (id: 'schedule', label: loc.t('日程表', 'Schedule'), icon: Icons.schedule),
      (
        id: 'todo',
        label: loc.t('待办', 'Todos'),
        icon: Icons.checklist_rtl_rounded
      ),
      (
        id: 'contact',
        label: loc.t('通讯录', 'Contacts'),
        icon: Icons.contact_page_rounded
      ),
      (
        id: 'qrcode',
        label: loc.t('二维码', 'QR Code'),
        icon: Icons.qr_code_2_rounded
      ),
      (
        id: 'weblinks',
        label: loc.t('常用网站', 'Web Links'),
        icon: Icons.language_rounded
      ),
      (
        id: 'notifications',
        label: loc.t('通知', 'Notifications'),
        icon: Icons.notifications_rounded
      ),
    ];
    if (widget.session.canTakeAttendance) {
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

  List<({String id, String label, IconData icon})>
      _availablePageOptionsNoLoc() {
    final loc = Provider.of<LocaleProvider>(context, listen: false);
    return _availablePageOptions(loc);
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
          icon: const Icon(Icons.schedule_outlined),
          selectedIcon: const Icon(Icons.schedule),
          label: Text(loc.t('日程表', 'Schedule')),
        ),
        id: 'schedule',
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
      (
        destination: NavigationRailDestination(
          icon: const Icon(Icons.qr_code_2_outlined),
          selectedIcon: const Icon(Icons.qr_code_2_rounded),
          label: Text(loc.t('二维码', 'QR Code')),
        ),
        id: 'qrcode',
      ),
      (
        destination: NavigationRailDestination(
          icon: const Icon(Icons.language_outlined),
          selectedIcon: const Icon(Icons.language_rounded),
          label: Text(loc.t('常用网站', 'Web Links')),
        ),
        id: 'weblinks',
      ),
      (
        destination: NavigationRailDestination(
          icon: const Icon(Icons.notifications_outlined),
          selectedIcon: const Icon(Icons.notifications_rounded),
          label: Text(loc.t('通知', 'Notifications')),
        ),
        id: 'notifications',
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
    final selectedPageId = pageIds.contains(_targetPageId)
        ? _targetPageId!
        : (pageIds.contains(_currentPageId) ? _currentPageId : pageIds.first);
    final actualActiveIdx = pageIds.isEmpty
        ? 0
        : pageIds.indexOf(selectedPageId).clamp(0, pageIds.length - 1);

    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Row(
        children: [
          // Custom Desktop Sidebar
          AnimatedContainer(
            duration: kAppRouteTransitionDuration,
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
                  Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: AnimatedContainer(
                            duration: kAppRouteTransitionDuration,
                            curve: Curves.easeInOutCubic,
                            width: _isExtended ? 160 : 0,
                            child: ClipRect(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 200),
                                  opacity: _isExtended ? 1.0 : 0.0,
                                  child: OverflowBox(
                                    maxWidth: double.infinity,
                                    alignment: Alignment.centerLeft,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          child: Image.asset(
                                            'assets/images/logo.png',
                                            width: 24,
                                            height: 24,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text('LBG System',
                                            style: tt.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (!_isExtended)
                          InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: () =>
                                setState(() => _isExtended = !_isExtended),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.asset(
                                'assets/images/logo.png',
                                width: 24,
                                height: 24,
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                        else
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            transformAlignment: Alignment.center,
                            transform:
                                Matrix4.rotationZ(_isExtended ? 0 : 3.1415926),
                            child: IconButton(
                              icon: const Icon(Icons.menu_open),
                              onPressed: () =>
                                  setState(() => _isExtended = !_isExtended),
                            ),
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
                          AppSlidePageRoute(
                            builder: (_) =>
                                ProfilePage(session: widget.session),
                          ),
                        );
                      },
                      child: AnimatedContainer(
                        duration: kAppRouteTransitionDuration,
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
                                      color: Colors.grey.shade200,
                                      width: 1,
                                    ),
                                    image: _getAvatarImage(
                                      widget.session.profile.avatar,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: (_getAvatarImage(
                                              widget.session.profile.avatar) ==
                                          null)
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
                                    duration: kAppRouteTransitionDuration,
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
                        final isSelected = actualActiveIdx == index;
                        final dest = items[index].destination;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Bounceable(
                            onTap: () {
                              final id = items[index].id;
                              _changePage(id);
                            },
                            child: Container(
                              height: 56,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? cs.secondaryContainer
                                        .withValues(alpha: 214)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      child: AnimatedAlign(
                                        duration: kAppRouteTransitionDuration,
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
                                                      ? cs.onSecondaryContainer
                                                      : cs.onSurfaceVariant,
                                                ),
                                              ),
                                              child: isSelected
                                                  ? dest.selectedIcon
                                                  : dest.icon,
                                            ),
                                            AnimatedContainer(
                                              duration:
                                                  kAppRouteTransitionDuration,
                                              curve: Curves.easeInOutCubic,
                                              width:
                                                  0, // removed width: _isExtended ? 12 : 0, as it's fixed below
                                            ),
                                            if (_isExtended)
                                              const SizedBox(width: 12),
                                            AnimatedContainer(
                                              duration:
                                                  kAppRouteTransitionDuration,
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
                                                            ? cs.onSecondaryContainer
                                                            : cs.onSurfaceVariant,
                                                        fontWeight: isSelected
                                                            ? FontWeight.bold
                                                            : FontWeight.w600,
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
                                  if (isSelected && _isExtended)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 14),
                                      child: Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 14,
                                        color: cs.onSecondaryContainer,
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
                          AppScalePageRoute(
                            builder: (_) => _NavSettingsPage(
                              optionsBuilder: _availablePageOptionsNoLoc,
                              initialOrder: const [],
                              onImportWakeUp: () async {
                                if (_timetableController.importWakeUp != null) {
                                  await _timetableController.importWakeUp!();
                                } else {
                                  final loc = Provider.of<LocaleProvider>(
                                      context,
                                      listen: false);
                                  showExpressiveSnackBar(
                                      context,
                                      loc.t('请先切换到课表页面',
                                          'Please switch to Timetable page first'));
                                }
                              },
                              onClearTimetable:
                                  _timetableController.clearTimetable,
                              isTeacher: widget.session.isTeacher,
                              session: widget.session,
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
                                duration: kAppRouteTransitionDuration,
                                curve: Curves.easeInOutCubic,
                                width: _isExtended ? 16 : 0,
                              ),
                              Icon(Icons.settings, color: cs.onSurfaceVariant),
                              AnimatedContainer(
                                duration: kAppRouteTransitionDuration,
                                curve: Curves.easeInOutCubic,
                                width: _isExtended ? 12 : 0,
                              ),
                              AnimatedContainer(
                                duration: kAppRouteTransitionDuration,
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
                                duration: kAppRouteTransitionDuration,
                                curve: Curves.easeInOutCubic,
                                width: _isExtended ? 16 : 0,
                              ),
                              Icon(Icons.logout, color: cs.error),
                              AnimatedContainer(
                                duration: kAppRouteTransitionDuration,
                                curve: Curves.easeInOutCubic,
                                width: _isExtended ? 12 : 0,
                              ),
                              AnimatedContainer(
                                duration: kAppRouteTransitionDuration,
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
              color: cs.surface,
              child: _PagedShellViewport(
                scrollDirection: Axis.vertical,
                pageIds: pageIds,
                activeIndex: actualActiveIdx,
                onPageChanged: (id) {
                  if (!mounted) return;
                  setState(() {
                    _currentPageId = id;
                    _targetPageId = null;
                  });
                },
                pageBuilder: (context, index) => _getPage(pageIds[index]),
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
  String _currentPageId = 'timetable';
  String? _targetPageId;
  List<String>? _bottomNavIds;
  bool _navPrefsLoaded = false;
  final Map<String, Widget> _pageCache = {};
  final TimetableController _timetableController = TimetableController();
  final Set<String> _readyPageIds = {};
  LocaleProvider? _localeProvider;
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
    if (id == _currentPageId && _targetPageId == null) return;
    setState(() {
      _targetPageId = id;
    });
  }

  @override
  void initState() {
    super.initState();
    widget.session.addListener(_onSessionChanged);
    _localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    _localeProvider?.addListener(_onLocaleChanged);
    _loadNavPrefs();

    // Start background sync
    IncrementalSync.startSync(context, () {
      if (mounted) setState(() {});
    });
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
      (id: 'schedule', label: loc.t('日程表', 'Schedule'), icon: Icons.schedule),
      (
        id: 'todo',
        label: loc.t('待办', 'Todos'),
        icon: Icons.checklist_rtl_rounded
      ),
      (
        id: 'contact',
        label: loc.t('通讯录', 'Contacts'),
        icon: Icons.contact_page_rounded
      ),
      (
        id: 'qrcode',
        label: loc.t('二维码', 'QR Code'),
        icon: Icons.qr_code_2_rounded
      ),
      (
        id: 'weblinks',
        label: loc.t('常用网站', 'Web Links'),
        icon: Icons.language_rounded
      ),
      (
        id: 'notifications',
        label: loc.t('通知', 'Notifications'),
        icon: Icons.notifications_rounded
      ),
    ];
    if (widget.session.canTakeAttendance) {
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

  List<({String id, String label, IconData icon})>
      _availablePageOptionsNoLoc() {
    final loc = Provider.of<LocaleProvider>(context, listen: false);
    return _availablePageOptions(loc);
  }

  Future<void> _openNavSettings() async {
    final optionIds =
        _availablePageOptionsNoLoc().map((e) => e.id).toList(growable: false);
    final current = (_bottomNavIds ?? _defaultBottomNav())
        .where((id) => optionIds.contains(id))
        .toList();
    final normalizedCurrent = <String>[...current];
    for (final id in optionIds) {
      if (!normalizedCurrent.contains(id)) normalizedCurrent.add(id);
    }
    final res = await Navigator.of(context).push<List<String>>(
      AppScalePageRoute(
        builder: (_) => _NavSettingsPage(
          optionsBuilder: _availablePageOptionsNoLoc,
          initialOrder: normalizedCurrent,
          onImportWakeUp: () async {
            if (_timetableController.importWakeUp != null) {
              await _timetableController.importWakeUp!();
            } else {
              final loc = Provider.of<LocaleProvider>(context, listen: false);
              showExpressiveSnackBar(context,
                  loc.t('请先切换到课表页面', 'Please switch to Timetable page first'));
            }
          },
          onClearTimetable: _timetableController.clearTimetable,
          isTeacher: widget.session.isTeacher,
          session: widget.session,
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
      'schedule' => SchedulePage(
          session: widget.session,
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
      'qrcode' => QrCodePage(session: widget.session),
      'weblinks' => WeblinksPage(session: widget.session),
      'notifications' => NotificationsPage(session: widget.session),
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
    final pageIds = _availablePageOptions(loc).map((e) => e.id).toList();
    if (pageIds.isEmpty) {
      return const SizedBox.shrink();
    }
    final resolvedActivePageId = pageIds.contains(_targetPageId)
        ? _targetPageId!
        : (pageIds.contains(_currentPageId) ? _currentPageId : pageIds.first);
    final actualActiveIdx = pageIds.isEmpty
        ? 0
        : pageIds.indexOf(resolvedActivePageId).clamp(0, pageIds.length - 1);
    final navIndex = barItems.indexWhere((e) => e.id == resolvedActivePageId);

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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (resolvedActivePageId != 'timetable') {
          _changePage('timetable');
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
        backgroundColor: Theme.of(context).colorScheme.surface,
        drawerEdgeDragWidth: 100, // Make it easier to swipe from edge
        drawerScrimColor: Colors.black.withValues(alpha: 0.3),
        drawer: Drawer(
          child: HomeDrawer(
            session: widget.session,
            activePage: resolvedActivePageId,
            hiddenPageIds: _navPrefsLoaded
                ? _navItems().map((e) => e.id).toSet()
                : const <String>{},
            onNavigate: (pageId) {
              if (pageId == 'profile') {
                Navigator.of(context).push(
                  AppSlidePageRoute(
                    builder: (_) => ProfilePage(session: widget.session),
                  ),
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
        ),
        body: Builder(
          builder: (context) {
            return _PagedShellViewport(
              scrollDirection: Axis.horizontal,
              pageIds: pageIds,
              activeIndex: actualActiveIdx,
              onPageChanged: (id) {
                if (!mounted) return;
                setState(() {
                  _currentPageId = id;
                  _targetPageId = null;
                });
              },
              pageBuilder: (context, index) => _pageForId(pageIds[index]),
            );
          },
        ),
        bottomNavigationBar: Builder(
          builder: (context) {
            final key = ValueKey(barItems.map((e) => e.id).join('|'));
            return AnimatedSwitcher(
              duration: kAppRouteTransitionDuration,
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
  final List<({String id, String label, IconData icon})> Function()
      optionsBuilder;
  final List<String> initialOrder;
  final Future<void> Function()? onImportWakeUp;
  final Future<void> Function()? onClearTimetable;
  final bool isTeacher;
  final Session session;

  const _NavSettingsPage({
    required this.optionsBuilder,
    required this.initialOrder,
    required this.onImportWakeUp,
    required this.onClearTimetable,
    required this.isTeacher,
    required this.session,
  });

  @override
  State<_NavSettingsPage> createState() => _NavSettingsPageState();
}

class _NavSettingsPageState extends State<_NavSettingsPage> {
  late List<String> _order;
  late final TextEditingController _cloudUrlController;

  @override
  void initState() {
    super.initState();
    _cloudUrlController =
        TextEditingController(text: ApiConfig.instance.cloudIp.trim());
    // We don't have loc in initState, so we can't get options yet.
    // Wait, initialOrder handles that.
    _order = widget.initialOrder.toList();
  }

  @override
  void dispose() {
    _cloudUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDesktop =
        Platform.isWindows || Platform.isLinux || Platform.isMacOS;
    final localeProvider = Provider.of<LocaleProvider>(context);
    final currentOptions = widget.optionsBuilder();

    final optionIds = currentOptions.map((e) => e.id).toList(growable: false);
    final validOrder = _order.where((id) => optionIds.contains(id)).toList();
    for (final id in optionIds) {
      if (!validOrder.contains(id)) validOrder.add(id);
    }
    _order = validOrder;

    final optionsById = {
      for (final o in currentOptions) o.id: o,
    };
    final orderedOpts = _order
        .map((id) => optionsById[id])
        .whereType<({String id, String label, IconData icon})>()
        .toList(growable: false);

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
                  final isDark =
                      Theme.of(context).brightness == Brightness.dark;
                  return AnimatedBuilder(
                    animation: animation,
                    builder: (context, child) {
                      return Material(
                        elevation: 0,
                        color: isDark
                            ? const Color(0xFF2C2C2C)
                            : const Color(0xFFF5F5F5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide.none,
                        ),
                        child: child,
                      );
                    },
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
                      borderRadius: BorderRadius.circular(8),
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
            const SizedBox(height: 16),
            Text(
              localeProvider.t('云端配置', 'Cloud Configuration'),
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
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    title: Text(localeProvider.t('使用云端数据', 'Use Cloud Data')),
                    subtitle: Text(localeProvider.t('开启后将连接到指定的云端服务器',
                        'Connect to a remote server when enabled')),
                    value: ApiConfig.instance.useCloud,
                    onChanged: (bool value) async {
                      ApiConfig.instance.useCloud = value;
                      await ApiConfig.instance.save(widget.session.dataDir);
                      if (value) {
                        widget.session.startRealtimeSync();
                      } else {
                        widget.session.stopRealtimeSync();
                      }
                      setState(() {});
                    },
                  ),
                  if (ApiConfig.instance.useCloud) ...[
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: TextField(
                        controller: _cloudUrlController,
                        keyboardType: TextInputType.url,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          hintText: 'https://192.168.1.x:8080',
                          helperText: localeProvider.t(
                            '示例：`https://192.168.1.x:8080`',
                            'Example: `https://192.168.1.x:8080`',
                          ),
                          prefixIcon: const Icon(Icons.cloud_outlined),
                        ),
                        onChanged: (val) {
                          ApiConfig.instance.cloudIp = val.trim();
                        },
                        onSubmitted: (val) async {
                          ApiConfig.instance.cloudIp = val.trim();
                          await ApiConfig.instance.save(widget.session.dataDir);
                          widget.session.startRealtimeSync();
                          if (mounted) {
                            setState(() {});
                          }
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          TextButton(
                            style: ButtonStyle(
                              backgroundColor:
                                  WidgetStatePropertyAll(cs.primary),
                              foregroundColor:
                                  WidgetStatePropertyAll(cs.onPrimary),
                              elevation: const WidgetStatePropertyAll(0),
                              overlayColor:
                                  WidgetStateProperty.resolveWith((states) {
                                if (states.contains(WidgetState.pressed)) {
                                  return cs.onPrimary.withValues(alpha: 0.3);
                                }
                                return Colors.transparent;
                              }),
                            ),
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              ApiConfig.instance.cloudIp =
                                  _cloudUrlController.text.trim();
                              await ApiConfig.instance
                                  .save(widget.session.dataDir);
                              widget.session.startRealtimeSync();
                              if (!mounted) return;
                              setState(() {});
                              messenger.showSnackBar(SnackBar(
                                  content: Text(localeProvider.t(
                                      '已保存云端地址', 'Cloud URL saved'))));
                              Future.delayed(const Duration(seconds: 1), () {
                                if (mounted)
                                  Navigator.of(context)
                                      .maybePop(_order.toList());
                              });
                            },
                            child: Text(localeProvider.t('保存云端地址', 'Save URL')),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () async {
                              Future<void> connect() async {
                                final messenger = ScaffoldMessenger.of(context);
                                ApiConfig.instance.cloudIp =
                                    _cloudUrlController.text.trim();
                                await ApiConfig.instance
                                    .save(widget.session.dataDir);
                                widget.session.startRealtimeSync();
                                if (!mounted) return;
                                setState(() {});
                                final res = await ApiConfig.instance
                                    .get('/api/system/init?seed=false');
                                if (!context.mounted) return;
                                if (res['ok'] == true) {
                                  messenger.showSnackBar(SnackBar(
                                    content: Text(localeProvider.t(
                                        '链接成功', 'Connection successful')),
                                    backgroundColor: Colors.green,
                                  ));
                                  // Close settings and trigger logout/return to login
                                  Navigator.of(context)
                                      .maybePop(_order.toList());
                                  // Wait for the animation to finish then logout to go back to login screen
                                  Future.delayed(
                                      const Duration(milliseconds: 300), () {
                                    if (mounted) {
                                      // Call logout callback if possible, or just pushReplacement
                                      // Since we are in NavSettingsPage, we can't directly call onLogout from shell.
                                      // Wait, we have access to shell's context if we use root navigator?
                                      // Actually, we can just clear token and pushReplacement to LoginPage
                                      // or better, if we have a way to notify ShellPage.
                                      // The easiest way is to pushAndRemoveUntil.
                                      Navigator.of(context, rootNavigator: true)
                                          .pushAndRemoveUntil(
                                        MaterialPageRoute(
                                          builder: (ctx) => LoginPage(
                                            dataDir: widget.session.dataDir,
                                            cliPath:
                                                widget.session.cli?.exePath ??
                                                    '',
                                            nativeLibDir: widget
                                                .session.features.nativeLibDir,
                                            onLoggedIn: (newSession) {
                                              Navigator.of(ctx).pushReplacement(
                                                MaterialPageRoute(
                                                  builder: (_) => ShellPage(
                                                    session: newSession,
                                                    onLogout: () {
                                                      // ...
                                                    },
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        (route) => false,
                                      );
                                    }
                                  });
                                } else {
                                  final code = res['error']?['code'] ?? '';
                                  final msg = res['error']?['message'] ?? '';
                                  if (code == 'unauthorized' ||
                                      msg.contains('token') ||
                                      msg.contains('失效')) {
                                    ApiConfig.instance.token = '';
                                    await ApiConfig.instance
                                        .save(widget.session.dataDir);
                                    if (!context.mounted) return;
                                    await Navigator.of(context)
                                        .push(MaterialPageRoute(
                                            builder: (ctx) => LoginPage(
                                                  dataDir:
                                                      widget.session.dataDir,
                                                  cliPath: widget.session.cli
                                                          ?.exePath ??
                                                      '',
                                                  nativeLibDir: widget.session
                                                      .features.nativeLibDir,
                                                  onLoggedIn: (newSession) {
                                                    Navigator.of(ctx).pop();
                                                  },
                                                )));
                                    if (mounted) {
                                      await connect();
                                    }
                                  } else {
                                    messenger.showSnackBar(SnackBar(
                                      content: Text(
                                          '${localeProvider.t('链接失败', 'Connection failed')}: $msg'),
                                      backgroundColor: Colors.red,
                                    ));
                                  }
                                }
                              }

                              await connect();
                            },
                            child:
                                Text(localeProvider.t('立即链接', 'Connect Now')),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
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
