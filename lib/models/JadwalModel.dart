import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'jadwal_kelas_info_model.dart';
import 'jadwal_perhentian_model.dart';

class JadwalModel {
  final String id;
  final String idKereta;
  final String namaKereta;
  final List<JadwalPerhentianModel> detailPerhentian;
  final List<String> ruteLengkapKodeStasiun;
  final List<JadwalKelasInfoModel> daftarKelasHarga;
  final int hargaMulaiDari;
  bool isExpanded;

  JadwalModel({
    required this.id,
    required this.idKereta,
    required this.namaKereta,
    required this.detailPerhentian,
    required this.daftarKelasHarga,
    this.isExpanded = false,
  })  : hargaMulaiDari = _hitungHargaMulaiDari(daftarKelasHarga),
        ruteLengkapKodeStasiun = detailPerhentian.map((p) => p.idStasiun.toUpperCase()).toList() {
    if (detailPerhentian.isEmpty || detailPerhentian.length < 2) {
      throw ArgumentError("Detail perhentian minimal harus ada 2 (asal dan tujuan).");
    }
  }

  // Getter yang sudah ada (tidak berubah)
  JadwalPerhentianModel get stasiunAwal => detailPerhentian.first;
  JadwalPerhentianModel get stasiunAkhir => detailPerhentian.last;
  String get idStasiunAsal => stasiunAwal.idStasiun;
  String get idStasiunTujuan => stasiunAkhir.idStasiun;
  Timestamp get tanggalBerangkatUtama => stasiunAwal.waktuBerangkat ?? Timestamp.now();
  Timestamp get tanggalTibaUtama => stasiunAkhir.waktuTiba ?? Timestamp.now();
  String get jamBerangkatFormatted => DateFormat('HH:mm').format(tanggalBerangkatUtama.toDate());
  String get jamTibaFormatted => DateFormat('HH:mm').format(tanggalTibaUtama.toDate());
  String get durasiPerjalananTotal {
    if (stasiunAwal.waktuBerangkat == null || stasiunAkhir.waktuTiba == null) return "N/A";
    final durasi = stasiunAkhir.waktuTiba!.toDate().difference(stasiunAwal.waktuBerangkat!.toDate());
    if (durasi.isNegative) return "N/A";
    final jam = durasi.inHours;
    final menit = durasi.inMinutes.remainder(60).toString().padLeft(2, "0");
    return "${jam}j ${menit}m";
  }
  static int _hitungHargaMulaiDari(List<JadwalKelasInfoModel> kelas) {
    if (kelas.isEmpty) return 0;
    return kelas.map((k) => k.harga).reduce((min, current) => current < min ? current : min);
  }

  // Factory dari DocumentSnapshot (tidak berubah)
  factory JadwalModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    if (data == null) {
      throw Exception("Data jadwal null untuk dokumen ID: ${snapshot.id}");
    }
    // Tambahkan ID dari snapshot ke dalam map data sebelum dikirim ke fromMap
    data['id'] = snapshot.id;
    return JadwalModel.fromMap(data);
  }

  // --- FACTORY BARU DARI MAP (INI KUNCINYA) ---
  factory JadwalModel.fromMap(Map<String, dynamic> data) {
    List<JadwalKelasInfoModel> listKelas = [];
    if (data['daftar_kelas_harga'] != null && data['daftar_kelas_harga'] is List) {
      listKelas = (data['daftar_kelas_harga'] as List)
          .map((kelasMap) => JadwalKelasInfoModel.fromMap(kelasMap as Map<String, dynamic>))
          .toList();
    }

    List<JadwalPerhentianModel> listPerhentian = [];
    if (data['detail_perhentian'] != null && data['detail_perhentian'] is List) {
      listPerhentian = (data['detail_perhentian'] as List)
          .map((perhentianMap) => JadwalPerhentianModel.fromMap(perhentianMap as Map<String, dynamic>, perhentianMap['nama_stasiun'] ?? 'N/A'))
          .toList();
      listPerhentian.sort((a, b) => a.urutan.compareTo(b.urutan));
    }

    return JadwalModel(
      id: data['id'] ?? '', // Ambil ID dari map
      idKereta: data['id_kereta'] ?? '',
      namaKereta: data['nama_kereta'] ?? '',
      detailPerhentian: listPerhentian,
      daftarKelasHarga: listKelas,
    );
  }

  // --- MODIFIKASI toFirestore ---
  Map<String, dynamic> toFirestore() {
    return {
      'id': id, // Pastikan ID ikut disimpan saat menjadi Map
      'id_kereta': idKereta,
      'nama_kereta': namaKereta,
      'detail_perhentian': detailPerhentian.map((perhentian) => perhentian.toMap()).toList(),
      'daftar_kelas_harga': daftarKelasHarga.map((kelas) => kelas.toMap()).toList(),
      // Field query ini sebenarnya bisa digenerate ulang, tapi kita simpan saja agar konsisten
      'queryIdStasiunAsal': idStasiunAsal,
      'queryIdStasiunTujuan': idStasiunTujuan,
      'queryWaktuBerangkatUtama': tanggalBerangkatUtama,
      'ruteLengkapKodeStasiun': ruteLengkapKodeStasiun,
    };
  }
}