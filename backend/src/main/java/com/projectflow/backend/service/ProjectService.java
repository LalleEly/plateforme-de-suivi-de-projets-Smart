package com.projectflow.backend.service;

import com.projectflow.backend.domain.entity.Project;
import com.projectflow.backend.domain.entity.ProjectMember;
import com.projectflow.backend.domain.entity.User;
import com.projectflow.backend.domain.enums.GlobalRole;
import com.projectflow.backend.domain.enums.ProjectRole;
import com.projectflow.backend.domain.enums.ProjectStatus;
import com.projectflow.backend.domain.enums.TaskStatus;
import com.projectflow.backend.dto.request.AddMemberRequest;
import com.projectflow.backend.dto.request.CreateProjectRequest;
import com.projectflow.backend.dto.request.UpdateProjectRequest;
import com.projectflow.backend.dto.response.ProjectResponse;
import com.projectflow.backend.dto.response.UserResponse;
import com.projectflow.backend.repository.ProjectMemberRepository;
import com.projectflow.backend.repository.ProjectRepository;
import com.projectflow.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ProjectService {

    private final ProjectRepository projectRepository;
    private final UserRepository userRepository;
    private final ProjectMemberRepository memberRepository;
    private final NotificationService notificationService;

    // Seul un MANAGER cree des projets (verifie au niveau du Controller) : il
    // designe toujours qui en est le chef de projet (owner), via request.ownerId —
    // ce n'est plus forcement lui-meme.
    public ProjectResponse createProject(CreateProjectRequest request) {
        User owner = userRepository.findById(request.getOwnerId())
            .orElseThrow(() -> new RuntimeException(
                "Utilisateur assigné comme chef de projet introuvable"));

        // Diriger un projet requiert le role CHEF_PROJET pour que le modele de
        // permission reste coherent (checkOwnershipOrManager) ; assigner
        // quelqu'un comme lead d'un projet le promeut donc automatiquement s'il
        // n'etait qu'un simple MEMBRE.
        if (owner.getGlobalRole() == GlobalRole.MEMBRE) {
            owner.setGlobalRole(GlobalRole.CHEF_PROJET);
            userRepository.save(owner);
        }

        if (projectRepository.existsByKey(request.getKey())) {
            throw new RuntimeException(
                "Clé de projet déjà utilisée : " + request.getKey());
        }

        Project project = Project.builder()
            .name(request.getName())
            .key(request.getKey().toUpperCase())
            .description(request.getDescription())
            .status(ProjectStatus.PLANNING)
            .owner(owner)
            .startDate(request.getStartDate())
            .endDate(request.getEndDate())
            .budget(request.getBudget())
            .hourlyRate(request.getHourlyRate())
            .build();

        Project saved = projectRepository.save(project);

        // Sans ceci, un owner solo qui travaille seul sur son projet n'a aucune
        // ligne project_members : les KPI "Performance Membres" le montrent
        // comme vide alors qu'il a du vrai travail assigne.
        ProjectMember ownerMember = memberRepository.save(ProjectMember.builder()
            .project(saved)
            .user(owner)
            .role(ProjectRole.PROJECT_MANAGER)
            .build());
        // memberRepository.save() ne met pas a jour saved.getMembers() en memoire :
        // sans cet ajout manuel, la reponse de creation affichait memberCount=0
        // (corrige tout seul au prochain fetch, mais trompeur sur l'instant).
        saved.getMembers().add(ownerMember);

        return toResponse(saved);
    }

    public List<ProjectResponse> getMyProjects(String email) {
        User user = userRepository.findByEmail(email)
            .orElseThrow(() -> new RuntimeException("Utilisateur non trouvé"));
        return projectRepository.findByOwner_IdAndArchivedFalse(user.getId())
            .stream().map(this::toResponse).collect(Collectors.toList());
    }

    public ProjectResponse getProjectById(Long id) {
        Project project = projectRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Projet non trouvé : " + id));
        return toResponse(project);
    }

    // MANAGER كيشوف كل المشاريع (Visualiser tous les projets - use case Manager)
    // CHEF_PROJET/MEMBRE كيشوفو غير المشاريع لي هوما owner فيها أو member فيها
    public List<ProjectResponse> getAllProjects(String username) {
        return getAllProjects(username, false);
    }

    // includeArchived=true : utilise par l'ecran Projets pour afficher l'onglet
    // "Archives" (les autres ecrans/dropdowns continuent d'appeler la variante
    // sans archives, pour ne pas proposer un projet archive a la selection).
    public List<ProjectResponse> getAllProjects(String username, boolean includeArchived) {
        User current = userRepository.findByEmail(username)
            .orElseThrow(() -> new RuntimeException("Utilisateur non trouvé"));

        List<Project> projects;
        if (current.getGlobalRole() == GlobalRole.MANAGER) {
            projects = includeArchived
                ? projectRepository.findAll()
                : projectRepository.findByArchivedFalse();
        } else {
            // ندمجو المشاريع لي هو owner فيها + لي هو member فيها، بلا تكرار
            Map<Long, Project> merged = new LinkedHashMap<>();
            List<Project> owned = includeArchived
                ? projectRepository.findByOwner_Id(current.getId())
                : projectRepository.findByOwner_IdAndArchivedFalse(current.getId());
            List<Project> memberOf = includeArchived
                ? projectRepository.findByMembers_User_Id(current.getId())
                : projectRepository.findByMembers_User_IdAndArchivedFalse(current.getId());
            for (Project p : owned) {
                merged.put(p.getId(), p);
            }
            for (Project p : memberOf) {
                merged.put(p.getId(), p);
            }
            projects = List.copyOf(merged.values());
        }

        return projects.stream().map(this::toResponse).collect(Collectors.toList());
    }

    // MANAGER : n'importe quel projet. CHEF_PROJET : uniquement ses projets (owner/membre).
    public void deleteProject(Long id, String username) {
        Project project = projectRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Projet non trouvé : " + id));
        checkOwnershipOrManager(project, username);
        projectRepository.deleteById(id);
    }

    public ProjectResponse updateProject(Long id, UpdateProjectRequest request, String username) {
        Project project = projectRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Projet non trouvé : " + id));
        checkOwnershipOrManager(project, username);

        if (!project.getKey().equals(request.getKey())
                && projectRepository.existsByKey(request.getKey())) {
            throw new RuntimeException("Clé de projet déjà utilisée : " + request.getKey());
        }

        project.setName(request.getName());
        project.setKey(request.getKey().toUpperCase());
        project.setDescription(request.getDescription());
        project.setStartDate(request.getStartDate());
        project.setEndDate(request.getEndDate());
        project.setBudget(request.getBudget());
        project.setHourlyRate(request.getHourlyRate());
        return toResponse(projectRepository.save(project));
    }

    public void setArchived(Long id, boolean archived, String username) {
        Project project = projectRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Projet non trouvé : " + id));
        checkOwnershipOrManager(project, username);
        project.setArchived(archived);
        projectRepository.save(project);
    }

    // ── إدارة الأعضاء ──────────────────────────────────
    // Garantit que le owner apparait toujours, meme sur un projet cree avant
    // l'ajout automatique du owner comme ProjectMember (createProject) : sans
    // ca, un tel projet "legacy" retourne une liste vide et la page Ressources
    // d'un CHEF_PROJET semble completement cassee alors que son projet a bien
    // un owner et potentiellement d'autres membres reels.
    public List<UserResponse> getProjectMembers(Long projectId) {
        Project project = projectRepository.findById(projectId)
            .orElseThrow(() -> new RuntimeException("Projet non trouvé : " + projectId));

        Map<Long, User> users = new LinkedHashMap<>();
        users.put(project.getOwner().getId(), project.getOwner());
        for (ProjectMember pm : memberRepository.findByProject_Id(projectId)) {
            users.put(pm.getUser().getId(), pm.getUser());
        }

        return users.values().stream()
            .map(this::toUserResponse)
            .collect(Collectors.toList());
    }

    public void addMember(Long projectId, AddMemberRequest request, String username) {
        Project project = projectRepository.findById(projectId)
            .orElseThrow(() -> new RuntimeException("Projet non trouvé"));
        checkOwnershipOrManager(project, username);

        User user = userRepository.findById(request.getUserId())
            .orElseThrow(() -> new RuntimeException("Utilisateur non trouvé"));

        if (memberRepository.existsByUser_IdAndProject_Id(
                user.getId(), projectId)) {
            throw new RuntimeException("Membre déjà dans le projet");
        }

        ProjectMember member = ProjectMember.builder()
            .project(project)
            .user(user)
            .role(request.getRole())
            .build();

        memberRepository.save(member);
        notificationService.notify(user,
            "Ajout à un projet",
            "Vous avez été ajouté au projet \"" + project.getName() + "\"");
    }

    public void removeMember(Long projectId, Long userId, String username) {
        Project project = projectRepository.findById(projectId)
            .orElseThrow(() -> new RuntimeException("Projet non trouvé"));
        checkOwnershipOrManager(project, username);

        ProjectMember member = memberRepository
            .findByUser_IdAndProject_Id(userId, projectId)
            .orElseThrow(() -> new RuntimeException("Membre non trouvé"));
        memberRepository.delete(member);
    }

    // فحص الصلاحية: MANAGER دايما مسموح، CHEF_PROJET فقط إذا هو owner (lead) ديال
    // المشروع — pas seulement membre. Un CHEF_PROJET simplement ajouté comme membre
    // d'un projet qu'il ne dirige pas ne doit pas pouvoir gerer ses membres/le
    // modifier/l'archiver/le supprimer (avant : "owner OU membre" laissait n'importe
    // quel CHEF_PROJET membre d'un projet gerer l'equipe d'un autre chef).
    private void checkOwnershipOrManager(Project project, String username) {
        User current = userRepository.findByEmail(username)
            .orElseThrow(() -> new RuntimeException("Utilisateur non trouvé"));

        boolean isManager = current.getGlobalRole() == GlobalRole.MANAGER;
        boolean isOwner = current.getGlobalRole() == GlobalRole.CHEF_PROJET
            && project.getOwner().getId().equals(current.getId());

        if (!isManager && !isOwner) {
            throw new AccessDeniedException(
                "Vous n'êtes pas autorisé à modifier ce projet.");
        }
    }

    // Meme logique que getProjectMembers() : compte le owner meme s'il n'a pas
    // (encore) de ligne ProjectMember explicite (projets crees avant l'ajout
    // automatique du owner a la creation).
    private int effectiveMemberCount(Project p) {
        boolean ownerIsMember = p.getMembers().stream()
            .anyMatch(m -> m.getUser().getId().equals(p.getOwner().getId()));
        return p.getMembers().size() + (ownerIsMember ? 0 : 1);
    }

    // ── Mappers ────────────────────────────────────────
    private ProjectResponse toResponse(Project p) {
        return ProjectResponse.builder()
            .id(p.getId())
            .name(p.getName())
            .key(p.getKey())
            .description(p.getDescription())
            .status(p.getStatus())
            .ownerName(p.getOwner().getFullName())
            .ownerId(p.getOwner().getId())
            .startDate(p.getStartDate())
            .endDate(p.getEndDate())
            .budget(p.getBudget())
            .hourlyRate(p.getHourlyRate())
            .memberCount(effectiveMemberCount(p))
            .taskCount(p.getTasks().size())
            .completedTaskCount((int) p.getTasks().stream()
                .filter(t -> t.getStatus() == TaskStatus.DONE).count())
            .archived(p.isArchived())
            .createdAt(p.getCreatedAt())
            .build();
    }

    private UserResponse toUserResponse(User u) {
        return UserResponse.builder()
            .id(u.getId())
            .firstName(u.getFirstName())
            .lastName(u.getLastName())
            .fullName(u.getFullName())
            .email(u.getEmail())
            .globalRole(u.getGlobalRole())
            .active(u.isActive())
            .createdAt(u.getCreatedAt())
            .build();
    }
}