package org.isetn;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.sql.Date;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/api/manage")
@CrossOrigin("*")
public class AcademicManagementController {
    @Autowired private ClasseRepository classeRepository;
    @Autowired private DepartementRepository departementRepository;
    @Autowired private EtudiantRepository etudiantRepository;
    @Autowired private FormationRepository formationRepository;

    public static class ClassRequest {
        public String nomClass;
        public int nbreEtud;
        public Long codDept;
    }

    public static class ClassDTO {
        public Long codClass;
        public String nomClass;
        public int nbreEtud;
        public Long codDept;
        public String nomDept;
        ClassDTO(Classe c) {
            codClass = c.getCodClass(); nomClass = c.getNomClass(); nbreEtud = c.getNbreEtud();
            if (c.getDepartement() != null) {
                codDept = c.getDepartement().getCodDept(); nomDept = c.getDepartement().getNomDept();
            }
        }
    }

    public static class StudentRequest {
        public String nce;
        public String nom;
        public String prenom;
        public String dateNais;
        public String lieuNais;
        public Long codClass;
        public Long formationId;
    }

    public static class StudentDTO {
        public Long id;
        public String nce;
        public String nom;
        public String prenom;
        public Date dateNais;
        public String lieuNais;
        public Long classeId;
        public Long formationId;
        StudentDTO(Etudiant e) {
            id=e.getId(); nce=e.getNce(); nom=e.getNom(); prenom=e.getPrenom();
            dateNais=e.getDateNais() == null ? null : new Date(e.getDateNais().getTime());
            lieuNais=e.getLieuNais();
            if(e.getClasse()!=null) classeId=e.getClasse().getCodClass();
            if(e.getFormation()!=null) formationId=e.getFormation().getId();
        }
    }

    @GetMapping("/classes")
    public List<ClassDTO> getClasses() {
        List<ClassDTO> result = new ArrayList<>();
        for (Classe c : classeRepository.findAll()) result.add(new ClassDTO(c));
        return result;
    }

    @PutMapping("/classes/{id}/count-students")
    public ResponseEntity<?> updateStudentCount(@PathVariable Long id) {
        Optional<Classe> classe = classeRepository.findById(id);
        if (!classe.isPresent()) return ResponseEntity.notFound().build();
        int count = etudiantRepository.findByClasseCodClass(id).size();
        classe.get().setNbreEtud(count);
        classeRepository.save(classe.get());
        return ResponseEntity.ok(new ClassDTO(classe.get()));
    }

    @PostMapping("/classes")
    public ResponseEntity<?> addClass(@RequestBody ClassRequest req) {
        Optional<Departement> dept = req.codDept == null ? Optional.empty() : departementRepository.findById(req.codDept);
        if (req.codDept != null && !dept.isPresent()) return ResponseEntity.badRequest().body("Departement not found");
        return ResponseEntity.ok(new ClassDTO(classeRepository.save(new Classe(null, req.nomClass, req.nbreEtud, dept.orElse(null), null))));
    }

    @PutMapping("/classes/{id}")
    public ResponseEntity<?> updateClass(@PathVariable Long id, @RequestBody ClassRequest req) {
        Optional<Classe> current = classeRepository.findById(id);
        if (!current.isPresent()) return ResponseEntity.notFound().build();
        Optional<Departement> dept = req.codDept == null ? Optional.empty() : departementRepository.findById(req.codDept);
        if (req.codDept != null && !dept.isPresent()) return ResponseEntity.badRequest().body("Departement not found");
        Classe c = current.get(); c.setNomClass(req.nomClass); c.setNbreEtud(req.nbreEtud); c.setDepartement(dept.orElse(null));
        return ResponseEntity.ok(new ClassDTO(classeRepository.save(c)));
    }

    @DeleteMapping("/classes/{id}")
    public ResponseEntity<?> deleteClass(@PathVariable Long id) {
        if (!classeRepository.existsById(id)) return ResponseEntity.notFound().build();
        classeRepository.deleteById(id); return ResponseEntity.ok().build();
    }

    @GetMapping("/students")
    public List<StudentDTO> getStudents(@RequestParam(required=false) Long codClass) {
        List<StudentDTO> result = new ArrayList<>();
        List<Etudiant> students = codClass == null ? etudiantRepository.findAll() : etudiantRepository.findByClasseCodClass(codClass);
        for (Etudiant e : students) result.add(new StudentDTO(e));
        return result;
    }

    private ResponseEntity<?> persistStudent(StudentRequest req, Etudiant student) {
        if (req.codClass == null || !classeRepository.existsById(req.codClass)) return ResponseEntity.badRequest().body("Classe not found");
        if (req.formationId == null || !formationRepository.existsById(req.formationId)) return ResponseEntity.badRequest().body("Formation not found");
        student.setNce(req.nce); student.setNom(req.nom); student.setPrenom(req.prenom); student.setLieuNais(req.lieuNais);
        student.setClasse(classeRepository.findById(req.codClass).get());
        student.setFormation(formationRepository.findById(req.formationId).get());
        try {
            student.setDateNais(req.dateNais == null || req.dateNais.isEmpty() ? null : Date.valueOf(req.dateNais));
        } catch (IllegalArgumentException error) {
            return ResponseEntity.badRequest().body("dateNais must use yyyy-MM-dd");
        }
        return ResponseEntity.ok(new StudentDTO(etudiantRepository.save(student)));
    }

    @PostMapping("/students")
    public ResponseEntity<?> addStudent(@RequestBody StudentRequest req) {
        return persistStudent(req, new Etudiant());
    }

    @PutMapping("/students/{id}")
    public ResponseEntity<?> updateStudent(@PathVariable Long id, @RequestBody StudentRequest req) {
        Optional<Etudiant> student = etudiantRepository.findById(id);
        if (!student.isPresent()) return ResponseEntity.notFound().build();
        return persistStudent(req, student.get());
    }

    @DeleteMapping("/students/{id}")
    public ResponseEntity<?> deleteStudent(@PathVariable Long id) {
        if (!etudiantRepository.existsById(id)) return ResponseEntity.notFound().build();
        etudiantRepository.deleteById(id); return ResponseEntity.ok().build();
    }
}
