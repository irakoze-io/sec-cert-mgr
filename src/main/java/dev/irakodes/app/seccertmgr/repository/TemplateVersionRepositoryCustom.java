package dev.irakodes.app.seccertmgr.repository;

import dev.irakodes.app.seccertmgr.entity.TemplateVersion;

import java.util.List;
import java.util.Optional;

public interface TemplateVersionRepositoryCustom {

    void setTenantSchema(String tenantSchema);

    Optional<TemplateVersion> findByTemplateIdAndVersionInSchema(String tenantSchema, Long templateId, Integer version);

    List<TemplateVersion> findByTemplateIdInSchema(String tenantSchema, Long templateId);

    List<TemplateVersion> findAllInSchema(String tenantSchema);

    TemplateVersion saveInSchema(String tenantSchema, TemplateVersion templateVersion);
}
