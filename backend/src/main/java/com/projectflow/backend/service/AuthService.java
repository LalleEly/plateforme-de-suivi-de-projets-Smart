package com.projectflow.backend.service;

import com.projectflow.backend.domain.entity.PasswordResetToken;
import com.projectflow.backend.domain.entity.User;
import com.projectflow.backend.domain.enums.GlobalRole;
import com.projectflow.backend.dto.request.ForgotPasswordRequest;
import com.projectflow.backend.dto.request.LoginRequest;
import com.projectflow.backend.dto.request.RegisterRequest;
import com.projectflow.backend.dto.request.ResetPasswordRequest;
import com.projectflow.backend.dto.response.AuthResponse;
import com.projectflow.backend.repository.PasswordResetTokenRepository;
import com.projectflow.backend.repository.UserRepository;
import com.projectflow.backend.security.JwtTokenProvider;
import lombok.RequiredArgsConstructor;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.security.SecureRandom;
import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider jwtTokenProvider;
    private final AuthenticationManager authenticationManager;
    private final PasswordResetTokenRepository passwordResetTokenRepository;
    private final JavaMailSender mailSender;

    private static final SecureRandom RESET_CODE_RANDOM = new SecureRandom();

    public AuthResponse register(RegisterRequest request) {
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new RuntimeException("Email deja utilise : " + request.getEmail());
        }
        User user = User.builder()
            .firstName(request.getFirstName())
            .lastName(request.getLastName())
            .email(request.getEmail())
            .passwordHash(passwordEncoder.encode(request.getPassword()))
            .globalRole(GlobalRole.MEMBRE)
            .active(true)
            .build();
        userRepository.save(user);
        String accessToken = jwtTokenProvider.generateAccessToken(user.getEmail());
        String refreshToken = jwtTokenProvider.generateRefreshToken(user.getEmail());
        return AuthResponse.builder()
            .accessToken(accessToken)
            .refreshToken(refreshToken)
            .tokenType("Bearer")
            .userId(user.getId())
            .email(user.getEmail())
            .firstName(user.getFirstName())
            .lastName(user.getLastName())
            .globalRole(user.getGlobalRole().name())
            .build();
    }

    public AuthResponse login(LoginRequest request) {
        authenticationManager.authenticate(
            new UsernamePasswordAuthenticationToken(
                request.getEmail(), request.getPassword()));
        User user = userRepository.findByEmail(request.getEmail())
            .orElseThrow(() -> new RuntimeException("Utilisateur non trouve"));
        String accessToken = jwtTokenProvider.generateAccessToken(user.getEmail());
        String refreshToken = jwtTokenProvider.generateRefreshToken(user.getEmail());
        return AuthResponse.builder()
            .accessToken(accessToken)
            .refreshToken(refreshToken)
            .tokenType("Bearer")
            .userId(user.getId())
            .email(user.getEmail())
            .firstName(user.getFirstName())
            .lastName(user.getLastName())
            .globalRole(user.getGlobalRole().name())
            .build();
    }

    public void forgotPassword(ForgotPasswordRequest request) {
        User user = userRepository.findByEmail(request.getEmail())
            .orElseThrow(() -> new RuntimeException("Utilisateur non trouve"));

        passwordResetTokenRepository.deleteByUser(user);

        String code = generateResetCode();
        PasswordResetToken resetToken = PasswordResetToken.builder()
            .token(code)
            .user(user)
            .expiryDate(LocalDateTime.now().plusMinutes(15))
            .build();
        passwordResetTokenRepository.save(resetToken);

        SimpleMailMessage message = new SimpleMailMessage();
        message.setTo(user.getEmail());
        message.setSubject("ProjectFlow - Reinitialisation de mot de passe");
        message.setText("Bonjour " + user.getFirstName() + ",\n\n"
            + "Voici votre code de reinitialisation de mot de passe : " + code + "\n"
            + "Ce code expire dans 15 minutes.\n\n"
            + "Si vous n'etes pas a l'origine de cette demande, ignorez cet email.");
        mailSender.send(message);
    }

    public void resetPassword(ResetPasswordRequest request) {
        PasswordResetToken resetToken = passwordResetTokenRepository.findByToken(request.getToken())
            .orElseThrow(() -> new RuntimeException("Code de reinitialisation invalide"));

        if (resetToken.isExpired()) {
            passwordResetTokenRepository.delete(resetToken);
            throw new RuntimeException("Code de reinitialisation expire");
        }

        User user = resetToken.getUser();
        user.setPasswordHash(passwordEncoder.encode(request.getNewPassword()));
        userRepository.save(user);
        passwordResetTokenRepository.delete(resetToken);
    }

    private String generateResetCode() {
        int code = RESET_CODE_RANDOM.nextInt(1_000_000);
        return String.format("%06d", code);
    }
}