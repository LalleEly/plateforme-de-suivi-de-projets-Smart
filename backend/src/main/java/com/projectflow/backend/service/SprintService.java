package com.projectflow.backend.service;

import com.projectflow.backend.domain.entity.Project;
import com.projectflow.backend.domain.entity.Sprint;
import com.projectflow.backend.domain.entity.User;
import com.projectflow.backend.domain.enums.GlobalRole;
import com.projectflow.backend.dto.request.SprintRequest;
import com.projectflow.backend.dto.response.SprintResponse;
import com.projectflow.backend.repository.ProjectMemberRepository;
import com.projectflow.backend.repository.ProjectRepository;
import com.projectflow.backend.repository.SprintRepository;
import com.projectflow.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class SprintService {

    private final SprintRepository sprintRepository;
    private final ProjectRepository projectRepository;
    private final UserRepository userRepository;
    private final ProjectMemberRepository projectMemberRepository;

    public List<SprintResponse> getSprintsByProject(Long projectId) {
        return sprintRepository.findByProject_Id(projectId)
            .stream().map(this::toResponse).collect(Collectors.toList());
    }

    public SprintResponse createSprint(SprintRequest request, String username) {
        Project project = projectRepository.findById(request.getProjectId())
            .orElseThrow(() -> new RuntimeException("Projet non trouve"));
        checkManageRights(project, username);

        Sprint sprint = Sprint.builder()
            .project(project)
            .name(request.getName())
            .number(request.getNumber())
            .startDate(request.getStartDate())
            .endDate(request.getEndDate())
            .goalPoints(request.getGoalPoints())
            .goal(request.getGoal())
            .build();
        return toResponse(sprintRepository.save(sprint));
    }

    public SprintResponse updateSprint(Long id, SprintRequest request, String username) {
        Sprint sprint = sprintRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Sprint non trouve"));
        checkManageRights(sprint.getProject(), username);

        sprint.setName(request.getName());
        sprint.setNumber(request.getNumber());
        sprint.setStartDate(request.getStartDate());
        sprint.setEndDate(request.getEndDate());
        sprint.setGoalPoints(request.getGoalPoints());
        sprint.setGoal(request.getGoal());
        return toResponse(sprintRepository.save(sprint));
    }

    public void deleteSprint(Long id, String username) {
        Sprint sprint = sprintRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Sprint non trouve"));
        checkManageRights(sprint.getProject(), username);
        sprintRepository.delete(sprint);
    }

    // MANAGER : tout sprint. CHEF_PROJET : sprints des projets dont il est owner ou membre.
    private void checkManageRights(Project project, String username) {
        User current = userRepository.findByEmail(username)
            .orElseThrow(() -> new RuntimeException("Utilisateur non trouve"));
        boolean isManager = current.getGlobalRole() == GlobalRole.MANAGER;
        boolean isChefOfProject = current.getGlobalRole() == GlobalRole.CHEF_PROJET
            && (project.getOwner().getId().equals(current.getId())
                || projectMemberRepository.existsByUser_IdAndProject_Id(
                    current.getId(), project.getId()));
        if (!isManager && !isChefOfProject) {
            throw new AccessDeniedException(
                "Vous n'êtes pas autorisé à gérer les sprints de ce projet.");
        }
    }

    private SprintResponse toResponse(Sprint s) {
        return SprintResponse.builder()
            .id(s.getId())
            .projectId(s.getProject().getId())
            .name(s.getName())
            .number(s.getNumber())
            .status(s.getStatus())
            .startDate(s.getStartDate())
            .endDate(s.getEndDate())
            .goalPoints(s.getGoalPoints())
            .goal(s.getGoal())
            .remainingDays(s.getRemainingDays())
            .velocity(s.getVelocity())
            .taskCount(s.getTasks().size())
            .createdAt(s.getCreatedAt())
            .build();
    }
}
