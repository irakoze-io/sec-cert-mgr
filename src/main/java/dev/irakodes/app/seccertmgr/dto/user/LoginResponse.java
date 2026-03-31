package dev.irakodes.app.seccertmgr.dto.user;

import com.fasterxml.jackson.annotation.JsonInclude;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import dev.irakodes.app.seccertmgr.entity.User;

import java.time.LocalDateTime;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Schema(description = "User response")
@JsonInclude(JsonInclude.Include.NON_NULL)
public class LoginResponse {

    @Schema(description = "User ID", example = "550e8400-e29b-41d4-a716-446655440000")
    private UUID id;

    @Schema(description = "Customer ID", example = "1")
    private Long customerId;

    @Schema(description = "User email", example = "john.doe@example.com")
    private String email;

    @Schema(description = "Keycloak ID", example = "550e8400-e29b-41d4-a716-446655440000")
    private String keycloakId;

    @Schema(description = "First name", example = "John")
    private String firstName;

    @Schema(description = "Last name", example = "Doe")
    private String lastName;

    @Schema(description = "User role", example = "ADMIN")
    private User.UserRole role;

    @Schema(description = "Whether the user is active", example = "true")
    private Boolean active;

    @Schema(description = "Last login timestamp")
    private LocalDateTime lastLogin;

    @Schema(description = "Creation timestamp")
    private LocalDateTime createdAt;

    @Schema(description = "Last update timestamp")
    private LocalDateTime updatedAt;

    public static LoginResponse from(dev.irakodes.app.seccertmgr.entity.User user) {
        return LoginResponse.builder()
            .id(user.getId())
            .customerId(user.getCustomerId())
            .email(user.getEmail())
            .keycloakId(user.getKeycloakId())
            .firstName(user.getFirstName())
            .lastName(user.getLastName())
            .role(user.getRole())
            .active(user.getActive())
            .lastLogin(user.getLastLogin())
            .createdAt(user.getCreatedAt())
            .updatedAt(user.getUpdatedAt())
            .build();
    }
}
