// mobile/lib/shared/models/time_log_model.dart
class TimeLogModel {
  final int id;
  final int taskId;
  final String taskTitle;
  final int projectId;
  final String projectName;
  final int userId;
  final String userName;
  final String date;
  final int minutes;
  final String? description;
  final String? createdAt;

  TimeLogModel({
    required this.id,
    required this.taskId,
    required this.taskTitle,
    required this.projectId,
    required this.projectName,
    required this.userId,
    required this.userName,
    required this.date,
    required this.minutes,
    this.description,
    this.createdAt,
  });

  double get hours => minutes / 60.0;

  String get formattedHours {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return '${h}h00';
    return '${h}h${m.toString().padLeft(2, '0')}';
  }

  factory TimeLogModel.fromJson(Map<String, dynamic> json) {
    return TimeLogModel(
      id: json['id'] ?? 0,
      taskId: json['taskId'] ?? 0,
      taskTitle: json['taskTitle'] ?? '',
      projectId: json['projectId'] ?? 0,
      projectName: json['projectName'] ?? '',
      userId: json['userId'] ?? 0,
      userName: json['userName'] ?? '',
      date: json['date'] ?? '',
      minutes: json['minutes'] ?? 0,
      description: json['description'],
      createdAt: json['createdAt'],
    );
  }
}