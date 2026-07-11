class TaskModel {
  final int id;
  final String title;
  final String? description;
  final String status;
  final String priority;
  final String type;
  final int projectId;
  final String projectName;
  final int? assigneeId;
  final String? assigneeName;
  final int? storyPoints;
  final int? estimatedHours;
  final int loggedHours;
  final bool overdue;
  final bool archived;
  final String? dueDate;
  final String? createdAt;

  TaskModel({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    required this.type,
    required this.projectId,
    required this.projectName,
    this.assigneeId,
    this.assigneeName,
    this.storyPoints,
    this.estimatedHours,
    required this.loggedHours,
    required this.overdue,
    this.archived = false,
    this.dueDate,
    this.createdAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      status: json['status'] ?? '',
      priority: json['priority'] ?? '',
      type: json['type'] ?? '',
      projectId: json['projectId'] ?? 0,
      projectName: json['projectName'] ?? '',
      assigneeId: json['assigneeId'],
      assigneeName: json['assigneeName'],
      storyPoints: json['storyPoints'],
      estimatedHours: json['estimatedHours'],
      loggedHours: json['loggedHours'] ?? 0,
      overdue: json['overdue'] ?? false,
      archived: json['archived'] ?? false,
      dueDate: json['dueDate'],
      createdAt: json['createdAt'],
    );
  }

  // Egalite par id : evite les crashs de DropdownButton quand l'instance
  // selectionnee devient obsolete apres un refetch (nouvelle instance, meme id).
  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is TaskModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
