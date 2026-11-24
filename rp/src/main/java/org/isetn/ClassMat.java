package org.isetn;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import javax.persistence.Entity;
import javax.persistence.FetchType;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.JoinColumn;
import javax.persistence.ManyToOne;
import javax.persistence.Table;
import javax.persistence.UniqueConstraint;

@Entity
@Table(uniqueConstraints = @UniqueConstraint(columnNames = {"classe_cod_class", "matiere_cod_mat"}))
public class ClassMat {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "classe_cod_class")
    @JsonIgnoreProperties({"etudiants", "matieres"})
    private Classe classe;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "matiere_cod_mat")
    @JsonIgnoreProperties("classes")
    private Matiere matiere;

    private Double coef;
    private Double chsm;

    public ClassMat() {}
    public ClassMat(Classe classe, Matiere matiere, Double coef, Double chsm) {
        this.classe = classe;
        this.matiere = matiere;
        this.coef = coef;
        this.chsm = chsm;
    }
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Classe getClasse() { return classe; }
    public void setClasse(Classe classe) { this.classe = classe; }
    public Matiere getMatiere() { return matiere; }
    public void setMatiere(Matiere matiere) { this.matiere = matiere; }
    public Double getCoef() { return coef; }
    public void setCoef(Double coef) { this.coef = coef; }
    public Double getChsm() { return chsm; }
    public void setChsm(Double chsm) { this.chsm = chsm; }
}
