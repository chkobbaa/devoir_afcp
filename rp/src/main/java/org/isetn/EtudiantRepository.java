package org.isetn;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.repository.query.Param;
import org.springframework.data.rest.core.annotation.RepositoryRestResource;
import org.springframework.data.rest.core.annotation.RestResource;

@RepositoryRestResource
public interface EtudiantRepository extends JpaRepository<Etudiant, Long> {
	public List<Etudiant> findByNomContains(String nom); 

	@RestResource(path = "byClasse")
	List<Etudiant> findByClasseCodClass(@Param("codClass") Long codClass);
}
