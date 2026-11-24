import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:auth/api_config.dart';
import 'package:auth/departement.dart';
import 'package:auth/classe.dart';
import 'package:auth/etudiant.dart';
import 'package:auth/matiere.dart';
import 'package:auth/absence.dart';
import 'package:auth/total_absences_screen.dart';
import 'package:auth/releve_notes_screen.dart';

class AbsencesScreen extends StatefulWidget {
  const AbsencesScreen({super.key});

  @override
  State<AbsencesScreen> createState() => _AbsencesScreenState();
}

class _AbsencesScreenState extends State<AbsencesScreen> {
  // Dropdown data
  List<Departement> departements = [];
  Departement? selectedDept;

  List<Classe> classes = [];
  Classe? selectedClasse;

  List<Etudiant> etudiants = [];
  Etudiant? selectedEtudiant;

  List<Matiere> matieres = [];

  // Absences table data
  List<Absence> absences = [];

  // Controllers for Nom / Prenom text zones
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();

  bool loadingDepts = true;
  bool loadingClasses = false;
  bool loadingEtudiants = false;
  bool loadingAbsences = false;

  @override
  void initState() {
    super.initState();
    fetchDepartements();
    fetchMatieres();
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    super.dispose();
  }

  // 1. Fetch Departements
  Future<void> fetchDepartements() async {
    setState(() => loadingDepts = true);
    try {
      final res = await http.get(Uri.parse("${ApiConfig.baseUrl}/departements"));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data["_embedded"]["departements"] as List;
        final loaded = list.map((e) => Departement.fromMap(e)).toList();
        setState(() {
          departements = loaded;
          loadingDepts = false;
          if (departements.isNotEmpty) {
            selectedDept = departements.first;
          }
        });
        if (selectedDept != null) {
          fetchClassesByDept(selectedDept!.codDept);
        }
      }
    } catch (e) {
      debugPrint("Error fetching departements: $e");
      setState(() => loadingDepts = false);
    }
  }

  // 2. Fetch Classes by Departement
  Future<void> fetchClassesByDept(int codDept) async {
    setState(() {
      loadingClasses = true;
      classes = [];
      selectedClasse = null;
      etudiants = [];
      selectedEtudiant = null;
      absences = [];
      _nomController.clear();
      _prenomController.clear();
    });
    try {
      final res = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/classes/search/byDept?codDept=$codDept"),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final embedded = data["_embedded"];
        List<Classe> loaded = [];
        if (embedded != null && embedded["classes"] != null) {
          final list = embedded["classes"] as List;
          loaded = list.map((e) => Classe.fromMap(e)).toList();
        }
        setState(() {
          classes = loaded;
          loadingClasses = false;
          if (classes.isNotEmpty) {
            selectedClasse = classes.first;
          }
        });
        if (selectedClasse != null) {
          fetchEtudiantsByClasse(selectedClasse!.id);
        }
      }
    } catch (e) {
      debugPrint("Error fetching classes: $e");
      setState(() => loadingClasses = false);
    }
  }

  // 3. Fetch Etudiants by Classe
  Future<void> fetchEtudiantsByClasse(int codClass) async {
    setState(() {
      loadingEtudiants = true;
      etudiants = [];
      selectedEtudiant = null;
      absences = [];
      _nomController.clear();
      _prenomController.clear();
    });
    try {
      final res = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/etudiants/search/byClasse?codClass=$codClass"),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final embedded = data["_embedded"];
        List<Etudiant> loaded = [];
        if (embedded != null && embedded["etudiants"] != null) {
          final list = embedded["etudiants"] as List;
          loaded = list.map((e) => Etudiant.fromMap(e)).toList();
        }
        setState(() {
          etudiants = loaded;
          loadingEtudiants = false;
          if (etudiants.isNotEmpty) {
            selectedEtudiant = etudiants.first;
            _nomController.text = selectedEtudiant!.nom;
            _prenomController.text = selectedEtudiant!.prenom;
          }
        });
        if (selectedEtudiant != null) {
          fetchAbsences(selectedEtudiant!.id);
        }
      }
    } catch (e) {
      debugPrint("Error fetching etudiants: $e");
      setState(() => loadingEtudiants = false);
    }
  }

  // Fetch Matieres for add/edit dialogs
  Future<void> fetchMatieres() async {
    try {
      final res = await http.get(Uri.parse("${ApiConfig.baseUrl}/api/matieres"));
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        setState(() {
          matieres = data.map((e) => Matiere.fromMap(e)).toList();
        });
      }
    } catch (e) {
      debugPrint("Error fetching matieres: $e");
    }
  }

  // 4. Fetch Absences for selected student
  Future<void> fetchAbsences(int etudiantId) async {
    setState(() => loadingAbsences = true);
    try {
      final res = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/api/absences/etudiant/$etudiantId"),
      );
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        setState(() {
          absences = data.map((e) => Absence.fromMap(e)).toList();
          loadingAbsences = false;
        });
      } else {
        setState(() => loadingAbsences = false);
      }
    } catch (e) {
      debugPrint("Error fetching absences: $e");
      setState(() => loadingAbsences = false);
    }
  }

  // Add Absence
  Future<void> addAbsence(String dateA, String codMat, double nha) async {
    if (selectedEtudiant == null) return;
    try {
      final body = jsonEncode({
        "etudiantId": selectedEtudiant!.id,
        "codMat": codMat,
        "dateA": dateA,
        "nha": nha,
      });
      final res = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/api/absences"),
        headers: {"Content-Type": "application/json"},
        body: body,
      );
      if (res.statusCode == 200) {
        fetchAbsences(selectedEtudiant!.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Absence ajoutée avec succès")),
        );
      }
    } catch (e) {
      debugPrint("Error adding absence: $e");
    }
  }

  // Update Absence
  Future<void> updateAbsence(int id, String dateA, String codMat, double nha) async {
    try {
      final body = jsonEncode({
        "codMat": codMat,
        "dateA": dateA,
        "nha": nha,
      });
      final res = await http.put(
        Uri.parse("${ApiConfig.baseUrl}/api/absences/$id"),
        headers: {"Content-Type": "application/json"},
        body: body,
      );
      if (res.statusCode == 200) {
        fetchAbsences(selectedEtudiant!.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Absence mise à jour avec succès")),
        );
      }
    } catch (e) {
      debugPrint("Error updating absence: $e");
    }
  }

  // Delete Absence
  Future<void> deleteAbsence(int id) async {
    try {
      final res = await http.delete(
        Uri.parse("${ApiConfig.baseUrl}/api/absences/$id"),
      );
      if (res.statusCode == 200) {
        fetchAbsences(selectedEtudiant!.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Absence supprimée")),
        );
      }
    } catch (e) {
      debugPrint("Error deleting absence: $e");
    }
  }

  // Show Add/Edit Dialog
  void showAbsenceDialog({Absence? existing}) {
    if (selectedEtudiant == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez sélectionner un étudiant")),
      );
      return;
    }

    final dateController = TextEditingController(
      text: existing != null ? existing.dateA : "11-11-2025",
    );
    final nhaController = TextEditingController(
      text: existing != null ? existing.nha.toString() : "1.5",
    );
    String selectedMat = existing != null && existing.codMat.isNotEmpty
        ? existing.codMat
        : (matieres.isNotEmpty ? matieres.first.codMat : "AFCP");

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(existing == null ? "Ajouter une Absence" : "Modifier l'Absence"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: dateController,
                      decoration: const InputDecoration(
                        labelText: "Date (ex: 11-11-2025)",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedMat,
                      decoration: const InputDecoration(
                        labelText: "Matière (CodMat)",
                        border: OutlineInputBorder(),
                      ),
                      items: matieres
                          .map((m) => DropdownMenuItem(
                                value: m.codMat,
                                child: Text("${m.codMat} - ${m.intMat}"),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedMat = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nhaController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: "Nombre d'heures (NHA)",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Annuler"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                  onPressed: () {
                    final nhaVal = double.tryParse(nhaController.text) ?? 1.5;
                    final dateVal = dateController.text.trim();
                    if (existing == null) {
                      addAbsence(dateVal, selectedMat, nhaVal);
                    } else {
                      updateAbsence(existing.id, dateVal, selectedMat, nhaVal);
                    }
                    Navigator.pop(ctx);
                  },
                  child: Text(
                    existing == null ? "Ajouter" : "Mettre à jour",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loadingDepts) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Filter Card: 3 Dropdowns
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Sélection des critères",
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 1. Departement Dropdown
                    Row(
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(
                            "Département :",
                            style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Expanded(
                          child: DropdownButton<Departement>(
                            isExpanded: true,
                            value: selectedDept,
                            hint: const Text("Choisir un département"),
                            items: departements
                                .map((d) => DropdownMenuItem(
                                      value: d,
                                      child: Text(d.nomDept),
                                    ))
                                .toList(),
                            onChanged: (Departement? newDept) {
                              if (newDept != null) {
                                setState(() => selectedDept = newDept);
                                fetchClassesByDept(newDept.codDept);
                              }
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // 2. Classe Dropdown
                    Row(
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(
                            "Classe :",
                            style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Expanded(
                          child: loadingClasses
                              ? const LinearProgressIndicator()
                              : DropdownButton<Classe>(
                                  isExpanded: true,
                                  value: selectedClasse,
                                  hint: const Text("Choisir une classe"),
                                  items: classes
                                      .map((c) => DropdownMenuItem(
                                            value: c,
                                            child: Text(c.nomClass),
                                          ))
                                      .toList(),
                                  onChanged: (Classe? newClasse) {
                                    if (newClasse != null) {
                                      setState(() => selectedClasse = newClasse);
                                      fetchEtudiantsByClasse(newClasse.id);
                                    }
                                  },
                                ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // 3. Etudiant Dropdown
                    Row(
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(
                            "Etudiant :",
                            style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Expanded(
                          child: loadingEtudiants
                              ? const LinearProgressIndicator()
                              : DropdownButton<Etudiant>(
                                  isExpanded: true,
                                  value: selectedEtudiant,
                                  hint: const Text("Choisir un étudiant"),
                                  items: etudiants
                                      .map((e) => DropdownMenuItem(
                                            value: e,
                                            child: Text("E${e.id} - ${e.nom} ${e.prenom}"),
                                          ))
                                      .toList(),
                                  onChanged: (Etudiant? newEtudiant) {
                                    if (newEtudiant != null) {
                                      setState(() {
                                        selectedEtudiant = newEtudiant;
                                        _nomController.text = newEtudiant.nom;
                                        _prenomController.text = newEtudiant.prenom;
                                      });
                                      fetchAbsences(newEtudiant.id);
                                    }
                                  },
                                ),
                        ),
                      ],
                    ),

                    const Divider(height: 24),

                    // Nom & Prenom TextZones
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _nomController,
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: "Nom de l'étudiant",
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _prenomController,
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: "Prénom de l'étudiant",
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Absences Table Header with "Voir Total & Courbe" button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Tableau des Absences",
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade900,
                  ),
                ),
                if (selectedEtudiant != null)
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo.shade700,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReleveNotesScreen(
                                etudiantId: selectedEtudiant!.id,
                                etudiant: selectedEtudiant,
                                initialClasseName: selectedClasse?.nomClass,
                                initialDeptName: selectedDept?.nomDept,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.assignment, size: 18),
                        label: const Text("Relevé de Notes"),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple.shade700,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TotalAbsencesScreen(
                                etudiantId: selectedEtudiant!.id,
                                nom: selectedEtudiant!.nom,
                                prenom: selectedEtudiant!.prenom,
                                nomClass: selectedClasse?.nomClass ?? "",
                                nomDept: selectedDept?.nomDept ?? "",
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.bar_chart, size: 18),
                        label: const Text("Total & Courbe"),
                      ),
                    ],
                  ),
              ],
            ),

            const SizedBox(height: 8),

            // Absences DataTable Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: loadingAbsences
                  ? const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : absences.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Center(child: Text("Aucune absence enregistrée pour cet étudiant.")),
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(Colors.purple.shade50),
                            columns: const [
                              DataColumn(
                                label: Text("DateA", style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              DataColumn(
                                label: Text("CodMat", style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              DataColumn(
                                label: Text("NHA", style: TextStyle(fontWeight: FontWeight.bold)),
                                numeric: true,
                              ),
                              DataColumn(
                                label: Text("Actions", style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                            rows: absences.map((a) {
                              return DataRow(
                                cells: [
                                  DataCell(Text(a.dateA)),
                                  DataCell(Text(
                                    a.codMat,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  )),
                                  DataCell(Text("${a.nha} h")),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Edit button
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.blue),
                                          tooltip: "Mettre à jour",
                                          onPressed: () => showAbsenceDialog(existing: a),
                                        ),
                                        // Delete button
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          tooltip: "Supprimer",
                                          onPressed: () => deleteAbsence(a.id),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
            ),

            const SizedBox(height: 80), // Space for floating button
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.purple,
        onPressed: () => showAbsenceDialog(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Ajouter une absence",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
