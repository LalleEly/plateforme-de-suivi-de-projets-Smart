package com.projectflow.backend.repository;

import com.projectflow.backend.domain.entity.Sprint;
import com.projectflow.backend.domain.enums.SprintStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface SprintRepository extends JpaRepository<Sprint, Long> {
    List<Sprint> findByProject_Id(Long projectId);
    List<Sprint> findByProject_IdAndStatus(Long projectId, SprintStatus status);
    Optional<Sprint> findFirstByProject_IdAndStatus(Long projectId, SprintStatus status);
}
