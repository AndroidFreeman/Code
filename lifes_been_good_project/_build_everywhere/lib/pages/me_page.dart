import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../state/session.dart';

class MePage extends StatelessWidget {
  final Session session;
  final VoidCallback onLogout;

  const MePage({super.key, required this.session, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final p = session.profile;
    final account = p.role == 'teacher' ? p.staffNo : p.studentNo;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final loc = Provider.of<LocaleProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text(loc.t('我的', 'Me'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Profile Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(32),
              ),
              child: Column(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      p.displayName.isNotEmpty ? p.displayName.substring(0, 1) : '?',
                      style: tt.headlineLarge?.copyWith(
                        color: cs.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(p.displayName, style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: cs.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      p.role == 'teacher'
                          ? loc.t('教师', 'Teacher')
                          : loc.t('学生', 'Student'),
                      style: tt.labelMedium?.copyWith(color: cs.onSecondaryContainer),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                      Icons.badge_rounded, loc.t('账号', 'Account'), account, cs, tt),
                  const SizedBox(height: 12),
                  if (p.role == 'student')
                    _buildInfoRow(
                        Icons.class_rounded, loc.t('班级', 'Class'), p.classCode, cs, tt),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Actions
            Container(
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cs.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.logout_rounded, color: cs.onErrorContainer),
                    ),
                    title: Text(loc.t('退出登录', 'Sign out'),
                        style: tt.titleMedium?.copyWith(color: cs.error)),
                    trailing: Icon(Icons.chevron_right_rounded, color: cs.outline),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    onTap: onLogout,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, ColorScheme cs, TextTheme tt) {
    return Row(
      children: [
        Icon(icon, size: 20, color: cs.outline),
        const SizedBox(width: 12),
        Text(label, style: tt.bodyMedium?.copyWith(color: cs.outline)),
        const Spacer(),
        Text(value, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
