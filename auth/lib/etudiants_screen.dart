import 'dart:convert';
import 'package:auth/api_config.dart';
import 'package:auth/classe.dart';
import 'package:auth/etudiant.dart';
import 'package:auth/formation.dart';
import 'package:auth/releve_notes_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class EtudiantsScreen extends StatefulWidget {
  const EtudiantsScreen({super.key});
  @override
  State<EtudiantsScreen> createState() => _EtudiantsScreenState();
}

class _EtudiantsScreenState extends State<EtudiantsScreen> {
  List<Classe> classes = [];
  Classe? selectedClasse;
  List<Etudiant> etudiants = [];
  List<Formation> formations = [];
  bool loadingClasses = true;
  bool loadingEtudiants = false;
  String get studentsUrl => '${ApiConfig.baseUrl}/api/manage/students';

  @override
  void initState() { super.initState(); fetchClasses(); }

  Future<void> fetchClasses() async {
    setState(() => loadingClasses = true);
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/classes'));
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final list = data['_embedded']?['classes'] as List? ?? [];
      final loaded = list.map((e) => Classe.fromMap(e)).toList();
      if (!mounted) return;
      setState(() { classes = loaded; selectedClasse = loaded.isEmpty ? null : loaded.first; loadingClasses = false; });
      if (selectedClasse != null) await fetchEtudiants(selectedClasse!.id);
    } catch (error) {
      if (!mounted) return;
      setState(() => loadingClasses = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Chargement des classes impossible : $error')));
    }
  }

