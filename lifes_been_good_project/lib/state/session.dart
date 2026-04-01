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
  bool get isCadre => isStudent && studentPosition == 'cadre';

  bool get canTakeAttendance => isTeacher || isCadre;
  bool get canViewStudents => isTeacher;
  bool get canDeleteStudents => isTeacher;
}
