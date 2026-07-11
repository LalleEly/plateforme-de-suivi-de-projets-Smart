package com.projectflow.backend.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDate;

@Data
public class CreateProjectRequest {
    @NotBlank(message = "Nom obligatoire")
    private String name;
    @NotBlank(message = "Cle obligatoire")
    @Size(max = 10, message = "Max 10 caracteres")
    private String key;
    private String description;
    // Utilisateur assigne comme chef de projet (lead/owner) : seul un MANAGER
    // cree des projets desormais, il doit donc toujours designer qui le dirige.
    @NotNull(message = "Chef de projet obligatoire")
    private Long ownerId;
    private LocalDate startDate;
    private LocalDate endDate;
    private BigDecimal budget;
    private BigDecimal hourlyRate;
}
