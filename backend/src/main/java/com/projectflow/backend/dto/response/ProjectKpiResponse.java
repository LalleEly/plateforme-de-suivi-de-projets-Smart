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
    private double profitability;
    private boolean onSchedule;
}
