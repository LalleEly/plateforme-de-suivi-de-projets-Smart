package com.projectflow.backend.dto.response;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class MemberKpiResponse {
    private Long userId;
    private String memberName;
    private int tasksAssigned;
    private int tasksCompleted;
    private int loggedHours;
    private double workload;
    private double efficiency;
    private boolean overloaded;
}
