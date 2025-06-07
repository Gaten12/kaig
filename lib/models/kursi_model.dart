import 'package:cloud_firestore/cloud_firestore.dart';

class KursiModel {
  final String id; // ID dokumen kursi
  final String idJadwal;
  final String idGerbong;
  final String nomorKursi; // e.g., "1A", "1B", "12D"
  final String status; // "tersedia", "terisi"

  KursiModel({
    required this.id,
    required this.idJadwal,
    required this.idGerbong,
    required this.nomorKursi,
    required this.status,
  });

  factory KursiModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    if (data == null) {
      throw Exception("Data kursi null untuk ID: ${snapshot.id}");
    }
    return KursiModel(
      id: snapshot.id,
      idJadwal: data['id_jadwal'] ?? '',
      idGerbong: data['id_gerbong'] ?? '',
      nomorKursi: data['nomor_kursi'] ?? '',
      status: data['status'] ?? 'terisi',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id_jadwal': idJadwal,
      'id_gerbong': idGerbong,
      'nomor_kursi': nomorKursi,
      'status': status,
    };
  }
}