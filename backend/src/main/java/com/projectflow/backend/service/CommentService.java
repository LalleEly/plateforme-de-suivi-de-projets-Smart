package com.projectflow.backend.service;

import com.projectflow.backend.domain.entity.Comment;
import com.projectflow.backend.domain.entity.Task;
import com.projectflow.backend.domain.entity.User;
import com.projectflow.backend.domain.enums.GlobalRole;
import com.projectflow.backend.dto.request.CommentRequest;
import com.projectflow.backend.dto.response.CommentResponse;
import com.projectflow.backend.repository.CommentRepository;
import com.projectflow.backend.repository.TaskRepository;
import com.projectflow.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class CommentService {

    private final CommentRepository commentRepository;
    private final TaskRepository taskRepository;
    private final UserRepository userRepository;

    public List<CommentResponse> getCommentsByTask(Long taskId) {
        return commentRepository.findByTask_IdOrderByCreatedAtAsc(taskId)
            .stream().map(this::toResponse).collect(Collectors.toList());
    }

    // MANAGER/CHEF_PROJET : n'importe quelle tache. MEMBRE : uniquement ses taches assignees.
    public CommentResponse addComment(CommentRequest request, String username) {
        Task task = taskRepository.findById(request.getTaskId())
            .orElseThrow(() -> new RuntimeException("Tache non trouvee"));
        User author = userRepository.findByEmail(username)
            .orElseThrow(() -> new RuntimeException("Utilisateur non trouve"));

        boolean isManagerOrChef = author.getGlobalRole() == GlobalRole.MANAGER
            || author.getGlobalRole() == GlobalRole.CHEF_PROJET;
        boolean isAssignee = task.getAssignee() != null
            && task.getAssignee().getId().equals(author.getId());
        if (!isManagerOrChef && !isAssignee) {
            throw new AccessDeniedException(
                "Vous ne pouvez commenter que vos propres tâches.");
        }

        Comment.CommentBuilder builder = Comment.builder()
            .task(task)
            .author(author)
            .content(request.getContent());
        if (request.getParentId() != null) {
            commentRepository.findById(request.getParentId()).ifPresent(builder::parent);
        }
        return toResponse(commentRepository.save(builder.build()));
    }

    private CommentResponse toResponse(Comment c) {
        return CommentResponse.builder()
            .id(c.getId())
            .taskId(c.getTask().getId())
            .authorId(c.getAuthor().getId())
            .authorName(c.getAuthor().getFullName())
            .content(c.getContent())
            .parentId(c.getParent() != null ? c.getParent().getId() : null)
            .edited(c.isEdited())
            .createdAt(c.getCreatedAt())
            .build();
    }
}
