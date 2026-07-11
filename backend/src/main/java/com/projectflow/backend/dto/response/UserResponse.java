package com.projectflow.backend.dto.response;

import com.projectflow.backend.domain.enums.GlobalRole;
import lombok.Builder;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@Builder
public class UserResponse {
    private Long id;
    private String firstName;
    private String lastName;
    private String fullName;
    private String email;
    private GlobalRole globalRole;
    private boolean active;
    private LocalDateTime createdAt;
}