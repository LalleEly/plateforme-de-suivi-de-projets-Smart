package com.projectflow.backend.domain.entity;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity @Table(name = "time_logs")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class TimeLog {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "task_id", nullable = false)
    private Task task;
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;
    @Column(nullable = false)
    private LocalDate date;
    @Column(nullable = false)
    private Integer minutes;
    @Column(length = 500)
    private String description;
    @CreationTimestamp @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;
    public double getHours() { return minutes / 60.0; }
}
