package com.projectflow.backend.config;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import java.util.HashMap;
import java.util.Map;

@RestControllerAdvice
public class GlobalExceptionHandler {

    // 403 — ممنوع (دور غير مسموح أو ليس صاحب المورد)
    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<Map<String, String>> handleAccessDenied(AccessDeniedException ex) {
        return ResponseEntity.status(HttpStatus.FORBIDDEN).body(error(ex.getMessage()));
    }

    // 404 — أي رسالة فيها "non trouv" (non trouvé / non trouvée)
    @ExceptionHandler(RuntimeException.class)
    public ResponseEntity<Map<String, String>> handleRuntime(RuntimeException ex) {
        String message = ex.getMessage() != null ? ex.getMessage() : "Erreur inconnue";
        HttpStatus status = message.contains("non trouv")
            ? HttpStatus.NOT_FOUND
            : HttpStatus.BAD_REQUEST;
        return ResponseEntity.status(status).body(error(message));
    }

    private Map<String, String> error(String message) {
        Map<String, String> body = new HashMap<>();
        body.put("message", message);
        return body;
    }
}