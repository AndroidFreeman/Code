class TodoItem {
  final String id;
  final String ownerProfileId;
  final String folder;
  final String title;
  final String content;
  final bool isDone;
  final String dueAt;
  final String startAt;
  final String endAt;
  final String createdAt;
  final String updatedAt;

  const TodoItem({
    required this.id,
    required this.ownerProfileId,
    required this.folder,
    required this.title,
    this.content = '',
    required this.isDone,
    required this.dueAt,
    this.startAt = '',
    this.endAt = '',
    required this.createdAt,
    required this.updatedAt,
  });

  factory TodoItem.fromJson(Map<String, dynamic> json) {
    final raw = (json['is_done'] ?? '').toString().toLowerCase();
    final isDone = raw == 'true' || raw == '1' || raw == 'yes';
    return TodoItem(
      id: (json['id'] ?? '').toString(),
      ownerProfileId: (json['owner_profile_id'] ?? '').toString(),
      folder: (json['folder'] ?? '默认').toString(),
      title: (json['title'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      isDone: isDone,
      dueAt: (json['due_at'] ?? '').toString(),
      startAt: (json['start_at'] ?? '').toString(),
      endAt: (json['end_at'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
      updatedAt: (json['updated_at'] ?? '').toString(),
    );
  }

  TodoItem copyWith({
    String? id,
    String? ownerProfileId,
    String? folder,
    String? title,
    String? content,
    bool? isDone,
    String? dueAt,
    String? startAt,
    String? endAt,
    String? createdAt,
    String? updatedAt,
  }) {
    return TodoItem(
      id: id ?? this.id,
      ownerProfileId: ownerProfileId ?? this.ownerProfileId,
      folder: folder ?? this.folder,
      title: title ?? this.title,
      content: content ?? this.content,
      isDone: isDone ?? this.isDone,
      dueAt: dueAt ?? this.dueAt,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
