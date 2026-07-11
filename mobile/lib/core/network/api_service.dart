import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';
import '../../shared/models/user_model.dart';
import '../../shared/models/project_model.dart';
import '../../shared/models/task_model.dart';
import '../../shared/models/kpi_model.dart';
import '../../shared/models/time_log_model.dart';
import '../../shared/models/member_model.dart';
import '../../shared/models/notification_model.dart';
import '../../shared/models/sprint_model.dart';
import '../../shared/models/comment_model.dart';

class ApiService {
  // URL de production injectee au build via --dart-define=API_BASE_URL=...
  // (ex: flutter build web --dart-define=API_BASE_URL=https://mon-backend.onrender.com/api).
  // Vide par defaut : dans ce cas on retombe sur les URLs locales ci-dessous.
  static const String _prodBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_prodBaseUrl.isNotEmpty) return _prodBaseUrl;
    if (kIsWeb) return 'http://localhost:8080/api';
    // 10.0.2.2 est l'alias loopback special de l'emulateur Android vers l'hote ;
    // les autres plateformes (Windows, macOS, Linux, iOS) utilisent localhost.
    if (Platform.isAndroid) return 'http://10.0.2.2:8080/api';
    return 'http://localhost:8080/api';
  }

  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Content-Type': 'application/json'},
  ));

  static void init() {
    _dio.options.baseUrl = baseUrl;
  }

  static void setToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  static void clearToken() {
    _dio.options.headers.remove('Authorization');
  }

  static Future<UserModel> login(String email, String password) async {
    final res = await _dio.post('/auth/login',
        data: {'email': email, 'password': password});
    final user = UserModel.fromJson(res.data);
    setToken(user.accessToken);
    return user;
  }

  static Future<UserModel> register(
      String firstName, String lastName, String email, String password) async {
    final res = await _dio.post('/auth/register', data: {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'password': password,
    });
    final user = UserModel.fromJson(res.data);
    setToken(user.accessToken);
    return user;
  }

  static Future<String> forgotPassword(String email) async {
    final res = await _dio.post('/auth/forgot-password', data: {'email': email});
    return (res.data['message'] ?? '').toString();
  }

  static Future<String> resetPassword(String token, String newPassword) async {
    final res = await _dio.post('/auth/reset-password',
        data: {'token': token, 'newPassword': newPassword});
    return (res.data['message'] ?? '').toString();
  }

  static Future<List<ProjectModel>> getProjects({bool includeArchived = false}) async {
    final res = await _dio.get('/projects',
        queryParameters: includeArchived ? {'includeArchived': true} : null);
    return (res.data as List).map((e) => ProjectModel.fromJson(e)).toList();
  }

  static Future<ProjectModel> createProject(
      String name, String key, String description, double budget) async {
    final res = await _dio.post('/projects', data: {
      'name': name,
      'key': key,
      'description': description,
      'budget': budget,
      'hourlyRate': 45,
    });
    return ProjectModel.fromJson(res.data);
  }

  static Future<void> deleteProject(int id) async {
    await _dio.delete('/projects/$id');
  }

  static Future<ProjectModel> updateProject(
      int id, String name, String key, String description, double budget,
      {double? hourlyRate}) async {
    final res = await _dio.put('/projects/$id', data: {
      'name': name,
      'key': key,
      'description': description,
      'budget': budget,
      'hourlyRate': hourlyRate ?? 45,
    });
    return ProjectModel.fromJson(res.data);
  }

  static Future<void> archiveProject(int id, {bool archived = true}) async {
    await _dio.patch('/projects/$id/archive', data: {'archived': archived});
  }

  static Future<List<MemberModel>> getProjectMembers(int projectId) async {
    final res = await _dio.get('/projects/$projectId/members');
    return (res.data as List).map((e) => MemberModel.fromJson(e)).toList();
  }

  static Future<void> addMemberToProject(
      int projectId, int userId, String role) async {
    await _dio.post('/projects/$projectId/members',
        data: {'userId': userId, 'role': role});
  }

  static Future<void> removeMemberFromProject(int projectId, int userId) async {
    await _dio.delete('/projects/$projectId/members/$userId');
  }

  static Future<List<TaskModel>> getTasksByProject(int projectId) async {
    final res = await _dio.get('/tasks/project/$projectId');
    return (res.data as List).map((e) => TaskModel.fromJson(e)).toList();
  }

  static Future<List<TaskModel>> getMyTasks() async {
    final res = await _dio.get('/tasks/my');
    return (res.data as List).map((e) => TaskModel.fromJson(e)).toList();
  }

  static Future<List<TaskModel>> getTasksByUser(int userId) async {
    final res = await _dio.get('/tasks/user/$userId');
    return (res.data as List).map((e) => TaskModel.fromJson(e)).toList();
  }

  static Future<TaskModel> createTask(
      String title, String description, int projectId, String priority) async {
    final res = await _dio.post('/tasks', data: {
      'title': title,
      'description': description,
      'projectId': projectId,
      'priority': priority,
      'type': 'TASK',
    });
    return TaskModel.fromJson(res.data);
  }

  static Future<TaskModel> updateTaskStatus(int taskId, String status) async {
    final res = await _dio.patch('/tasks/$taskId/status?status=$status');
    return TaskModel.fromJson(res.data);
  }

  static Future<TaskModel> updateTask(
    int taskId, {
    required String title,
    String? description,
    String? priority,
    int? assigneeId,
    int? storyPoints,
    int? estimatedHours,
  }) async {
    final res = await _dio.put('/tasks/$taskId', data: {
      'title': title,
      'description': description,
      'priority': priority,
      'assigneeId': assigneeId,
      'storyPoints': storyPoints,
      'estimatedHours': estimatedHours,
    });
    return TaskModel.fromJson(res.data);
  }

  static Future<void> deleteTask(int taskId) async {
    await _dio.delete('/tasks/$taskId');
  }

  static Future<void> archiveTask(int taskId, {bool archived = true}) async {
    await _dio.patch('/tasks/$taskId/archive', data: {'archived': archived});
  }

  static Future<KpiDashboardModel> getDashboard() async {
    final res = await _dio.get('/kpi/dashboard');
    return KpiDashboardModel.fromJson(res.data);
  }

  static Future<List<MemberKpiModel>> getMemberKpis(int projectId) async {
    final res = await _dio.get('/kpi/members/$projectId');
    return (res.data as List).map((e) => MemberKpiModel.fromJson(e)).toList();
  }

  static Future<List<TimeLogModel>> getMyTimeLogs() async {
    final res = await _dio.get('/timelogs/my');
    return (res.data as List).map((e) => TimeLogModel.fromJson(e)).toList();
  }

  static Future<List<TimeLogModel>> getTimeLogsByProject(int projectId) async {
    final res = await _dio.get('/timelogs/project/$projectId');
    return (res.data as List).map((e) => TimeLogModel.fromJson(e)).toList();
  }

  static Future<TimeLogModel> logTime({
    required int taskId,
    required double hours,
    required String date,
    required String description,
  }) async {
    final res = await _dio.post('/timelogs', data: {
      'taskId': taskId,
      'minutes': (hours * 60).round(),
      'date': date,
      'description': description,
    });
    return TimeLogModel.fromJson(res.data);
  }

  static Future<void> deleteTimeLog(int id) async {
    await _dio.delete('/timelogs/$id');
  }

  static Future<List<MemberModel>> getAllUsers() async {
    final res = await _dio.get('/users');
    return (res.data as List).map((e) => MemberModel.fromJson(e)).toList();
  }

  static Future<List<NotificationModel>> getNotifications() async {
    final res = await _dio.get('/notifications');
    return (res.data as List).map((e) => NotificationModel.fromJson(e)).toList();
  }

  static Future<int> getUnreadNotificationCount() async {
    final res = await _dio.get('/notifications/unread-count');
    return (res.data['count'] as num).toInt();
  }

  static Future<void> markNotificationAsRead(int id) async {
    await _dio.patch('/notifications/$id/read');
  }

  static Future<void> markAllNotificationsAsRead() async {
    await _dio.patch('/notifications/read-all');
  }

  static Future<List<SprintModel>> getSprints(int projectId) async {
    final res = await _dio.get('/sprints/project/$projectId');
    return (res.data as List).map((e) => SprintModel.fromJson(e)).toList();
  }

  static Future<SprintModel> createSprint({
    required int projectId,
    required String name,
    required int number,
    String? startDate,
    String? endDate,
    int? goalPoints,
    String? goal,
  }) async {
    final res = await _dio.post('/sprints', data: {
      'projectId': projectId,
      'name': name,
      'number': number,
      'startDate': startDate,
      'endDate': endDate,
      'goalPoints': goalPoints,
      'goal': goal,
    });
    return SprintModel.fromJson(res.data);
  }

  static Future<void> deleteSprint(int id) async {
    await _dio.delete('/sprints/$id');
  }

  static Future<List<CommentModel>> getComments(int taskId) async {
    final res = await _dio.get('/comments/task/$taskId');
    return (res.data as List).map((e) => CommentModel.fromJson(e)).toList();
  }

  static Future<CommentModel> addComment(int taskId, String content) async {
    final res = await _dio.post('/comments',
        data: {'taskId': taskId, 'content': content});
    return CommentModel.fromJson(res.data);
  }

  static Future<String> changePassword(
      String oldPassword, String newPassword) async {
    final res = await _dio.put('/users/me/password',
        data: {'oldPassword': oldPassword, 'newPassword': newPassword});
    return (res.data['message'] ?? '').toString();
  }
}