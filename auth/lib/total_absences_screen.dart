import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:auth/api_config.dart';
import 'package:auth/absence.dart';
import 'package:auth/curve_chart_widget.dart';

class TotalAbsencesScreen extends StatefulWidget {
  final int etudiantId;
  final String nom;
  final String prenom;
  final String nomClass;
  final String nomDept;

  const TotalAbsencesScreen({
    super.key,
    required this.etudiantId,
    required this.nom,
    required this.prenom,
    required this.nomClass,
    required this.nomDept,
  });

  @override
  State<TotalAbsencesScreen> createState() => _TotalAbsencesScreenState();
}

class _TotalAbsencesScreenState extends State<TotalAbsencesScreen> {
  List<TotalAbsence> totals = [];
  bool loading = false;
  bool calculated = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> fetchTotals() async {
    setState(() => loading = true);
    try {
      final url = "${ApiConfig.baseUrl}/api/absences/total/${widget.etudiantId}";
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        setState(() {
          totals = data.map((e) => TotalAbsence.fromMap(e)).toList();
          loading = false;
          calculated = true;
        });
      } else {
        setState(() { loading = false; calculated = true; });
      }
    } catch (e) {
      debugPrint("Error fetching totals: $e");
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Total des Absences",
          style: GoogleFonts.roboto(color: Colors.white),
        ),
        backgroundColor: Colors.purple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Student details header card
                  Card(
                    color: Colors.purple.shade50,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Classe : ${widget.nomClass}",
                                style: GoogleFonts.roboto(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple.shade900,
                                ),
                              ),
                              Text(
                                "Département : ${widget.nomDept}",
                                style: GoogleFonts.roboto(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple.shade900,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            children: [
                              Text(
                                "Etudiant : E${widget.etudiantId}  ",
                                style: GoogleFonts.roboto(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                "Nom : ${widget.nom}  ",
                                style: GoogleFonts.roboto(fontSize: 15),
                              ),
                              Text(
                                "Prénom : ${widget.prenom}",
                                style: GoogleFonts.roboto(fontSize: 15),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  FilledButton.icon(
                    onPressed: fetchTotals,
                    icon: const Icon(Icons.calculate),
                    label: const Text("Calculer"),
                    style: FilledButton.styleFrom(backgroundColor: Colors.purple),
                  ),
                  const SizedBox(height: 12),

                  if (calculated)
                    Card(
                      color: Colors.purple.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          "Total des absences / semestre : ${totals.fold<double>(0, (sum, item) => sum + item.totalNha).toStringAsFixed(1)} h",
                          style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                  // Table Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            "Total des absences par matière",
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                          const SizedBox(height: 8),
                          totals.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Center(
                                    child: Text("Aucune absence enregistrée."),
                                  ),
                                )
                              : DataTable(
                                  headingRowColor: WidgetStateProperty.all(
                                      Colors.purple.shade100),
                                  columns: const [
                                    DataColumn(
                                      label: Text(
                                        "CodMat",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        "Total NHA",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      numeric: true,
                                    ),
                                  ],
                                  rows: totals.map((t) {
                                    return DataRow(
                                      cells: [
                                        DataCell(Text(
                                          t.codMat,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600),
                                        )),
                                        DataCell(Text("${t.totalNha} h")),
                                      ],
                                    );
                                  }).toList(),
                                ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Chart Card
                  if (calculated)
                    SizedBox(
                      height: 320,
                      child: CurveChartWidget(totals: totals),
                    ),
                ],
              ),
            ),
    );
  }
}
