class KpiDashboardModel {
  final int totalProjects;
  final int totalTasks;
  final int completedTasks;
  final double completionRate;
  final int totalLoggedHours;
  final double? totalBudget;
  final double? totalLaborCost;
  final double? totalBudgetVariance;
  // null = pas assez de donnees reelles (aucun budget defini ou aucune heure
  // enregistree sur l'ensemble des projets) : ne jamais afficher 100% par defaut.
  final double? globalProfitability;
  final List<ProjectKpiModel> projectKpis;

  KpiDashboardModel({
    required this.totalProjects,
    required this.totalTasks,
    required this.completedTasks,
    required this.completionRate,
    required this.totalLoggedHours,
    this.totalBudget,
    this.totalLaborCost,
    this.totalBudgetVariance,
    this.globalProfitability,
    required this.projectKpis,
  });

  factory KpiDashboardModel.fromJson(Map<String, dynamic> json) {
    return KpiDashboardModel(
      totalProjects: json['totalProjects'] ?? 0,
      totalTasks: json['totalTasks'] ?? 0,
      completedTasks: json['completedTasks'] ?? 0,
      completionRate: (json['completionRate'] ?? 0).toDouble(),
      totalLoggedHours: json['totalLoggedHours'] ?? 0,
      totalBudget: json['totalBudget']?.toDouble(),
      totalLaborCost: json['totalLaborCost']?.toDouble(),
      totalBudgetVariance: json['totalBudgetVariance']?.toDouble(),
      globalProfitability: json['globalProfitability']?.toDouble(),
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
  // null = pas assez de donnees reelles (pas de budget defini, ou aucune heure
  // enregistree) : jamais deduit a 100% par defaut, cf. KpiService (backend).
  final double? profitability;
  final bool onSchedule;
  final double? laborCost;
  final double? budget;
  final double? budgetVariance;

  ProjectKpiModel({
    required this.projectId,
    required this.projectName,
    required this.totalTasks,
    required this.completedTasks,
    required this.completionRate,
    required this.loggedHours,
    this.profitability,
    required this.onSchedule,
    this.laborCost,
    this.budget,
    this.budgetVariance,
  });

  factory ProjectKpiModel.fromJson(Map<String, dynamic> json) {
    return ProjectKpiModel(
      projectId: json['projectId'] ?? 0,
      projectName: json['projectName'] ?? '',
      totalTasks: json['totalTasks'] ?? 0,
      completedTasks: json['completedTasks'] ?? 0,
      completionRate: (json['completionRate'] ?? 0).toDouble(),
      loggedHours: json['loggedHours'] ?? 0,
      profitability: json['profitability']?.toDouble(),
      onSchedule: json['onSchedule'] ?? true,
      laborCost: json['laborCost']?.toDouble(),
      budget: json['budget']?.toDouble(),
      budgetVariance: json['budgetVariance']?.toDouble(),
    );
  }
}
