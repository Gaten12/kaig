import 'package:cloud_firestore/cloud_firestore.dart';

// Enum untuk menstandarisasi kelas utama
enum KelasUtama { eksekutif, ekonomi, bisnis, luxury, panoramic }

// Enum untuk menstandarisasi tipe layout gerbong
enum TipeLayoutGerbong {
  layout_2_2, // 2 kursi di kiri, 2 di kanan
  layout_3_2, // 3 di kiri, 2 di kanan
  layout_2_1, // 2 di kiri, 1 di kanan
  layout_1_1, // Untuk Suite/Luxury/Compartment
  lainnya;

  String get deskripsi {
    switch (this) {
      case TipeLayoutGerbong.layout_2_2:
        return 'Layout 2-2';
      case TipeLayoutGerbong.layout_3_2:
        return 'Layout 3-2';
      case TipeLayoutGerbong.layout_2_1:
        return 'Layout 2-1';
      case TipeLayoutGerbong.layout_1_1:
        return 'Layout 1-1';
      case TipeLayoutGerbong.lainnya:
        return 'Layout Lainnya';
    }
  }
}

class GerbongTipeModel {
  final String id; // ID Dokumen Firestore
  final KelasUtama kelas;
  final String subTipe; // Nama spesifik: "New Generation 2024", "Premium", "Subsidi"
  final TipeLayoutGerbong tipeLayout;
  final int jumlahKursi;

  GerbongTipeModel({
    required this.id,
    required this.kelas,
    required this.subTipe,
    required this.tipeLayout,
    required this.jumlahKursi,
  });

  // Getter untuk menampilkan nama lengkap di UI
  String get namaTipeLengkap {
    String kelasStr = kelas.name[0].toUpperCase() + kelas.name.substring(1);
    return "$kelasStr - $subTipe".trim();
  }

  factory GerbongTipeModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    if (data == null) throw Exception("Data Tipe Gerbong null untuk ID: ${snapshot.id}");

    return GerbongTipeModel(
      id: snapshot.id,
      kelas: KelasUtama.values.firstWhere(
            (e) => e.name == data['kelas'],
        orElse: () => KelasUtama.ekonomi, // Fallback
      ),
      subTipe: data['subTipe'] ?? 'Tanpa Sub-tipe',
      tipeLayout: TipeLayoutGerbong.values.firstWhere(
            (e) => e.name == data['tipeLayout'],
        orElse: () => TipeLayoutGerbong.lainnya, // Fallback
      ),
      jumlahKursi: data['jumlahKursi'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'kelas': kelas.name, // Simpan nama enum sebagai string
      'subTipe': subTipe,
      'tipeLayout': tipeLayout.name,
      'jumlahKursi': jumlahKursi,
    };
  }
}