import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // <-- TAMBAHKAN IMPORT INI
import 'jadwal_kelas_info_model.dart';

class JadwalModel {
  final String id;
  final String idKereta;
  final String idStasiunAsal;
  final String idStasiunTujuan;
  final String namaKereta;
  final Timestamp tanggalBerangkat;
  final Timestamp jamTiba; // Seharusnya ini adalah tanggal dan waktu tiba lengkap
  final List<JadwalKelasInfoModel> daftarKelasHarga;
  final int hargaMulaiDari; // Akan dihitung oleh konstruktor

  bool isExpanded; // Untuk UI

  JadwalModel({
    required this.id,
    required this.idKereta,
    required this.idStasiunAsal,
    required this.idStasiunTujuan,
    required this.namaKereta,
    required this.tanggalBerangkat,
    required this.jamTiba,
    required this.daftarKelasHarga,
    // hargaMulaiDari tidak diinisialisasi di sini lagi (dihapus this.hargaMulaiDari = 0)
    this.isExpanded = false,
  }) : hargaMulaiDari = _hitungHargaMulaiDari(daftarKelasHarga); // Inisialisasi di sini

  static int _hitungHargaMulaiDari(List<JadwalKelasInfoModel> kelas) {
    if (kelas.isEmpty) return 0;
    // Menggunakan reduce untuk mencari harga minimum dengan aman
    return kelas.map((k) => k.harga).reduce((min, current) => current < min ? current : min);
  }

  String get jamBerangkatFormatted => DateFormat('HH:mm').format(tanggalBerangkat.toDate());
  String get jamTibaFormatted => DateFormat('HH:mm').format(jamTiba.toDate());

  String get durasiPerjalanan {
    final durasi = jamTiba.toDate().difference(tanggalBerangkat.toDate());
    // Handle kasus durasi negatif jika jamTiba < tanggalBerangkat (seharusnya tidak terjadi dengan data valid)
    if (durasi.isNegative) return "N/A";

    final jam = durasi.inHours; // Tidak perlu padding untuk jam jika bisa lebih dari 2 digit
    final menit = durasi.inMinutes.remainder(60).toString().padLeft(2, "0");
    return "${jam}j ${menit}m";
  }

  factory JadwalModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    if (data == null) {
      throw Exception("Data jadwal null!");
    }

    List<JadwalKelasInfoModel> listKelas = [];
    if (data['daftar_kelas_harga'] != null && data['daftar_kelas_harga'] is List) {
      listKelas = (data['daftar_kelas_harga'] as List)
          .map((kelasMap) => JadwalKelasInfoModel.fromMap(kelasMap as Map<String, dynamic>))
          .toList();
    }

    Timestamp tibaTimestamp = data['jam_tiba'] ?? data['tanggal_tiba'] ?? Timestamp.now();

    return JadwalModel(
      id: snapshot.id,
      idKereta: data['id_kereta'] ?? '',
      idStasiunAsal: data['id_stasiun_asal'] ?? '',
      idStasiunTujuan: data['id_stasiun_tujuan'] ?? '',
      namaKereta: data['nama_kereta'] ?? '',
      tanggalBerangkat: data['tanggal_berangkat'] ?? Timestamp.now(),
      jamTiba: tibaTimestamp,
      daftarKelasHarga: listKelas,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id_kereta': idKereta,
      'id_stasiun_asal': idStasiunAsal,
      'id_stasiun_tujuan': idStasiunTujuan,
      'nama_kereta': namaKereta,
      'tanggal_berangkat': tanggalBerangkat,
      'jam_tiba': jamTiba,
      'daftar_kelas_harga': daftarKelasHarga.map((kelas) => kelas.toMap()).toList(),
    };
  }
}