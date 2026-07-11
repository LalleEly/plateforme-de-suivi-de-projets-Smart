package com.projectflow.backend.controller;

import com.projectflow.backend.dto.request.SprintRequest;
import com.projectflow.backend.dto.response.SprintResponse;
import com.projectflow.backend.service.SprintService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/sprints")
@RequiredArgsConstructor
public class SprintController {

    private final SprintService sprintService;

    // Lecture ouverte a tous les authentifies (MEMBRE : lecture seule)
    @GetMapping("/project/{projectId}")
    public ResponseEntity<List<SprintResponse>> getSprintsByProject(
            @PathVariable Long projectId) {
        return ResponseEntity.ok(sprintService.getSprintsByProject(projectId));
    }

    @PreAuthorize("hasAnyRole('MANAGER','CHEF_PROJET')")
    @PostMapping
    public ResponseEntity<SprintResponse> createSprint(
            @Valid @RequestBody SprintRequest request,
            @AuthenticationPrincipal UserDetails userDetails) {
        return ResponseEntity.ok(
            sprintService.createSprint(request, userDetails.getUsername()));
    }

    @PreAuthorize("hasAnyRole('MANAGER','CHEF_PROJET')")
    @PutMapping("/{id}")
    public ResponseEntity<SprintResponse> updateSprint(
            @PathVariable Long id,
            @Valid @RequestBody SprintRequest request,
            @AuthenticationPrincipal UserDetails userDetails) {
        return ResponseEntity.ok(
            sprintService.updateSprint(id, request, userDetails.getUsername()));
    }

    @PreAuthorize("hasAnyRole('MANAGER','CHEF_PROJET')")
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteSprint(
            @PathVariable Long id,
            @AuthenticationPrincipal UserDetails userDetails) {
        sprintService.deleteSprint(id, userDetails.getUsername());
        return ResponseEntity.noContent().build();
    }
}
