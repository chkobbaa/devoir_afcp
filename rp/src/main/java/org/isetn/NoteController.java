package org.isetn;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@RestController
@CrossOrigin("*")
public class NoteController {

    @Autowired
    private NoteRepository noteRepository;

    @Autowired
    private EtudiantRepository etudiantRepository;

    @Autowired
    private MatiereRepository matiereRepository;

    @Autowired
    private ClassMatRepository classMatRepository;

    private Double coefficientFor(Etudiant etudiant, Matiere matiere) {
        if (etudiant.getClasse() != null) {
            Optional<ClassMat> mapping = classMatRepository.findByClasseCodClassAndMatiereCodMat(
                    etudiant.getClasse().getCodClass(), matiere.getCodMat());
            if (mapping.isPresent() && mapping.get().getCoef() != null) return mapping.get().getCoef();
        }
        return matiere.getCoef() != null ? matiere.getCoef() : 1.0;
    }

    public static class NoteRequest {
        public Long etudiantId;
        public String codMat;
        public Double tp1;
        public Double tp2;
        public Double ds;
        public Double examen;
    }

    public static class NoteDTO {
        public Long id;
        public String codMat;
        public String intMat;
        public Double coef;
        public Double tp1;
        public Double tp2;
        public Double ds;
        public Double examen;
        public Double moyenneMatiere;
        public Double totalPoints;

        public NoteDTO(Long id, String codMat, String intMat, Double coef, Double tp1, Double tp2, Double ds, Double examen, Double moyenneMatiere, Double totalPoints) {
            this.id = id;
            this.codMat = codMat;
            this.intMat = intMat;
            this.coef = coef;
            this.tp1 = tp1;
            this.tp2 = tp2;
            this.ds = ds;
            this.examen = examen;
            this.moyenneMatiere = moyenneMatiere;
            this.totalPoints = totalPoints;
        }
    }

    public static class ReleveNotesDTO {
        public Long etudiantId;
        public String nce;
        public String nom;
        public String prenom;
        public String nomClasse;
        public String nomDept;
        public List<NoteDTO> notes = new ArrayList<>();
        public Double moyenneGenerale;
        public Double totalCoef;
        public Double totalPoints;
        public String mention;
        public String decision;
    }

    public static Double round2(Double val) {
        if (val == null) return null;
        return Math.round(val * 100.0) / 100.0;
    }

    public static Double calculateMoyenneMatiere(Double tp1, Double tp2, Double ds, Double examen) {
        boolean hasTp1 = tp1 != null;
        boolean hasTp2 = tp2 != null;
        boolean hasDs = ds != null;
        boolean hasExam = examen != null;

        if (!hasTp1 && !hasTp2 && !hasDs && !hasExam) {
            return null;
        }

        // TPs are 50/50
        Double tpScore = null;
        if (hasTp1 && hasTp2) {
            tpScore = (tp1 + tp2) / 2.0;
        } else if (hasTp1) {
            tpScore = tp1;
        } else if (hasTp2) {
            tpScore = tp2;
        }

        // DS and Examen are 40% and 60%
        Double theoryScore = null;
        if (hasDs && hasExam) {
            theoryScore = 0.40 * ds + 0.60 * examen;
        } else if (hasExam) {
            theoryScore = examen;
        } else if (hasDs) {
            theoryScore = ds;
        }

        Double result;
        if (tpScore != null && theoryScore != null) {
            if (hasDs && hasExam) {
                result = 0.20 * tpScore + 0.20 * ds + 0.60 * examen;
            } else if (hasExam) {
                result = 0.40 * tpScore + 0.60 * examen;
            } else {
                result = 0.50 * tpScore + 0.50 * ds;
            }
        } else if (tpScore != null) {
            result = tpScore;
        } else {
            result = theoryScore;
        }

        return round2(result);
    }

