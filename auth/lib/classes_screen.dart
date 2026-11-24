import 'dart:convert';
import 'package:auth/api_config.dart';
import 'package:auth/classe.dart';
import 'package:auth/departement.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});
  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  List<Classe> classes = [];
  List<Departement> departements = [];
  bool loading = true;
  String get url => '${ApiConfig.baseUrl}/api/manage/classes';

  @override
  void initState() { super.initState(); loadData(); }

  Future<void> loadData() async {
    setState(() => loading = true);
    try {
      final responses = await Future.wait([
        http.get(Uri.parse(url)),
        http.get(Uri.parse('${ApiConfig.baseUrl}/departements')),
      ]);
      final classData = jsonDecode(responses[0].body) as List;
      final deptData = jsonDecode(responses[1].body) as Map<String, dynamic>;
      final deptList = (deptData['_embedded']?['departements'] as List? ?? []);
      if (!mounted) return;
      setState(() {
        classes = classData.map((e) => Classe.fromMap(e)).toList();
        departements = deptList.map((e) => Departement.fromMap(e)).toList();
        loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Chargement impossible : $error')));
    }
  }

  Future<void> editClass([Classe? item]) async {
    final name = TextEditingController(text: item?.nomClass ?? '');
    final count = TextEditingController(text: item?.nbreEtud.toString() ?? '0');
    final currentDeptExists = item?.codDept != null && departements.any((d) => d.codDept == item!.codDept);
    int? deptId = currentDeptExists ? item!.codDept : (departements.isEmpty ? null : departements.first.codDept);
    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
        title: Text(item == null ? 'Ajouter une classe' : 'Modifier la classe'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Nom de classe')),
          TextField(controller: count, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Nombre d’étudiants')),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: deptId,
            decoration: const InputDecoration(labelText: 'Département'),
            items: departements.map((d) => DropdownMenuItem(value: d.codDept, child: Text(d.nomDept))).toList(),
            onChanged: (value) => setDialogState(() => deptId = value),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Annuler')),
          FilledButton(onPressed: () {
            if (name.text.trim().isEmpty || int.tryParse(count.text) == null || deptId == null) return;
            Navigator.pop(dialogContext, {'nomClass': name.text.trim(), 'nbreEtud': int.parse(count.text), 'codDept': deptId});
          }, child: const Text('Enregistrer')),
        ],
      )),
    );
    name.dispose(); count.dispose();
    if (payload == null) return;
    try {
      final response = item == null
          ? await http.post(Uri.parse(url), headers: {'Content-Type': 'application/json'}, body: jsonEncode(payload))
          : await http.put(Uri.parse('$url/${item.id}'), headers: {'Content-Type': 'application/json'}, body: jsonEncode(payload));
      if (response.statusCode < 200 || response.statusCode >= 300) throw Exception('HTTP ${response.statusCode}');
      await loadData();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Enregistrement impossible : $error')));
    }
  }

  Future<void> deleteClass(Classe item) async {
    try {
      final response = await http.delete(Uri.parse('$url/${item.id}'));
      if (response.statusCode < 200 || response.statusCode >= 300) throw Exception('Cette classe contient peut-être des étudiants.');
      await loadData();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Suppression impossible : $error')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: loading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(
      onRefresh: loadData,
      child: classes.isEmpty ? ListView(children: const [SizedBox(height: 160), Center(child: Text('Aucune classe trouvée.'))]) : ListView.builder(
        itemCount: classes.length,
        itemBuilder: (context, i) {
          final c = classes[i];
          return Card(margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), child: ListTile(
            leading: const Icon(Icons.class_, color: Colors.purple),
            title: Text(c.nomClass, style: GoogleFonts.roboto(fontSize: 16)),
            subtitle: Text('Étudiants : ${c.nbreEtud}'),
            trailing: Wrap(children: [
              IconButton(onPressed: () => editClass(c), icon: const Icon(Icons.edit, color: Colors.indigo)),
              IconButton(onPressed: () => deleteClass(c), icon: const Icon(Icons.delete, color: Colors.red)),
            ]),
          ));
        },
      ),
    ),
    floatingActionButton: FloatingActionButton.extended(onPressed: () => editClass(), icon: const Icon(Icons.add), label: const Text('Ajouter une classe')),
  );
}
