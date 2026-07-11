package com.projectflow.backend.dto.response;

import lombok.Builder;
import lombok.Data;
import java.util.List;

@Data
@Builder
public class KpiDashboardResponse {
    private int totalProjects;
    private int totalTasks;
    private int completedTasks;
    private double completionRate;
    private int totalLoggedHours;
    private List<ProjectKpiResponse> projectKpis;
}
