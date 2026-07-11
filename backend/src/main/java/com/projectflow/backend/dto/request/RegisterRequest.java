package com.projectflow.backend.dto.request;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class RegisterRequest {
    @NotBlank(message = "Prenom obligatoire")
    private String firstName;
    @NotBlank(message = "Nom obligatoire")
    private String lastName;
    @Email(message = "Email invalide")
    @NotBlank(message = "Email obligatoire")
    private String email;
    @NotBlank(message = "Mot de passe obligatoire")
    @Size(min = 6, message = "Minimum 6 caracteres")
    private String password;
}
