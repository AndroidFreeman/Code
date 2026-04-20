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
  final String position;

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
      position: position,
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
    this.position = '',
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
      position: (json['position'] ?? '').toString(),
    );
  }

  Profile copyWith({
    String? id,
    String? role,
    String? staffNo,
    String? studentNo,
    String? displayName,
    String? realName,
    String? orgCode,
    String? classCode,
    String? phone,
    String? email,
    String? dorm,
    String? avatar,
    String? signature,
    String? position,
  }) {
    return Profile(
      id: id ?? this.id,
      role: role ?? this.role,
      staffNo: staffNo ?? this.staffNo,
      studentNo: studentNo ?? this.studentNo,
      displayName: displayName ?? this.displayName,
      realName: realName ?? this.realName,
      orgCode: orgCode ?? this.orgCode,
      classCode: classCode ?? this.classCode,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      dorm: dorm ?? this.dorm,
      avatar: avatar ?? this.avatar,
      signature: signature ?? this.signature,
      position: position ?? this.position,
    );
  }
}
