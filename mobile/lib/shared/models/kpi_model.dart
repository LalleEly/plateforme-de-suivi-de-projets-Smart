class KpiDashboardModel {
  final int totalProjects;
  final int totalTasks;
  final int completedTasks;
  final double completionRate;
  final int totalLoggedHours;
  final List<ProjectKpiModel> projectKpis;

  KpiDashboardModel({
    required this.totalProjects,
    required this.totalTasks,
    required this.completedTasks,
    required this.completionRate,
    required this.totalLoggedHours,
    required this.projectKpis,
  });

  factory KpiDashboardModel.fromJson(Map<String, dynamic> json) {
    return KpiDashboardModel(
      totalProjects: json['totalProjects'] ?? 0,
      totalTasks: json['totalTasks'] ?? 0,
      completedTasks: json['completedTasks'] ?? 0,
      completionRate: (json['completionRate'] ?? 0).toDouble(),
      totalLoggedHours: json['totalLoggedHours'] ?? 0,
      projectKpis: (json['projectKpis'] as List? ?? [])
          .map((e) => ProjectKpiModel.fromJson(e)).toList(),
    );
  }
}

class ProjectKpiModel {
  final int projectId;
  final String projectName;
  final int totalTasks;
  final int completedTasks;
  final double completionRate;
  final int loggedHours;
  final double profitability;
  final bool onSchedule;
  final double? laborCost;
  final double? budget;

  ProjectKpiModel({
    required this.projectId,
    required this.projectName,
    required this.totalTasks,
    required this.completedTasks,
    required this.completionRate,
    required this.loggedHours,
    required this.profitability,
    required this.onSchedule,
    this.laborCost,
    this.budget,
  });

  factory ProjectKpiModel.fromJson(Map<String, dynamic> json) {
    return ProjectKpiModel(
      projectId: json['projectId'] ?? 0,
      projectName: json['projectName'] ?? '',
      totalTasks: json['totalTasks'] ?? 0,
      completedTasks: json['completedTasks'] ?? 0,
      completionRate: (json['completionRate'] ?? 0).toDouble(),
      loggedHours: json['loggedHours'] ?? 0,
      profitability: (json['profitability'] ?? 0).toDouble(),
      onSchedule: json['onSchedule'] ?? true,
      laborCost: json['laborCost']?.toDouble(),
      budget: json['budget']?.toDouble(),
    );
  }
}
