import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kaig/models/user_data_daftar.dart';
import 'package:kaig/models/user_model.dart';
import 'package:kaig/models/passenger_model.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Stream & Getter Pengguna ---
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
  User? get currentUser => _firebaseAuth.currentUser;

  // --- Registrasi & Login ---

  Future<UserCredential?> registerWithEmailPassword(String email, String password, UserDataDaftar userDataDaftar) async {
    try {
      UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? newUser = userCredential.user;

      if (newUser != null) {
        // Buat dokumen user di koleksi 'users'
        UserModel userForFirestore = UserModel(
          id: newUser.uid,
          email: newUser.email ?? userDataDaftar.email,
          noTelepon: userDataDaftar.noTelepon,
          role: 'costumer',
          createdAt: Timestamp.now(),
        );
        await _firestore.collection('users').doc(newUser.uid).set(userForFirestore.toFirestore());

        // Buat dokumen penumpang utama (primary passenger) di sub-koleksi
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
      throw Exception("Terjadi kesalahan tidak terduga saat pendaftaran.");
    }
  }

  Future<bool> cekEmailTerdaftar(String email) async {
    try {
      final list = await _firebaseAuth.fetchSignInMethodsForEmail(email);

      return list.isNotEmpty;
    } catch (e) {
      print("Error saat cek email: $e");
      return false;
    }
  }

  Future<UserCredential> signInWithEmailPassword(String email, String password) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw Exception('Gagal login: ${e.message}');
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  // --- Pengambilan Data Pengguna & Penumpang ---

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

  Future<PassengerModel?> getPrimaryPassenger(String uid) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('passengers')
          .where('isPrimary', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return PassengerModel.fromFirestore(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      print("Error mendapatkan Primary Passenger: $e");
      return null;
    }
  }

  // --- CRUD Penumpang Tambahan ---

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
    return _passengersCollection(uid)
        .where('isPrimary', isEqualTo: false)
        .orderBy('nama_lengkap')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<void> addPassenger(String uid, PassengerModel passenger) {
    return _passengersCollection(uid).add(passenger);
  }

  Future<void> updatePassenger(String uid, PassengerModel passenger) {
    if (passenger.id == null) {
      throw Exception("Passenger ID tidak boleh null untuk update");
    }
    return _passengersCollection(uid).doc(passenger.id).update(passenger.toFirestore());
  }

  Future<void> deletePassenger(String uid, String passengerId) {
    return _passengersCollection(uid).doc(passengerId).delete();
  }


  Future<bool> verifikasiPassword(String password) async {
    try {
      final user = currentUser;
      if (user == null || user.email == null) return false;
      final cred = EmailAuthProvider.credential(email: user.email!, password: password);
      await user.reauthenticateWithCredential(cred);
      return true;
    } catch (e) {
      print("Verifikasi password gagal: $e");
      return false;
    }
  }

  Future<void> updateNomorTelepon(String noTeleponBaru) async {
    final user = currentUser;
    if (user == null) throw Exception("User tidak login");
    await _firestore.collection('users').doc(user.uid).update({'no_telepon': noTeleponBaru});
  }

  Future<void> updateEmail(String emailBaru) async {
    final user = currentUser;
    if (user == null) throw Exception("User tidak login");
    await user.verifyBeforeUpdateEmail(emailBaru);
    await _firestore.collection('users').doc(user.uid).update({'email': emailBaru});
  }

  Future<void> updatePrimaryPassenger(PassengerModel updatedData) async {
    final user = currentUser;
    if (user == null) throw Exception("User tidak login");

    final querySnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('passengers')
        .where('isPrimary', isEqualTo: true)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      throw Exception("Data penumpang utama tidak ditemukan.");
    }

    final passengerDocRef = querySnapshot.docs.first.reference;
    await passengerDocRef.update(updatedData.toFirestore());
  }

  Future<void> hapusAkun() async {
    final user = currentUser;
    if (user == null) throw Exception("User tidak login");

    try {
      await _firestore.collection('users').doc(user.uid).delete();
      await user.delete();
    } catch (e) {
      print("Gagal menghapus akun: $e");
      throw Exception("Gagal menghapus akun. Silakan coba login ulang dan ulangi lagi.");
    }
  }
}