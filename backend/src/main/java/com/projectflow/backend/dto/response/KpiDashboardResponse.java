package com.projectflow.backend.dto.response;

import lombok.Builder;
import lombok.Data;
import java.math.BigDecimal;
import java.util.List;

@Data
@Builder
public class KpiDashboardResponse {
    private int totalProjects;
    private int totalTasks;
    private int completedTasks;
    private double completionRate;
    private int totalLoggedHours;
    private BigDecimal totalBudget;
    private BigDecimal totalLaborCost;
    private BigDecimal totalBudgetVariance;
    // Calculee a partir des sommes budget/cout reel de tous les projets
    // (pas une simple moyenne des pourcentages projet par projet) ;
    // null si aucun budget defini ou aucune heure enregistree nulle part.
    private Double globalProfitability;
    private List<ProjectKpiResponse> projectKpis;
}
