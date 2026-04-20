class Course {
  final String id;
  final String courseName;
  final String teacherProfileId;
  final String termCode;
  final String? color;
  final String? credits;
  final String? notes;

  const Course({
    required this.id,
    required this.courseName,
    required this.teacherProfileId,
    required this.termCode,
    this.color,
    this.credits,
    this.notes,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: (json['id'] ?? '').toString(),
      courseName: (json['course_name'] ?? '').toString(),
      teacherProfileId: (json['teacher_profile_id'] ?? '').toString(),
      termCode: (json['term_code'] ?? '').toString(),
      color: json['color']?.toString(),
      credits: json['credits']?.toString(),
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_name': courseName,
      'teacher_profile_id': teacherProfileId,
      'term_code': termCode,
      'color': color,
      'credits': credits,
      'notes': notes,
    };
  }
}

