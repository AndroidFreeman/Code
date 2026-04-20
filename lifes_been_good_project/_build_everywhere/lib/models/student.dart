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

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: (json['id'] ?? '').toString(),
      studentNo: (json['student_no'] ?? '').toString(),
      fullName: (json['full_name'] ?? '').toString(),
      pinyin: (json['pinyin'] ?? '').toString(),
      gender: (json['gender'] ?? '').toString(),
      classCode: (json['class_code'] ?? '').toString(),
      className: (json['class_name'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      position: (json['position'] ?? '').toString(),
    );
  }
}
