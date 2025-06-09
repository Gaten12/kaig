import 'package:cloud_firestore/cloud_firestore.dart'; // Diperlukan jika Anda menyimpan tanggal_lahir sebagai Timestamp

class UserDataDaftar {
  final String namaLengkap;
  final String noTelepon;
  final String email;
  final String tipeId;
  final String nomorId;
  final DateTime tanggalLahir; // Menggunakan DateTime untuk kemudahan input di UI
  final String jenisKelamin;

  UserDataDaftar({
    required this.namaLengkap,
    required this.noTelepon,
    required this.email,
    required this.tipeId,
    required this.nomorId,
    required this.tanggalLahir,
    required this.jenisKelamin,
  });


  Map<String, dynamic> toPassengerFirestoreMap() {
    return {
      'nama_lengkap': namaLengkap,
      'tipe_id': tipeId,
      'nomor_id': nomorId,
      'tanggal_lahir': Timestamp.fromDate(tanggalLahir), // Konversi ke Timestamp
      'jenis_kelamin': jenisKelamin,
      'tipe_penumpang': 'Dewasa', // Contoh default
      'isPrimary': true,
    };
  }

  Map<String, dynamic> toUserFirestoreMap() {
    return {
      'email': email,
      'no_telepon': noTelepon,
      'role': 'costumer',
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}