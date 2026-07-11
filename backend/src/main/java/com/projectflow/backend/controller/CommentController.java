package com.projectflow.backend.controller;

import com.projectflow.backend.dto.request.CommentRequest;
import com.projectflow.backend.dto.response.CommentResponse;
import com.projectflow.backend.service.CommentService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/comments")
@RequiredArgsConstructor
public class CommentController {

    private final CommentService commentService;

    @GetMapping("/task/{taskId}")
    public ResponseEntity<List<CommentResponse>> getCommentsByTask(
            @PathVariable Long taskId) {
        return ResponseEntity.ok(commentService.getCommentsByTask(taskId));
    }

    // Ajout ouvert a tous les authentifies : MEMBRE restreint a ses propres taches (verifie dans le service)
    @PostMapping
    public ResponseEntity<CommentResponse> addComment(
            @Valid @RequestBody CommentRequest request,
            @AuthenticationPrincipal UserDetails userDetails) {
        return ResponseEntity.ok(
            commentService.addComment(request, userDetails.getUsername()));
    }
}
