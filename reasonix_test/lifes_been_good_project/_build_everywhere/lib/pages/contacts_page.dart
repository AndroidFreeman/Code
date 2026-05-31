import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:lpinyin/lpinyin.dart';

import '../models/profile.dart';
import '../services/local_profiles.dart';
import '../state/session.dart';
import '../main.dart';
import 'profile_page.dart';
import '../widgets/expressive_ui.dart';

class ContactsPage extends StatefulWidget {
  final Session session;
  final VoidCallback? onReady;

  const ContactsPage({super.key, required this.session, this.onReady});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  String _status = '';
  List<Profile> _profiles = const [];
  List<Map<String, dynamic>> _myClasses = [];
  Map<String, String> _classNameByCode = const {};
  bool _dataReady = false;
  Set<String> _myPinnedProfileIds = {};
  StreamSubscription<SessionDataChange>? _dataChangeSub;
  late TabController _tabController;

  bool _showFabMenu = false;

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

  DecorationImage? _getAvatarProvider(String path) {
    return AvatarImageProvider.getDecorationImage(path);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _dataChangeSub = widget.session
        .watchDataChanges({'profiles', 'contacts', 'classes'}).listen((event) {
      if (mounted) {
        unawaited(_refresh(silent: true, forceNetwork: event.remote));
      }
    });
    _refresh();
  }

