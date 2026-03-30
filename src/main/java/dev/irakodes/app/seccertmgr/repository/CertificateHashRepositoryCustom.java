package dev.irakodes.app.seccertmgr.repository;

import dev.irakodes.app.seccertmgr.entity.CertificateHash;

import java.util.Optional;
import java.util.UUID;

public interface CertificateHashRepositoryCustom {

    void setTenantSchema(String tenantSchema);

    Optional<CertificateHash> findByCertificateIdInSchema(String tenantSchema, UUID certificateId);

    Optional<CertificateHash> findByHashValueInSchema(String tenantSchema, String hashValue);

    CertificateHash saveInSchema(String tenantSchema, CertificateHash certificateHash);
}
