package com.projectflow.backend.dto.response;

import lombok.Builder;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@Builder
public class CommentResponse {
    private Long id;
    private Long taskId;
    private Long authorId;
    private String authorName;
    private String content;
    private Long parentId;
    private boolean edited;
    private LocalDateTime createdAt;
}