  @override
  void dispose() {
    _dataChangeSub?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<Set<String>> _loadPinnedContacts() async {
    final res = await widget.session.features
        .csvOp(action: 'read', file: 'pinned_contacts.csv');
    if (res['ok'] != true) return {};
    final items = ((res['data'] ?? const {})['items'] as List?) ?? const [];
    final rows = items.map((e) => (e as Map).cast<String, String>()).toList();

    final ownerId = widget.session.profile.id.trim();
    final out = <String>{};
    for (final r in rows) {
      final owner = (r['owner_profile_id'] ?? '').trim();
      final contactPid = (r['contact_profile_id'] ?? '').trim();
      if (owner == ownerId && contactPid.isNotEmpty) out.add(contactPid);
    }
    return out;
  }

  Future<void> _addPin(Profile p) async {
    final ownerId = widget.session.profile.id.trim();
    final contactId = p.id.trim();
    if (ownerId.isEmpty || contactId.isEmpty) return;

    final res = await widget.session.features
        .csvOp(action: 'read', file: 'pinned_contacts.csv');
    final items = ((res['data'] ?? const {})['items'] as List?) ?? const [];
    final rows = items.map((e) => (e as Map).cast<String, String>()).toList();

    final already = rows.any((r) =>
        (r['owner_profile_id'] ?? '').trim() == ownerId &&
        (r['contact_profile_id'] ?? '').trim() == contactId);

    if (!already) {
      rows.add({
        'id': 'pin_${DateTime.now().millisecondsSinceEpoch}',
        'owner_profile_id': ownerId,
        'contact_profile_id': contactId,
      });
      await widget.session.features.csvOp(
          action: 'write',
          file: 'pinned_contacts.csv',
          headers: ['id', 'owner_profile_id', 'contact_profile_id'],
          rows: rows);

      if (!mounted) return;
      setState(() {
        _myPinnedProfileIds = {..._myPinnedProfileIds, contactId};
        _status = ''; // Removed 'Pinned' text
      });
    }
  }

  Future<void> _removePin(Profile p) async {
    final ownerId = widget.session.profile.id.trim();
    final contactId = p.id.trim();
    if (ownerId.isEmpty || contactId.isEmpty) return;

    final res = await widget.session.features
        .csvOp(action: 'read', file: 'pinned_contacts.csv');
    final items = ((res['data'] ?? const {})['items'] as List?) ?? const [];
    final rows = items.map((e) => (e as Map).cast<String, String>()).toList();

    rows.removeWhere((r) =>
        (r['owner_profile_id'] ?? '').trim() == ownerId &&
        (r['contact_profile_id'] ?? '').trim() == contactId);

    await widget.session.features.csvOp(
        action: 'write',
        file: 'pinned_contacts.csv',
        headers: ['id', 'owner_profile_id', 'contact_profile_id'],
        rows: rows);

    if (!mounted) return;
    final next = {..._myPinnedProfileIds};
    next.remove(contactId);
    setState(() {
      _myPinnedProfileIds = next;
      _status = ''; // Removed 'Unpinned' text
    });
  }

  Future<void> _togglePin(Profile p) async {
    final contactId = p.id.trim();
    if (_myPinnedProfileIds.contains(contactId)) {
      await _removePin(p);
    } else {
      await _addPin(p);
    }

    // Re-sort profiles locally for immediate feedback with animation
    final nextProfiles = List<Profile>.from(_profiles);
    nextProfiles.sort((a, b) {
      final aPinned = _myPinnedProfileIds.contains(a.id);
      final bPinned = _myPinnedProfileIds.contains(b.id);
      if (aPinned && !bPinned) return -1;
      if (!aPinned && bPinned) return 1;

      if (a.role == 'teacher' && b.role != 'teacher') return -1;
      if (a.role != 'teacher' && b.role == 'teacher') return 1;

      return a.displayWithRealName.compareTo(b.displayWithRealName);
    });

    setState(() {
      _profiles = nextProfiles;
    });
  }

  Future<void> _openAddContactPicker() async {
    final loc = Provider.of<LocaleProvider>(context, listen: false);
    final ownerId = widget.session.profile.id.trim();
    if (ownerId.isEmpty) return;

    final noCtrl = TextEditingController();

    final selected = await showDialog<Profile>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(loc.t('添加联系人', 'Add Contact')),
          content: TextField(
            controller: noCtrl,
            decoration: InputDecoration(
              hintText: loc.t('请输入学号或工号', 'Enter Student/Staff No.'),
              prefixIcon: const Icon(Icons.badge_outlined),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(loc.t('取消', 'Cancel')),
            ),
            FilledButton(
              onPressed: () {
                final v = noCtrl.text.trim();
                if (v.isEmpty) return;
                final p = _profiles.firstWhere(
                  (p) => p.staffNo == v || p.studentNo == v,
                  orElse: () => const Profile(
                      id: '',
                      role: '',
                      staffNo: '',
                      studentNo: '',
                      displayName: '',
                      orgCode: '',
                      classCode: ''),
                );
                if (p.id.isNotEmpty && p.id != ownerId) {
                  Navigator.of(ctx).pop(p);
                } else if (p.id == ownerId) {
                  showExpressiveSnackBar(
                    ctx,
                    loc.t('不能添加自己', 'Cannot add yourself'),
                  );
                } else {
                  showExpressiveSnackBar(
                    ctx,
                    loc.t('未找到该用户', 'User not found'),
                  );
                }
              },
              child: Text(loc.t('添加', 'Add')),
            ),
          ],
        );
      },
    );
    noCtrl.dispose();
    if (selected == null) return;
    await _addPin(selected);
  }

  String _lastSignature = '';
  DateTime? _lastSyncTime;

  Future<void> _refresh(
      {bool silent = false, bool forceNetwork = false}) async {
    try {
      _myPinnedProfileIds = await _loadPinnedContacts();
      List<String> classes = [];
      if (widget.session.isTeacher) {
        classes = await LocalProfiles.getTeacherClasses(
          widget.session.dataDir,
          widget.session.profile.id,
        );
      } else {
        classes = [widget.session.profile.classCode.trim()];
      }

      final allClassesMapList =
          await LocalProfiles.getAllClassesWithNames(widget.session.dataDir);
      final classNameByCode = {
        for (final row in allClassesMapList)
          (row['id'] ?? '').trim(): ((row['name'] ?? '').trim().isEmpty
              ? (row['id'] ?? '').trim()
              : (row['name'] ?? '').trim()),
      };

      // Fetch all profiles to get detailed info for everyone
      Map<String, dynamic> profilesRes;
      if (!forceNetwork && widget.session.preloadedData['profiles'] != null) {
        profilesRes = {
          'ok': true,
          'data': widget.session.preloadedData['profiles']
        };
      } else if (await widget.session.features.hasFeature('profiles_list')) {
        profilesRes =
            await widget.session.features.listProfiles(classCodes: classes);
        if (profilesRes['ok'] == true) {
          widget.session.preloadedData['profiles'] = profilesRes['data'];
        }
      } else {
        final cli = widget.session.cli;
        if (cli != null) {
          profilesRes =
              await cli.call('profiles.list', {'class_codes': classes});
          if (profilesRes['ok'] == true) {
            widget.session.preloadedData['profiles'] = profilesRes['data'];
          }
        } else {
          profilesRes = {'ok': false};
        }
      }

      if (profilesRes['ok'] != true) {
        if (!mounted) return;
        final loc = Provider.of<LocaleProvider>(context, listen: false);
        setState(() {
          _loading = false;
          _status = loc.t('获取个人资料失败', 'Failed to load profiles');
        });
        widget.onReady?.call();
        return;
      }

      List profilesRaw = [];
      final profilesData = profilesRes['data'];
      if (profilesData is Map && profilesData.containsKey('items')) {
        profilesRaw = profilesData['items'] as List;
      } else if (profilesData is List) {
        profilesRaw = profilesData;
      }

      final filteredProfiles = <Profile>[];
      final List<Map<String, dynamic>> myClasses = [];

      for (final p in profilesRaw) {
        final map = (p as Map).cast<String, dynamic>();
        final profile = Profile.fromJson(map);

        // If teacher, check if they teach any of the target classes
        if (profile.role == 'teacher') {
          final teacherClasses =
              profile.classCode.split('|').map((e) => e.trim());
          if (teacherClasses.any((c) => classes.contains(c))) {
            filteredProfiles.add(profile);
          }
        } else {
          // If student, check if they are in the target classes
          // OR if they are pinned by me
          if (classes.contains(profile.classCode.trim()) ||
              _myPinnedProfileIds.contains(profile.id)) {
            filteredProfiles.add(profile);
          }
        }
      }

      // Build class stats for "My Class" tab
      for (final cCode in classes) {
        if (cCode.isEmpty) continue;
        final cName = classNameByCode[cCode] ?? cCode;
        final studentsInClass = profilesRaw.where((p) {
          final map = (p as Map).cast<String, dynamic>();
          return map['role'] != 'teacher' && (map['class_code'] ?? '') == cCode;
        }).toList();

        final headTeacher = profilesRaw.firstWhere((p) {
          final map = (p as Map).cast<String, dynamic>();
          final tClasses = (map['class_code'] ?? '').toString().split('|');
          return map['role'] == 'teacher' && tClasses.contains(cCode);
        }, orElse: () => null);

        myClasses.add({
          'code': cCode,
          'name': cName,
          'count': studentsInClass.length,
          'headTeacher': headTeacher != null
              ? Profile.fromJson((headTeacher as Map).cast<String, dynamic>())
                  .displayWithRealName
              : 'Unknown',
        });
      }

      final sessionProfile = widget.session.profile;
      final sessionIndex = filteredProfiles
          .indexWhere((profile) => profile.id == sessionProfile.id);
      if (sessionIndex >= 0) {
        filteredProfiles[sessionIndex] = sessionProfile;
      }

      // Sort: Pinned first, then Teachers first, then by pinyin name
      filteredProfiles.sort((a, b) {
        final aPinned = _myPinnedProfileIds.contains(a.id);
        final bPinned = _myPinnedProfileIds.contains(b.id);
        if (aPinned && !bPinned) return -1;
        if (!aPinned && bPinned) return 1;

        if (a.role == 'teacher' && b.role != 'teacher') return -1;
        if (a.role != 'teacher' && b.role == 'teacher') return 1;

        // Sort by pinyin of display name
        final pyA =
            PinyinHelper.getPinyinE(a.displayWithRealName).toLowerCase();
        final pyB =
            PinyinHelper.getPinyinE(b.displayWithRealName).toLowerCase();
        return pyA.compareTo(pyB);
      });

      if (!mounted) return;

      final signature = filteredProfiles
              .map((e) =>
                  '${e.id}:${e.displayWithRealName}:${e.signature}:${e.role}:${e.avatar}')
              .join('|') +
          '||' +
          _myPinnedProfileIds.join('|') +
          '||' +
          myClasses.map((e) => '${e['code']}:${e['count']}').join('|');

      if (signature == _lastSignature && _dataReady) {
        setState(() {
          _loading = false;
          if (forceNetwork) _lastSyncTime = DateTime.now();
        });
        widget.onReady?.call();
        return;
      }
      _lastSignature = signature;

      setState(() {
        _loading = false;
        _profiles = filteredProfiles;
        _myClasses = myClasses;
        _classNameByCode = classNameByCode;
        _dataReady = true;
        _lastSyncTime = DateTime.now();
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
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
        title: Text(loc.t('通讯录', 'Contacts')),
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                dividerColor: Colors.transparent,
                labelStyle:
                    tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                unselectedLabelStyle: tt.titleMedium,
                indicatorSize: TabBarIndicatorSize.label,
                tabs: [
                  Tab(text: loc.t('全部', 'All')),
                  Tab(text: loc.t('我的班级', 'My Class')),
                ],
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildContactsList(cs, tt, loc),
          _buildClassView(cs, tt, loc),
        ],
      ),
      floatingActionButton:
          _tabController.index == 0 ? _buildFab(context, loc) : null,
    );
  }

  Widget _buildFab(BuildContext context, LocaleProvider loc) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AnimatedOpacity(
          opacity: _showFabMenu ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          child: AnimatedScale(
            scale: _showFabMenu ? 1.0 : 0.8,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton.extended(
                  heroTag: 'fab_add_contact',
                  onPressed: _showFabMenu
                      ? () {
                          setState(() => _showFabMenu = false);
                          _openAddContactPicker();
                        }
                      : null,
                  icon: const Icon(Icons.person_add),
                  label: Text(loc.t('添加联系人', 'Add Contact')),
                  tooltip: loc.t('添加通讯录', 'Add Contact'),
                  elevation: 2,
                  backgroundColor:
                      Theme.of(context).colorScheme.secondaryContainer,
                  foregroundColor:
                      Theme.of(context).colorScheme.onSecondaryContainer,
                  shape: const StadiumBorder(),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.extended(
                  heroTag: 'fab_edit_profile',
                  onPressed: _showFabMenu
                      ? () {
                          setState(() => _showFabMenu = false);
                          Navigator.of(context).push(
                            AppSlidePageRoute(
                              builder: (_) =>
                                  ProfilePage(session: widget.session),
                            ),
                          );
                        }
                      : null,
                  icon: const Icon(Icons.edit),
                  label: Text(loc.t('修改信息', 'Edit Profile')),
                  tooltip: loc.t('更改个人信息', 'Edit Profile'),
                  elevation: 2,
                  backgroundColor:
                      Theme.of(context).colorScheme.tertiaryContainer,
                  foregroundColor:
                      Theme.of(context).colorScheme.onTertiaryContainer,
                  shape: const StadiumBorder(),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        FloatingActionButton(
          heroTag: 'fab_main',
          onPressed: () {
            setState(() {
              _showFabMenu = !_showFabMenu;
            });
          },
          elevation: 2,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
          shape: const CircleBorder(),
          tooltip: loc.t('菜单', 'Menu'),
          child: AnimatedRotation(
            turns: _showFabMenu ? 0.125 : 0, // Rotate 45 degrees
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Widget _buildContactsList(ColorScheme cs, TextTheme tt, LocaleProvider loc) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              if (_status.trim().isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.errorContainer,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Text(_status,
                      style: TextStyle(color: cs.onErrorContainer)),
                ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => _refresh(forceNetwork: true),
                  child: (_profiles.isEmpty && !_loading)
                      ? Center(
                          child: Text(loc.t('暂无联系人', 'No contacts'),
                              style: tt.bodyLarge))
                      : (_profiles.isEmpty && _loading)
                          ? const Center(child: CircularProgressIndicator())
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.only(top: 8, bottom: 80),
                              itemCount: _profiles.length,
                              itemBuilder: (context, index) {
                                final profile = _profiles[index];
                                final isTeacher = profile.role == 'teacher';
                                final resolvedAvatarPath =
                                    _resolveAvatarUrlOrPath(profile.avatar) ??
                                        '';
                                final avatar =
                                    _getAvatarProvider(resolvedAvatarPath);

                                return Container(
                                  key: ValueKey(profile.id),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: Bounceable(
                                    onTap: () => _showContactDetails(
                                        context, profile, cs, tt),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: cs.surface,
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(
                                            color: cs.outlineVariant
                                                .withValues(alpha: 0.5)),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 56,
                                            height: 56,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                color: Colors.grey.shade200,
                                                width: 1,
                                              ),
                                              image: avatar,
                                            ),
                                            alignment: Alignment.center,
                                            child: avatar == null
                                                ? Text(
                                                    profile.displayName
                                                            .isNotEmpty
                                                        ? profile.displayName
                                                            .substring(0, 1)
                                                        : '?',
                                                    style:
                                                        tt.titleLarge?.copyWith(
                                                      color: isTeacher
                                                          ? cs.onSecondaryContainer
                                                          : cs.onPrimaryContainer,
                                                    ),
                                                  )
                                                : null,
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                    profile.displayWithRealName,
                                                    style: tt.titleMedium),
                                                Text(
                                                    isTeacher
                                                        ? '${loc.t('工号', 'Staff ID')}: ${profile.staffNo}'
                                                        : '${loc.t('班级', 'Class')}: ${profile.classCode.isEmpty ? loc.t('未填写', 'Not set') : (_classNameByCode[profile.classCode.trim()] ?? profile.classCode)}',
                                                    style: tt.bodySmall?.copyWith(
                                                        color: cs
                                                            .onSurfaceVariant)),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () =>
                                                _togglePin(profile),
                                            icon: AnimatedSwitcher(
                                              duration: const Duration(
                                                  milliseconds: 300),
                                              transitionBuilder:
                                                  (child, animation) {
                                                return ScaleTransition(
                                                  scale: animation,
                                                  child: child,
                                                );
                                              },
                                              child: Icon(
                                                _myPinnedProfileIds
                                                        .contains(profile.id)
                                                    ? Icons.star_rounded
                                                    : Icons
                                                        .star_outline_rounded,
                                                key: ValueKey(
                                                    _myPinnedProfileIds
                                                        .contains(profile.id)),
                                              ),
                                            ),
                                            color: _myPinnedProfileIds
                                                    .contains(profile.id)
                                                ? cs.primary
                                                : cs.onSurfaceVariant
                                                    .withValues(alpha: 0.7),
                                            tooltip: _myPinnedProfileIds
                                                    .contains(profile.id)
                                                ? loc.t('取消置顶', 'Unpin')
                                                : loc.t('置顶', 'Pin'),
                                          ),
                                          Icon(Icons.chevron_right_rounded,
                                              color: cs.onSurfaceVariant
                                                  .withValues(alpha: 0.5)),
                                        ],
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
      ],
    );
  }

  Widget _buildClassView(ColorScheme cs, TextTheme tt, LocaleProvider loc) {
    if (_loading && _myClasses.isEmpty)
      return const Center(child: CircularProgressIndicator());
    if (_myClasses.isEmpty) {
      return Center(child: Text(loc.t('暂无班级信息', 'No class info')));
    }

    return RefreshIndicator(
      onRefresh: () => _refresh(forceNetwork: true),
      child: Column(
        children: [
          if (_lastSyncTime != null &&
              widget.session.cli == null) // Check if offline/local mode
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off,
                      size: 14,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
                  const SizedBox(width: 6),
                  Text(
                    '${loc.t('离线缓存 • 上次同步于', 'Offline cache • Last synced at')} ${_lastSyncTime!.hour.toString().padLeft(2, '0')}:${_lastSyncTime!.minute.toString().padLeft(2, '0')}',
                    style: tt.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _myClasses.length,
              itemBuilder: (context, index) {
                final cls = _myClasses[index];
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(
                        color: cs.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: InkWell(
                    onTap: () => _showClassMembers(cls),
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: cs.primaryContainer,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(Icons.group_outlined,
                                    color: cs.onPrimaryContainer, size: 28),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(cls['name'],
                                        style: tt.titleLarge?.copyWith(
                                            fontWeight: FontWeight.bold)),
                                    Text(
                                        '${cls['count']} ${loc.t('人', 'People')}',
                                        style: tt.bodyMedium?.copyWith(
                                            color: cs.onSurfaceVariant)),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded,
                                  color: cs.onSurfaceVariant),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(Icons.person_outline,
                                  size: 16, color: cs.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Text(
                                  '${loc.t('班主任', 'Head Teacher')}: ${cls['headTeacher']}',
                                  style: tt.bodySmall),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showClassMembers(Map<String, dynamic> cls) {
    final loc = Provider.of<LocaleProvider>(context, listen: false);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final classMembers =
        _profiles.where((p) => p.classCode.contains(cls['code'])).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: cs.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cls['name'],
                          style: tt.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      Text('${classMembers.length} ${loc.t('名成员', 'Members')}',
                          style: tt.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: classMembers.length,
                itemBuilder: (ctx, idx) {
                  final p = classMembers[idx];
                  final isTeacher = p.role == 'teacher';
                  final resolvedAvatarPath =
                      _resolveAvatarUrlOrPath(p.avatar) ?? '';
                  final avatar = _getAvatarProvider(resolvedAvatarPath);

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                        image: avatar,
                      ),
                      alignment: Alignment.center,
                      child: avatar == null
                          ? Text(p.displayName.isNotEmpty
                              ? p.displayName.substring(0, 1)
                              : '?')
                          : null,
                    ),
                    title: Text(p.displayName),
                    subtitle: Text(isTeacher
                        ? loc.t('教师', 'Teacher')
                        : (p.studentNo.isNotEmpty ? p.studentNo : p.staffNo)),
                    onTap: () => _showContactDetails(context, p, cs, tt),
                    trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContactDetails(
      BuildContext context, Profile p, ColorScheme cs, TextTheme tt) {
    final loc = Provider.of<LocaleProvider>(context, listen: false);
    final resolvedAvatarPath = _resolveAvatarUrlOrPath(p.avatar) ?? '';
    final avatar = _getAvatarProvider(resolvedAvatarPath);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: cs.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                    image: avatar,
                  ),
                  alignment: Alignment.center,
                  child: avatar == null
                      ? Text(
                          p.displayName.isNotEmpty
                              ? p.displayName.substring(0, 1).toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: cs.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 32,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  p.displayName,
                  style:
                      tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (p.signature.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    p.signature,
                    style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 32),
                _buildProfileItem(
                    Icons.person_outline,
                    loc.t('昵称', 'Nickname'),
                    p.displayName.isEmpty
                        ? loc.t('未填写', 'Not set')
                        : p.displayName,
                    cs,
                    tt),
                _buildProfileItem(
                    Icons.badge_outlined,
                    loc.t('姓名', 'Name'),
                    p.realName.isEmpty
                        ? (p.displayName.isEmpty
                            ? loc.t('未填写', 'Not set')
                            : p.displayName)
                        : p.realName,
                    cs,
                    tt),
                _buildProfileItem(
                    p.role == 'teacher'
                        ? Icons.badge_outlined
                        : Icons.badge_outlined,
                    p.role == 'teacher'
                        ? loc.t('工号', 'Staff No.')
                        : loc.t('学号', 'Student No.'),
                    p.role == 'teacher' ? p.staffNo : p.studentNo,
                    cs,
                    tt),
                if (p.role != 'teacher')
                  _buildProfileItem(
                      Icons.class_outlined,
                      loc.t('班级', 'Class'),
                      p.classCode.isEmpty
                          ? loc.t('未填写', 'Not set')
                          : (_classNameByCode[p.classCode.trim()] ??
                              p.classCode),
                      cs,
                      tt),
                _buildProfileItem(
                    Icons.phone_outlined,
                    loc.t('电话', 'Phone'),
                    p.phone.isEmpty ? loc.t('未填写', 'Not set') : p.phone,
                    cs,
                    tt),
                _buildProfileItem(
                    Icons.email_outlined,
                    loc.t('邮箱', 'Email'),
                    p.email.isEmpty ? loc.t('未填写', 'Not set') : p.email,
                    cs,
                    tt),
                _buildProfileItem(
                    Icons.apartment_outlined,
                    loc.t('寝室', 'Dormitory'),
                    p.dorm.isEmpty ? loc.t('未填写', 'Not set') : p.dorm,
                    cs,
                    tt),
                _buildProfileItem(
                    Icons.edit_note_outlined,
                    loc.t('个性签名', 'Bio'),
                    p.signature.isEmpty ? loc.t('未填写', 'Not set') : p.signature,
                    cs,
                    tt),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileItem(
      IconData icon, String label, String value, ColorScheme cs, TextTheme tt) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: cs.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                Text(value,
                    style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
