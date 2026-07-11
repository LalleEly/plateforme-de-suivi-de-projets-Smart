package com.projectflow.backend.service;

import com.projectflow.backend.domain.entity.*;
import com.projectflow.backend.domain.enums.GlobalRole;
import com.projectflow.backend.domain.enums.TaskStatus;
import com.projectflow.backend.dto.request.CreateTaskRequest;
import com.projectflow.backend.dto.request.UpdateTaskRequest;
import com.projectflow.backend.dto.response.TaskResponse;
import com.projectflow.backend.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class TaskService {

    private final TaskRepository taskRepository;
    private final ProjectRepository projectRepository;
    private final UserRepository userRepository;
    private final SprintRepository sprintRepository;
    private final ProjectMemberRepository projectMemberRepository;
    private final NotificationService notificationService;
    private final TimeLogRepository timeLogRepository;
    private final CommentRepository commentRepository;

    public TaskResponse createTask(CreateTaskRequest request, String reporterEmail) {
        Project project = projectRepository.findById(request.getProjectId())
            .orElseThrow(() -> new RuntimeException("Projet non trouve"));
        User reporter = userRepository.findByEmail(reporterEmail)
            .orElseThrow(() -> new RuntimeException("Utilisateur non trouve"));
        checkManageRights(project, reporter);
        Task task = Task.builder()
            .title(request.getTitle())
            .description(request.getDescription())
            .project(project)
            .reporter(reporter)
            .priority(request.getPriority())
            .type(request.getType())
            .storyPoints(request.getStoryPoints())
            .estimatedHours(request.getEstimatedHours())
            .dueDate(request.getDueDate())
            .status(TaskStatus.BACKLOG)
            .build();
        if (request.getAssigneeId() != null) {
            userRepository.findById(request.getAssigneeId())
                .ifPresent(task::setAssignee);
        }
        if (task.getAssignee() != null) {
            notificationService.notify(task.getAssignee(),
                "Nouvelle tâche assignée",
                "Vous avez été assigné à la tâche \"" + task.getTitle() + "\" ("
                    + project.getName() + ")");
        }
        if (request.getSprintId() != null) {
            sprintRepository.findById(request.getSprintId())
                .ifPresent(task::setSprint);
        }
        if (request.getParentId() != null) {
            taskRepository.findById(request.getParentId())
                .ifPresent(task::setParent);
        }
        Task saved = taskRepository.save(task);
        return toResponse(saved);
    }

    public List<TaskResponse> getTasksByProject(Long projectId) {
        return taskRepository.findByProject_IdAndArchivedFalse(projectId)
            .stream().map(this::toResponse).collect(Collectors.toList());
    }

    public List<TaskResponse> getMyTasks(String email) {
        User user = userRepository.findByEmail(email)
            .orElseThrow(() -> new RuntimeException("Utilisateur non trouve"));
        return taskRepository.findByAssignee_IdAndArchivedFalse(user.getId())
            .stream().map(this::toResponse).collect(Collectors.toList());
    }

    public List<TaskResponse> getTasksByUser(Long userId) {
        return taskRepository.findByAssignee_IdAndArchivedFalse(userId)
            .stream().map(this::toResponse).collect(Collectors.toList());
    }

    // MANAGER يبدل حالة أي تاسك، CHEF_PROJET غير ديال المشاريع لي هو owner/membre فيها، MEMBRE غير التاسك المُكلّف بها
    public TaskResponse updateStatus(Long taskId, TaskStatus newStatus, String username) {
        Task task = taskRepository.findById(taskId)
            .orElseThrow(() -> new RuntimeException("Tache non trouvee"));
        User current = userRepository.findByEmail(username)
            .orElseThrow(() -> new RuntimeException("Utilisateur non trouve"));

        boolean isAssignee = task.getAssignee() != null
            && task.getAssignee().getId().equals(current.getId());

        if (!hasManageRights(task.getProject(), current) && !isAssignee) {
            throw new AccessDeniedException(
                "Vous ne pouvez modifier que les tâches de vos projets.");
        }

        task.setStatus(newStatus);
        if (newStatus == TaskStatus.DONE) {
            task.setCompletedAt(java.time.LocalDateTime.now());
        }
        return toResponse(taskRepository.save(task));
    }

    public TaskResponse getTaskById(Long id) {
        Task task = taskRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Tache non trouvee : " + id));
        return toResponse(task);
    }

    // MANAGER : n'importe quelle tache. CHEF_PROJET : uniquement les taches de ses projets (owner/membre).
    public TaskResponse updateTask(Long taskId, UpdateTaskRequest request, String username) {
        Task task = taskRepository.findById(taskId)
            .orElseThrow(() -> new RuntimeException("Tache non trouvee"));
        User current = userRepository.findByEmail(username)
            .orElseThrow(() -> new RuntimeException("Utilisateur non trouve"));
        checkManageRights(task.getProject(), current);

        task.setTitle(request.getTitle());
        task.setDescription(request.getDescription());
        if (request.getPriority() != null) task.setPriority(request.getPriority());
        task.setStoryPoints(request.getStoryPoints());
        task.setEstimatedHours(request.getEstimatedHours());
        task.setDueDate(request.getDueDate());
        if (request.getAssigneeId() != null) {
            userRepository.findById(request.getAssigneeId()).ifPresent(task::setAssignee);
        } else {
            task.setAssignee(null);
        }
        return toResponse(taskRepository.save(task));
    }

    public void deleteTask(Long taskId, String username) {
        Task task = taskRepository.findById(taskId)
            .orElseThrow(() -> new RuntimeException("Tache non trouvee"));
        User current = userRepository.findByEmail(username)
            .orElseThrow(() -> new RuntimeException("Utilisateur non trouve"));
        checkManageRights(task.getProject(), current);
        timeLogRepository.deleteAll(timeLogRepository.findByTask_Id(taskId));
        commentRepository.deleteAll(commentRepository.findByTask_IdOrderByCreatedAtAsc(taskId));
        taskRepository.delete(task);
    }

    public void setArchived(Long taskId, boolean archived, String username) {
        Task task = taskRepository.findById(taskId)
            .orElseThrow(() -> new RuntimeException("Tache non trouvee"));
        User current = userRepository.findByEmail(username)
            .orElseThrow(() -> new RuntimeException("Utilisateur non trouve"));
        checkManageRights(task.getProject(), current);
        task.setArchived(archived);
        taskRepository.save(task);
    }

    private boolean hasManageRights(Project project, User current) {
        boolean isManager = current.getGlobalRole() == GlobalRole.MANAGER;
        boolean isChefOfProject = current.getGlobalRole() == GlobalRole.CHEF_PROJET
            && (project.getOwner().getId().equals(current.getId())
                || projectMemberRepository.existsByUser_IdAndProject_Id(
                    current.getId(), project.getId()));
        return isManager || isChefOfProject;
    }

    private void checkManageRights(Project project, User current) {
        if (!hasManageRights(project, current)) {
            throw new AccessDeniedException(
                "Vous ne pouvez gérer que les tâches de vos projets.");
        }
    }

    private TaskResponse toResponse(Task t) {
        return TaskResponse.builder()
            .id(t.getId())
            .title(t.getTitle())
            .description(t.getDescription())
            .status(t.getStatus())
            .priority(t.getPriority())
            .type(t.getType())
            .projectId(t.getProject().getId())
            .projectName(t.getProject().getName())
            .sprintId(t.getSprint() != null ? t.getSprint().getId() : null)
            .assigneeId(t.getAssignee() != null ? t.getAssignee().getId() : null)
            .assigneeName(t.getAssignee() != null ? t.getAssignee().getFullName() : null)
            .reporterId(t.getReporter() != null ? t.getReporter().getId() : null)
            .reporterName(t.getReporter() != null ? t.getReporter().getFullName() : null)
            .parentId(t.getParent() != null ? t.getParent().getId() : null)
            .storyPoints(t.getStoryPoints())
            .estimatedHours(t.getEstimatedHours())
            .loggedHours(t.getLoggedHours())
            .dueDate(t.getDueDate())
            .overdue(t.isOverdue())
            .archived(t.isArchived())
            .createdAt(t.getCreatedAt())
            .build();
    }
}