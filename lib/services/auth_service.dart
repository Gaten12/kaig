import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_data_daftar.dart'; // Model untuk data pendaftaran awal
import '../../models/user_model.dart'; // Model pengguna Anda
import '../../models/passenger_model.dart'; // Model penumpang Anda

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
  User? get currentUser => _firebaseAuth.currentUser;

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

  Future<UserCredential?> registerWithEmailPassword(String email, String password, UserDataDaftar userDataDaftar) async {
    // ... implementasi registerWithEmailPassword tetap sama ...
    try {
      UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? newUser = userCredential.user;

      if (newUser != null) {
        UserModel userForFirestore = UserModel(
          id: newUser.uid,
          email: newUser.email ?? userDataDaftar.email,
          noTelepon: userDataDaftar.noTelepon,
          role: 'costumer',
          createdAt: Timestamp.now(),
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
      // ... (penanganan error tetap sama) ...
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

  Future<UserCredential?> signInWithEmailPassword(String email, String password) async { /* ... implementasi tetap sama ... */ return null; }
  Future<void> signOut() async { /* ... implementasi tetap sama ... */ }
  Future<void> sendPasswordResetEmail(String email) async { /* ... implementasi tetap sama ... */ }

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
    print("[AuthService] Mengambil daftar penumpang tersimpan (isPrimary: false) untuk UID: $uid");
    // PERHATIAN: Query ini sekarang memfilter penumpang yang bukan utama, dan mengurutkannya berdasarkan nama.
    // Ini MEMERLUKAN INDEKS KOMPOSIT di Firestore agar bisa berfungsi.
    // Jika data tidak muncul, buat indeks di Firebase Console:
    // Koleksi: passengers (Collection Group)
    // 1. isPrimary (Ascending)
    // 2. nama_lengkap (Ascending)
    return _passengersCollection(uid)
        .where('isPrimary', isEqualTo: false) // Mengambil penumpang yang ditambahkan saja
    // PERBAIKAN DI SINI: Menggunakan 'nama_lengkap' (snake_case) sesuai field di Firestore
        .orderBy('nama_lengkap')
        .snapshots()
        .map((snapshot) {
      print("[AuthService] Daftar penumpang tersimpan snapshot diterima, jumlah: ${snapshot.docs.length}");
      return snapshot.docs.map((doc) => doc.data()).toList();
    })
        .handleError((error) {
      print("[AuthService] Error mengambil daftar penumpang tersimpan: $error");
      return [];
    });
  }

  Future<void> addPassenger(String uid, PassengerModel passenger) {
    print("[AuthService] Menambahkan penumpang baru untuk UID: $uid, Nama: ${passenger.namaLengkap}");
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
    print("[AuthService] Menghapus penumpang ID: $passengerId untuk UID: $uid");
    return _passengersCollection(uid).doc(passengerId).delete();
  }
}
