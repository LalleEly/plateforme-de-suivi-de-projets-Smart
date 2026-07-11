package com.projectflow.backend.controller;

import com.projectflow.backend.domain.entity.Project;
import com.projectflow.backend.dto.response.*;
import com.projectflow.backend.repository.ProjectRepository;
import com.projectflow.backend.service.KpiService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/kpi")
@RequiredArgsConstructor
public class KpiController {

    private final KpiService kpiService;
    private final ProjectRepository projectRepository;

    // KPIs : MANAGER (vue globale) أو CHEF_PROJET (فلترة على مشاريعه فقط، ديال KpiService)
    @PreAuthorize("hasAnyRole('MANAGER','CHEF_PROJET')")
    @GetMapping("/dashboard")
    public ResponseEntity<KpiDashboardResponse> getDashboard(
            @AuthenticationPrincipal UserDetails userDetails) {
        return ResponseEntity.ok(kpiService.getDashboard(userDetails.getUsername()));
    }

    // KPI مشروع واحد: MANAGER أو CHEF_PROJET (فحص ownership فالـ KpiService مستقبلًا إذا تحتاج)
    @PreAuthorize("hasAnyRole('MANAGER','CHEF_PROJET')")
    @GetMapping("/project/{projectId}")
    public ResponseEntity<ProjectKpiResponse> getProjectKpi(
            @PathVariable Long projectId) {
        Project project = projectRepository.findById(projectId)
            .orElseThrow(() -> new RuntimeException("Projet non trouve"));
        return ResponseEntity.ok(kpiService.calculateProjectKpi(project));
    }

    // KPI الأعضاء: MANAGER أو CHEF_PROJET
    @PreAuthorize("hasAnyRole('MANAGER','CHEF_PROJET')")
    @GetMapping("/members/{projectId}")
    public ResponseEntity<List<MemberKpiResponse>> getMemberKpis(
            @PathVariable Long projectId) {
        return ResponseEntity.ok(kpiService.getMemberKpis(projectId));
    }
}