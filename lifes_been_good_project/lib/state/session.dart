import 'package:flutter/foundation.dart';
import '../models/profile.dart';
import '../services/native_cli.dart';
import '../services/native_features.dart';

class Session extends ChangeNotifier {
  final NativeCli? cli;
  final NativeFeatures features;
  final String dataDir;
  Profile _profile;
  final String studentPosition;

  Session({
    required this.cli,
    required this.features,
    required this.dataDir,
    required Profile profile,
    required this.studentPosition,
  }) : _profile = profile;

  Profile get profile => _profile;

  set profile(Profile newProfile) {
    if (_profile != newProfile) {
      _profile = newProfile;
      notifyListeners();
    }
  }

  void updateProfile(Profile newProfile) {
    profile = newProfile;
  }

  bool get isTeacher => profile.role == 'teacher';
  bool get isStudent => !isTeacher;

  // Refined student roles (positions)
  bool get isMonitor => isStudent && studentPosition == '班长';
  bool get isStudyRep => isStudent && studentPosition == '学习委员';
  bool get isLifeRep => isStudent && studentPosition == '生活委员';
  bool get isPsychRep => isStudent && studentPosition == '心理委员';
  bool get isPublicityRep => isStudent && studentPosition == '宣传委员';
  bool get isOrgRep => isStudent && studentPosition == '组织委员';

  // Original 'cadre' was used for general student leaders.
  // We keep it for backward compatibility if needed, or map it to the new roles.
  bool get isCadre =>
      isMonitor ||
      isStudyRep ||
      isLifeRep ||
      isPsychRep ||
      isPublicityRep ||
      isOrgRep ||
      studentPosition == 'cadre';

  // Permission checks
  bool get canTakeAttendance => isTeacher || isMonitor || isStudyRep;
  bool get canViewStudents => isTeacher;
  bool get canDeleteStudents => isTeacher;
}
