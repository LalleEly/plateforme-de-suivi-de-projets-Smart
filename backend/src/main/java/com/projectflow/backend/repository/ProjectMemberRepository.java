package com.projectflow.backend.repository;

import com.projectflow.backend.domain.entity.ProjectMember;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface ProjectMemberRepository extends JpaRepository<ProjectMember, Long> {
    List<ProjectMember> findByProject_Id(Long projectId);
    List<ProjectMember> findByUser_Id(Long userId);
    Optional<ProjectMember> findByUser_IdAndProject_Id(Long userId, Long projectId);
    boolean existsByUser_IdAndProject_Id(Long userId, Long projectId);
}
