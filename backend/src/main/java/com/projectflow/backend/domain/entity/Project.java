package com.projectflow.backend.domain.entity;
import com.projectflow.backend.domain.enums.ProjectStatus;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity @Table(name = "projects")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Project {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(nullable = false, length = 200)
    private String name;
    @Column(unique = true, length = 10)
    private String key;
    @Column(columnDefinition = "TEXT")
    private String description;
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20) @Builder.Default
    private ProjectStatus status = ProjectStatus.PLANNING;
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "owner_id", nullable = false)
    private User owner;
    @Column(name = "start_date")
    private LocalDate startDate;
    @Column(name = "end_date")
    private LocalDate endDate;
    @Column(precision = 15, scale = 2)
    private BigDecimal budget;
    @Column(name = "hourly_rate", precision = 8, scale = 2)
    private BigDecimal hourlyRate;
    @Column(nullable = false, columnDefinition = "boolean default false") @Builder.Default
    private boolean archived = false;
    @CreationTimestamp @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;
    @UpdateTimestamp @Column(name = "updated_at")
    private LocalDateTime updatedAt;
    @OneToMany(mappedBy = "project", cascade = CascadeType.ALL) @Builder.Default
    private List<Sprint> sprints = new ArrayList<>();
    @OneToMany(mappedBy = "project", cascade = CascadeType.ALL) @Builder.Default
    private List<Task> tasks = new ArrayList<>();
    @OneToMany(mappedBy = "project", cascade = CascadeType.ALL) @Builder.Default
    private List<ProjectMember> members = new ArrayList<>();
    public boolean isOnSchedule() {
        if (endDate == null) return true;
        return LocalDate.now().isBefore(endDate);
    }
}
