class NotificationModel {
  final int id;
  final String title;
  final String? message;
  final bool read;
  final String? createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    this.message,
    required this.read,
    this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      message: json['message'],
      read: json['read'] ?? false,
      createdAt: json['createdAt'],
    );
  }
}
