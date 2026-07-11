package com.projectflow.backend.service;

import com.projectflow.backend.domain.entity.Task;
import com.projectflow.backend.domain.entity.TimeLog;
import com.projectflow.backend.domain.entity.User;
import com.projectflow.backend.dto.request.CreateTimeLogRequest;
import com.projectflow.backend.dto.response.TimeLogResponse;
import com.projectflow.backend.repository.TaskRepository;
import com.projectflow.backend.repository.TimeLogRepository;
import com.projectflow.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class TimeLogService {

    private final TimeLogRepository timeLogRepository;
    private final TaskRepository taskRepository;
    private final UserRepository userRepository;

    // سجّل وقت جديد
    public TimeLogResponse logTime(CreateTimeLogRequest request, String userEmail) {
        User user = userRepository.findByEmail(userEmail)
            .orElseThrow(() -> new RuntimeException("Utilisateur non trouvé"));

        Task task = taskRepository.findById(request.getTaskId())
            .orElseThrow(() -> new RuntimeException("Tâche non trouvée"));

        TimeLog log = TimeLog.builder()
            .task(task)
            .user(user)
            .date(request.getDate())
            .minutes(request.getMinutes())
            .description(request.getDescription())
            .build();

        return toResponse(timeLogRepository.save(log));
    }

    // كل سجلات الوقت للمستخدم الحالي
    public List<TimeLogResponse> getMyTimeLogs(String userEmail) {
        User user = userRepository.findByEmail(userEmail)
            .orElseThrow(() -> new RuntimeException("Utilisateur non trouvé"));

        return timeLogRepository.findByUser_Id(user.getId())
            .stream()
            .map(this::toResponse)
            .collect(Collectors.toList());
    }

    // كل سجلات الوقت حسب المشروع
    public List<TimeLogResponse> getTimeLogsByProject(Long projectId) {
        return timeLogRepository.findByTask_Project_Id(projectId)
            .stream()
            .map(this::toResponse)
            .collect(Collectors.toList());
    }

    // كل سجلات الوقت حسب المهمة
    public List<TimeLogResponse> getTimeLogsByTask(Long taskId) {
        return timeLogRepository.findByTask_Id(taskId)
            .stream()
            .map(this::toResponse)
            .collect(Collectors.toList());
    }

    // حذف سجل وقت — فقط صاحبه
    public void deleteTimeLog(Long id, String userEmail) {
        TimeLog log = timeLogRepository.findById(id)
            .orElseThrow(() -> new RuntimeException("Entrée de temps non trouvée"));

        if (!log.getUser().getEmail().equals(userEmail)) {
            throw new AccessDeniedException(
                "Vous ne pouvez supprimer que vos propres entrées de temps.");
        }

        timeLogRepository.deleteById(id);
    }

    private TimeLogResponse toResponse(TimeLog log) {
        return TimeLogResponse.builder()
            .id(log.getId())
            .taskId(log.getTask().getId())
            .taskTitle(log.getTask().getTitle())
            .projectId(log.getTask().getProject().getId())
            .projectName(log.getTask().getProject().getName())
            .userId(log.getUser().getId())
            .userName(log.getUser().getFullName())
            .date(log.getDate())
            .minutes(log.getMinutes())
            .description(log.getDescription())
            .createdAt(log.getCreatedAt())
            .build();
    }
}