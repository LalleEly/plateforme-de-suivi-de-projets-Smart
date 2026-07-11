package com.projectflow.backend.controller;

import com.projectflow.backend.dto.response.*;
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

    // KPIs : MANAGER (vue globale) أو CHEF_PROJET (فلترة على مشاريعه فقط، ديال KpiService)
    @PreAuthorize("hasAnyRole('MANAGER','CHEF_PROJET')")
    @GetMapping("/dashboard")
    public ResponseEntity<KpiDashboardResponse> getDashboard(
            @AuthenticationPrincipal UserDetails userDetails) {
        return ResponseEntity.ok(kpiService.getDashboard(userDetails.getUsername()));
    }

    // KPI مشروع واحد: MANAGER أو CHEF_PROJET، فحص ownership فالـ KpiService
    // (bloque un CHEF_PROJET qui devinerait l'id d'un projet qui n'est pas le sien)
    @PreAuthorize("hasAnyRole('MANAGER','CHEF_PROJET')")
    @GetMapping("/project/{projectId}")
    public ResponseEntity<ProjectKpiResponse> getProjectKpi(
            @PathVariable Long projectId,
            @AuthenticationPrincipal UserDetails userDetails) {
        return ResponseEntity.ok(
            kpiService.getProjectKpi(projectId, userDetails.getUsername()));
    }

    // KPI الأعضاء: MANAGER أو CHEF_PROJET، نفس فحص ownership
    @PreAuthorize("hasAnyRole('MANAGER','CHEF_PROJET')")
    @GetMapping("/members/{projectId}")
    public ResponseEntity<List<MemberKpiResponse>> getMemberKpis(
            @PathVariable Long projectId,
            @AuthenticationPrincipal UserDetails userDetails) {
        return ResponseEntity.ok(
            kpiService.getMemberKpis(projectId, userDetails.getUsername()));
    }
}