import 'package:cloud_firestore/cloud_firestore.dart';

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
  final String id;
  final String namaTipe;
  final int jumlahKursi;
  final TipeLayoutGerbong tipeLayout;
  final String kelas;
  final int subkelas;
  final String imageAssetPath;

  String get namaTipeLengkap => '$namaTipe ($kelas - $subkelas)';

  GerbongTipeModel({
    required this.id,
    required this.namaTipe,
    required this.jumlahKursi,
    required this.tipeLayout,
    required this.kelas,
    required this.subkelas,
    this.imageAssetPath = 'gerbong_default.png', // Fallback nama file gambar
  });

  factory GerbongTipeModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return GerbongTipeModel(
      id: doc.id,
      namaTipe: data['nama_tipe'] ?? '',
      jumlahKursi: data['jumlah_kursi'] ?? 0,
      // [FIXED] Logika parsing dari Firestore disesuaikan dengan enum Anda
      tipeLayout: TipeLayoutGerbong.values.firstWhere(
            (e) => e.name == data['tipe_layout'],
        // Fallback ke nilai pertama dari enum jika data tidak valid
        orElse: () => TipeLayoutGerbong.values.first,
      ),
      kelas: data['kelas'] ?? '',
      subkelas: data['subkelas'] ?? 0,
      imageAssetPath: data['image_asset_path'] ?? 'gerbong_default.png',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nama_tipe': namaTipe,
      'jumlah_kursi': jumlahKursi,
      // Menyimpan nama enum sebagai String, e.g., 'layout_2_2'
      'tipe_layout': tipeLayout.name,
      'kelas': kelas,
      'subkelas': subkelas,
      'image_asset_path': imageAssetPath,
    };
  }
}