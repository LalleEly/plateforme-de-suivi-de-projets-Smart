package com.projectflow.backend.dto.request;

import com.projectflow.backend.domain.enums.GlobalRole;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class UpdateRoleRequest {
    @NotNull(message = "Le rôle est obligatoire")
    private GlobalRole role;
}
