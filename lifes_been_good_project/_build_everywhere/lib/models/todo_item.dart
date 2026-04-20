class TodoItem {
  final String id;
  final String ownerProfileId;
  final String folder;
  final String title;
  final bool isDone;
  final String dueAt;
  final String createdAt;
  final String updatedAt;

  const TodoItem({
    required this.id,
    required this.ownerProfileId,
    required this.folder,
    required this.title,
    required this.isDone,
    required this.dueAt,
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
      isDone: isDone,
      dueAt: (json['due_at'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
      updatedAt: (json['updated_at'] ?? '').toString(),
    );
  }
}

