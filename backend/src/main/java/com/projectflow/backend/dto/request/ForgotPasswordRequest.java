package com.projectflow.backend.dto.request;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class ForgotPasswordRequest {
    @Email(message = "Email invalide")
    @NotBlank(message = "Email obligatoire")
    private String email;
}
