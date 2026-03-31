package dev.irakodes.app.seccertmgr.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import dev.irakodes.app.seccertmgr.entity.CertificateHash;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface CertificateHashRepository extends JpaRepository<CertificateHash, Long>, CertificateHashRepositoryCustom {

    Optional<CertificateHash> findByCertificateId(UUID certificateId);

    boolean existsByCertificateId(UUID certificateId);
}
