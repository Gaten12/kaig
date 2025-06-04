import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_data_daftar.dart'; // Model untuk data pendaftaran awal
import '../../models/user_model.dart'; // Model pengguna Anda
import '../../models/passenger_model.dart'; // Model penumpang Anda

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream untuk memantau perubahan status autentikasi
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Mendapatkan pengguna yang sedang login saat ini
  User? get currentUser => _firebaseAuth.currentUser;

  // Mendapatkan UserModel dari Firestore berdasarkan UID
  Future<UserModel?> getUserModel(String uid) async {
    try {
      final docSnapshot = await _firestore.collection('users').doc(uid).get();
      if (docSnapshot.exists) {
        return UserModel.fromFirestore(docSnapshot);
      }
      return null;
    } catch (e) {
      print("Error mendapatkan UserModel: $e");
      return null;
    }
  }


  Future<UserCredential?> registerWithEmailPassword(
      String email,
      String password,
      UserDataDaftar userDataDaftar,
      ) async {
    try {
      UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? newUser = userCredential.user;

      if (newUser != null) {
        // Membuat UserModel dari UserDataDaftar
        UserModel userForFirestore = UserModel(
          id: newUser.uid,
          email: newUser.email ?? userDataDaftar.email, // Ambil email dari newUser jika ada
          noTelepon: userDataDaftar.noTelepon,
          role: 'costumer', // Default role untuk pendaftar baru
          createdAt: Timestamp.now(), // Atau FieldValue.serverTimestamp() jika diinginkan
        );

        await _firestore.collection('users').doc(newUser.uid).set(userForFirestore.toFirestore());

        // Membuat PassengerModel untuk penumpang pertama
        PassengerModel passengerData = PassengerModel(
          // id tidak perlu diisi di sini karena akan di-generate oleh .add()
          namaLengkap: userDataDaftar.namaLengkap,
          tipeId: userDataDaftar.tipeId,
          nomorId: userDataDaftar.nomorId,
          tanggalLahir: Timestamp.fromDate(userDataDaftar.tanggalLahir), // Konversi DateTime ke Timestamp
          jenisKelamin: userDataDaftar.jenisKelamin,
          tipePenumpang: 'Dewasa', // Default
          isPrimary: true,
        );

        await _firestore
            .collection('users')
            .doc(newUser.uid)
            .collection('passengers')
            .add(passengerData.toFirestore());

        // (Opsional) Kirim email verifikasi
        // await newUser.sendEmailVerification();

        return userCredential;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      // Tangani error spesifik dari Firebase Auth
      // Misalnya, email sudah digunakan, password lemah, dll.
      String friendlyMessage = "Pendaftaran gagal.";
      if (e.code == 'weak-password') {
        friendlyMessage = 'Kata sandi terlalu lemah.';
      } else if (e.code == 'email-already-in-use') {
        friendlyMessage = 'Alamat email ini sudah digunakan.';
      } else if (e.code == 'invalid-email') {
        friendlyMessage = 'Format email tidak valid.';
      }
      throw Exception(friendlyMessage);
    } catch (e) {
      print("Error saat registrasi: $e");
      throw Exception("Terjadi kesalahan tidak terduga saat pendaftaran.");
    }
  }

  Future<UserCredential?> signInWithEmailPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      String friendlyMessage = "Login gagal.";
      if (e.code == 'user-not-found') {
        friendlyMessage = 'Email tidak ditemukan.';
      } else if (e.code == 'wrong-password') {
        friendlyMessage = 'Kata sandi salah.';
      } else if (e.code == 'invalid-email') {
        friendlyMessage = 'Format email tidak valid.';
      } else if (e.code == 'invalid-credential') {
        friendlyMessage = 'Kredensial tidak valid. Pastikan email dan password benar.';
      }
      // Anda bisa menambahkan penanganan untuk error lain seperti 'user-disabled', dll.
      throw Exception(friendlyMessage);
    } catch (e) {
      print("Error saat signIn: $e");
      throw Exception("Terjadi kesalahan tidak terduga saat login.");
    }
  }

  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      print("Error saat signOut: $e");
      // Pertimbangkan untuk melempar error jika diperlukan penanganan khusus di UI
      // throw Exception("Gagal melakukan logout.");
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      String friendlyMessage = "Gagal mengirim email reset.";
      if (e.code == 'user-not-found') {
        friendlyMessage = "Email tidak terdaftar.";
      } else if (e.code == 'invalid-email') {
        friendlyMessage = "Format email tidak valid.";
      }
      throw Exception(friendlyMessage);
    } catch (e) {
      print("Error saat sendPasswordResetEmail: $e");
      throw Exception("Terjadi kesalahan saat mengirim email reset kata sandi.");
    }
  }
}
