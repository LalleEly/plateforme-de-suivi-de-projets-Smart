// mobile/lib/shared/models/member_model.dart
class MemberModel {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String globalRole;
  final bool active;
  final String? createdAt;

  MemberModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.globalRole,
    required this.active,
    this.createdAt,
  });

  String get fullName => '$firstName $lastName';

  String get initials {
    final f = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final l = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$f$l';
  }

  factory MemberModel.fromJson(Map<String, dynamic> json) {
    return MemberModel(
      id: json['id'] ?? 0,
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      globalRole: json['globalRole'] ?? 'MEMBRE',
      active: json['active'] ?? true,
      createdAt: json['createdAt'],
    );
  }
}

class MemberKpiModel {
  final int userId;
  final String memberName;
  final int tasksAssigned;
  final int tasksCompleted;
  final int loggedHours;
  final double workload;
  final double efficiency;
  final bool overloaded;

  MemberKpiModel({
    required this.userId,
    required this.memberName,
    required this.tasksAssigned,
    required this.tasksCompleted,
    required this.loggedHours,
    required this.workload,
    required this.efficiency,
    required this.overloaded,
  });

  factory MemberKpiModel.fromJson(Map<String, dynamic> json) {
    return MemberKpiModel(
      userId: json['userId'] ?? 0,
      memberName: json['memberName'] ?? '',
      tasksAssigned: json['tasksAssigned'] ?? 0,
      tasksCompleted: json['tasksCompleted'] ?? 0,
      loggedHours: json['loggedHours'] ?? 0,
      workload: (json['workload'] ?? 0).toDouble(),
      efficiency: (json['efficiency'] ?? 0).toDouble(),
      overloaded: json['overloaded'] ?? false,
    );
  }
}