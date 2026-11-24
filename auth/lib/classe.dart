class Classe {
  int id;
  String nomClass;
  int nbreEtud;
  int? codDept;

  Classe(this.id, this.nomClass, this.nbreEtud, {this.codDept});

  factory Classe.fromMap(Map<String, dynamic> map) => Classe(
        map["codClass"],
        map["nomClass"],
        map["nbreEtud"],
        codDept: map["codDept"] ?? map["departement"]?["codDept"],
      );
}
