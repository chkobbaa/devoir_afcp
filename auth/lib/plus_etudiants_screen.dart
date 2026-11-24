import 'dart:convert';
import 'package:auth/api_config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PlusEtudiantsScreen extends StatefulWidget {
  const PlusEtudiantsScreen({super.key});

  @override
  State<PlusEtudiantsScreen> createState() => _PlusEtudiantsScreenState();
}

class _PlusEtudiantsScreenState extends State<PlusEtudiantsScreen> {
  Map? classeMax;
  int total = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    compter();
  }

  Future<void> compter() async {
    final reponses = await Future.wait([
      http.get(Uri.parse('${ApiConfig.baseUrl}/api/manage/classes')),
      http.get(Uri.parse('${ApiConfig.baseUrl}/api/manage/students')),
    ]);
    final classes = jsonDecode(reponses[0].body) as List;
    final etudiants = jsonDecode(reponses[1].body) as List;
    for (final c in classes) {
      final n = etudiants.where((e) => e['classeId'] == c['codClass']).length;
      if (classeMax == null || n > total) {
        classeMax = c;
        total = n;
      }
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> mettreAJour() async {
    await http.put(Uri.parse('${ApiConfig.baseUrl}/api/manage/classes/${classeMax!['codClass']}/count-students'));
    await compter();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nombre d’étudiants mis à jour')));
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (classeMax == null) return const Center(child: Text('Aucune classe trouvée'));
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Classe : ${classeMax!['nomClass']}'),
        Text('Nombre réel d’étudiants : $total'),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: mettreAJour, child: const Text('recalculer nbr etudiants')),
      ]),
    );
  }
}
