package org.isetn;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.Id;

@Entity
@Data
@AllArgsConstructor
@NoArgsConstructor
public class Matiere {
    @Id
    @Column(length = 50)
    private String codMat;
    private String intMat;
    private String description;
    private Double coef = 1.0;


    public Matiere(String codMat, String intMat, String description) {
        this.codMat = codMat;
        this.intMat = intMat;
        this.description = description;
        this.coef = 1.0;
    }
}
