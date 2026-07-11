package com.projectflow.backend.controller;

import com.projectflow.backend.dto.request.CreateTimeLogRequest;
import com.projectflow.backend.dto.response.TimeLogResponse;
import com.projectflow.backend.service.TimeLogService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/timelogs")
@RequiredArgsConstructor
public class TimeLogController {

    private final TimeLogService timeLogService;

    // POST /api/timelogs — تسجيل وقت جديد
    @PostMapping
    public ResponseEntity<TimeLogResponse> logTime(
            @Valid @RequestBody CreateTimeLogRequest request,
            @AuthenticationPrincipal UserDetails userDetails) {
        return ResponseEntity.ok(
            timeLogService.logTime(request, userDetails.getUsername()));
    }

    // GET /api/timelogs/my — سجلات الوقت للمستخدم الحالي
    @GetMapping("/my")
    public ResponseEntity<List<TimeLogResponse>> getMyTimeLogs(
            @AuthenticationPrincipal UserDetails userDetails) {
        return ResponseEntity.ok(
            timeLogService.getMyTimeLogs(userDetails.getUsername()));
    }

    // GET /api/timelogs/project/{projectId} — سجلات وقت مشروع
    @GetMapping("/project/{projectId}")
    public ResponseEntity<List<TimeLogResponse>> getByProject(
            @PathVariable Long projectId) {
        return ResponseEntity.ok(
            timeLogService.getTimeLogsByProject(projectId));
    }

    // GET /api/timelogs/task/{taskId} — سجلات وقت مهمة
    @GetMapping("/task/{taskId}")
    public ResponseEntity<List<TimeLogResponse>> getByTask(
            @PathVariable Long taskId) {
        return ResponseEntity.ok(
            timeLogService.getTimeLogsByTask(taskId));
    }

    // DELETE /api/timelogs/{id} — حذف سجل وقت
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteTimeLog(
            @PathVariable Long id,
            @AuthenticationPrincipal UserDetails userDetails) {
        timeLogService.deleteTimeLog(id, userDetails.getUsername());
        return ResponseEntity.noContent().build();
    }
}