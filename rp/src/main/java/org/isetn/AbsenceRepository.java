package org.isetn;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.rest.core.annotation.RepositoryRestResource;

import java.util.List;

@RepositoryRestResource
public interface AbsenceRepository extends JpaRepository<Absence, Long> {
    List<Absence> findByEtudiantId(Long etudiantId);
}
