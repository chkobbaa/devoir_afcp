import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:auth/api_config.dart';
import 'package:auth/etudiant.dart';
import 'package:auth/matiere.dart';
import 'package:auth/note.dart';

class ReleveNotesScreen extends StatefulWidget {
  final int etudiantId;
  final Etudiant? etudiant;
  final String? initialClasseName;
  final String? initialDeptName;

  const ReleveNotesScreen({
    super.key,
    required this.etudiantId,
    this.etudiant,
    this.initialClasseName,
    this.initialDeptName,
  });

  @override
  State<ReleveNotesScreen> createState() => _ReleveNotesScreenState();
}

class _ReleveNotesScreenState extends State<ReleveNotesScreen> {
  ReleveNotes? releve;
  List<Matiere> matieres = [];
  bool loading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchReleve();
    fetchMatieres();
  }

  Future<void> fetchMatieres() async {
    try {
      final res =
          await http.get(Uri.parse("${ApiConfig.baseUrl}/api/matieres"));
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            matieres = data.map((e) => Matiere.fromMap(e)).toList();
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching matieres: $e");
    }
  }

  Future<void> fetchReleve() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final res = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/api/notes/etudiant/${widget.etudiantId}"),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          releve = ReleveNotes.fromMap(data);
          loading = false;
        });
      } else {
        setState(() {
          errorMessage = "Impossible de charger le relevé (Code: ${res.statusCode})";
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Erreur de connexion au serveur: $e";
        loading = false;
      });
    }
  }

  Future<void> saveNote({
    required String codMat,
    double? tp1,
    double? tp2,
    double? ds,
    double? examen,
  }) async {
    try {
      final body = jsonEncode({
        "etudiantId": widget.etudiantId,
        "codMat": codMat,
        "tp1": tp1,
        "tp2": tp2,
        "ds": ds,
        "examen": examen,
      });

      final res = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/api/notes"),
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (res.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Notes enregistrées avec succès"),
            backgroundColor: Colors.green,
          ),
        );
        fetchReleve();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur d'enregistrement: ${res.body}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> deleteNote(int id) async {
    try {
      final res = await http.delete(
        Uri.parse("${ApiConfig.baseUrl}/api/notes/$id"),
      );
      if (res.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Note supprimée")),
        );
        fetchReleve();
      }
    } catch (e) {
      debugPrint("Error deleting note: $e");
    }
  }

  void _showNoteDialog({NoteItem? existing}) {
    String selectedMat = existing?.codMat ??
        (matieres.isNotEmpty ? matieres.first.codMat : "");

    final tp1Controller = TextEditingController(
        text: existing?.tp1 != null ? existing!.tp1.toString() : "");
    final tp2Controller = TextEditingController(
        text: existing?.tp2 != null ? existing!.tp2.toString() : "");
    final dsController = TextEditingController(
        text: existing?.ds != null ? existing!.ds.toString() : "");
    final examController = TextEditingController(
        text: existing?.examen != null ? existing!.examen.toString() : "");

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            double? pTp1 = double.tryParse(tp1Controller.text.trim());
            double? pTp2 = double.tryParse(tp2Controller.text.trim());
            double? pDs = double.tryParse(dsController.text.trim());
            double? pExam = double.tryParse(examController.text.trim());
            double? previewMoy =
                NoteItem.calculateMoyenne(pTp1, pTp2, pDs, pExam);

            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.edit_note, color: Colors.purple),
                  const SizedBox(width: 8),
                  Text(
                    existing != null
                        ? "Modifier les Notes"
                        : "Saisir des Notes",
                    style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Matière",
                        style: GoogleFonts.roboto(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedMat.isNotEmpty ? selectedMat : null,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      items: matieres
                          .map((m) => DropdownMenuItem(
                                value: m.codMat,
                                child: Text("${m.codMat} - ${m.intMat}",
                                    overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: existing != null
                          ? null // Do not change subject when editing existing
                          : (val) {
                              if (val != null) {
                                setDialogState(() => selectedMat = val);
                              }
                            },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Notes (TPs: 50/50 | DS: 40%, Examen: 60%)",
                      style: GoogleFonts.roboto(
                          fontSize: 12,
                          color: Colors.purple.shade700,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: tp1Controller,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: InputDecoration(
                              labelText: "TP 1",
                              hintText: "ex: 18",
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            onChanged: (_) => setDialogState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: tp2Controller,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: InputDecoration(
                              labelText: "TP 2",
                              hintText: "ex: 17",
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            onChanged: (_) => setDialogState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: dsController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: InputDecoration(
                              labelText: "DS (40%)",
                              hintText: "ex: 14",
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            onChanged: (_) => setDialogState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: examController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: InputDecoration(
                              labelText: "Examen (60%)",
                              hintText: "ex: 16",
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            onChanged: (_) => setDialogState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.purple.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Moyenne calculée :",
                              style: GoogleFonts.roboto(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple.shade900)),
                          Text(
                            previewMoy != null
                                ? "${previewMoy.toStringAsFixed(2)} / 20"
                                : "--",
                            style: GoogleFonts.roboto(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple.shade900),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                if (existing?.id != null)
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text("Effacer"),
                    onPressed: () {
                      Navigator.pop(ctx);
                      deleteNote(existing!.id!);
                    },
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Annuler"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    if (selectedMat.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Veuillez choisir une matière")),
                      );
                      return;
                    }
                    Navigator.pop(ctx);
                    saveNote(
                      codMat: selectedMat,
                      tp1: double.tryParse(tp1Controller.text.trim()),
                      tp2: double.tryParse(tp2Controller.text.trim()),
                      ds: double.tryParse(dsController.text.trim()),
                      examen: double.tryParse(examController.text.trim()),
                    );
                  },
                  child: const Text("Enregistrer"),
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
    final studentName = releve != null
        ? "${releve!.nom} ${releve!.prenom}"
        : widget.etudiant != null
            ? "${widget.etudiant!.nom} ${widget.etudiant!.prenom}"
            : "Étudiant";
    final nce = releve?.nce.isNotEmpty == true
        ? releve!.nce
        : (widget.etudiant?.displayNce ?? "E${widget.etudiantId}");
    final classeName = releve?.nomClasse ?? widget.initialClasseName ?? "N/A";
    final deptName = releve?.nomDept ?? widget.initialDeptName ?? "N/A";

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          "Relevé de Notes",
          style: GoogleFonts.roboto(
              fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.purple,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Actualiser",
            onPressed: fetchReleve,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("Saisir Note"),
        onPressed: () => _showNoteDialog(),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 60, color: Colors.red),
                        const SizedBox(height: 12),
                        Text(errorMessage!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.roboto(fontSize: 16)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: fetchReleve,
                          icon: const Icon(Icons.refresh),
                          label: const Text("Réessayer"),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: fetchReleve,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Student Info Header Card
                        _buildStudentCard(studentName, nce, classeName, deptName),
                        const SizedBox(height: 16),

                        // Academic Summary Card (Moyenne Générale, Mention, Decision)
                        _buildSummaryCard(),
                        const SizedBox(height: 20),

                        // Section Title
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Détails des Notes par Matière",
                              style: GoogleFonts.roboto(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple.shade900,
                              ),
                            ),
                            Text(
                              "${releve?.notes.length ?? 0} matières",
                              style: GoogleFonts.roboto(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Notes Table / Cards
                        _buildNotesTable(),
                        const SizedBox(height: 80), // padding for FAB
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildStudentCard(
      String studentName, String nce, String classeName, String deptName) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: Colors.purple.shade100,
              child: Text(
                studentName.isNotEmpty ? studentName[0].toUpperCase() : "E",
                style: GoogleFonts.roboto(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade800,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    studentName,
                    style: GoogleFonts.roboto(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _buildChip(Icons.badge, "NCE: $nce", Colors.indigo),
                      _buildChip(Icons.class_, "Classe: $classeName", Colors.teal),
                      _buildChip(Icons.account_balance, "Dép: $deptName", Colors.blueGrey),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String label, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color.shade700),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final mg = releve?.moyenneGenerale;
    final decision = releve?.decision ?? "N/A";
    final mention = releve?.mention ?? "N/A";
    final totalCoef = releve?.totalCoef ?? 0.0;
    final totalPoints = releve?.totalPoints ?? 0.0;

    final isAdmis = decision == "Admis";
    final isAjourne = decision == "Ajourné";

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isAdmis
              ? [const Color(0xFF1B5E20), const Color(0xFF2E7D32)]
              : isAjourne
                  ? [const Color(0xFFB71C1C), const Color(0xFFC62828)]
                  : [Colors.purple.shade800, Colors.purple.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isAdmis ? Colors.green : Colors.purple).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "MOYENNE GÉNÉRALE",
                    style: GoogleFonts.roboto(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        mg != null ? mg.toStringAsFixed(2) : "--",
                        style: GoogleFonts.roboto(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "/ 20",
                        style: GoogleFonts.roboto(
                          color: Colors.white70,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white38),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isAdmis
                              ? Icons.check_circle
                              : isAjourne
                                  ? Icons.cancel
                                  : Icons.help_outline,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          decision,
                          style: GoogleFonts.roboto(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Mention : $mention",
                    style: GoogleFonts.roboto(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummarySubItem("Total Coef.", totalCoef.toStringAsFixed(1)),
              _buildSummarySubItem(
                  "Total Points", totalPoints.toStringAsFixed(2)),
              _buildSummarySubItem("Statut", isAdmis ? "Succès" : "En cours"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySubItem(String label, String value) {
    return Column(
      children: [
        Text(label,
            style: GoogleFonts.roboto(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value,
            style: GoogleFonts.roboto(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildNotesTable() {
    final list = releve?.notes ?? [];
    if (list.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(
            child: Text("Aucune matière trouvée."),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Table header
          Container(
            color: Colors.purple.shade700,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    "Matière",
                    style: GoogleFonts.roboto(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text("TP1",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                ),
                Expanded(
                  flex: 1,
                  child: Text("TP2",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                ),
                Expanded(
                  flex: 1,
                  child: Text("DS",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                ),
                Expanded(
                  flex: 1,
                  child: Text("Exam",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                ),
                Expanded(
                  flex: 2,
                  child: Text("Moy.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ),
                Expanded(
                  flex: 1,
                  child: Text("Coef",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                ),
                const SizedBox(width: 40), // for edit button
              ],
            ),
          ),
          // Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            separatorBuilder: (_, index) => Divider(height: 1, color: Colors.grey.shade200),
            itemBuilder: (context, i) {
              final n = list[i];
              final hasNote = n.moyenneMatiere != null;
              final isPassing = (n.moyenneMatiere ?? 0.0) >= 10.0;

              return InkWell(
                onTap: () => _showNoteDialog(existing: n),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      // Matière
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              n.codMat,
                              style: GoogleFonts.roboto(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple.shade900,
                                  fontSize: 13),
                            ),
                            Text(
                              n.intMat,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.roboto(
                                  fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      // TP1
                      Expanded(
                        flex: 1,
                        child: Text(
                          n.tp1 != null ? n.tp1!.toStringAsFixed(1) : "-",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.roboto(
                              fontSize: 12,
                              color: n.tp1 != null ? Colors.black87 : Colors.grey.shade400),
                        ),
                      ),
                      // TP2
                      Expanded(
                        flex: 1,
                        child: Text(
                          n.tp2 != null ? n.tp2!.toStringAsFixed(1) : "-",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.roboto(
                              fontSize: 12,
                              color: n.tp2 != null ? Colors.black87 : Colors.grey.shade400),
                        ),
                      ),
                      // DS
                      Expanded(
                        flex: 1,
                        child: Text(
                          n.ds != null ? n.ds!.toStringAsFixed(1) : "-",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.roboto(
                              fontSize: 12,
                              color: n.ds != null ? Colors.black87 : Colors.grey.shade400),
                        ),
                      ),
                      // Examen
                      Expanded(
                        flex: 1,
                        child: Text(
                          n.examen != null ? n.examen!.toStringAsFixed(1) : "-",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.roboto(
                              fontSize: 12,
                              color: n.examen != null ? Colors.black87 : Colors.grey.shade400),
                        ),
                      ),
                      // Moyenne
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: hasNote
                                ? (isPassing
                                    ? Colors.green.shade50
                                    : Colors.red.shade50)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            hasNote
                                ? n.moyenneMatiere!.toStringAsFixed(2)
                                : "N/A",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.roboto(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: hasNote
                                  ? (isPassing
                                      ? Colors.green.shade800
                                      : Colors.red.shade800)
                                  : Colors.grey.shade500,
                            ),
                          ),
                        ),
                      ),
                      // Coef
                      Expanded(
                        flex: 1,
                        child: Text(
                          n.coef.toStringAsFixed(1),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.roboto(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.blueGrey),
                        ),
                      ),
                      // Edit button
                      SizedBox(
                        width: 40,
                        child: IconButton(
                          icon: const Icon(Icons.edit_outlined,
                              size: 18, color: Colors.purple),
                          tooltip: "Modifier",
                          onPressed: () => _showNoteDialog(existing: n),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
