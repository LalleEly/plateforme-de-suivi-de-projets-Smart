package com.projectflow.backend.dto.request;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.Data;
import java.time.LocalDate;

@Data
public class CreateTimeLogRequest {

    @NotNull(message = "La tâche est obligatoire")
    private Long taskId;

    @NotNull(message = "La durée est obligatoire")
    @Min(value = 1, message = "Minimum 1 minute")
    private Integer minutes;

    @NotNull(message = "La date est obligatoire")
    private LocalDate date;

    private String description;
}