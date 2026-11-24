package org.isetn;

import com.fasterxml.jackson.annotation.JsonIgnore;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import javax.persistence.*;
import java.util.Collection;

@Entity
@Data
@AllArgsConstructor
@NoArgsConstructor
public class Classe {
	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long codClass;
	private String nomClass;
	private int nbreEtud;

	@ManyToOne
	private Departement departement;

	@JsonIgnore
	@OneToMany(mappedBy = "classe")
	private Collection<Etudiant> etudiants; 
}
