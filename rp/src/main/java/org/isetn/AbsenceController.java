package org.isetn;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@RestController
@CrossOrigin("*")
public class AbsenceController {

    @Autowired
    private AbsenceRepository absenceRepository;

    @Autowired
    private EtudiantRepository etudiantRepository;

    @Autowired
    private MatiereRepository matiereRepository;

    // Model for incoming create/update request
    public static class AbsenceRequest {
        public Long etudiantId;
        public String codMat;
        public String dateA;
        public Double nha;
    }

    // Model for outgoing response
    public static class AbsenceDTO {
        public Long id;
        public String dateA;
        public Double nha;
        public String codMat;
        public Long etudiantId;

        public AbsenceDTO(Long id, String dateA, Double nha, String codMat, Long etudiantId) {
            this.id = id;
            this.dateA = dateA;
            this.nha = nha;
            this.codMat = codMat;
            this.etudiantId = etudiantId;
        }
    }

    // Model for total absences by subject
    public static class TotalAbsenceDTO {
        public String codMat;
        public Double totalNha;

        public TotalAbsenceDTO(String codMat, Double totalNha) {
            this.codMat = codMat;
            this.totalNha = totalNha;
        }
    }

    @GetMapping("/api/absences/etudiant/{etudiantId}")
    public List<AbsenceDTO> getAbsencesByEtudiant(@PathVariable Long etudiantId) {
        List<Absence> absences = absenceRepository.findByEtudiantId(etudiantId);
        List<AbsenceDTO> dtos = new ArrayList<>();
        for (Absence a : absences) {
            String codMat = a.getMatiere() != null ? a.getMatiere().getCodMat() : "";
            Long etId = a.getEtudiant() != null ? a.getEtudiant().getId() : null;
            dtos.add(new AbsenceDTO(a.getId(), a.getDateA(), a.getNha(), codMat, etId));
        }
        return dtos;
    }

    @PostMapping("/api/absences")
    public ResponseEntity<?> addAbsence(@RequestBody AbsenceRequest req) {
        Optional<Etudiant> etOpt = etudiantRepository.findById(req.etudiantId);
        Optional<Matiere> matOpt = matiereRepository.findById(req.codMat);
        if (!etOpt.isPresent() || !matOpt.isPresent()) {
            return ResponseEntity.badRequest().body("Etudiant or Matiere not found");
        }

        Absence absence = new Absence();
        absence.setDateA(req.dateA);
        absence.setNha(req.nha);
        absence.setEtudiant(etOpt.get());
        absence.setMatiere(matOpt.get());
        Absence saved = absenceRepository.save(absence);
        return ResponseEntity.ok(new AbsenceDTO(saved.getId(), saved.getDateA(), saved.getNha(), saved.getMatiere().getCodMat(), saved.getEtudiant().getId()));
    }

    @PutMapping("/api/absences/{id}")
    public ResponseEntity<?> updateAbsence(@PathVariable Long id, @RequestBody AbsenceRequest req) {
        Optional<Absence> absOpt = absenceRepository.findById(id);
        if (!absOpt.isPresent()) {
            return ResponseEntity.notFound().build();
        }
        Absence absence = absOpt.get();
        if (req.dateA != null) absence.setDateA(req.dateA);
        if (req.nha != null) absence.setNha(req.nha);
        if (req.codMat != null) {
            Optional<Matiere> matOpt = matiereRepository.findById(req.codMat);
            matOpt.ifPresent(absence::setMatiere);
        }
        Absence saved = absenceRepository.save(absence);
        return ResponseEntity.ok(new AbsenceDTO(saved.getId(), saved.getDateA(), saved.getNha(), saved.getMatiere().getCodMat(), saved.getEtudiant().getId()));
    }

    @DeleteMapping("/api/absences/{id}")
    public ResponseEntity<?> deleteAbsence(@PathVariable Long id) {
        if (!absenceRepository.existsById(id)) {
            return ResponseEntity.notFound().build();
        }
        absenceRepository.deleteById(id);
        return ResponseEntity.ok().build();
    }

    @GetMapping("/api/absences/total/{etudiantId}")
    public List<TotalAbsenceDTO> getTotalAbsencesByMatiere(@PathVariable Long etudiantId) {
        List<Absence> absences = absenceRepository.findByEtudiantId(etudiantId);
        Map<String, Double> totals = new LinkedHashMap<>();
        for (Absence a : absences) {
            if (a.getMatiere() != null) {
                String code = a.getMatiere().getCodMat();
                double nha = a.getNha() != null ? a.getNha() : 0.0;
                totals.put(code, totals.getOrDefault(code, 0.0) + nha);
            }
        }

        List<TotalAbsenceDTO> result = new ArrayList<>();
        for (Map.Entry<String, Double> entry : totals.entrySet()) {
            result.add(new TotalAbsenceDTO(entry.getKey(), entry.getValue()));
        }
        return result;
    }

    @GetMapping("/api/matieres")
    public List<Matiere> getAllMatieres() {
        return matiereRepository.findAll();
    }
}
