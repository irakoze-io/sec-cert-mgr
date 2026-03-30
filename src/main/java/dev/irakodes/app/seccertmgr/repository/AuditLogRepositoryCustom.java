package dev.irakodes.app.seccertmgr.repository;

import dev.irakodes.app.seccertmgr.entity.AuditLog;

import java.util.List;
import java.util.UUID;

public interface AuditLogRepositoryCustom {

    void setTenantSchema(String tenantSchema);

    List<AuditLog> findByCustomerIdInSchema(String tenantSchema, UUID customerId);

    List<AuditLog> findByEntityTypeAndEntityIdInSchema(String tenantSchema, String entityType, UUID entityId);

    List<AuditLog> findAllInSchema(String tenantSchema);

    AuditLog saveInSchema(String tenantSchema, AuditLog auditLog);
}
