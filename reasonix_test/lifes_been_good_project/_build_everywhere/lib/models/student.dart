class Student {
  final String id;
  final String studentNo;
  final String fullName;
  final String pinyin;
  final String gender;
  final String classCode;
  final String className;
  final String phone;
  final String position;

  const Student({
    required this.id,
    required this.studentNo,
    required this.fullName,
    this.pinyin = '',
    this.gender = '未知',
    required this.classCode,
    this.className = '',
    required this.phone,
    required this.position,
  });

  String get displayClassLabel {
    final resolved = className.trim();
    if (resolved.isNotEmpty) return resolved;
    return classCode.trim();
  }

  factory Student.fromJson(Map<String, dynamic> json) {
    final rawClassCode =
        (json['class_code'] ?? json['classCode'] ?? '').toString().trim();
    final rawClassName =
        (json['class_name'] ?? json['className'] ?? '').toString().trim();
    return Student(
      id: (json['id'] ?? '').toString(),
      studentNo: (json['student_no'] ?? '').toString(),
      fullName: (json['full_name'] ?? '').toString(),
      pinyin: (json['pinyin'] ?? '').toString(),
      gender: (json['gender'] ?? '').toString(),
      classCode: rawClassCode,
      className: rawClassName,
      phone: (json['phone'] ?? '').toString(),
      position: (json['position'] ?? '').toString(),
    );
  }

  Student copyWith({
    String? id,
    String? studentNo,
    String? fullName,
    String? pinyin,
    String? gender,
    String? classCode,
    String? className,
    String? phone,
    String? position,
  }) {
    return Student(
      id: id ?? this.id,
      studentNo: studentNo ?? this.studentNo,
      fullName: fullName ?? this.fullName,
      pinyin: pinyin ?? this.pinyin,
      gender: gender ?? this.gender,
      classCode: classCode ?? this.classCode,
      className: className ?? this.className,
      phone: phone ?? this.phone,
      position: position ?? this.position,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_no': studentNo,
      'full_name': fullName,
      'pinyin': pinyin,
      'gender': gender,
      'class_code': classCode,
      'class_name': className,
      'phone': phone,
      'position': position,
    };
  }
}
