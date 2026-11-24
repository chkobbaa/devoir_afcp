package org.isetn;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.rest.core.annotation.RepositoryRestResource;
import java.util.Optional;

@RepositoryRestResource
public interface ClassMatRepository extends JpaRepository<ClassMat, Long> {
    Optional<ClassMat> findByClasseCodClassAndMatiereCodMat(Long codClass, String codMat);
}
