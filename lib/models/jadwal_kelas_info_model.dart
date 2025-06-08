class JadwalKelasInfoModel {
  final String namaKelas;       // e.g., "EKSEKUTIF"
  final String? subKelas;      // e.g., "AA", "A", "H"
  final int harga;
  final int kuota;             // FIELD BARU: Kuota untuk sub-kelas harga ini
  // Field 'ketersediaan' dan 'idGerbong' tidak lagi relevan di sini
  // final String ketersediaan;
  // final String? idGerbong;

  JadwalKelasInfoModel({
    required this.namaKelas,
    this.subKelas,
    required this.harga,
    required this.kuota,
  });

  String get displayKelasLengkap => "$namaKelas ${subKelas != null && subKelas!.isNotEmpty ? '($subKelas)' : ''}".trim();

  factory JadwalKelasInfoModel.fromMap(Map<String, dynamic> map) {
    return JadwalKelasInfoModel(
      namaKelas: map['nama_kelas'] ?? '',
      subKelas: map['sub_kelas'],
      harga: map['harga'] ?? 0,
      kuota: map['kuota'] as int? ?? 0, // Baca kuota dari map
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nama_kelas': namaKelas,
      'sub_kelas': subKelas,
      'harga': harga,
      'kuota': kuota, // Simpan kuota ke map
    };
  }
}