package com.projectflow.backend.dto.response;

import com.projectflow.backend.domain.enums.Priority;
import com.projectflow.backend.domain.enums.TaskStatus;
import com.projectflow.backend.domain.enums.TaskType;
import lombok.Builder;
import lombok.Data;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Builder
public class TaskResponse {
    private Long id;
    private String title;
    private String description;
    private TaskStatus status;
    private Priority priority;
    private TaskType type;
    private Long projectId;
    private String projectName;
    private Long sprintId;
    private Long assigneeId;
    private String assigneeName;
    private Long reporterId;
    private String reporterName;
    private Long parentId;
    private Integer storyPoints;
    private Integer estimatedHours;
    private int loggedHours;
    private LocalDate dueDate;
    private boolean overdue;
    private boolean archived;
    private LocalDateTime createdAt;
}
