package com.projectflow.backend.dto.response;

import lombok.Builder;
import lombok.Data;
import java.math.BigDecimal;

@Data
@Builder
public class ProjectKpiResponse {
    private Long projectId;
    private String projectName;
    private int totalTasks;
    private int completedTasks;
    private double completionRate;
    private int loggedHours;
    private BigDecimal laborCost;
    private BigDecimal budget;
    // null = pas assez de donnees pour un calcul fiable (pas de budget defini,
    // ou aucune heure enregistree) -- ne jamais deduire 100% par defaut.
    private Double profitability;
    private BigDecimal budgetVariance;
    private boolean onSchedule;
}
