package com.projectflow.backend.repository;

import com.projectflow.backend.domain.entity.TimeLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface TimeLogRepository extends JpaRepository<TimeLog, Long> {
    List<TimeLog> findByTask_Id(Long taskId);
    List<TimeLog> findByUser_Id(Long userId);
    List<TimeLog> findByTask_Project_Id(Long projectId);

    @Query("SELECT COALESCE(SUM(t.minutes), 0) FROM TimeLog t WHERE t.task.project.id = :projectId")
    int sumMinutesByProjectId(@Param("projectId") Long projectId);

    @Query("SELECT COALESCE(SUM(t.minutes), 0) FROM TimeLog t WHERE t.user.id = :userId")
    int sumMinutesByUserId(@Param("userId") Long userId);
}
