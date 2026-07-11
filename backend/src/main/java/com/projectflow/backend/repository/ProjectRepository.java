package com.projectflow.backend.repository;

import com.projectflow.backend.domain.entity.Project;
import com.projectflow.backend.domain.enums.ProjectStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface ProjectRepository extends JpaRepository<Project, Long> {
    List<Project> findByOwner_Id(Long ownerId);
    List<Project> findByStatus(ProjectStatus status);
    List<Project> findByMembers_User_Id(Long userId);
    List<Project> findByArchivedFalse();
    List<Project> findByOwner_IdAndArchivedFalse(Long ownerId);
    List<Project> findByMembers_User_IdAndArchivedFalse(Long userId);
    boolean existsByKey(String key);
}
