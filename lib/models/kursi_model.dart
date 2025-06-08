import 'package:cloud_firestore/cloud_firestore.dart';

class KursiModel {
  final String id; // ID dokumen kursi
  final String idJadwal;
  final String idTipeGerbong; // ID dari master tipe gerbong
  final int nomorGerbong; // Nomor urut gerbong dalam rangkaian (1, 2, 3, dst.)
  final String nomorKursi; // e.g., "1A", "1B", "12D"
  final String status; // "tersedia", "terisi", "sebagian_terisi"
  final List<dynamic> segmenTerisi; // List untuk menyimpan segmen yang sudah dipesan

  KursiModel({
    required this.id,
    required this.idJadwal,
    required this.idTipeGerbong,
    required this.nomorGerbong,
    required this.nomorKursi,
    required this.status,
    this.segmenTerisi = const [],
  });

  factory KursiModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    if (data == null) throw Exception("Data kursi null untuk ID: ${snapshot.id}");

    return KursiModel(
      id: snapshot.id,
      idJadwal: data['id_jadwal'] ?? '',
      idTipeGerbong: data['id_tipe_gerbong'] ?? data['id_gerbong'] ?? '', // Fallback untuk nama field lama
      nomorGerbong: data['nomor_gerbong'] as int? ?? 0,
      nomorKursi: data['nomor_kursi'] ?? '',
      status: data['status'] ?? 'terisi',
      segmenTerisi: List<dynamic>.from(data['segmenTerisi'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id_jadwal': idJadwal,
      'id_tipe_gerbong': idTipeGerbong,
      'nomor_gerbong': nomorGerbong,
      'nomor_kursi': nomorKursi,
      'status': status,
      'segmenTerisi': segmenTerisi,
    };
  }
}