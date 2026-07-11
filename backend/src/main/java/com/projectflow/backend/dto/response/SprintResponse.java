package com.projectflow.backend.dto.response;

import com.projectflow.backend.domain.enums.SprintStatus;
import lombok.Builder;
import lombok.Data;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Builder
public class SprintResponse {
    private Long id;
    private Long projectId;
    private String name;
    private Integer number;
    private SprintStatus status;
    private LocalDate startDate;
    private LocalDate endDate;
    private Integer goalPoints;
    private String goal;
    private long remainingDays;
    private int velocity;
    private int taskCount;
    private LocalDateTime createdAt;
}
