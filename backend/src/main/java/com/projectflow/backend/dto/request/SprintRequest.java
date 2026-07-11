package com.projectflow.backend.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;
import java.time.LocalDate;

@Data
public class SprintRequest {
    @NotNull(message = "Projet obligatoire")
    private Long projectId;
    @NotBlank(message = "Nom obligatoire")
    private String name;
    @NotNull(message = "Numero obligatoire")
    private Integer number;
    private LocalDate startDate;
    private LocalDate endDate;
    private Integer goalPoints;
    private String goal;
}
