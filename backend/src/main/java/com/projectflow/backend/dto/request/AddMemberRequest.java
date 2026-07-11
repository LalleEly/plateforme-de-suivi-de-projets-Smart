package com.projectflow.backend.dto.request;

import com.projectflow.backend.domain.enums.ProjectRole;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class AddMemberRequest {

    @NotNull(message = "L'utilisateur est obligatoire")
    private Long userId;

    @NotNull(message = "Le rôle est obligatoire")
    private ProjectRole role;
}