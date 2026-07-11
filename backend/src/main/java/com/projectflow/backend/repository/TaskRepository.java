package com.projectflow.backend.repository;

import com.projectflow.backend.domain.entity.Task;
import com.projectflow.backend.domain.enums.TaskStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface TaskRepository extends JpaRepository<Task, Long> {
    List<Task> findByProject_Id(Long projectId);
    List<Task> findByAssignee_Id(Long userId);
    List<Task> findBySprint_Id(Long sprintId);
    List<Task> findByProject_IdAndStatus(Long projectId, TaskStatus status);
    List<Task> findByParentIsNullAndProject_Id(Long projectId);
    List<Task> findByProject_IdAndArchivedFalse(Long projectId);
    List<Task> findByAssignee_IdAndArchivedFalse(Long userId);
    List<Task> findByProject_IdAndAssignee_Id(Long projectId, Long userId);
}