    @GetMapping("/api/notes/etudiant/{etudiantId}")
    public ResponseEntity<?> getReleveNotes(@PathVariable Long etudiantId) {
        Optional<Etudiant> etOpt = etudiantRepository.findById(etudiantId);
        if (!etOpt.isPresent()) {
            return ResponseEntity.notFound().build();
        }
        Etudiant etudiant = etOpt.get();

        ReleveNotesDTO releve = new ReleveNotesDTO();
        releve.etudiantId = etudiant.getId();
        releve.nce = etudiant.getNce();
        releve.nom = etudiant.getNom();
        releve.prenom = etudiant.getPrenom();
        if (etudiant.getClasse() != null) {
            releve.nomClasse = etudiant.getClasse().getNomClass();
            if (etudiant.getClasse().getDepartement() != null) {
                releve.nomDept = etudiant.getClasse().getDepartement().getNomDept();
            }
        }

        List<Note> notes = noteRepository.findByEtudiantId(etudiantId);
        // Map notes by codMat for quick lookup
        Map<String, Note> noteMap = new HashMap<>();
        for (Note n : notes) {
            if (n.getMatiere() != null) {
                noteMap.put(n.getMatiere().getCodMat(), n);
            }
        }

        // Also fetch all matieres so relevé can show all subjects
        List<Matiere> allMatieres = matiereRepository.findAll();
        double sumPoints = 0.0;
        double sumCoef = 0.0;

        for (Matiere m : allMatieres) {
            Note n = noteMap.get(m.getCodMat());
            Long noteId = n != null ? n.getId() : null;
            Double tp1 = n != null ? n.getTp1() : null;
            Double tp2 = n != null ? n.getTp2() : null;
            Double ds = n != null ? n.getDs() : null;
            Double examen = n != null ? n.getExamen() : null;
            Double coef = coefficientFor(etudiant, m);

            Double moy = calculateMoyenneMatiere(tp1, tp2, ds, examen);
            Double totalPoints = null;
            if (moy != null) {
                totalPoints = round2(moy * coef);
                sumPoints += totalPoints;
                sumCoef += coef;
            }

            releve.notes.add(new NoteDTO(
                    noteId,
                    m.getCodMat(),
                    m.getIntMat(),
                    coef,
                    tp1,
                    tp2,
                    ds,
                    examen,
                    moy,
                    totalPoints
            ));
        }

        releve.totalCoef = round2(sumCoef);
        releve.totalPoints = round2(sumPoints);

        if (sumCoef > 0) {
            double mg = round2(sumPoints / sumCoef);
            releve.moyenneGenerale = mg;
            if (mg >= 16.0) {
                releve.mention = "Très Bien";
                releve.decision = "Admis";
            } else if (mg >= 14.0) {
                releve.mention = "Bien";
                releve.decision = "Admis";
            } else if (mg >= 12.0) {
                releve.mention = "Assez Bien";
                releve.decision = "Admis";
            } else if (mg >= 10.0) {
                releve.mention = "Passable";
                releve.decision = "Admis";
            } else {
                releve.mention = "Ajourné";
                releve.decision = "Ajourné";
            }
        } else {
            releve.moyenneGenerale = null;
            releve.mention = "N/A";
            releve.decision = "N/A";
        }

        return ResponseEntity.ok(releve);
    }

    @PostMapping("/api/notes")
    public ResponseEntity<?> saveOrUpdateNote(@RequestBody NoteRequest req) {
        Optional<Etudiant> etOpt = etudiantRepository.findById(req.etudiantId);
        Optional<Matiere> matOpt = matiereRepository.findById(req.codMat);

        if (!etOpt.isPresent() || !matOpt.isPresent()) {
            return ResponseEntity.badRequest().body("Etudiant or Matiere not found");
        }

        Optional<Note> existing = noteRepository.findByEtudiantIdAndMatiereCodMat(req.etudiantId, req.codMat);
        Note note = existing.orElseGet(Note::new);

        note.setEtudiant(etOpt.get());
        note.setMatiere(matOpt.get());
        note.setTp1(req.tp1);
        note.setTp2(req.tp2);
        note.setDs(req.ds);
        note.setExamen(req.examen);

        Note saved = noteRepository.save(note);
        Matiere m = saved.getMatiere();
        Double coef = coefficientFor(saved.getEtudiant(), m);
        Double moy = calculateMoyenneMatiere(saved.getTp1(), saved.getTp2(), saved.getDs(), saved.getExamen());
        Double totalPoints = moy != null ? round2(moy * coef) : null;

        return ResponseEntity.ok(new NoteDTO(
                saved.getId(),
                m.getCodMat(),
                m.getIntMat(),
                coef,
                saved.getTp1(),
                saved.getTp2(),
                saved.getDs(),
                saved.getExamen(),
                moy,
                totalPoints
        ));
    }

    @DeleteMapping("/api/notes/{id}")
    public ResponseEntity<?> deleteNote(@PathVariable Long id) {
        if (!noteRepository.existsById(id)) {
            return ResponseEntity.notFound().build();
        }
        noteRepository.deleteById(id);
        return ResponseEntity.ok().build();
    }
}
