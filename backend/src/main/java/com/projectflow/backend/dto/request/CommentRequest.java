package com.projectflow.backend.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class CommentRequest {
    @NotNull(message = "Tache obligatoire")
    private Long taskId;
    @NotBlank(message = "Contenu obligatoire")
    private String content;
    private Long parentId;
}
