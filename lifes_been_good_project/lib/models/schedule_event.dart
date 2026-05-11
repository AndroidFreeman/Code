class ScheduleEvent {
  final String id;
  final String title;
  final String location;
  final String startTime;
  final String endTime;
  final String type;
  final String backgroundColor;
  final String note;
  final int updatedAt;

  ScheduleEvent({
    required this.id,
    required this.title,
    required this.location,
    required this.startTime,
    required this.endTime,
    required this.type,
    required this.backgroundColor,
    required this.note,
    this.updatedAt = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'location': location,
      'start_time': startTime,
      'end_time': endTime,
      'type': type,
      'background_color': backgroundColor,
      'note': note,
      'updated_at': updatedAt,
    };
  }

  factory ScheduleEvent.fromMap(Map<String, dynamic> map) {
    return ScheduleEvent(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      location: map['location']?.toString() ?? '',
      startTime: map['start_time']?.toString() ?? '',
      endTime: map['end_time']?.toString() ?? '',
      type: map['type']?.toString() ?? '',
      backgroundColor: map['background_color']?.toString() ?? '',
      note: map['note']?.toString() ?? '',
      updatedAt: map['updated_at'] as int? ?? 0,
    );
  }
}