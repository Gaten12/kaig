import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kaig/models/JadwalModel.dart';
import 'package:kaig/models/jadwal_kelas_info_model.dart';

class KeranjangModel {
  final String? id;
  final String userId;
  final JadwalModel jadwalDipesan;
  final JadwalKelasInfoModel kelasDipilih;
  final List<Map<String, String>> penumpang;
  final int totalBayar;
  final Timestamp waktuDitambahkan;
  final Timestamp batasWaktuPembayaran;

  KeranjangModel({
    this.id,
    required this.userId,
    required this.jadwalDipesan,
    required this.kelasDipilih,
    required this.penumpang,
    required this.totalBayar,
    required this.waktuDitambahkan,
    required this.batasWaktuPembayaran,
  });

  factory KeranjangModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data()!;
    return KeranjangModel(
      id: snapshot.id,
      userId: data['userId'],
      // --- PERBAIKAN DI SINI ---
      // Panggil JadwalModel.fromMap, bukan fromFirestore
      jadwalDipesan: JadwalModel.fromMap(data['jadwalDipesan']),
      kelasDipilih: JadwalKelasInfoModel.fromMap(data['kelasDipilih']),
      penumpang: List<Map<String, String>>.from((data['penumpang'] as List).map((p) => Map<String, String>.from(p))),
      totalBayar: data['totalBayar'],
      waktuDitambahkan: data['waktuDitambahkan'],
      batasWaktuPembayaran: data['batasWaktuPembayaran'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'jadwalDipesan': jadwalDipesan.toFirestore(),
      'kelasDipilih': kelasDipilih.toMap(),
      'penumpang': penumpang,
      'totalBayar': totalBayar,
      'waktuDitambahkan': waktuDitambahkan,
      'batasWaktuPembayaran': batasWaktuPembayaran,
    };
  }
}