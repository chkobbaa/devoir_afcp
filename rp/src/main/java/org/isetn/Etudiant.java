package org.isetn;

import com.fasterxml.jackson.annotation.JsonIgnore;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import javax.persistence.*;
import java.util.Collection;
import java.util.Date;

@Entity
@Data
@AllArgsConstructor
@NoArgsConstructor
public class Etudiant {
	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;
	private String nce;
	private String nom;
	private String prenom;
	private Date dateNais;
	private String lieuNais;

	@ManyToOne
	private Formation formation;

	@ManyToOne
	private Classe classe;

	@JsonIgnore
	@OneToMany(mappedBy = "etudiant")
	private Collection<Absence> absences;

	@JsonIgnore
	@OneToMany(mappedBy = "etudiant")
	private Collection<Note> notes;

	public Etudiant(Long id, String nom, String prenom, Date dateNais, String lieuNais, Formation formation, Classe classe, Collection<Absence> absences) {
		this.id = id;
		this.nce = id != null ? ("E" + id) : null;
		this.nom = nom;
		this.prenom = prenom;
		this.dateNais = dateNais;
		this.lieuNais = lieuNais;
		this.formation = formation;
		this.classe = classe;
		this.absences = absences;
	}

	public String getNce() {
		if (nce != null && !nce.trim().isEmpty()) {
			return nce;
		}
		return id != null ? ("E" + id) : "";
	}
}
