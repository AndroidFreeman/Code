class TimetableItem {
  final String id;
  final String ownerProfileId;
  final int weekday;
  final int startPeriod;
  final int endPeriod;
  final String startTime;
  final String endTime;
  final String courseId;
  final String location;
  final String createdByProfileId;
  final bool isLocked;
  final String weeks;

  const TimetableItem({
    required this.id,
    required this.ownerProfileId,
    required this.weekday,
    required this.startPeriod,
    required this.endPeriod,
    required this.startTime,
    required this.endTime,
    required this.courseId,
    required this.location,
    required this.createdByProfileId,
    required this.isLocked,
    required this.weeks,
  });

  // Keep compatibility with 'period' if it's used in existing code
  int get period => startPeriod;

  bool isWeekIncluded(int week) {
    if (weeks.trim().isEmpty) return true;
    final parts = weeks.split(',');
    for (final p in parts) {
      if (p.contains('-')) {
        final range = p.split('-');
        if (range.length == 2) {
          final start = int.tryParse(range[0]) ?? 0;
          final end = int.tryParse(range[1]) ?? 0;
          if (week >= start && week <= end) return true;
        }
      } else {
        final w = int.tryParse(p);
        if (w == week) return true;
      }
    }
    return false;
  }

  factory TimetableItem.fromJson(Map<String, dynamic> json) {
    final wd = int.tryParse((json['weekday'] ?? '').toString()) ?? 0;
    
    // Support both 'period' and 'start_period/end_period'
    int sp = int.tryParse((json['start_period'] ?? '').toString()) ?? 0;
    int ep = int.tryParse((json['end_period'] ?? '').toString()) ?? 0;
    if (sp == 0) {
      sp = int.tryParse((json['period'] ?? '').toString()) ?? 0;
    }
    if (ep == 0) {
      ep = sp;
    }

    final lockedRaw = (json['is_locked'] ?? '').toString().toLowerCase();
    final isLocked =
        lockedRaw == 'true' || lockedRaw == '1' || lockedRaw == 'yes';
    return TimetableItem(
      id: (json['id'] ?? '').toString(),
      ownerProfileId: (json['owner_profile_id'] ?? '').toString(),
      weekday: wd,
      startPeriod: sp,
      endPeriod: ep,
      startTime: (json['start_time'] ?? '').toString(),
      endTime: (json['end_time'] ?? '').toString(),
      courseId: (json['course_id'] ?? '').toString(),
      location: (json['location'] ?? '').toString(),
      createdByProfileId: (json['created_by_profile_id'] ?? '').toString(),
      isLocked: isLocked,
      weeks: (json['weeks'] ?? '1-20').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_profile_id': ownerProfileId,
      'weekday': weekday,
      'start_period': startPeriod,
      'end_period': endPeriod,
      'start_time': startTime,
      'end_time': endTime,
      'course_id': courseId,
      'location': location,
      'created_by_profile_id': createdByProfileId,
      'is_locked': isLocked,
      'weeks': weeks,
    };
  }
}
