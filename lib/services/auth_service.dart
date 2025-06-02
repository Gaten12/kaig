// Di dalam file auth_service.dart Anda

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_data_daftar.dart'; // Pastikan path ini benar
// Mungkin juga perlu model UserModel dan PassengerModel yang kita buat sebelumnya
// import '../models/user_model.dart';
// import '../models/passenger_model.dart';


class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserCredential?> registerWithEmailPassword(
      String email,
      String password,
      UserDataDaftar userDataDaftar, // Semua data dari form pendaftaran
      ) async {
    try {
      // 1. Buat user di Firebase Authentication
      UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? newUser = userCredential.user;

      if (newUser != null) {
        // 2. Simpan detail user tambahan ke Firestore
        //    Menggunakan UserModel yang sudah kita definisikan sebelumnya akan lebih baik
        await _firestore.collection('users').doc(newUser.uid).set({
          'email': newUser.email,
          'no_telepon': userDataDaftar.noTelepon, // Asumsi field ini ada di UserDataDaftar
          'role': 'costumer', // Default role
          'createdAt': FieldValue.serverTimestamp(),
          // Tambahkan field lain dari userDataDaftar jika disimpan di dokumen user utama
        });

        // 3. Simpan detail penumpang pertama ke subkoleksi 'passengers'
        //    Menggunakan PassengerModel akan lebih baik
        await _firestore
            .collection('users')
            .doc(newUser.uid)
            .collection('passengers')
            .add({
          'nama_lengkap': userDataDaftar.namaLengkap, // Asumsi field ini ada
          'tipe_id': userDataDaftar.tipeId,             // Asumsi field ini ada
          'nomor_id': userDataDaftar.nomorId,           // Asumsi field ini ada
          'tanggal_lahir': userDataDaftar.tanggalLahir, // Asumsi field ini ada (pastikan formatnya Timestamp atau konversi)
          'jenis_kelamin': userDataDaftar.jenisKelamin, // Asumsi field ini ada
          'tipe_penumpang': 'Dewasa', // Default atau ambil dari UserDataDaftar
          'isPrimary': true,
        });

        // (Opsional) Kirim email verifikasi standar
        // await newUser.sendEmailVerification();

        return userCredential;
      }
      return null; // Seharusnya tidak sampai sini jika createUserWithEmailAndPassword berhasil
    } on FirebaseAuthException catch (e) {
      // Tangani error spesifik dari Firebase Auth
      // Misalnya, email sudah digunakan, password lemah, dll.
      // Anda bisa melempar error ini kembali ke UI untuk ditampilkan
      throw Exception(e.message); // atau e.code
    } catch (e) {
      // Tangani error lainnya
      throw Exception(e.toString());
    }
  }

// ... metode lain seperti signIn, signOut, dll.
}