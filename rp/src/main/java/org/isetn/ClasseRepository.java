package org.isetn;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.repository.query.Param;
import org.springframework.data.rest.core.annotation.RepositoryRestResource;
import org.springframework.data.rest.core.annotation.RestResource;

import java.util.List;

@RepositoryRestResource
public interface ClasseRepository extends JpaRepository<Classe, Long> {
	@RestResource(path = "byDept")
	List<Classe> findByDepartementCodDept(@Param("codDept") Long codDept);
}
