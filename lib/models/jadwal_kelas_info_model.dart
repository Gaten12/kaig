class JadwalKelasInfoModel {
  final String namaKelas;       // e.g., "EKSEKUTIF"
  final String? subKelas;      // e.g., "AA", "A", "H"
  final int harga;
  final int kuota;             // Kuota untuk sub-kelas harga ini

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
      kuota: map['kuota'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nama_kelas': namaKelas,
      'sub_kelas': subKelas,
      'harga': harga,
      'kuota': kuota,
    };
  }

  // Method ini penting untuk memperbarui objek secara immutable (aman)
  JadwalKelasInfoModel copyWith({
    String? namaKelas,
    String? subKelas,
    int? harga,
    int? kuota,
  }) {
    return JadwalKelasInfoModel(
      namaKelas: namaKelas ?? this.namaKelas,
      subKelas: subKelas ?? this.subKelas,
      harga: harga ?? this.harga,
      kuota: kuota ?? this.kuota,
    );
  }
}