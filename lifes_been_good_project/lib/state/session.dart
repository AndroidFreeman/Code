import 'package:flutter/foundation.dart';
import '../models/profile.dart';
import '../services/native_cli.dart';
import '../services/native_features.dart';
import '../services/accounting_service.dart';

class Session extends ChangeNotifier {
  final NativeCli? cli;
  final NativeFeatures features;
  final String dataDir;
  Profile _profile;
  late final AccountingService accounting;

  Session({
    required this.cli,
    required this.features,
    required this.dataDir,
    required Profile profile,
  }) : _profile = profile {
    accounting = AccountingService(
        dataDir: dataDir, nativeLibDir: features.nativeLibDir);
  }

  Profile get profile => _profile;

  set profile(Profile newProfile) {
    if (_profile != newProfile) {
      _profile = newProfile;
      notifyListeners();
    }
  }

  void updateProfile(Profile newProfile) {
    profile = newProfile;
    notifyDataChanged();
  }

  bool get isTeacher => profile.role.trim().toLowerCase() == 'teacher';
  bool get isStudent => !isTeacher;

  static const cadreRoles = [
    'psychological',
    'life',
    'publicity',
    'monitor',
    'study',
    'organize',
    'branch_secretary',
    '心理',
    '生活',
    '宣传',
    '班长',
    '学习',
    '组织',
    '团支书',
  ];
  static const powerCadreRoles = [
    'monitor',
    'study',
    'publicity',
    '班长',
    '学习',
    '宣传',
    '宣委',
  ];

  String get studentPosition => profile.position;
  String get normalizedPosition => studentPosition.trim().toLowerCase();

  bool get isCadre {
    final p = normalizedPosition;
    if (p.isEmpty) return false;
    return cadreRoles.any((role) {
      final r = role.toLowerCase();
      return p.contains(r) || r.contains(p);
    });
  }

  bool get isPowerCadre {
    final p = normalizedPosition;
    if (p.isEmpty) return false;
    return powerCadreRoles.any((role) {
      final r = role.toLowerCase();
      return p.contains(r) || r.contains(p);
    });
  }

  bool get canTakeAttendance => isTeacher || isPowerCadre;
  bool get canViewStudents => isTeacher || isPowerCadre;
  bool get canDeleteStudents => isTeacher;

  void notifyDataChanged() {
    notifyListeners();
  }
}
