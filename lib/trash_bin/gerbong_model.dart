import 'package:cloud_firestore/cloud_firestore.dart';

enum TipeLayoutGerbong {
  eksekutif_2_2_50, // 2-2, 50 kursi
  ekonomi_3_2_80, // 3-2, 80 kursi
  ekonomi_new_gen_72, // 2-2 captain seat, 72 kursi
  suite_compartment, // Layout khusus, misal 1-1
  lainnya;

  String get deskripsi {
    switch (this) {
      case TipeLayoutGerbong.eksekutif_2_2_50:
        return 'Eksekutif (2-2, 50 Kursi)';
      case TipeLayoutGerbong.ekonomi_3_2_80:
        return 'Ekonomi (3-2, 80 Kursi)';
      case TipeLayoutGerbong.ekonomi_new_gen_72:
        return 'Ekonomi New Gen (2-2, 72 Kursi)';
      case TipeLayoutGerbong.suite_compartment:
        return 'Suite Class / Compartment';
      case TipeLayoutGerbong.lainnya:
        return 'Layout Lainnya';
    }
  }
}

class GerbongModel {
  final String id; // ID Dokumen Firestore
  final String kodeGerbong; // Misal: K1 0 18 01
  final TipeLayoutGerbong tipeLayout;
  final int jumlahKursi;

  GerbongModel({
    required this.id,
    required this.kodeGerbong,
    required this.tipeLayout,
    required this.jumlahKursi,
  });

  factory GerbongModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    if (data == null) throw Exception("Data gerbong null");

    return GerbongModel(
      id: snapshot.id,
      kodeGerbong: data['kodeGerbong'] ?? '',
      tipeLayout: TipeLayoutGerbong.values.firstWhere(
            (e) => e.name == data['tipeLayout'],
        orElse: () => TipeLayoutGerbong.lainnya,
      ),
      jumlahKursi: data['jumlahKursi'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'kodeGerbong': kodeGerbong,
      'tipeLayout': tipeLayout.name,
      'jumlahKursi': jumlahKursi,
    };
  }
}