package org.isetn;

import java.util.Date;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class ScolA7Application implements CommandLineRunner {
	@Autowired
	private FormationRepository formationRepository;

	@Autowired
	private ClasseRepository classeRepository;

	@Autowired
	private EtudiantRepository etudiantRepository;

	@Autowired
	private UserRepository userRepository;

	@Autowired
	private DepartementRepository departementRepository;

	@Autowired
	private MatiereRepository matiereRepository;

	@Autowired
	private AbsenceRepository absenceRepository;

	@Autowired
	private NoteRepository noteRepository;

	public static void main(String[] args) {
		SpringApplication.run(ScolA7Application.class, args);
	}

	@Override
	public void run(String... args) throws Exception {
		// Keep the demo seed idempotent and preserve records created by the app.
		if (userRepository.count() > 0 || departementRepository.count() > 0) {
			return;
		}

		// Formations
		Formation f1 = formationRepository.save(new Formation(null, "DSI", 100, null));
		Formation f2 = formationRepository.save(new Formation(null, "RSI", 10, null));
		Formation f3 = formationRepository.save(new Formation(null, "SEM", 120, null));

		// Departements
		Departement d1 = departementRepository.save(new Departement(null, "TI", null));
		Departement d2 = departementRepository.save(new Departement(null, "GE", null));
		Departement d3 = departementRepository.save(new Departement(null, "GM", null));

		// Classes with Departement
		Classe c1 = classeRepository.save(new Classe(null, "DSI33", 25, d1, null));
		Classe c2 = classeRepository.save(new Classe(null, "DSI21", 20, d1, null));
		Classe c3 = classeRepository.save(new Classe(null, "DSI22", 27, d1, null));
		Classe c4 = classeRepository.save(new Classe(null, "GE11", 30, d2, null));

		// User
		userRepository.save(new User(null, "admin@gmail.com", "admin"));

		// Students
		Etudiant e1 = etudiantRepository.save(new Etudiant(null, "Ben Foulen1", "Foulen1", new Date(), "Nabeul", f1, c1, null));
		Etudiant e2 = etudiantRepository.save(new Etudiant(null, "Ben Ali", "Ali", new Date(), "Tunis", f1, c1, null));
		Etudiant e3 = etudiantRepository.save(new Etudiant(null, "Ben Mohamed", "Mohamed", new Date(), "Sousse", f1, c2, null));
		Etudiant e4 = etudiantRepository.save(new Etudiant(null, "Ben Mahmoud", "Amin", new Date(), "Sfax", f2, c3, null));

		// Matieres with Coefficients
		Matiere m1 = matiereRepository.save(new Matiere("AFCP", "Atelier Framework Cross Platform", "Flutter & Spring Boot", 1.5));
		Matiere m2 = matiereRepository.save(new Matiere("SOA", "Architecture Orientee Services", "REST & Microservices", 2.0));
		Matiere m3 = matiereRepository.save(new Matiere("DEV_WEB", "Developpement Web Avance", "Angular & React", 1.5));
		Matiere m4 = matiereRepository.save(new Matiere("M012", "Base de Donnees Avancee", "SGBD & SQL", 2.0));

		// Absences as per TP example for student e1 (Ben Foulen1 Foulen1)
		absenceRepository.save(new Absence(null, "11-11-2025", 1.5, e1, m1));
		absenceRepository.save(new Absence(null, "04-10-2025", 4.5, e1, m1));
		absenceRepository.save(new Absence(null, "20-10-2025", 1.5, e1, m2));
		absenceRepository.save(new Absence(null, "23-10-2025", 3.0, e1, m2));
		absenceRepository.save(new Absence(null, "16-10-2025", 3.0, e1, m2));

		// Notes: Note (#NCE, #CodMat, tp1, tp2, ds, examen)
		// e1 notes (Ben Foulen1):
		// - AFCP: Pure TP (50/50): 18.0, 17.0
		// - SOA: Mixed TP + DS + Examen: tp1=15.0, tp2=14.0, ds=13.0, examen=15.0
		// - DEV_WEB: Only DS and Examen (40/60): ds=14.0, examen=16.0
		// - M012: Note (E1, M012, 18, 17, NULL, NULL) as per example!
		noteRepository.save(new Note(null, e1, m1, 18.0, 17.0, null, null));
		noteRepository.save(new Note(null, e1, m2, 15.0, 14.0, 13.0, 15.0));
		noteRepository.save(new Note(null, e1, m3, null, null, 14.0, 16.0));
		noteRepository.save(new Note(null, e1, m4, 18.0, 17.0, null, null));

		// e2 notes (Ben Ali):
		noteRepository.save(new Note(null, e2, m1, 14.0, 15.0, null, null));
		noteRepository.save(new Note(null, e2, m2, 12.0, 13.0, 11.0, 12.5));
		noteRepository.save(new Note(null, e2, m3, null, null, 12.0, 13.0));
		noteRepository.save(new Note(null, e2, m4, 15.0, 16.0, null, null));

		// e3 notes (Ben Mohamed):
		noteRepository.save(new Note(null, e3, m1, 16.0, 17.0, null, null));
		noteRepository.save(new Note(null, e3, m2, 14.0, 15.0, 13.5, 14.0));
		noteRepository.save(new Note(null, e3, m3, null, null, 15.0, 16.5));
	}
}
