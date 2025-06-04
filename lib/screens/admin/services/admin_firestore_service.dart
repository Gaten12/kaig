import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/stasiun_model.dart'; // Pastikan path ini benar
import '../../../models/KeretaModel.dart';

class AdminFirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Stasiun CRUD (Sudah ada dari sebelumnya) ---
  CollectionReference<StasiunModel> get stasiunCollection =>
      _db.collection('stasiun').withConverter<StasiunModel>(
        fromFirestore: (snapshots, _) => StasiunModel.fromFirestore(snapshots),
        toFirestore: (stasiun, _) => stasiun.toFirestore(),
      );

  Stream<List<StasiunModel>> getStasiunList() {
    return stasiunCollection
        .orderBy('nama')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<void> addStasiun(StasiunModel stasiun) {
    return stasiunCollection.doc(stasiun.kode.toUpperCase()).set(stasiun);
  }

  Future<void> updateStasiun(StasiunModel stasiun) {
    return stasiunCollection.doc(stasiun.id).update(stasiun.toFirestore());
  }

  Future<void> deleteStasiun(String stasiunId) {
    return stasiunCollection.doc(stasiunId).delete();
  }

  // --- Kereta CRUD ---
  CollectionReference<KeretaModel> get keretaCollection =>
      _db.collection('kereta').withConverter<KeretaModel>(
        fromFirestore: (snapshots, _) => KeretaModel.fromFirestore(snapshots),
        toFirestore: (kereta, _) => kereta.toFirestore(),
      );

  Stream<List<KeretaModel>> getKeretaList() {
    return keretaCollection
        .orderBy('nama') // Urutkan berdasarkan nama kereta
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<void> addKereta(KeretaModel kereta) {
    // Menggunakan ID yang di-generate otomatis oleh Firestore
    return keretaCollection.add(kereta).then((docRef) {
      print("Kereta ditambahkan dengan ID: ${docRef.id}");
      // Anda bisa update dokumen dengan ID-nya jika diperlukan, tapi KeretaModel sudah punya 'id'
    });
  }

  Future<void> updateKereta(KeretaModel kereta) {
    // Pastikan kereta.id adalah Document ID yang benar
    return keretaCollection.doc(kereta.id).update(kereta.toFirestore());
  }

  Future<void> deleteKereta(String keretaId) {
    return keretaCollection.doc(keretaId).delete();
  }

// TODO: Tambahkan CRUD untuk Jadwal
}

// File: lib/src/admin/screens/kelola_kereta/list_kereta_screen.dart


// File: lib/src/admin/screens/kelola_kereta/form_kereta_screen.dart
