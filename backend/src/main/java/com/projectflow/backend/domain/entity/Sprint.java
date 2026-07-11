package com.projectflow.backend.domain.entity;
import com.projectflow.backend.domain.enums.SprintStatus;
import com.projectflow.backend.domain.enums.TaskStatus;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity @Table(name = "sprints")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Sprint {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "project_id", nullable = false)
    private Project project;
    @Column(nullable = false, length = 100)
    private String name;
    @Column(nullable = false)
    private Integer number;
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20) @Builder.Default
    private SprintStatus status = SprintStatus.PLANNING;
    @Column(name = "start_date")
    private LocalDate startDate;
    @Column(name = "end_date")
    private LocalDate endDate;
    @Column(name = "goal_points")
    private Integer goalPoints;
    @Column(columnDefinition = "TEXT")
    private String goal;
    @CreationTimestamp @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;
    @OneToMany(mappedBy = "sprint", cascade = CascadeType.ALL) @Builder.Default
    private List<Task> tasks = new ArrayList<>();
    public long getRemainingDays() {
        if (endDate == null) return 0;
        return LocalDate.now().until(endDate).getDays();
    }
    public int getVelocity() {
        return tasks.stream()
            .filter(t -> t.getStatus() == TaskStatus.DONE)
            .mapToInt(t -> t.getStoryPoints() != null ? t.getStoryPoints() : 0)
            .sum();
    }
}
