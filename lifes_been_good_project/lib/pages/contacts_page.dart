import 'dart:io';

import 'package:flutter/material.dart';
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

  bool _showFabMenu = false;

  @override
  void initState() {
    super.initState();
    _refresh();
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
      setState(() {
        _loading = false;
        _profiles = filteredProfiles;
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

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              ScaffoldState? scaffold = Scaffold.maybeOf(context);
              if (scaffold != null && !scaffold.hasDrawer) {
                scaffold =
                    scaffold.context.findAncestorStateOfType<ScaffoldState>();
              }
              scaffold?.openDrawer();
            },
          ),
        ),
        title: Text(loc.t('班级通讯录', 'Class Contacts')),
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
                            final p = _profiles[index];
                            final isTeacher = p.role == 'teacher';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Bounceable(
                                onTap: () =>
                                    _showContactDetails(context, p, cs, tt),
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
                                          image: p.avatar.isNotEmpty &&
                                                  File(p.avatar).existsSync()
                                              ? DecorationImage(
                                                  image: FileImage(
                                                    File(p.avatar),
                                                  ),
                                                  fit: BoxFit.cover,
                                                )
                                              : null,
                                        ),
                                        alignment: Alignment.center,
                                        child: (p.avatar.isEmpty ||
                                                !File(p.avatar).existsSync())
                                            ? Text(
                                                p.displayName.isNotEmpty
                                                    ? p.displayName
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
                                            Text(p.displayWithRealName,
                                                style: tt.titleMedium?.copyWith(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            Text(
                                                isTeacher
                                                    ? '${loc.t('工号', 'Staff ID')}: ${p.staffNo}'
                                                    : '${loc.t('学号', 'Student ID')}: ${p.studentNo}',
                                                style: tt.bodySmall?.copyWith(
                                                    color:
                                                        cs.onSurfaceVariant)),
                                          ],
                                        ),
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(loc.t(
                                      '添加通讯录功能开发中...',
                                      'Add contact is under development...'))),
                            );
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StudentDetailPage(
          session: widget.session,
          student: p.toStudent(),
        ),
      ),
    );
  }
}
