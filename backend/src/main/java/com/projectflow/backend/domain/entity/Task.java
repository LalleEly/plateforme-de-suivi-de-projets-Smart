package com.projectflow.backend.domain.entity;
import com.projectflow.backend.domain.enums.*;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity @Table(name = "tasks")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Task {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(nullable = false, length = 500)
    private String title;
    @Column(columnDefinition = "TEXT")
    private String description;
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20) @Builder.Default
    private TaskStatus status = TaskStatus.BACKLOG;
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 15) @Builder.Default
    private Priority priority = Priority.MEDIUM;
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 15) @Builder.Default
    private TaskType type = TaskType.TASK;
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "project_id", nullable = false)
    private Project project;
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "sprint_id")
    private Sprint sprint;
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "assignee_id")
    private User assignee;
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "reporter_id")
    private User reporter;
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "parent_id")
    private Task parent;
    @OneToMany(mappedBy = "parent", cascade = CascadeType.ALL) @Builder.Default
    private List<Task> subtasks = new ArrayList<>();
    @Column(name = "story_points")
    private Integer storyPoints;
    @Column(name = "estimated_hours")
    private Integer estimatedHours;
    @Column(name = "due_date")
    private LocalDate dueDate;
    @Column(nullable = false, columnDefinition = "boolean default false") @Builder.Default
    private boolean archived = false;
    @Column(name = "completed_at")
    private LocalDateTime completedAt;
    @CreationTimestamp @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;
    @UpdateTimestamp @Column(name = "updated_at")
    private LocalDateTime updatedAt;
    @OneToMany(mappedBy = "task", cascade = CascadeType.ALL) @Builder.Default
    private List<TimeLog> timeLogs = new ArrayList<>();
    @OneToMany(mappedBy = "task", cascade = CascadeType.ALL) @Builder.Default
    private List<Comment> comments = new ArrayList<>();
    public boolean isOverdue() {
        if (dueDate == null || status == TaskStatus.DONE) return false;
        return LocalDate.now().isAfter(dueDate);
    }
    public int getLoggedHours() {
        return timeLogs.stream().mapToInt(TimeLog::getMinutes).sum() / 60;
    }
}
