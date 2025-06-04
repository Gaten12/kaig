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
      print("[AuthService] UserModel tidak ditemukan untuk UID: $uid");
      return null;
    } catch (e) {
      print("Error mendapatkan UserModel: $e");
      return null;
    }
  }

  // Fungsi untuk mengambil data penumpang utama (yang isPrimary = true)
  Future<PassengerModel?> getPrimaryPassenger(String uid) async {
    print("[AuthService] Mencoba mengambil Primary Passenger untuk UID: $uid");
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('passengers')
          .where('isPrimary', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        print("[AuthService] Primary Passenger ditemukan: ${querySnapshot.docs.first.data()}");
        return PassengerModel.fromFirestore(querySnapshot.docs.first);
      }
      print("[AuthService] Primary Passenger tidak ditemukan untuk UID: $uid");
      return null;
    } catch (e) {
      print("Error mendapatkan Primary Passenger: $e");
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
        // UserModel TIDAK menyimpan namaLengkap secara langsung berdasarkan definisi UserModel Anda.
        // namaLengkap dari userDataDaftar akan disimpan di primaryPassengerData.
        UserModel userForFirestore = UserModel(
          id: newUser.uid,
          email: newUser.email ?? userDataDaftar.email,
          noTelepon: userDataDaftar.noTelepon,
          role: 'costumer',
          createdAt: Timestamp.now(),
          // namaLengkap: userDataDaftar.namaLengkap, // Dihapus karena UserModel Anda tidak punya field ini
        );
        await _firestore.collection('users').doc(newUser.uid).set(userForFirestore.toFirestore());

        PassengerModel primaryPassengerData = PassengerModel(
          namaLengkap: userDataDaftar.namaLengkap,
          tipeId: userDataDaftar.tipeId,
          nomorId: userDataDaftar.nomorId,
          tanggalLahir: Timestamp.fromDate(userDataDaftar.tanggalLahir),
          jenisKelamin: userDataDaftar.jenisKelamin,
          tipePenumpang: 'Dewasa',
          isPrimary: true,
        );
        await _firestore
            .collection('users')
            .doc(newUser.uid)
            .collection('passengers')
            .add(primaryPassengerData.toFirestore());

        return userCredential;
      }
      return null;
    } on FirebaseAuthException catch (e) {
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
      print("Error saat registrasi (catch umum): $e");
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
      throw Exception(friendlyMessage);
    } catch (e) {
      print("Error saat signIn (catch umum): $e");
      throw Exception("Terjadi kesalahan tidak terduga saat login.");
    }
  }

  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      print("Error saat signOut: $e");
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
      print("Error saat sendPasswordResetEmail (catch umum): $e");
      throw Exception("Terjadi kesalahan saat mengirim email reset kata sandi.");
    }
  }

  // --- Passenger CRUD ---
  CollectionReference<PassengerModel> _passengersCollection(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('passengers')
        .withConverter<PassengerModel>(
      fromFirestore: (snapshots, _) => PassengerModel.fromFirestore(snapshots),
      toFirestore: (passenger, _) => passenger.toFirestore(),
    );
  }

  Stream<List<PassengerModel>> getSavedPassengers(String uid) {
    print("[AuthService] Mengambil daftar penumpang untuk UID: $uid");
    return _passengersCollection(uid)
        .orderBy('isPrimary', descending: true) // Penumpang utama (jika ada) di atas
        .orderBy('namaLengkap') // Kemudian urutkan berdasarkan nama
        .snapshots()
        .map((snapshot) {
      print("[AuthService] Daftar penumpang snapshot diterima, jumlah: ${snapshot.docs.length}");
      return snapshot.docs.map((doc) => doc.data()).toList();
    })
        .handleError((error) {
      print("[AuthService] Error mengambil daftar penumpang: $error");
      return []; // Kembalikan list kosong jika ada error
    });
  }

  Future<void> addPassenger(String uid, PassengerModel passenger) {
    print("[AuthService] Menambahkan penumpang baru untuk UID: $uid, Nama: ${passenger.namaLengkap}");
    // isPrimary seharusnya false untuk penumpang yang ditambahkan dari menu "Daftar Penumpang"
    // kecuali ada logika khusus. Untuk sekarang, kita asumsikan isPrimary di-set dengan benar
    // sebelum memanggil metode ini (misalnya, selalu false).
    return _passengersCollection(uid).add(passenger);
  }

  Future<void> updatePassenger(String uid, PassengerModel passenger) {
    if (passenger.id == null) {
      print("[AuthService] Error: Passenger ID tidak boleh null untuk update.");
      throw Exception("Passenger ID tidak boleh null untuk update");
    }
    print("[AuthService] Mengupdate penumpang ID: ${passenger.id} untuk UID: $uid");
    return _passengersCollection(uid).doc(passenger.id).update(passenger.toFirestore());
  }

  Future<void> deletePassenger(String uid, String passengerId) {
    // Tambahkan pengecekan agar tidak bisa menghapus penumpang utama (isPrimary: true)
    // dari fungsi generik ini. Pengecekan sebaiknya ada di UI atau sebelum memanggil ini.
    print("[AuthService] Menghapus penumpang ID: $passengerId untuk UID: $uid");
    return _passengersCollection(uid).doc(passengerId).delete();
  }
}