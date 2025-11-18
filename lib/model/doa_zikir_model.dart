class DoaModel {
  final String judul;
  final String arab;
  final String indo;
  final String source;

  DoaModel({
    required this.judul,
    required this.arab,
    required this.indo,
    required this.source,
  });

  factory DoaModel.fromJson(Map<String, dynamic> json) {
    return DoaModel(
      judul: json['judul'] ?? '',
      arab: json['arab'] ?? '',
      indo: json['indo'] ?? '',
      source: json['source'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'judul': judul, 'arab': arab, 'indo': indo, 'source': source};
  }

  // @override
  // String toString() {
  //   return 'DoaModel(judul: $judul, source: $source)';
  // }
}
