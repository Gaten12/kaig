class KelasKereta {
  final String namaKelas;
  final String subKelas;
  final int harga;
  final String ketersediaan;
  final String? detailTambahan;

  KelasKereta({
    required this.namaKelas,
    required this.subKelas,
    required this.harga,
    required this.ketersediaan,
    this.detailTambahan,
  });
}

class JadwalItem {
  final String namaKereta;
  final String nomorKereta;
  final String stasiunAsal;
  final String stasiunTujuan;
  final String jamBerangkat;
  final String jamTiba;
  final String durasi;
  final int hargaMulaiDari;
  final List<KelasKereta> daftarKelas;
  bool isExpanded;

  JadwalItem({
    required this.namaKereta,
    required this.nomorKereta,
    required this.stasiunAsal,
    required this.stasiunTujuan,
    required this.jamBerangkat,
    required this.jamTiba,
    required this.durasi,
    required this.hargaMulaiDari,
    required this.daftarKelas,
    this.isExpanded = false,
  });
}