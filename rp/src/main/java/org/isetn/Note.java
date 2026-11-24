package org.isetn;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import javax.persistence.*;

@Entity
@Data
@AllArgsConstructor
@NoArgsConstructor
public class Note {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    private Etudiant etudiant;

    @ManyToOne
    private Matiere matiere;

    private Double tp1;
    private Double tp2;
    private Double ds;
    private Double examen;

    public Note(Etudiant etudiant, Matiere matiere, Double tp1, Double tp2, Double ds, Double examen) {
        this.etudiant = etudiant;
        this.matiere = matiere;
        this.tp1 = tp1;
        this.tp2 = tp2;
        this.ds = ds;
        this.examen = examen;
    }
}
