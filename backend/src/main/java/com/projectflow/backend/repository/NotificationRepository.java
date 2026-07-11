package com.projectflow.backend.repository;

import com.projectflow.backend.domain.entity.Notification;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface NotificationRepository extends JpaRepository<Notification, Long> {
    List<Notification> findByRecipient_IdOrderByCreatedAtDesc(Long recipientId);
    long countByRecipient_IdAndReadFalse(Long recipientId);
    List<Notification> findByRecipient_IdAndReadFalse(Long recipientId);
}
