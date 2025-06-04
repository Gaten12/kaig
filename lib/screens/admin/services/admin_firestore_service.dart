import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/JadwalModel.dart';
import '../../../models/stasiun_model.dart'; // Pastikan path ini benar
import '../../../models/KeretaModel.dart';

class AdminFirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Stasiun CRUD (Sudah ada) ---
  CollectionReference<StasiunModel> get stasiunCollection =>
      _db.collection('stasiun').withConverter<StasiunModel>(
        fromFirestore: (snapshots, _) => StasiunModel.fromFirestore(snapshots),
        toFirestore: (stasiun, _) => stasiun.toFirestore(),
      );
  Stream<List<StasiunModel>> getStasiunList() {/* ... implementasi ... */
    return stasiunCollection.orderBy('nama').snapshots().map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
  Future<void> addStasiun(StasiunModel stasiun) {/* ... implementasi ... */
    return stasiunCollection.doc(stasiun.kode.toUpperCase()).set(stasiun);
  }
  Future<void> updateStasiun(StasiunModel stasiun) {/* ... implementasi ... */
    return stasiunCollection.doc(stasiun.id).update(stasiun.toFirestore());
  }
  Future<void> deleteStasiun(String stasiunId) {/* ... implementasi ... */
    return stasiunCollection.doc(stasiunId).delete();
  }

  // --- Kereta CRUD (Sudah ada) ---
  CollectionReference<KeretaModel> get keretaCollection =>
      _db.collection('kereta').withConverter<KeretaModel>(
        fromFirestore: (snapshots, _) => KeretaModel.fromFirestore(snapshots),
        toFirestore: (kereta, _) => kereta.toFirestore(),
      );
  Stream<List<KeretaModel>> getKeretaList() {/* ... implementasi ... */
    return keretaCollection.orderBy('nama').snapshots().map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
  Future<void> addKereta(KeretaModel kereta) {/* ... implementasi ... */
    return keretaCollection.add(kereta);
  }
  Future<void> updateKereta(KeretaModel kereta) {/* ... implementasi ... */
    return keretaCollection.doc(kereta.id).update(kereta.toFirestore());
  }
  Future<void> deleteKereta(String keretaId) {/* ... implementasi ... */
    return keretaCollection.doc(keretaId).delete();
  }

  // --- Jadwal CRUD ---
  CollectionReference<JadwalModel> get jadwalCollection =>
      _db.collection('jadwal').withConverter<JadwalModel>(
        fromFirestore: (snapshots, _) => JadwalModel.fromFirestore(snapshots),
        toFirestore: (jadwal, _) => jadwal.toFirestore(),
      );

  Stream<List<JadwalModel>> getJadwalList() {
    return jadwalCollection
        .orderBy('tanggalBerangkat', descending: true) // Contoh urutan
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<DocumentReference<JadwalModel>> addJadwal(JadwalModel jadwal) {
    // Firestore akan generate ID otomatis
    return jadwalCollection.add(jadwal);
  }

  Future<void> updateJadwal(JadwalModel jadwal) {
    // Pastikan jadwal.id adalah Document ID yang valid
    return jadwalCollection.doc(jadwal.id).update(jadwal.toFirestore());
  }

  Future<void> deleteJadwal(String jadwalId) {
    return jadwalCollection.doc(jadwalId).delete();
  }
}