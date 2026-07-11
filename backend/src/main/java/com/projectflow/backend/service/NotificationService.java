package com.projectflow.backend.service;

import com.projectflow.backend.domain.entity.Notification;
import com.projectflow.backend.domain.entity.User;
import com.projectflow.backend.dto.response.NotificationResponse;
import com.projectflow.backend.repository.NotificationRepository;
import com.projectflow.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class NotificationService {

    private final NotificationRepository notificationRepository;
    private final UserRepository userRepository;

    public List<NotificationResponse> getMyNotifications(String username) {
        User user = userRepository.findByEmail(username)
            .orElseThrow(() -> new RuntimeException("Utilisateur non trouve"));
        return notificationRepository.findByRecipient_IdOrderByCreatedAtDesc(user.getId())
            .stream().map(this::toResponse).collect(Collectors.toList());
    }

    public long getUnreadCount(String username) {
        User user = userRepository.findByEmail(username)
            .orElseThrow(() -> new RuntimeException("Utilisateur non trouve"));
        return notificationRepository.countByRecipient_IdAndReadFalse(user.getId());
    }

    public NotificationResponse markAsRead(Long notificationId, String username) {
        Notification notification = notificationRepository.findById(notificationId)
            .orElseThrow(() -> new RuntimeException("Notification non trouvee"));
        if (!notification.getRecipient().getEmail().equals(username)) {
            throw new AccessDeniedException("Cette notification ne vous appartient pas.");
        }
        notification.setRead(true);
        return toResponse(notificationRepository.save(notification));
    }

    public void markAllAsRead(String username) {
        User user = userRepository.findByEmail(username)
            .orElseThrow(() -> new RuntimeException("Utilisateur non trouve"));
        List<Notification> unread = notificationRepository.findByRecipient_IdAndReadFalse(user.getId());
        unread.forEach(n -> n.setRead(true));
        notificationRepository.saveAll(unread);
    }

    public void notify(User recipient, String title, String message) {
        Notification notification = Notification.builder()
            .recipient(recipient)
            .title(title)
            .message(message)
            .read(false)
            .build();
        notificationRepository.save(notification);
    }

    private NotificationResponse toResponse(Notification n) {
        return NotificationResponse.builder()
            .id(n.getId())
            .title(n.getTitle())
            .message(n.getMessage())
            .read(n.isRead())
            .createdAt(n.getCreatedAt())
            .build();
    }
}
