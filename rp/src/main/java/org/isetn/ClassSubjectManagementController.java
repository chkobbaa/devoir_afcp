package org.isetn;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/api/manage/class-subjects")
@CrossOrigin("*")
public class ClassSubjectManagementController {
    @Autowired private ClassMatRepository repository;
    @Autowired private ClasseRepository classeRepository;
    @Autowired private MatiereRepository matiereRepository;

    public static class LinkRequest {
        public Long codClass;
        public String codMat;
        public Double coef;
        public Double chsm;
    }
    public static class LinkDTO {
        public Long id;
        public Long codClass;
        public String nomClass;
        public String codMat;
        public String intMat;
        public Double coef;
        public Double chsm;
        LinkDTO(ClassMat row) {
            id = row.getId();
            codClass = row.getClasse().getCodClass();
            nomClass = row.getClasse().getNomClass();
            codMat = row.getMatiere().getCodMat();
            intMat = row.getMatiere().getIntMat();
            coef = row.getCoef();
            chsm = row.getChsm();
        }
    }

    @GetMapping
    public List<LinkDTO> list() {
        List<LinkDTO> result = new ArrayList<>();
        for (ClassMat row : repository.findAll()) result.add(new LinkDTO(row));
        return result;
    }

    private ResponseEntity<?> save(LinkRequest req, ClassMat row) {
        if (req.codClass == null || req.codMat == null || req.codMat.trim().isEmpty())
            return ResponseEntity.badRequest().body("Classe and Matiere are required");
        Optional<Classe> classe = classeRepository.findById(req.codClass);
        Optional<Matiere> matiere = matiereRepository.findById(req.codMat);
        if (!classe.isPresent() || !matiere.isPresent()) return ResponseEntity.badRequest().body("Classe or Matiere not found");
        Optional<ClassMat> duplicate = repository.findByClasseCodClassAndMatiereCodMat(req.codClass, req.codMat);
        if (duplicate.isPresent() && (row.getId() == null || !duplicate.get().getId().equals(row.getId())))
            return ResponseEntity.badRequest().body("This subject is already linked to the class");
        row.setClasse(classe.get()); row.setMatiere(matiere.get()); row.setCoef(req.coef); row.setChsm(req.chsm);
        return ResponseEntity.ok(new LinkDTO(repository.save(row)));
    }

    @PostMapping
    public ResponseEntity<?> create(@RequestBody LinkRequest req) { return save(req, new ClassMat()); }

    @PutMapping("/{id}")
    public ResponseEntity<?> update(@PathVariable Long id, @RequestBody LinkRequest req) {
        Optional<ClassMat> row = repository.findById(id);
        if (!row.isPresent()) return ResponseEntity.notFound().build();
        return save(req, row.get());
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> delete(@PathVariable Long id) {
        if (!repository.existsById(id)) return ResponseEntity.notFound().build();
        repository.deleteById(id); return ResponseEntity.ok().build();
    }
}
