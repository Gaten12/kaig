class JadwalKelasInfoModel {
  final String namaKelas;       // e.g., "EKONOMI", "EKSEKUTIF"
  final String? subKelas;      // e.g., "CA", "AA", "A", opsional
  final int harga;
  final String ketersediaan;    // e.g., "Tersedia", "Habis", "2 Kursi"
  final String? idGerbong;     // Opsional, jika info ini ada per kelas di jadwal

  JadwalKelasInfoModel({
    required this.namaKelas,
    this.subKelas,
    required this.harga,
    required this.ketersediaan,
    this.idGerbong,
  });

  // Tampilan gabungan untuk UI
  String get displayKelasLengkap => "$namaKelas ${subKelas != null && subKelas!.isNotEmpty ? '($subKelas)' : ''}".trim();

  factory JadwalKelasInfoModel.fromMap(Map<String, dynamic> map) {
    return JadwalKelasInfoModel(
      namaKelas: map['nama_kelas'] ?? '',
      subKelas: map['sub_kelas'], // Bisa null
      harga: map['harga'] ?? 0,
      ketersediaan: map['ketersediaan'] ?? 'Info tidak ada',
      idGerbong: map['id_gerbong'], // Bisa null
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nama_kelas': namaKelas,
      'sub_kelas': subKelas,
      'harga': harga,
      'ketersediaan': ketersediaan,
      'id_gerbong': idGerbong,
    };
  }
}