package com.projectflow.backend.service;

import com.projectflow.backend.domain.entity.*;
import com.projectflow.backend.domain.enums.GlobalRole;
import com.projectflow.backend.domain.enums.TaskStatus;
import com.projectflow.backend.dto.response.*;
import com.projectflow.backend.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class KpiService {

    private final ProjectRepository projectRepository;
    private final TaskRepository taskRepository;
    private final TimeLogRepository timeLogRepository;
    private final UserRepository userRepository;
    private final ProjectMemberRepository memberRepository;

    // MANAGER يشوف KPI ديال كل المشاريع (vue globale)
    // CHEF_PROJET يشوف غير KPI ديال المشاريع لي هو owner فيها أو member فيها
    public KpiDashboardResponse getDashboard(String username) {
        User current = userRepository.findByEmail(username)
            .orElseThrow(() -> new RuntimeException("Utilisateur non trouve"));

        List<Project> projects;
        if (current.getGlobalRole() == GlobalRole.MANAGER) {
            projects = projectRepository.findAll();
        } else {
            Map<Long, Project> merged = new LinkedHashMap<>();
            for (Project p : projectRepository.findByOwner_Id(current.getId())) {
                merged.put(p.getId(), p);
            }
            for (Project p : projectRepository.findByMembers_User_Id(current.getId())) {
                merged.put(p.getId(), p);
            }
            projects = List.copyOf(merged.values());
        }

        List<Task> tasks = projects.stream()
            .flatMap(p -> taskRepository.findByProject_Id(p.getId()).stream())
            .collect(Collectors.toList());
        long completed = tasks.stream()
            .filter(t -> t.getStatus() == TaskStatus.DONE).count();
        int totalMinutes = projects.stream()
            .mapToInt(p -> timeLogRepository.sumMinutesByProjectId(p.getId()))
            .sum();
        double rate = tasks.isEmpty() ? 0 :
            Math.round((double) completed / tasks.size() * 10000.0) / 100.0;
        List<ProjectKpiResponse> projectKpis = projects.stream()
            .map(this::calculateProjectKpi).collect(Collectors.toList());
        return KpiDashboardResponse.builder()
            .totalProjects(projects.size())
            .totalTasks(tasks.size())
            .completedTasks((int) completed)
            .completionRate(rate)
            .totalLoggedHours(totalMinutes / 60)
            .projectKpis(projectKpis)
            .build();
    }

    // MANAGER : n'importe quel projet. CHEF_PROJET : uniquement ses projets
    // (owner/membre) — sans ca, un CHEF_PROJET pouvait lire le KPI/les stats
    // de n'importe quel projet en devinant son id (aucune verification avant).
    private void checkProjectAccess(Long projectId, String username) {
        User current = userRepository.findByEmail(username)
            .orElseThrow(() -> new RuntimeException("Utilisateur non trouve"));
        if (current.getGlobalRole() == GlobalRole.MANAGER) return;

        Project project = projectRepository.findById(projectId)
            .orElseThrow(() -> new RuntimeException("Projet non trouve"));
        boolean isOwnerOrMember = project.getOwner().getId().equals(current.getId())
            || memberRepository.existsByUser_IdAndProject_Id(current.getId(), projectId);
        if (!isOwnerOrMember) {
            throw new AccessDeniedException(
                "Vous n'êtes pas autorisé à consulter ce projet.");
        }
    }

    public ProjectKpiResponse getProjectKpi(Long projectId, String username) {
        checkProjectAccess(projectId, username);
        Project project = projectRepository.findById(projectId)
            .orElseThrow(() -> new RuntimeException("Projet non trouve"));
        return calculateProjectKpi(project);
    }

    public ProjectKpiResponse calculateProjectKpi(Project project) {
        List<Task> tasks = taskRepository.findByProject_Id(project.getId());
        long completed = tasks.stream()
            .filter(t -> t.getStatus() == TaskStatus.DONE).count();
        double rate = tasks.isEmpty() ? 0 :
            Math.round((double) completed / tasks.size() * 10000.0) / 100.0;
        int totalMinutes = timeLogRepository.sumMinutesByProjectId(project.getId());
        double hours = totalMinutes / 60.0;
        BigDecimal rate2 = project.getHourlyRate() != null ?
            project.getHourlyRate() : BigDecimal.ZERO;
        BigDecimal laborCost = BigDecimal.valueOf(hours)
            .multiply(rate2).setScale(2, RoundingMode.HALF_UP);
        double profitability = 0;
        if (project.getBudget() != null &&
            project.getBudget().compareTo(BigDecimal.ZERO) > 0) {
            BigDecimal margin = project.getBudget().subtract(laborCost);
            profitability = margin.divide(project.getBudget(), 4, RoundingMode.HALF_UP)
                .multiply(BigDecimal.valueOf(100))
                .setScale(2, RoundingMode.HALF_UP).doubleValue();
        }
        return ProjectKpiResponse.builder()
            .projectId(project.getId())
            .projectName(project.getName())
            .totalTasks(tasks.size())
            .completedTasks((int) completed)
            .completionRate(rate)
            .loggedHours((int) hours)
            .laborCost(laborCost)
            .budget(project.getBudget())
            .profitability(profitability)
            .onSchedule(project.isOnSchedule())
            .build();
    }

    public List<MemberKpiResponse> getMemberKpis(Long projectId, String username) {
        checkProjectAccess(projectId, username);

        // Union des ProjectMember officiels + de quiconque a une tache assignee
        // dans ce projet : un owner solo qui n'a jamais ete ajoute comme membre
        // (cas frequent avant l'ajout automatique a la creation) aurait sinon
        // une liste vide malgre du vrai travail assigne.
        List<Task> projectTasks = taskRepository.findByProject_Id(projectId);

        Map<Long, User> users = new LinkedHashMap<>();
        for (ProjectMember pm : memberRepository.findByProject_Id(projectId)) {
            users.put(pm.getUser().getId(), pm.getUser());
        }
        for (Task t : projectTasks) {
            if (t.getAssignee() != null) {
                users.put(t.getAssignee().getId(), t.getAssignee());
            }
        }

        return users.values().stream().map(user -> {
            List<Task> assigned = taskRepository.findByProject_IdAndAssignee_Id(
                projectId, user.getId());
            long completed = assigned.stream()
                .filter(t -> t.getStatus() == TaskStatus.DONE).count();
            int minutes = timeLogRepository.sumMinutesByUserIdAndProjectId(
                user.getId(), projectId);
            int hours = minutes / 60;
            int capacity = 40;
            double workload = Math.min(Math.round(hours * 100.0 / capacity), 100);
            double efficiency = assigned.isEmpty() ? 0 :
                Math.round((double) completed / assigned.size() * 10000.0) / 100.0;
            return MemberKpiResponse.builder()
                .userId(user.getId())
                .memberName(user.getFullName())
                .tasksAssigned(assigned.size())
                .tasksCompleted((int) completed)
                .loggedHours(hours)
                .workload(workload)
                .efficiency(efficiency)
                .overloaded(workload > 90)
                .build();
        }).collect(Collectors.toList());
    }
}
