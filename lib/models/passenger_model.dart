import 'package:cloud_firestore/cloud_firestore.dart';

class PassengerModel {
  final String? id; // ID dokumen penumpang, bisa nullable jika objek dibuat sebelum disimpan
  final String namaLengkap;
  final String tipeId; // Misal: KTP, Paspor
  final String nomorId;
  final Timestamp tanggalLahir;
  final String jenisKelamin; // Misal: Laki-laki, Perempuan
  final String tipePenumpang; // Misal: Dewasa, Anak, Bayi
  final bool? isPrimary; // Opsional, untuk menandakan penumpang utama/pembuat akun

  PassengerModel({
    this.id,
    required this.namaLengkap,
    required this.tipeId,
    required this.nomorId,
    required this.tanggalLahir,
    required this.jenisKelamin,
    required this.tipePenumpang,
    this.isPrimary,
  });

  // Factory constructor untuk membuat instance PassengerModel dari Firestore DocumentSnapshot
  factory PassengerModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    if (data == null) {
      throw Exception("Passenger data is null!");
    }
    return PassengerModel(
      id: snapshot.id,
      namaLengkap: data['nama_lengkap'] as String? ?? '',
      tipeId: data['tipe_id'] as String? ?? '',
      nomorId: data['nomor_id'] as String? ?? '',
      tanggalLahir: data['tanggal_lahir'] as Timestamp? ?? Timestamp.now(),
      jenisKelamin: data['jenis_kelamin'] as String? ?? '',
      tipePenumpang: data['tipe_penumpang'] as String? ?? 'Dewasa',
      isPrimary: data['isPrimary'] as bool?, // Bisa null jika field tidak ada
    );
  }

  // Method untuk mengubah instance PassengerModel menjadi Map<String, dynamic> untuk Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'nama_lengkap': namaLengkap,
      'tipe_id': tipeId,
      'nomor_id': nomorId,
      'tanggal_lahir': tanggalLahir,
      'jenis_kelamin': jenisKelamin,
      'tipe_penumpang': tipePenumpang,
      if (isPrimary != null) 'isPrimary': isPrimary, // Hanya sertakan jika tidak null
    };
  }
}