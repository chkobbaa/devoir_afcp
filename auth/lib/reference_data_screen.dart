import 'dart:convert';

import 'package:auth/api_config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

enum ReferenceKind { departments, subjects, users, formations, classSubjects }

class ReferenceDataScreen extends StatefulWidget {
  final ReferenceKind kind;
  const ReferenceDataScreen({super.key, required this.kind});

  @override
  State<ReferenceDataScreen> createState() => _ReferenceDataScreenState();
}

class _ReferenceDataScreenState extends State<ReferenceDataScreen> {
  List<Map<String, dynamic>> rows = [];
  bool loading = true;

  String get resource => switch (widget.kind) {
        ReferenceKind.departments => 'departements',
        ReferenceKind.subjects => 'matieres',
        ReferenceKind.users => 'users',
        ReferenceKind.formations => 'formations',
        ReferenceKind.classSubjects => 'api/manage/class-subjects',
      };
  String get title => switch (widget.kind) {
        ReferenceKind.departments => 'Départements',
        ReferenceKind.subjects => 'Matières',
        ReferenceKind.users => 'Utilisateurs',
        ReferenceKind.formations => 'Formations',
        ReferenceKind.classSubjects => 'Matières par classe',
      };
  String get idField => switch (widget.kind) {
        ReferenceKind.departments => 'codDept',
        ReferenceKind.subjects => 'codMat',
        ReferenceKind.users => 'id',
        ReferenceKind.formations => 'id',
        ReferenceKind.classSubjects => 'id',
      };
  List<String> get fields => switch (widget.kind) {
        ReferenceKind.departments => ['nomDept'],
        ReferenceKind.subjects => ['codMat', 'intMat', 'description', 'coef'],
        ReferenceKind.users => ['email', 'password'],
        ReferenceKind.formations => ['nom', 'duree'],
        ReferenceKind.classSubjects => ['codClass', 'codMat', 'coef', 'chsm'],
      };
  String get collectionKey => switch (widget.kind) {
        ReferenceKind.departments => 'departements',
        ReferenceKind.subjects => 'matieres',
        ReferenceKind.users => 'users',
        ReferenceKind.formations => 'formations',
        ReferenceKind.classSubjects => '',
      };

  Uri get endpoint => Uri.parse('${ApiConfig.baseUrl}/$resource');

  @override
  void initState() {
    super.initState();
    loadRows();
  }

  Future<void> loadRows() async {
    setState(() => loading = true);
    try {
      final response = await http.get(endpoint);
      if (response.statusCode != 200) throw Exception('HTTP ${response.statusCode}');
      final decoded = jsonDecode(response.body);
      final list = widget.kind == ReferenceKind.classSubjects
          ? decoded as List
          : (decoded as Map<String, dynamic>)['_embedded']?[collectionKey] as List? ?? [];
      if (!mounted) return;
      setState(() {
        rows = list.cast<Map<String, dynamic>>();
        loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Chargement impossible : $error')));
    }
  }

  String _itemUri(Map<String, dynamic> item) {
    final self = item['_links']?['self']?['href'];
    if (self is String) return self;
    return '${endpoint.toString()}/${item[idField]}';
  }

  Future<void> editItem([Map<String, dynamic>? item]) async {
    final controllers = <String, TextEditingController>{};
    for (final field in fields) {
      controllers[field] = TextEditingController(text: item?[field]?.toString() ?? '');
    }
    final formKey = GlobalKey<FormState>();
    final values = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(item == null ? 'Ajouter : $title' : 'Modifier : $title'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              for (final field in fields)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextFormField(
                    controller: controllers[field],
                    obscureText: field == 'password',
                    keyboardType: ['coef', 'duree'].contains(field) ? TextInputType.number : TextInputType.text,
                    decoration: InputDecoration(labelText: field, border: const OutlineInputBorder()),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Champ obligatoire';
                      if (field == 'duree' && int.tryParse(value) == null) return 'Saisissez un nombre entier';
                      if (['coef', 'chsm'].contains(field) && double.tryParse(value) == null) return 'Saisissez un nombre';
                      if (field == 'codClass' && int.tryParse(value) == null) return 'Saisissez un identifiant de classe';
                      return null;
                    },
                  ),
                ),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Annuler')),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              final result = <String, dynamic>{};
              for (final field in fields) {
                final value = controllers[field]!.text.trim();
                result[field] = switch (field) {
                  'coef' || 'chsm' => double.tryParse(value),
                  'duree' || 'codClass' => int.tryParse(value),
                  _ => value,
                };
              }
              Navigator.pop(dialogContext, result);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    for (final controller in controllers.values) { controller.dispose(); }
    if (values == null) return;
    try {
      final uri = item == null ? endpoint : Uri.parse(_itemUri(item));
      final response = item == null
          ? await http.post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(values))
      : await http.put(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode({...values, [idField]: item[idField]}));
      if (response.statusCode < 200 || response.statusCode >= 300) throw Exception('HTTP ${response.statusCode}');
      await loadRows();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Enregistrement impossible : $error')));
    }
  }

  Future<void> removeItem(Map<String, dynamic> item) async {
    try {
      final response = await http.delete(Uri.parse(_itemUri(item)));
      if (response.statusCode < 200 || response.statusCode >= 300) throw Exception('HTTP ${response.statusCode}');
      await loadRows();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Suppression impossible : $error')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: loadRows,
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    for (final item in rows)
                      Card(
                        child: ListTile(
                          title: Text(widget.kind == ReferenceKind.classSubjects
                              ? '${item['nomClass']} · ${item['codMat']} ${item['intMat'] ?? ''}'
                              : fields.map((field) => '${field == 'password' ? '••••••' : field}: ${field == 'password' ? '' : item[field] ?? ''}').join('  ·  ')),
                          subtitle: widget.kind == ReferenceKind.classSubjects
                              ? Text('Coef : ${item['coef'] ?? '-'} · CHSM : ${item['chsm'] ?? '-'}')
                              : null,
                          trailing: Wrap(children: [
                            IconButton(onPressed: () => editItem(item), icon: const Icon(Icons.edit, color: Colors.indigo)),
                            IconButton(onPressed: () => removeItem(item), icon: const Icon(Icons.delete, color: Colors.red)),
                          ]),
                        ),
                      ),
                    if (rows.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('Aucun enregistrement.'))),
                  ],
                ),
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => editItem(),
          icon: const Icon(Icons.add),
          label: Text('Ajouter ${title.toLowerCase()}'),
        ),
      );
}
