package dev.irakodes.app.seccertmgr.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import dev.irakodes.app.seccertmgr.entity.Template;

import java.util.List;
import java.util.Optional;

@Repository
public interface TemplateRepository extends JpaRepository<Template, Long> {
    
    /**
     * Find template by code (unique within tenant).
     */
    Optional<Template> findByCode(String code);
    
    /**
     * Find all templates for a customer.
     */
    List<Template> findByCustomerId(Long customerId);
    
    /**
     * Check if a template code exists (within tenant).
     */
    boolean existsByCode(String code);
}
