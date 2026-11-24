class Etudiant {
  int id;
  String? nce;
  String nom;
  String prenom;
  String? dateNais;
  int? classeId;
  int? formationId;
  String? lieuNais;

  Etudiant(
    this.id,
    this.nom,
    this.prenom,
    this.dateNais,
    this.classeId,
    this.formationId, {
    this.nce,
    this.lieuNais,
  });

  String get displayNce =>
      (nce != null && nce!.trim().isNotEmpty) ? nce! : "E$id";

  factory Etudiant.fromMap(Map<String, dynamic> map) => Etudiant(
        map["id"],
        map["nom"] ?? "",
        map["prenom"] ?? "",
        map["dateNais"]?.toString(),
        map["classeId"] ?? map["classe"]?["codClass"],
        map["formationId"] ?? map["formation"]?["id"],
        nce: map["nce"]?.toString(),
        lieuNais: map["lieuNais"]?.toString(),
      );

  Map<String, dynamic> toMap(int classeId, int formationId) => {
        "nce": displayNce,
        "nom": nom,
        "prenom": prenom,
        "dateNais": dateNais,
        "classe": {"codClass": classeId},
        "formation": {"id": formationId},
      };
}
