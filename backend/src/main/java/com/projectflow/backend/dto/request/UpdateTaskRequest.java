package com.projectflow.backend.dto.request;

import com.projectflow.backend.domain.enums.Priority;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;
import java.time.LocalDate;

@Data
public class UpdateTaskRequest {
    @NotBlank(message = "Titre obligatoire")
    private String title;
    private String description;
    private Priority priority;
    private Long assigneeId;
    private Integer storyPoints;
    private Integer estimatedHours;
    private LocalDate dueDate;
}
