package com.projectflow.backend.dto.response;

import com.projectflow.backend.domain.enums.ProjectStatus;
import lombok.Builder;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Builder
public class ProjectResponse {
    private Long id;
    private String name;
    private String key;
    private String description;
    private ProjectStatus status;
    private String ownerName;
    private Long ownerId;
    private LocalDate startDate;
    private LocalDate endDate;
    private BigDecimal budget;
    private BigDecimal hourlyRate;
    private int memberCount;
    private int taskCount;
    private boolean archived;
    private LocalDateTime createdAt;
}
