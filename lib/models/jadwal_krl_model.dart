import 'package:cloud_firestore/cloud_firestore.dart';
import 'perhentian_krl_model.dart';

class JadwalKrlModel {
  final String? id;
  final String nomorKa;
  final String relasi;
  final int harga;
  final String tipeHari; // Contoh: "Weekday", "Weekend"
  final List<PerhentianKrlModel> perhentian;

  JadwalKrlModel({
    this.id,
    required this.nomorKa,
    required this.relasi,
    required this.harga,
    required this.tipeHari,
    required this.perhentian,
  });

  factory JadwalKrlModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return JadwalKrlModel(
      id: doc.id,
      nomorKa: data['nomorKa'] ?? '',
      relasi: data['relasi'] ?? '',
      harga: data['harga'] ?? 0,
      tipeHari: data['tipeHari'] ?? 'Weekday',
      perhentian: (data['perhentian'] as List<dynamic>?)
          ?.map((p) => PerhentianKrlModel.fromMap(p))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nomorKa': nomorKa,
      'relasi': relasi,
      'harga': harga,
      'tipeHari': tipeHari,
      'perhentian': perhentian.map((p) => p.toMap()).toList(),
      // Helper field untuk query
      'stasiunTersedia': perhentian.map((p) => p.kodeStasiun).toList(),
    };
  }
}
