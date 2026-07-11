package com.projectflow.backend.repository;

import com.projectflow.backend.domain.entity.Comment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface CommentRepository extends JpaRepository<Comment, Long> {
    List<Comment> findByTask_IdOrderByCreatedAtAsc(Long taskId);
}
