import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'jadwal_kelas_info_model.dart';
import 'jadwal_perhentian_model.dart'; // Impor model perhentian baru

class JadwalModel {
  final String id;
  final String idKereta;
  final String namaKereta;

  final List<JadwalPerhentianModel> detailPerhentian;

  // Field untuk query keseluruhan rute
  final String queryIdStasiunAsal;
  final String queryIdStasiunTujuan;
  final Timestamp queryWaktuBerangkatUtama;

  // Field BARU untuk query segmen
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
  }) : hargaMulaiDari = _hitungHargaMulaiDari(daftarKelasHarga),
        queryIdStasiunAsal = detailPerhentian.isNotEmpty ? detailPerhentian.first.idStasiun : '',
        queryIdStasiunTujuan = detailPerhentian.isNotEmpty && detailPerhentian.length > 1
            ? detailPerhentian.last.idStasiun
            : (detailPerhentian.isNotEmpty ? detailPerhentian.first.idStasiun : ''),
        queryWaktuBerangkatUtama = detailPerhentian.isNotEmpty && detailPerhentian.first.waktuBerangkat != null
            ? detailPerhentian.first.waktuBerangkat!
            : Timestamp.now(), // Fallback
        ruteLengkapKodeStasiun = detailPerhentian.map((p) => p.idStasiun.toUpperCase()).toList() // Mengisi field baru
  {
    if (detailPerhentian.isEmpty || detailPerhentian.length < 2) {
      throw ArgumentError("Detail perhentian minimal harus ada 2 (asal dan tujuan).");
    }
  }

  JadwalPerhentianModel get stasiunAwal => detailPerhentian.first;
  JadwalPerhentianModel get stasiunAkhir => detailPerhentian.last;

  String get idStasiunAsal => stasiunAwal.idStasiun;
  String get idStasiunTujuan => stasiunAkhir.idStasiun;

  Timestamp get tanggalBerangkatUtama => stasiunAwal.waktuBerangkat ?? Timestamp.now();
  Timestamp get tanggalTibaUtama => stasiunAkhir.waktuTiba ?? Timestamp.now();

  static int _hitungHargaMulaiDari(List<JadwalKelasInfoModel> kelas) {
    if (kelas.isEmpty) return 0;
    return kelas.map((k) => k.harga).reduce((min, current) => current < min ? current : min);
  }

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

  factory JadwalModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    if (data == null) {
      throw Exception("Data jadwal null untuk dokumen ID: ${snapshot.id}");
    }

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

    if (listPerhentian.isEmpty || listPerhentian.length < 2) {
      print("PERINGATAN: detail_perhentian kurang dari 2 atau tidak valid untuk Jadwal ID: ${snapshot.id}.");
      if (data['queryIdStasiunAsal'] != null && data['queryWaktuBerangkatUtama'] != null && data['queryIdStasiunTujuan'] != null) {
        listPerhentian = [
          JadwalPerhentianModel(idStasiun: data['queryIdStasiunAsal'], namaStasiun: data['queryIdStasiunAsal'] ?? 'N/A', urutan: 0, waktuBerangkat: data['queryWaktuBerangkatUtama']),
          JadwalPerhentianModel(idStasiun: data['queryIdStasiunTujuan'], namaStasiun: data['queryIdStasiunTujuan'] ?? 'N/A', urutan: 1, waktuTiba: data['jam_tiba'] ?? data['queryWaktuBerangkatUtama']),
        ];
        print("Menggunakan fallback dari field query untuk detailPerhentian.");
      } else {
        throw Exception("Detail perhentian tidak valid dan tidak ada fallback untuk Jadwal ID: ${snapshot.id}");
      }
    }

    return JadwalModel(
      id: snapshot.id,
      idKereta: data['id_kereta'] ?? '',
      namaKereta: data['nama_kereta'] ?? '',
      detailPerhentian: listPerhentian,
      daftarKelasHarga: listKelas,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id_kereta': idKereta,
      'nama_kereta': namaKereta,
      'detail_perhentian': detailPerhentian.map((perhentian) => perhentian.toMap()).toList(),
      'daftar_kelas_harga': daftarKelasHarga.map((kelas) => kelas.toMap()).toList(),
      'queryIdStasiunAsal': queryIdStasiunAsal,
      'queryIdStasiunTujuan': queryIdStasiunTujuan,
      'queryWaktuBerangkatUtama': queryWaktuBerangkatUtama,
      'ruteLengkapKodeStasiun': ruteLengkapKodeStasiun, // Menyimpan field baru
    };
  }
}