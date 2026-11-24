import 'dart:convert';
import 'package:auth/api_config.dart';
import 'package:auth/formation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class FormationsScreen extends StatefulWidget {
  const FormationsScreen({super.key});

  @override
  State<FormationsScreen> createState() => _FormationsScreenState();
}

class _FormationsScreenState extends State<FormationsScreen> {
  String get baseUrl => "${ApiConfig.baseUrl}/formations";

  List<Formation> formations = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchFormations();
  }

  Future<void> fetchFormations() async {
    setState(() => loading = true);
    try {
      final res = await http.get(Uri.parse(baseUrl));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data["_embedded"]["formations"] as List;
        setState(() {
          formations = list.map((e) => Formation.fromMap(e)).toList();
          loading = false;
        });
      }
    } catch (e) {
      setState(() => loading = false);
      debugPrint("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: fetchFormations,
            child: formations.isEmpty
                ? const Center(child: Text("No formations found."))
                : ListView.builder(
                    itemCount: formations.length,
                    itemBuilder: (context, i) {
                      final f = formations[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: ListTile(
                          leading: const Icon(Icons.book, color: Colors.purple),
                          title: Text(
                            f.nom,
                            style: GoogleFonts.roboto(fontSize: 16),
                          ),
                          subtitle: Text("Duration: ${f.duree} hours"),
                        ),
                      );
                    },
                  ),
          );
  }
}
