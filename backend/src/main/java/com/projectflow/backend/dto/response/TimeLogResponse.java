package com.projectflow.backend.dto.response;

import lombok.Builder;
import lombok.Data;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Builder
public class TimeLogResponse {
    private Long id;
    private Long taskId;
    private String taskTitle;
    private Long projectId;
    private String projectName;
    private Long userId;
    private String userName;
    private LocalDate date;
    private Integer minutes;
    private String description;
    private LocalDateTime createdAt;
}