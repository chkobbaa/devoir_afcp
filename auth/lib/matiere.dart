class Matiere {
  final String codMat;
  final String intMat;
  final String? description;
  final double coef;

  Matiere({
    required this.codMat,
    required this.intMat,
    this.description,
    this.coef = 1.0,
  });

  factory Matiere.fromMap(Map<String, dynamic> map) {
    return Matiere(
      codMat: map["codMat"] ?? "",
      intMat: map["intMat"] ?? "",
      description: map["description"],
      coef: (map["coef"] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toMap() => {
        "codMat": codMat,
        "intMat": intMat,
        "description": description,
        "coef": coef,
      };
}
