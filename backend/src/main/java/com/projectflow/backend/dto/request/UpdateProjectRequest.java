package com.projectflow.backend.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDate;

@Data
public class UpdateProjectRequest {
    @NotBlank(message = "Nom obligatoire")
    private String name;
    @NotBlank(message = "Cle obligatoire")
    @Size(max = 10, message = "Max 10 caracteres")
    private String key;
    private String description;
    private LocalDate startDate;
    private LocalDate endDate;
    private BigDecimal budget;
    private BigDecimal hourlyRate;
}
