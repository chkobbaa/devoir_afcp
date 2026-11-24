package org.isetn;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import javax.persistence.*;

@Entity
@Data
@AllArgsConstructor
@NoArgsConstructor
public class Absence {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String dateA;
    private Double nha;

    @ManyToOne
    private Etudiant etudiant;

    @ManyToOne
    private Matiere matiere;
}
