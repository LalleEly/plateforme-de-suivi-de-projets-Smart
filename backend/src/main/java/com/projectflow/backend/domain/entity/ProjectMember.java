package com.projectflow.backend.domain.entity;
import com.projectflow.backend.domain.enums.ProjectRole;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import java.time.LocalDateTime;

@Entity @Table(name = "project_members",
    uniqueConstraints = @UniqueConstraint(columnNames = {"user_id", "project_id"}))
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class ProjectMember {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "project_id", nullable = false)
    private Project project;
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private ProjectRole role;
    @CreationTimestamp @Column(name = "joined_at", updatable = false)
    private LocalDateTime joinedAt;
    @Column(name = "is_active", nullable = false) @Builder.Default
    private boolean isActive = true;
}
