class Departement {
  final int codDept;
  final String nomDept;

  Departement({required this.codDept, required this.nomDept});

  factory Departement.fromMap(Map<String, dynamic> map) {
    return Departement(
      codDept: map["codDept"] ?? 0,
      nomDept: map["nomDept"] ?? "",
    );
  }
}