  Future<void> fetchEtudiants(int classeId) async {
    setState(() => loadingEtudiants = true);
    try {
      final results = await Future.wait([
        http.get(Uri.parse('$studentsUrl?codClass=$classeId')),
        http.get(Uri.parse('${ApiConfig.baseUrl}/formations')),
      ]);
      if (results[0].statusCode != 200 || results[1].statusCode != 200) throw Exception('Réponse serveur invalide');
      final students = (jsonDecode(results[0].body) as List).map((e) => Etudiant.fromMap(e)).toList();
      final formationData = jsonDecode(results[1].body) as Map<String, dynamic>;
      final formationList = formationData['_embedded']?['formations'] as List? ?? [];
      if (!mounted) return;
      setState(() {
        etudiants = students;
        formations = formationList.map((e) => Formation.fromMap(e)).toList();
        loadingEtudiants = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => loadingEtudiants = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Chargement des étudiants impossible : $error')));
    }
  }

  Future<void> editStudent([Etudiant? student]) async {
    if (selectedClasse == null || formations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Créez d’abord une classe et une formation.')));
      return;
    }
    final nce = TextEditingController(text: student?.displayNce ?? '');
    final nom = TextEditingController(text: student?.nom ?? '');
    final prenom = TextEditingController(text: student?.prenom ?? '');
    final date = TextEditingController(text: student?.dateNais?.split('T').first ?? '');
    final lieu = TextEditingController(text: student?.lieuNais ?? '');
    int? formationId = student?.formationId ?? formations.first.id;
    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
        title: Text(student == null ? 'Ajouter un étudiant' : 'Modifier l’étudiant'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nce, decoration: const InputDecoration(labelText: 'NCE')),
          TextField(controller: nom, decoration: const InputDecoration(labelText: 'Nom')),
          TextField(controller: prenom, decoration: const InputDecoration(labelText: 'Prénom')),
          TextField(controller: date, decoration: const InputDecoration(labelText: 'Date de naissance (AAAA-MM-JJ)')),
          TextField(controller: lieu, decoration: const InputDecoration(labelText: 'Lieu de naissance')),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: formationId,
            decoration: const InputDecoration(labelText: 'Formation'),
            items: formations.map((f) => DropdownMenuItem(value: f.id, child: Text(f.nom))).toList(),
            onChanged: (value) => setDialogState(() => formationId = value),
          ),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Annuler')),
          FilledButton(onPressed: () {
            if (nom.text.trim().isEmpty || prenom.text.trim().isEmpty || formationId == null) return;
            Navigator.pop(dialogContext, {
              'nce': nce.text.trim(), 'nom': nom.text.trim(), 'prenom': prenom.text.trim(),
              'dateNais': date.text.trim(), 'lieuNais': lieu.text.trim(),
              'codClass': selectedClasse!.id, 'formationId': formationId,
            });
          }, child: const Text('Enregistrer')),
        ],
      )),
    );
    nce.dispose(); nom.dispose(); prenom.dispose(); date.dispose(); lieu.dispose();
    if (payload == null) return;
    try {
      final response = student == null
          ? await http.post(Uri.parse(studentsUrl), headers: {'Content-Type': 'application/json'}, body: jsonEncode(payload))
          : await http.put(Uri.parse('$studentsUrl/${student.id}'), headers: {'Content-Type': 'application/json'}, body: jsonEncode(payload));
      if (response.statusCode < 200 || response.statusCode >= 300) throw Exception('HTTP ${response.statusCode}');
      await fetchEtudiants(selectedClasse!.id);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Enregistrement impossible : $error')));
    }
  }

  Future<void> deleteStudent(Etudiant student) async {
    try {
      final response = await http.delete(Uri.parse('$studentsUrl/${student.id}'));
      if (response.statusCode < 200 || response.statusCode >= 300) throw Exception('L’étudiant possède des notes ou des absences.');
      await fetchEtudiants(selectedClasse!.id);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Suppression impossible : $error')));
    }
  }

  void openReleve(Etudiant e) => Navigator.push(context, MaterialPageRoute(builder: (_) => ReleveNotesScreen(
    etudiantId: e.id, etudiant: e, initialClasseName: selectedClasse?.nomClass,
  )));

  @override
  Widget build(BuildContext context) {
    if (loadingClasses) return const Center(child: CircularProgressIndicator());
    return Scaffold(
      body: Column(children: [
        Container(padding: const EdgeInsets.all(12), color: Colors.purple.shade50, child: Row(children: [
          Text('Classe : ', style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.bold)),
          Expanded(child: DropdownButton<Classe>(
            isExpanded: true, value: selectedClasse,
            items: classes.map((c) => DropdownMenuItem(value: c, child: Text(c.nomClass))).toList(),
            onChanged: (value) { if (value != null) { setState(() { selectedClasse = value; etudiants = []; }); fetchEtudiants(value.id); } },
          )),
        ])),
        Container(width: double.infinity, padding: const EdgeInsets.all(8), color: Colors.purple.shade100.withValues(alpha: .5), child: const Text('Sélectionnez un étudiant pour consulter son relevé de notes.')),
        Expanded(child: loadingEtudiants ? const Center(child: CircularProgressIndicator()) : etudiants.isEmpty
          ? const Center(child: Text('Aucun étudiant dans cette classe.'))
          : ListView.builder(itemCount: etudiants.length, itemBuilder: (context, i) {
            final e = etudiants[i];
            return Card(margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), child: ListTile(
              onTap: () => openReleve(e),
              leading: CircleAvatar(backgroundColor: Colors.purple, child: Text(e.nom.isEmpty ? 'E' : e.nom[0].toUpperCase(), style: const TextStyle(color: Colors.white))),
              title: Text('${e.nom} ${e.prenom}'),
              subtitle: Text('NCE : ${e.displayNce}'),
              trailing: Wrap(children: [
                IconButton(tooltip: 'Relevé', onPressed: () => openReleve(e), icon: const Icon(Icons.assignment_outlined, color: Colors.purple)),
                IconButton(tooltip: 'Modifier', onPressed: () => editStudent(e), icon: const Icon(Icons.edit, color: Colors.indigo)),
                IconButton(tooltip: 'Supprimer', onPressed: () => deleteStudent(e), icon: const Icon(Icons.delete, color: Colors.red)),
              ]),
            ));
          })),
      ]),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => editStudent(), icon: const Icon(Icons.add), label: const Text('Ajouter un étudiant')),
    );
  }
}
