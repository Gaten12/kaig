class StasiunModel {
  final String id; // ID unik stasiun, bisa dari Firestore
  final String nama; // Nama lengkap stasiun, e.g., "BANDUNG"
  final String kode; // Kode stasiun, e.g., "BD"
  final String kota; // Kota atau area, e.g., "BANDUNG" atau "KABUPATEN GARUT"
  final String deskripsiTambahan; // e.g., "SEMUA STASIUN DI KOTA SOLO" (opsional)
  bool isFavorit; // Status favorit

  StasiunModel({
    required this.id,
    required this.nama,
    required this.kode,
    required this.kota,
    this.deskripsiTambahan = "",
    this.isFavorit = false,
  });

  // Helper untuk mendapatkan tampilan display utama
  String get displayName => "$nama ($kode)";
  String get displayArea => deskripsiTambahan.isNotEmpty ? deskripsiTambahan : kota;
}