package com.projectflow.backend.controller;

import com.projectflow.backend.domain.enums.TaskStatus;
import com.projectflow.backend.dto.request.CreateTaskRequest;
import com.projectflow.backend.dto.request.UpdateTaskRequest;
import com.projectflow.backend.dto.response.TaskResponse;
import com.projectflow.backend.service.TaskService;
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
@RequestMapping("/tasks")
@RequiredArgsConstructor
public class TaskController {

    private final TaskService taskService;

    // إنشاء تاسك: MANAGER أو CHEF_PROJET فقط (MEMBRE ما يقدر يخلق تاسك)
    @PreAuthorize("hasAnyRole('MANAGER','CHEF_PROJET')")
    @PostMapping
    public ResponseEntity<TaskResponse> createTask(
            @Valid @RequestBody CreateTaskRequest request,
            @AuthenticationPrincipal UserDetails userDetails) {
        return ResponseEntity.ok(
            taskService.createTask(request, userDetails.getUsername()));
    }

    @GetMapping("/project/{projectId}")
    public ResponseEntity<List<TaskResponse>> getTasksByProject(
            @PathVariable Long projectId) {
        return ResponseEntity.ok(taskService.getTasksByProject(projectId));
    }

    @GetMapping("/my")
    public ResponseEntity<List<TaskResponse>> getMyTasks(
            @AuthenticationPrincipal UserDetails userDetails) {
        return ResponseEntity.ok(
            taskService.getMyTasks(userDetails.getUsername()));
    }

    @GetMapping("/{id}")
    public ResponseEntity<TaskResponse> getTaskById(@PathVariable Long id) {
        return ResponseEntity.ok(taskService.getTaskById(id));
    }

    // Tâches d'un membre précis : MANAGER (tous) ou CHEF_PROJET (membres de ses projets, filtré côté UI)
    @PreAuthorize("hasAnyRole('MANAGER','CHEF_PROJET')")
    @GetMapping("/user/{userId}")
    public ResponseEntity<List<TaskResponse>> getTasksByUser(@PathVariable Long userId) {
        return ResponseEntity.ok(taskService.getTasksByUser(userId));
    }

    // تحديث حالة تاسك: مفتوح للجميع، لكن MEMBRE يقدر غير يبدل تاسكاته هو (فحص فالـ Service)
    @PatchMapping("/{id}/status")
    public ResponseEntity<TaskResponse> updateStatus(
            @PathVariable Long id,
            @RequestParam TaskStatus status,
            @AuthenticationPrincipal UserDetails userDetails) {
        return ResponseEntity.ok(
            taskService.updateStatus(id, status, userDetails.getUsername()));
    }

    // PUT /api/tasks/{id} — MANAGER ou CHEF_PROJET de son propre projet (verifie dans le Service)
    @PreAuthorize("hasAnyRole('MANAGER','CHEF_PROJET')")
    @PutMapping("/{id}")
    public ResponseEntity<TaskResponse> updateTask(
            @PathVariable Long id,
            @Valid @RequestBody UpdateTaskRequest request,
            @AuthenticationPrincipal UserDetails userDetails) {
        return ResponseEntity.ok(
            taskService.updateTask(id, request, userDetails.getUsername()));
    }

    // DELETE /api/tasks/{id} — MANAGER ou CHEF_PROJET de son propre projet
    @PreAuthorize("hasAnyRole('MANAGER','CHEF_PROJET')")
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteTask(
            @PathVariable Long id,
            @AuthenticationPrincipal UserDetails userDetails) {
        taskService.deleteTask(id, userDetails.getUsername());
        return ResponseEntity.noContent().build();
    }

    // PATCH /api/tasks/{id}/archive — memes regles que la suppression
    @PreAuthorize("hasAnyRole('MANAGER','CHEF_PROJET')")
    @PatchMapping("/{id}/archive")
    public ResponseEntity<Map<String, String>> archiveTask(
            @PathVariable Long id,
            @RequestBody(required = false) Map<String, Boolean> body,
            @AuthenticationPrincipal UserDetails userDetails) {
        boolean archived = body == null || body.getOrDefault("archived", true);
        taskService.setArchived(id, archived, userDetails.getUsername());
        return ResponseEntity.ok(Map.of("message",
            archived ? "Tâche archivée" : "Tâche désarchivée"));
    }
}