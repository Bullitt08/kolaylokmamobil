class AdminNotificationModel {
  final String id;
  final String type;
  final Map<String, dynamic> content;
  final bool isRead;
  final DateTime createdAt;

  AdminNotificationModel({
    required this.id,
    required this.type,
    required this.content,
    this.isRead = false,
    required this.createdAt,
  });

  factory AdminNotificationModel.fromMap(Map<String, dynamic> map) {
    return AdminNotificationModel(
      id: map['id'],
      type: map['type'],
      content: Map<String, dynamic>.from(map['content']),
      isRead: map['is_read'] ?? false,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'content': content,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
