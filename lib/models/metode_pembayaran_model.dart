import 'package:cloud_firestore/cloud_firestore.dart';

enum TipeMetodePembayaran { kartuDebit, ewallet }

class MetodePembayaranModel {
  final String? id;
  final String namaMetode; // e.g., "BCA", "Gopay"
  final TipeMetodePembayaran tipe;
  final String nomor; // Nomor Kartu atau Nomor E-Wallet (telepon)
  final String? masaBerlaku; // Hanya untuk kartu debit, format "MM/YY"
  final String? logoAsset; // Path ke logo jika ada

  MetodePembayaranModel({
    this.id,
    required this.namaMetode,
    required this.tipe,
    required this.nomor,
    this.masaBerlaku,
    this.logoAsset,
  });

  factory MetodePembayaranModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data()!;
    return MetodePembayaranModel(
      id: snapshot.id,
      namaMetode: data['namaMetode'],
      tipe: TipeMetodePembayaran.values.byName(data['tipe']),
      nomor: data['nomor'],
      masaBerlaku: data['masaBerlaku'],
      logoAsset: data['logoAsset'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'namaMetode': namaMetode,
      'tipe': tipe.name,
      'nomor': nomor,
      'masaBerlaku': masaBerlaku,
      'logoAsset': logoAsset,
    };
  }
}