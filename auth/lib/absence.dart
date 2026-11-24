class Absence {
  final int id;
  final String dateA;
  final double nha;
  final String codMat;
  final int etudiantId;

  Absence({
    required this.id,
    required this.dateA,
    required this.nha,
    required this.codMat,
    required this.etudiantId,
  });

  factory Absence.fromMap(Map<String, dynamic> map) {
    return Absence(
      id: map["id"] ?? 0,
      dateA: map["dateA"] ?? "",
      nha: (map["nha"] is num) ? (map["nha"] as num).toDouble() : 0.0,
      codMat: map["codMat"] ?? "",
      etudiantId: map["etudiantId"] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "dateA": dateA,
      "nha": nha,
      "codMat": codMat,
      "etudiantId": etudiantId,
    };
  }
}

class TotalAbsence {
  final String codMat;
  final double totalNha;

  TotalAbsence({required this.codMat, required this.totalNha});

  factory TotalAbsence.fromMap(Map<String, dynamic> map) {
    return TotalAbsence(
      codMat: map["codMat"] ?? "",
      totalNha: (map["totalNha"] is num) ? (map["totalNha"] as num).toDouble() : 0.0,
    );
  }
}
