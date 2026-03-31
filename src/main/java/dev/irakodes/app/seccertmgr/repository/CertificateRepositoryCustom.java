package dev.irakodes.app.seccertmgr.repository;

import dev.irakodes.app.seccertmgr.entity.Certificate;

import java.util.List;
import java.util.Optional;

public interface CertificateRepositoryCustom {

    void setTenantSchema(String tenantSchema);

    Optional<Certificate> findByCertificateNumberInSchema(String tenantSchema, String certificateNumber);

    List<Certificate> findByCustomerIdInSchema(String tenantSchema, Long customerId);

    List<Certificate> findByStatusInSchema(String tenantSchema, Certificate.CertificateStatus status);

    List<Certificate> findAllInSchema(String tenantSchema);

    Certificate saveInSchema(String tenantSchema, Certificate certificate);
}
