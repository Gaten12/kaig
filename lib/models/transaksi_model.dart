import 'package:cloud_firestore/cloud_firestore.dart';

class TransaksiModel {
  final String? id;
  final String userId;
  final String kodeBooking;
  final String namaKereta;
  final String idJadwal;
  final String rute; // Contoh: "GMR > YK"
  final String kelas; // Contoh: "Eksekutif (A)"
  final Timestamp tanggalBerangkat;
  final String waktuBerangkat; // Contoh: "08:00"
  final String waktuTiba; // Contoh: "15:30"
  final List<Map<String, String>> penumpang; // e.g., [{'nama': 'Budi', 'kursi': 'EKS-1 5A'}]
  final String metodePembayaran;
  final int totalBayar;
  final Timestamp tanggalTransaksi;
  final String status; // Contoh: "LUNAS", "BATAL"

  TransaksiModel({
    this.id,
    required this.userId,
    required this.kodeBooking,
    required this.namaKereta,
    required this.idJadwal,
    required this.rute,
    required this.kelas,
    required this.tanggalBerangkat,
    required this.waktuBerangkat,
    required this.waktuTiba,
    required this.penumpang,
    required this.metodePembayaran,
    required this.totalBayar,
    required this.tanggalTransaksi,
    this.status = "LUNAS",
  });

  // Factory untuk membuat instance dari Firestore
  factory TransaksiModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data()!;
    return TransaksiModel(
      id: snapshot.id,
      userId: data['userId'],
      kodeBooking: data['kodeBooking'],
      namaKereta: data['namaKereta'],
      idJadwal: data['idJadwal'],
      rute: data['rute'],
      kelas: data['kelas'],
      tanggalBerangkat: data['tanggalBerangkat'],
      waktuBerangkat: data['waktuBerangkat'],
      waktuTiba: data['waktuTiba'],
      penumpang: List<Map<String, String>>.from(
          (data['penumpang'] as List).map((p) => Map<String, String>.from(p))),
      metodePembayaran: data['metodePembayaran'],
      totalBayar: data['totalBayar'],
      tanggalTransaksi: data['tanggalTransaksi'],
      status: data['status'],
    );
  }

  // Method untuk mengubah instance menjadi Map untuk Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'kodeBooking': kodeBooking,
      'namaKereta': namaKereta,
      'idJadwal': idJadwal,
      'rute': rute,
      'kelas': kelas,
      'tanggalBerangkat': tanggalBerangkat,
      'waktuBerangkat': waktuBerangkat,
      'waktuTiba': waktuTiba,
      'penumpang': penumpang,
      'metodePembayaran': metodePembayaran,
      'totalBayar': totalBayar,
      'tanggalTransaksi': tanggalTransaksi,
      'status': status,
    };
  }
}
