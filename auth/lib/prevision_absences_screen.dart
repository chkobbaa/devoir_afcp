import 'dart:convert';
import 'package:auth/api_config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PrevisionAbsencesScreen extends StatefulWidget {
  const PrevisionAbsencesScreen({super.key});

  @override
  State<PrevisionAbsencesScreen> createState() => _PrevisionAbsencesScreenState();
}

class _PrevisionAbsencesScreenState extends State<PrevisionAbsencesScreen> {
  List classes = [];
  List matieres = [];
  List absents = [];
  Map? classe;
  Map? matiere;
  DateTime date = DateTime.now();
  double chsm = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    charger();
  }

  Future<void> charger() async {
    final r = await Future.wait([
      http.get(Uri.parse('${ApiConfig.baseUrl}/api/manage/classes')),
      http.get(Uri.parse('${ApiConfig.baseUrl}/api/matieres')),
    ]);
    if (!mounted) return;
    setState(() {
      classes = jsonDecode(r[0].body);
      matieres = jsonDecode(r[1].body);
      classe = classes.isEmpty ? null : classes.first;
      matiere = matieres.isEmpty ? null : matieres.first;
      loading = false;
    });
  }

  Future<void> afficherAbsents() async {
    if (classe == null || matiere == null) return;
    final dateChoisie = '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    final liens = jsonDecode((await http.get(Uri.parse('${ApiConfig.baseUrl}/api/manage/class-subjects'))).body) as List;
    final lien = liens.where((x) => x['codClass'] == classe!['codClass'] && x['codMat'] == matiere!['codMat']).toList();
    chsm = lien.isEmpty ? 0 : (lien.first['chsm'] as num?)?.toDouble() ?? 0;
    final r = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/manage/students?codClass=${classe!['codClass']}'));
    final etudiants = jsonDecode(r.body) as List;
    final resultats = [];
    for (final e in etudiants) {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/absences/etudiant/${e['id']}'));
      for (final a in jsonDecode(response.body) as List) {
        if (a['codMat'] == matiere!['codMat'] && a['dateA'].toString() == dateChoisie) {
          resultats.add({'nom': e['nom'], 'prenom': e['prenom'], 'nha': a['nha']});
        }
      }
    }
    if (mounted) setState(() => absents = resultats);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    return ListView(padding: const EdgeInsets.all(16), children: [
      DropdownButtonFormField<Map>(value: classe, decoration: const InputDecoration(labelText: 'Classe'), items: classes.map<DropdownMenuItem<Map>>((c) => DropdownMenuItem(value: c, child: Text(c['nomClass']))).toList(), onChanged: (v) => setState(() { classe = v; afficherAbsents(); })),
      DropdownButtonFormField<Map>(value: matiere, decoration: const InputDecoration(labelText: 'Matière'), items: matieres.map<DropdownMenuItem<Map>>((m) => DropdownMenuItem(value: m, child: Text(m['intMat']))).toList(), onChanged: (v) => setState(() { matiere = v; afficherAbsents(); })),
      ListTile(title: const Text('Date'), subtitle: Text('${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}'), onTap: () async { final d = await showDatePicker(context: context, initialDate: date, firstDate: DateTime(2000), lastDate: DateTime(2100)); if (d != null) setState(() { date = d; afficherAbsents(); }); }),
      Text('Classe: ${classe?['nomClass'] ?? ''}'),
      Text('Departement: ${classe?['nomDept'] ?? ''}'),
      Text('Matiere: ${matiere?['codMat'] ?? ''}'),
      Text('CHSM: $chsm heures'),
      Text('Date: ${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}'),
      DataTable(columns: const [DataColumn(label: Text('Nom')), DataColumn(label: Text('Prenom')), DataColumn(label: Text('NHA'))], rows: absents.map<DataRow>((e) => DataRow(cells: [DataCell(Text('${e['nom']}')), DataCell(Text('${e['prenom']}')), DataCell(Text('${e['nha']}'))])).toList()),
    ]);
  }
}
