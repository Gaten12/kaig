class RangkaianGerbongModel {
  final int nomorGerbong; // Gerbong ke-1, 2, 3, dst.
  final String idTipeGerbong; // ID dari koleksi 'tipeGerbong'

  RangkaianGerbongModel({
    required this.nomorGerbong,
    required this.idTipeGerbong,
  });

  factory RangkaianGerbongModel.fromMap(Map<String, dynamic> map) {
    return RangkaianGerbongModel(
      nomorGerbong: map['nomorGerbong'] as int? ?? 0,
      idTipeGerbong: map['idTipeGerbong'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nomorGerbong': nomorGerbong,
      'idTipeGerbong': idTipeGerbong,
    };
  }
}