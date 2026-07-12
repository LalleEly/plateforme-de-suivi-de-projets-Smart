class ProjectModel {
  final int id;
  final String name;
  final String key;
  final String? description;
  final String status;
  final String ownerName;
  final int? ownerId;
  final double? budget;
  final double? hourlyRate;
  final int memberCount;
  final int taskCount;
  final int completedTaskCount;
  final bool archived;
  final String? createdAt;

  ProjectModel({
    required this.id,
    required this.name,
    required this.key,
    this.description,
    required this.status,
    required this.ownerName,
    this.ownerId,
    this.budget,
    this.hourlyRate,
    required this.memberCount,
    required this.taskCount,
    this.completedTaskCount = 0,
    this.archived = false,
    this.createdAt,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      key: json['key'] ?? '',
      description: json['description'],
      status: json['status'] ?? '',
      ownerName: json['ownerName'] ?? '',
      ownerId: json['ownerId'],
      budget: json['budget']?.toDouble(),
      hourlyRate: json['hourlyRate']?.toDouble(),
      memberCount: json['memberCount'] ?? 0,
      taskCount: json['taskCount'] ?? 0,
      completedTaskCount: json['completedTaskCount'] ?? 0,
      archived: json['archived'] ?? false,
      createdAt: json['createdAt'],
    );
  }

  // Egalite par id : evite les crashs de DropdownButton quand l'instance
  // selectionnee devient obsolete apres un refetch (nouvelle instance, meme id).
  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is ProjectModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
