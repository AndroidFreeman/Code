import 'student.dart';

class Profile {
  final String id;
  final String role;
  final String staffNo;
  final String studentNo;
  final String displayName; // This will act as the username
  final String realName;
  final String orgCode;
  final String classCode;
  final String phone;
  final String email;
  final String dorm;
  final String avatar;
  final String signature;

  String get displayWithRealName {
    if (realName.isNotEmpty && displayName != realName) {
      return '$displayName ($realName)';
    }
    return displayName;
  }

  Student toStudent() {
    return Student(
      id: id,
      studentNo: studentNo.isNotEmpty ? studentNo : staffNo,
      fullName: displayName,
      pinyin: '',
      gender: '未知',
      classCode: classCode,
      className: classCode,
      phone: phone,
      position: role == 'teacher' ? '教师' : '',
    );
  }

  const Profile({
    required this.id,
    required this.role,
    required this.staffNo,
    required this.studentNo,
    required this.displayName,
    this.realName = '',
    required this.orgCode,
    required this.classCode,
    this.phone = '',
    this.email = '',
    this.dorm = '',
    this.avatar = '',
    this.signature = '',
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: (json['id'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
      staffNo: (json['staff_no'] ?? '').toString(),
      studentNo: (json['student_no'] ?? '').toString(),
      displayName: (json['display_name'] ?? '').toString(),
      realName: (json['real_name'] ?? '').toString(),
      orgCode: (json['org_code'] ?? '').toString(),
      classCode: (json['class_code'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      dorm: (json['dorm'] ?? '').toString(),
      avatar: (json['avatar'] ?? '').toString(),
      signature: (json['signature'] ?? '').toString(),
    );
  }
}
