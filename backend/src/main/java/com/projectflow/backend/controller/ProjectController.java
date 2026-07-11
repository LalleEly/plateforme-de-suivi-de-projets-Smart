package com.projectflow.backend.controller;

import com.projectflow.backend.dto.request.AddMemberRequest;
import com.projectflow.backend.dto.request.CreateProjectRequest;
import com.projectflow.backend.dto.request.UpdateProjectRequest;
import com.projectflow.backend.dto.response.ProjectResponse;
import com.projectflow.backend.dto.response.UserResponse;
import com.projectflow.backend.service.ProjectService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/projects")
@RequiredArgsConstructor
public class ProjectController {

    private final ProjectService projectService;

    // POST /api/projects — إنشاء مشروع: MANAGER أو CHEF_PROJET فقط
    @PreAuthorize("hasAnyRole('MANAGER','CHEF_PROJET')")
    @PostMapping
    public ResponseEntity<ProjectResponse> createProject(
            @Valid @RequestBody CreateProjectRequest request,
            @AuthenticationPrincipal UserDetails userDetails) {
        return ResponseEntity.ok(
            projectService.createProject(request, userDetails.getUsername()));
    }

    // GET /api/projects — دابا مفلترة حسب الدور (MANAGER كلشي، الباقي غير مشاريعهم)
    // includeArchived=true : necessaire pour l'onglet "Archives" de l'ecran Projets.
    @GetMapping
    public ResponseEntity<List<ProjectResponse>> getAllProjects(
            @RequestParam(required = false, defaultValue = "false") boolean includeArchived,
            @AuthenticationPrincipal UserDetails userDetails) {
        return ResponseEntity.ok(
            projectService.getAllProjects(userDetails.getUsername(), includeArchived));
    }

    @GetMapping("/my")
    public ResponseEntity<List<ProjectResponse>> getMyProjects(
            @AuthenticationPrincipal UserDetails userDetails) {
        return ResponseEntity.ok(
            projectService.getMyProjects(userDetails.getUsername()));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ProjectResponse> getProjectById(@PathVariable Long id) {
        return ResponseEntity.ok(projectService.getProjectById(id));
    }

    // DELETE /api/projects/{id} — MANAGER أو CHEF_PROJET (فحص الملكية الدقيق فالـ Service)
    @PreAuthorize("hasAnyRole('MANAGER','CHEF_PROJET')")
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteProject(
            @PathVariable Long id,
            @AuthenticationPrincipal UserDetails userDetails) {
        projectService.deleteProject(id, userDetails.getUsername());
        return ResponseEntity.noContent().build();
    }

    // PUT /api/projects/{id} — MANAGER أو CHEF_PROJET (فحص الملكية الدقيق فالـ Service)
    @PreAuthorize("hasAnyRole('MANAGER','CHEF_PROJET')")
    @PutMapping("/{id}")
    public ResponseEntity<ProjectResponse> updateProject(
            @PathVariable Long id,
            @Valid @RequestBody UpdateProjectRequest request,
            @AuthenticationPrincipal UserDetails userDetails) {
        return ResponseEntity.ok(
            projectService.updateProject(id, request, userDetails.getUsername()));
    }

    // PATCH /api/projects/{id}/archive — memes regles que la suppression
    @PreAuthorize("hasAnyRole('MANAGER','CHEF_PROJET')")
    @PatchMapping("/{id}/archive")
    public ResponseEntity<Map<String, String>> archiveProject(
            @PathVariable Long id,
            @RequestBody(required = false) Map<String, Boolean> body,
            @AuthenticationPrincipal UserDetails userDetails) {
        boolean archived = body == null || body.getOrDefault("archived", true);
        projectService.setArchived(id, archived, userDetails.getUsername());
        return ResponseEntity.ok(Map.of("message",
            archived ? "Projet archivé" : "Projet désarchivé"));
    }

    @GetMapping("/{id}/members")
    public ResponseEntity<List<UserResponse>> getProjectMembers(
            @PathVariable Long id) {
        return ResponseEntity.ok(projectService.getProjectMembers(id));
    }

    // POST /api/projects/{id}/members — MANAGER أو CHEF_PROJET
    @PreAuthorize("hasAnyRole('MANAGER','CHEF_PROJET')")
    @PostMapping("/{id}/members")
    public ResponseEntity<Void> addMember(
            @PathVariable Long id,
            @Valid @RequestBody AddMemberRequest request,
            @AuthenticationPrincipal UserDetails userDetails) {
        projectService.addMember(id, request, userDetails.getUsername());
        return ResponseEntity.ok().build();
    }

    // DELETE /api/projects/{id}/members/{userId} — MANAGER أو CHEF_PROJET
    @PreAuthorize("hasAnyRole('MANAGER','CHEF_PROJET')")
    @DeleteMapping("/{id}/members/{userId}")
    public ResponseEntity<Void> removeMember(
            @PathVariable Long id,
            @PathVariable Long userId,
            @AuthenticationPrincipal UserDetails userDetails) {
        projectService.removeMember(id, userId, userDetails.getUsername());
        return ResponseEntity.noContent().build();
    }
}