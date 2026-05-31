import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/locale_provider.dart';
import '../state/session.dart';
import '../widgets/expressive_ui.dart';

class HomeDrawer extends StatelessWidget {
  final Session session;
  final String activePage;
  final Function(String) onNavigate;
  final VoidCallback onLogout;
  final Set<String> hiddenPageIds;

  const HomeDrawer({
    super.key,
    required this.session,
    required this.activePage,
    required this.onNavigate,
    required this.onLogout,
    this.hiddenPageIds = const {},
  });

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
    return '${session.dataDir}/$v';
  }

  DecorationImage? _getAvatarImage(String path) {
    final resolved = _resolveAvatarUrlOrPath(path) ?? '';
    return AvatarImageProvider.getDecorationImage(resolved);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final loc = Provider.of<LocaleProvider>(context);
    bool show(String id) => !hiddenPageIds.contains(id);
    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 80) {
              return const SizedBox.shrink();
            }
            final maxHp = (constraints.maxWidth / 2).clamp(0.0, 24.0);
            final hp = (constraints.maxWidth * 0.08).clamp(0.0, maxHp);
            final maxListHp = (constraints.maxWidth / 2).clamp(0.0, 16.0);
            final listHp = (hp - 8).clamp(0.0, maxListHp);
            final displayName = session.profile.displayName.isNotEmpty
                ? session.profile.displayName
                : loc.t('未设置昵称', 'No Nickname');
            final account = session.profile.studentNo.isNotEmpty
                ? session.profile.studentNo
                : (session.profile.staffNo.isNotEmpty
                    ? session.profile.staffNo
                    : loc.t('未设置学号/工号', 'No ID'));

            return Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: Container(
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                    topLeft: Radius.circular(24),
                    bottomLeft: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(hp, 18, hp, 12),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 26,
                              height: 26,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            loc.t('更多工具', 'More Tools'),
                            style: tt.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(listHp, 4, listHp, 4),
                        children: [
                          if (show('timetable'))
                            _buildMenuItem(
                              context,
                              id: 'timetable',
                              icon: Icons.calendar_month_rounded,
                              label: loc.t('周课表', 'Timetable'),
                              isSelected: activePage == 'timetable',
                            ),
                          if (show('todo'))
                            _buildMenuItem(
                              context,
                              id: 'todo',
                              icon: Icons.checklist_rtl_rounded,
                              label: loc.t('待办', 'Todos'),
                              isSelected: activePage == 'todo',
                            ),
                          if (show('contact'))
                            _buildMenuItem(
                              context,
                              id: 'contact',
                              icon: Icons.contact_page_rounded,
                              label: loc.t('通讯录', 'Contacts'),
                              isSelected: activePage == 'contact',
                            ),
                          if (show('attendance') && session.canTakeAttendance)
                            _buildMenuItem(
                              context,
                              id: 'attendance',
                              icon: Icons.emoji_people_rounded,
                              label: loc.t('点名', 'Roll Call'),
                              isSelected: activePage == 'attendance',
                            ),
                          if (show('students') && session.canViewStudents)
                            _buildMenuItem(
                              context,
                              id: 'students',
                              icon: Icons.people_alt_rounded,
                              label: loc.t('学生', 'Students'),
                              isSelected: activePage == 'students',
                            ),
                          if (show('class_attendance') &&
                              session.canViewStudents)
                            _buildMenuItem(
                              context,
                              id: 'class_attendance',
                              icon: Icons.assessment_rounded,
                              label: loc.t('考勤', 'Attendance'),
                              isSelected: activePage == 'class_attendance',
                            ),
                          _buildMenuItem(
                            context,
                            id: 'qrcode',
                            icon: Icons.qr_code_rounded,
                            label: loc.t('QR Code', 'QR Code'),
                            isSelected: activePage == 'qrcode',
                          ),
                          _buildMenuItem(
                            context,
                            id: 'weblinks',
                            icon: Icons.language_rounded,
                            label: loc.t('常用网站', 'Web Links'),
                            isSelected: activePage == 'weblinks',
                          ),
                          _buildMenuItem(
                            context,
                            id: 'notifications',
                            icon: Icons.notifications_rounded,
                            label: loc.t('通知', 'Notifications'),
                            isSelected: activePage == 'notifications',
                          ),
                          _buildMenuItem(
                            context,
                            id: 'settings',
                            icon: Icons.settings_rounded,
                            label: loc.t('设置', 'Settings'),
                            isSelected: activePage == 'settings',
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: hp, right: hp, bottom: 12),
                      child: Bounceable(
                        onTap: () {
                          Navigator.of(context).pop();
                          Future<void>.delayed(const Duration(milliseconds: 16),
                              () {
                            onNavigate('profile');
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 44,
                                height: 44,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: cs.outlineVariant
                                          .withValues(alpha: 64),
                                      width: 1,
                                    ),
                                    image:
                                        _getAvatarImage(session.profile.avatar),
                                  ),
                                  alignment: Alignment.center,
                                  child: (_getAvatarImage(
                                              session.profile.avatar) ==
                                          null)
                                      ? Text(
                                          displayName.isNotEmpty
                                              ? displayName
                                                  .substring(0, 1)
                                                  .toUpperCase()
                                              : '?',
                                          style: tt.titleMedium?.copyWith(
                                            color: cs.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displayName,
                                      style: tt.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: cs.onSurface,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      account,
                                      style: tt.bodySmall?.copyWith(
                                        color: cs.onSurfaceVariant,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: cs.onSurfaceVariant,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(hp, 0, hp, 16),
                      child: FilledButton.tonalIcon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Future<void>.delayed(const Duration(milliseconds: 16),
                              () {
                            onLogout();
                          });
                        },
                        icon: Icon(Icons.logout_rounded, color: cs.error),
                        label: Text(
                          loc.t('退出登录', 'Sign out'),
                          style: tt.titleMedium?.copyWith(
                            color: cs.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: cs.errorContainer,
                          foregroundColor: cs.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required String id,
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    void closeAndNavigate() {
      Navigator.of(context).pop();
      if (isSelected) return;
      Future<void>.delayed(const Duration(milliseconds: 16), () {
        onNavigate(id);
      });
    }

    return AnimatedContainer(
      duration: kAppRouteTransitionDuration,
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? cs.secondaryContainer.withValues(alpha: 214)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: Bounceable(
          behavior: HitTestBehavior.deferToChild,
          child: InkWell(
            onTap: closeAndNavigate,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: isSelected
                        ? cs.onSecondaryContainer
                        : cs.onSurfaceVariant,
                    size: 22,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      label,
                      style: tt.titleMedium?.copyWith(
                        color: isSelected
                            ? cs.onSecondaryContainer
                            : cs.onSurfaceVariant,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: cs.onSecondaryContainer,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
