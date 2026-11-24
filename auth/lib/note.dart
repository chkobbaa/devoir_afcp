class NoteItem {
  final int? id;
  final String codMat;
  final String intMat;
  final double coef;
  final double? tp1;
  final double? tp2;
  final double? ds;
  final double? examen;
  final double? moyenneMatiere;
  final double? totalPoints;

  NoteItem({
    this.id,
    required this.codMat,
    required this.intMat,
    required this.coef,
    this.tp1,
    this.tp2,
    this.ds,
    this.examen,
    this.moyenneMatiere,
    this.totalPoints,
  });

  factory NoteItem.fromMap(Map<String, dynamic> map) {
    return NoteItem(
      id: map["id"] != null ? (map["id"] as num).toInt() : null,
      codMat: map["codMat"] ?? "",
      intMat: map["intMat"] ?? "",
      coef: (map["coef"] as num?)?.toDouble() ?? 1.0,
      tp1: (map["tp1"] as num?)?.toDouble(),
      tp2: (map["tp2"] as num?)?.toDouble(),
      ds: (map["ds"] as num?)?.toDouble(),
      examen: (map["examen"] as num?)?.toDouble(),
      moyenneMatiere: (map["moyenneMatiere"] as num?)?.toDouble(),
      totalPoints: (map["totalPoints"] as num?)?.toDouble(),
    );
  }

  static double? calculateMoyenne(
      double? tp1, double? tp2, double? ds, double? examen) {
    final hasTp1 = tp1 != null;
    final hasTp2 = tp2 != null;
    final hasDs = ds != null;
    final hasExam = examen != null;

    if (!hasTp1 && !hasTp2 && !hasDs && !hasExam) return null;

    // TPs are 50/50
    double? tpScore;
    if (hasTp1 && hasTp2) {
      tpScore = (tp1 + tp2) / 2.0;
    } else if (hasTp1) {
      tpScore = tp1;
    } else if (hasTp2) {
      tpScore = tp2;
    }

    // DS and Examen are 40% and 60%
    double? theoryScore;
    if (hasDs && hasExam) {
      theoryScore = 0.40 * ds + 0.60 * examen;
    } else if (hasExam) {
      theoryScore = examen;
    } else if (hasDs) {
      theoryScore = ds;
    }

    double result;
    if (tpScore != null && theoryScore != null) {
      if (ds != null && examen != null) {
        result = 0.20 * tpScore + 0.20 * ds + 0.60 * examen;
      } else if (examen != null) {
        result = 0.40 * tpScore + 0.60 * examen;
      } else if (ds != null) {
        result = 0.50 * tpScore + 0.50 * ds;
      } else {
        result = tpScore;
      }
    } else if (tpScore != null) {
      result = tpScore;
    } else {
      result = theoryScore!;
    }

    return (result * 100).round() / 100.0;
  }
}

class ReleveNotes {
  final int etudiantId;
  final String nce;
  final String nom;
  final String prenom;
  final String? nomClasse;
  final String? nomDept;
  final List<NoteItem> notes;
  final double? moyenneGenerale;
  final double? totalCoef;
  final double? totalPoints;
  final String? mention;
  final String? decision;

  ReleveNotes({
    required this.etudiantId,
    required this.nce,
    required this.nom,
    required this.prenom,
    this.nomClasse,
    this.nomDept,
    required this.notes,
    this.moyenneGenerale,
    this.totalCoef,
    this.totalPoints,
    this.mention,
    this.decision,
  });

  factory ReleveNotes.fromMap(Map<String, dynamic> map) {
    final list = (map["notes"] as List? ?? [])
        .map((e) => NoteItem.fromMap(e))
        .toList();
    return ReleveNotes(
      etudiantId: map["etudiantId"] != null
          ? (map["etudiantId"] as num).toInt()
          : 0,
      nce: map["nce"]?.toString() ?? "",
      nom: map["nom"] ?? "",
      prenom: map["prenom"] ?? "",
      nomClasse: map["nomClasse"]?.toString(),
      nomDept: map["nomDept"]?.toString(),
      notes: list,
      moyenneGenerale: (map["moyenneGenerale"] as num?)?.toDouble(),
      totalCoef: (map["totalCoef"] as num?)?.toDouble(),
      totalPoints: (map["totalPoints"] as num?)?.toDouble(),
      mention: map["mention"]?.toString(),
      decision: map["decision"]?.toString(),
    );
  }
}
