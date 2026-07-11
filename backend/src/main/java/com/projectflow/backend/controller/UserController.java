package com.projectflow.backend.controller;

import com.projectflow.backend.domain.entity.User;
import com.projectflow.backend.dto.request.ChangePasswordRequest;
import com.projectflow.backend.dto.response.UserResponse;
import com.projectflow.backend.repository.UserRepository;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/users")
@RequiredArgsConstructor
public class UserController {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    // GET /api/users — فقط MANAGER يقدر يشوف كل المستخدمين (Gérer les utilisateurs)
    @PreAuthorize("hasRole('MANAGER')")
    @GetMapping
    public ResponseEntity<List<UserResponse>> getAllUsers() {
        List<UserResponse> users = userRepository.findAll()
            .stream()
            .map(this::toResponse)
            .collect(Collectors.toList());
        return ResponseEntity.ok(users);
    }

    // GET /api/users/me — كل المستخدمين المسجلين يقدروا يشوفوا بياناتهم
    @GetMapping("/me")
    public ResponseEntity<UserResponse> getCurrentUser(
            @AuthenticationPrincipal UserDetails userDetails) {
        User user = userRepository.findByEmail(userDetails.getUsername())
            .orElseThrow(() -> new RuntimeException("Utilisateur non trouvé"));
        return ResponseEntity.ok(toResponse(user));
    }

    // GET /api/users/{id} — فقط MANAGER (يستعملها مثلاً عند إضافة عضو لمشروع)
    @PreAuthorize("hasRole('MANAGER')")
    @GetMapping("/{id}")
    public ResponseEntity<UserResponse> getUserById(@PathVariable Long id) {
        User user = userRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Utilisateur non trouvé : " + id));
        return ResponseEntity.ok(toResponse(user));
    }

    // PUT /api/users/me/password — l'utilisateur change son propre mot de passe
    @PutMapping("/me/password")
    public ResponseEntity<Map<String, String>> changePassword(
            @AuthenticationPrincipal UserDetails userDetails,
            @Valid @RequestBody ChangePasswordRequest request) {
        User user = userRepository.findByEmail(userDetails.getUsername())
            .orElseThrow(() -> new RuntimeException("Utilisateur non trouvé"));

        if (!passwordEncoder.matches(request.getOldPassword(), user.getPasswordHash())) {
            throw new RuntimeException("Ancien mot de passe incorrect");
        }

        user.setPasswordHash(passwordEncoder.encode(request.getNewPassword()));
        userRepository.save(user);
        return ResponseEntity.ok(Map.of("message", "Mot de passe mis à jour avec succès"));
    }

    private UserResponse toResponse(User u) {
        return UserResponse.builder()
            .id(u.getId())
            .firstName(u.getFirstName())
            .lastName(u.getLastName())
            .fullName(u.getFullName())
            .email(u.getEmail())
            .globalRole(u.getGlobalRole())
            .active(u.isActive())
            .createdAt(u.getCreatedAt())
            .build();
    }
}