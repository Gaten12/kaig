import 'package:cloud_firestore/cloud_firestore.dart';

class StasiunModel {
  final String id; // ID dokumen Firestore
  final String nama; // Nama stasiun, misal "BANDUNG"
  final String kode; // Kode stasiun, misal "BD"
  final String kota; // Kota stasiun, misal "BANDUNG"
  final String deskripsiTambahan; // Deskripsi tambahan, misal "SEMUA STASIUN DI KOTA SOLO"
  bool isFavorit; // Status favorit, bisa diubah

  StasiunModel({
    required this.id,
    required this.nama,
    required this.kode,
    required this.kota,
    this.deskripsiTambahan = "", // Default string kosong
    this.isFavorit = false,     // Default false
  });

  // Getter untuk tampilan UI
  String get displayName => "$nama ($kode)";
  String get displayArea => deskripsiTambahan.isNotEmpty ? deskripsiTambahan : kota;

  // Factory constructor untuk membuat instance StasiunModel dari Firestore DocumentSnapshot
  factory StasiunModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    if (data == null) {
      throw Exception("Data stasiun null untuk dokumen ID: ${snapshot.id}");
    }
    return StasiunModel(
      id: snapshot.id,
      nama: data['nama'] ?? data['stasiun'] ?? '', // Fleksibel jika nama field beda
      kode: data['kode'] ?? '',
      kota: data['kota'] ?? '',
      deskripsiTambahan: data['deskripsiTambahan'] ?? "", // Ambil dari Firestore
      isFavorit: data['isFavorit'] ?? false, // Ambil dari Firestore (jika disimpan per stasiun)
      // Jika status favorit disimpan per user, logika ini akan berbeda.
    );
  }

  // Method untuk mengubah instance StasiunModel menjadi Map untuk Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'nama': nama, // atau 'stasiun': nama, sesuaikan dengan field di DB Anda
      'kode': kode,
      'kota': kota,
      'deskripsiTambahan': deskripsiTambahan,
    };
  }
}