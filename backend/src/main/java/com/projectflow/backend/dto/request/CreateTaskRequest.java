package com.projectflow.backend.dto.request;

import com.projectflow.backend.domain.enums.Priority;
import com.projectflow.backend.domain.enums.TaskType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;
import java.time.LocalDate;

@Data
public class CreateTaskRequest {
    @NotBlank(message = "Titre obligatoire")
    private String title;
    private String description;
    @NotNull(message = "Projet obligatoire")
    private Long projectId;
    private Long sprintId;
    private Long assigneeId;
    private Long parentId;
    private Priority priority = Priority.MEDIUM;
    private TaskType type = TaskType.TASK;
    private Integer storyPoints;
    private Integer estimatedHours;
    private LocalDate dueDate;
}
