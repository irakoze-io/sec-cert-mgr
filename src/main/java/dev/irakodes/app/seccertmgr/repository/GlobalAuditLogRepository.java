package dev.irakodes.app.seccertmgr.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import dev.irakodes.app.seccertmgr.entity.GlobalAuditLog;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Repository
public interface GlobalAuditLogRepository extends JpaRepository<GlobalAuditLog, UUID> {

    List<GlobalAuditLog> findByCustomerId(Long customerId);

    List<GlobalAuditLog> findByAction(String action);

    List<GlobalAuditLog> findByCreatedAtBetween(LocalDateTime start, LocalDateTime end);

    List<GlobalAuditLog> findByCustomerIdOrderByCreatedAtDesc(Long customerId);

    long countByCustomerId(Long customerId);
}
