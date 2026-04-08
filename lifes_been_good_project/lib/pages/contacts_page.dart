import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../models/profile.dart';
import '../services/local_profiles.dart';
import '../state/session.dart';
import '../main.dart';
import 'profile_page.dart';
import 'student_detail_page.dart';
import '../widgets/expressive_ui.dart';

class ContactsPage extends StatefulWidget {
  final Session session;
  final VoidCallback? onReady;

  const ContactsPage({super.key, required this.session, this.onReady});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  bool _loading = true;
  String _status = '';
  List<Profile> _profiles = const [];
  Set<String> _myContactProfileIds = {};
  Map<String, ImageProvider?> _avatarProviders = const {};

  bool _showFabMenu = false;

  static const _contactsHeader =
      'id,owner_profile_id,contact_profile_id,alias,phone';

  String? _resolveAvatarUrlOrPath(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return null;
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

  Future<Map<String, ImageProvider?>> _buildAvatarProviders(
      List<Profile> profiles) async {
    final out = <String, ImageProvider?>{};
    for (final profile in profiles) {
      final resolved = _resolveAvatarUrlOrPath(profile.avatar);
      if (resolved == null) continue;
      final uri = Uri.tryParse(resolved);
      if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
        out[profile.id] = NetworkImage(resolved);
        continue;
      }
      final f = File(resolved);
      if (await f.exists()) {
        out[profile.id] = FileImage(f);
      }
    }
    return out;
  }

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<Set<String>> _loadMyContacts() async {
    final res = await widget.session.features
        .csvOp(action: 'read', file: 'contacts.csv');
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

  Future<void> _addContact(Profile p) async {
    final loc = Provider.of<LocaleProvider>(context, listen: false);
    final ownerId = widget.session.profile.id.trim();
    final contactId = p.id.trim();
    if (ownerId.isEmpty || contactId.isEmpty) return;
    if (ownerId == contactId) return;

    final res = await widget.session.features
        .csvOp(action: 'read', file: 'contacts.csv');
    final items = ((res['data'] ?? const {})['items'] as List?) ?? const [];
    final rows = items.map((e) => (e as Map).cast<String, String>()).toList();

    final already = rows.any((r) =>
        (r['owner_profile_id'] ?? '').trim() == ownerId &&
        (r['contact_profile_id'] ?? '').trim() == contactId);

    if (!already) {
      final id = 'ct_${DateTime.now().millisecondsSinceEpoch}';
      final alias = '';
      final phone = (p.phone).replaceAll(',', '');
      rows.add({
        'id': id,
        'owner_profile_id': ownerId,
        'contact_profile_id': contactId,
        'alias': alias,
        'phone': phone,
      });
      final headers = _contactsHeader.split(',');
      await widget.session.features.csvOp(
          action: 'write', file: 'contacts.csv', headers: headers, rows: rows);

      if (!mounted) return;
      setState(() {
        _myContactProfileIds = {..._myContactProfileIds, contactId};
        _status = loc.t('已添加到通讯录', 'Added to contacts');
      });
    }
  }

  Future<void> _removeContact(Profile p) async {
    final loc = Provider.of<LocaleProvider>(context, listen: false);
    final ownerId = widget.session.profile.id.trim();
    final contactId = p.id.trim();
    if (ownerId.isEmpty || contactId.isEmpty) return;

    final res = await widget.session.features
        .csvOp(action: 'read', file: 'contacts.csv');
    final items = ((res['data'] ?? const {})['items'] as List?) ?? const [];
    final rows = items.map((e) => (e as Map).cast<String, String>()).toList();

    rows.removeWhere((r) =>
        (r['owner_profile_id'] ?? '').trim() == ownerId &&
        (r['contact_profile_id'] ?? '').trim() == contactId);

    final headers = _contactsHeader.split(',');
    await widget.session.features.csvOp(
        action: 'write', file: 'contacts.csv', headers: headers, rows: rows);

    if (!mounted) return;
    final next = {..._myContactProfileIds};
    next.remove(contactId);
    setState(() {
      _myContactProfileIds = next;
      _status = loc.t('已从通讯录移除', 'Removed from contacts');
    });
  }

  Future<void> _toggleContact(Profile p) async {
    if (_myContactProfileIds.contains(p.id.trim())) {
      await _removeContact(p);
    } else {
      await _addContact(p);
    }
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
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                      content: Text(loc.t('不能添加自己', 'Cannot add yourself'))));
                } else {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                      content: Text(loc.t('未找到该用户', 'User not found'))));
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
    await _addContact(selected);
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _status = '';
    });

    try {
      List<String> classes = [];
      if (widget.session.isTeacher) {
        classes = await LocalProfiles.getTeacherClasses(
          widget.session.dataDir,
          widget.session.profile.id,
        );
      } else {
        classes = [widget.session.profile.classCode.trim()];
      }

      // Fetch all profiles to get detailed info for everyone
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

      if (profilesRes['ok'] != true) {
        final loc = Provider.of<LocaleProvider>(context, listen: false);
        setState(() {
          _loading = false;
          _status = loc.t('获取个人资料失败', 'Failed to load profiles');
        });
        widget.onReady?.call();
        return;
      }

      final profilesRaw =
          (((profilesRes['data'] ?? const {}) as Map)['items'] ?? const [])
              as List;

      final filteredProfiles = <Profile>[];
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
          if (classes.contains(profile.classCode.trim())) {
            filteredProfiles.add(profile);
          }
        }
      }

      // Sort: Teachers first, then by account number
      filteredProfiles.sort((a, b) {
        if (a.role == 'teacher' && b.role != 'teacher') return -1;
        if (a.role != 'teacher' && b.role == 'teacher') return 1;
        final aNo = a.role == 'teacher' ? a.staffNo : a.studentNo;
        final bNo = b.role == 'teacher' ? b.staffNo : b.studentNo;
        return aNo.compareTo(bNo);
      });

      if (!mounted) return;
      final myContactIds = await _loadMyContacts();
      final avatarProviders = await _buildAvatarProviders(filteredProfiles);
      setState(() {
        _loading = false;
        _profiles = filteredProfiles;
        _myContactProfileIds = myContactIds;
        _avatarProviders = avatarProviders;
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
    final showDrawerButton = !isDesktop || isPortrait;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.t('班级通讯录', 'Class Contacts'),
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
      ),
      body: Padding(
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
                child:
                    Text(_status, style: TextStyle(color: cs.onErrorContainer)),
              ),
            Expanded(
              child: _loading
                  ? const SizedBox.shrink()
                  : _profiles.isEmpty
                      ? Center(
                          child: Text(loc.t('暂无联系人', 'No contacts'),
                              style: tt.bodyLarge))
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 8, bottom: 80),
                          itemCount: _profiles.length,
                          itemBuilder: (context, index) {
                            final profile = _profiles[index];
                            final isTeacher = profile.role == 'teacher';
                            final avatar = _avatarProviders[profile.id];

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Bounceable(
                                onTap: () =>
                                    _showContactDetails(context, profile, cs, tt),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: cs.surface,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                        color:
                                            cs.outlineVariant.withOpacity(0.5)),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: isTeacher
                                              ? cs.secondaryContainer
                                              : cs.primaryContainer,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          image: avatar != null
                                              ? DecorationImage(
                                                  image: avatar,
                                                  fit: BoxFit.cover,
                                                )
                                              : null,
                                        ),
                                        alignment: Alignment.center,
                                        child: avatar == null
                                            ? Text(
                                                profile.displayName.isNotEmpty
                                                    ? profile.displayName
                                                        .substring(0, 1)
                                                    : '?',
                                                style: tt.titleLarge?.copyWith(
                                                  color: isTeacher
                                                      ? cs.onSecondaryContainer
                                                      : cs.onPrimaryContainer,
                                                  fontWeight: FontWeight.bold,
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
                                            Text(profile.displayWithRealName,
                                                style: tt.titleMedium?.copyWith(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            Text(
                                                isTeacher
                                                    ? '${loc.t('工号', 'Staff ID')}: ${profile.staffNo}'
                                                    : '${loc.t('学号', 'Student ID')}: ${profile.studentNo}',
                                                style: tt.bodySmall?.copyWith(
                                                    color:
                                                        cs.onSurfaceVariant)),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () => _toggleContact(profile),
                                        icon: Icon(
                                          _myContactProfileIds.contains(profile.id)
                                              ? Icons.star_rounded
                                              : Icons.star_outline_rounded,
                                        ),
                                        color:
                                            _myContactProfileIds.contains(profile.id)
                                                ? cs.primary
                                                : cs.onSurfaceVariant
                                                    .withOpacity(0.7),
                                        tooltip: _myContactProfileIds
                                                .contains(profile.id)
                                            ? loc.t('从通讯录移除',
                                                'Remove from contacts')
                                            : loc.t(
                                                '添加到通讯录', 'Add to contacts'),
                                      ),
                                      Icon(Icons.chevron_right_rounded,
                                          color: cs.onSurfaceVariant
                                              .withOpacity(0.5)),
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
      ),
      floatingActionButton: Column(
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
                              MaterialPageRoute(
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
            child: AnimatedRotation(
              turns: _showFabMenu ? 0.125 : 0, // Rotate 45 degrees
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              child: const Icon(Icons.add),
            ),
            tooltip: loc.t('菜单', 'Menu'),
          ),
        ],
      ),
    );
  }

  void _showContactDetails(
      BuildContext context, Profile p, ColorScheme cs, TextTheme tt) {
    final loc = Provider.of<LocaleProvider>(context, listen: false);
    final avatar = _avatarProviders[p.id];
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
                    color: cs.secondaryContainer,
                    shape: BoxShape.circle,
                    image: avatar != null
                        ? DecorationImage(image: avatar, fit: BoxFit.cover)
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: avatar == null
                      ? Text(
                          p.displayName.isNotEmpty
                              ? p.displayName.substring(0, 1).toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: cs.onSecondaryContainer,
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
                          : p.classCode,
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
