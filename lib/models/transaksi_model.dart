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
  final String waktuBerangkat;
  final String waktuTiba;
  // --- PERUBAHAN DI SINI ---
  // Menyimpan detail penumpang lebih lengkap
  final List<Map<String, String>> penumpang;
  final int jumlahBayi; // Menambahkan jumlah bayi
  final String metodePembayaran;
  final int totalBayar;
  final Timestamp tanggalTransaksi;
  final String status;

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
    required this.jumlahBayi, // Tambahkan di constructor
    required this.metodePembayaran,
    required this.totalBayar,
    required this.tanggalTransaksi,
    this.status = "LUNAS",
  });

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
      jumlahBayi: data['jumlahBayi'] ?? 0, // Ambil data jumlah bayi
      metodePembayaran: data['metodePembayaran'],
      totalBayar: data['totalBayar'],
      tanggalTransaksi: data['tanggalTransaksi'],
      status: data['status'],
    );
  }

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
      'jumlahBayi': jumlahBayi, // Simpan jumlah bayi
      'metodePembayaran': metodePembayaran,
      'totalBayar': totalBayar,
      'tanggalTransaksi': tanggalTransaksi,
      'status': status,
    };
  }
}
