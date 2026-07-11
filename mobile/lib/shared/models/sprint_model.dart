class SprintModel {
  final int id;
  final int projectId;
  final String name;
  final int number;
  final String status;
  final String? startDate;
  final String? endDate;
  final int? goalPoints;
  final String? goal;
  final int remainingDays;
  final int velocity;
  final int taskCount;

  SprintModel({
    required this.id,
    required this.projectId,
    required this.name,
    required this.number,
    required this.status,
    this.startDate,
    this.endDate,
    this.goalPoints,
    this.goal,
    required this.remainingDays,
    required this.velocity,
    required this.taskCount,
  });

  factory SprintModel.fromJson(Map<String, dynamic> json) {
    return SprintModel(
      id: json['id'] ?? 0,
      projectId: json['projectId'] ?? 0,
      name: json['name'] ?? '',
      number: json['number'] ?? 0,
      status: json['status'] ?? 'PLANNING',
      startDate: json['startDate'],
      endDate: json['endDate'],
      goalPoints: json['goalPoints'],
      goal: json['goal'],
      remainingDays: json['remainingDays'] ?? 0,
      velocity: json['velocity'] ?? 0,
      taskCount: json['taskCount'] ?? 0,
    );
  }
}
