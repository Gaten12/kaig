import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/JadwalModel.dart';
import '../../../models/stasiun_model.dart'; // Pastikan path ini benar
import '../../../models/KeretaModel.dart';

class AdminFirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Stasiun CRUD ---
  CollectionReference<StasiunModel> get stasiunCollection =>
      _db.collection('stasiun').withConverter<StasiunModel>(
        fromFirestore: (snapshots, _) => StasiunModel.fromFirestore(snapshots),
        toFirestore: (stasiun, _) => stasiun.toFirestore(),
      );

  Stream<List<StasiunModel>> getStasiunList() {
    return stasiunCollection.orderBy('nama').snapshots().map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
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
    return keretaCollection.orderBy('nama').snapshots().map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
  Future<void> addKereta(KeretaModel kereta) {
    return keretaCollection.add(kereta);
  }
  Future<void> updateKereta(KeretaModel kereta) {
    return keretaCollection.doc(kereta.id).update(kereta.toFirestore());
  }
  Future<void> deleteKereta(String keretaId) {
    return keretaCollection.doc(keretaId).delete();
  }

  // --- Jadwal CRUD ---
  CollectionReference<JadwalModel> get jadwalCollection =>
      _db.collection('jadwal').withConverter<JadwalModel>(
        fromFirestore: (snapshots, _) => JadwalModel.fromFirestore(snapshots),
        toFirestore: (jadwal, _) => jadwal.toFirestore(),
      );

  Stream<List<JadwalModel>> getJadwalList({DateTime? tanggal, String? kodeAsal, String? kodeTujuan}) {
    Query<JadwalModel> query = jadwalCollection;

    print("[AdminFirestoreService] getJadwalList dipanggil dengan: tanggal=$tanggal, kodeAsal=$kodeAsal, kodeTujuan=$kodeTujuan");

    if (tanggal != null && kodeAsal != null && kodeTujuan != null) {
      DateTime startOfDayDate = DateTime(tanggal.year, tanggal.month, tanggal.day, 0, 0, 0);
      DateTime endOfDayDate = DateTime(tanggal.year, tanggal.month, tanggal.day, 23, 59, 59, 999);
      Timestamp startOfDayTimestamp = Timestamp.fromDate(startOfDayDate);
      Timestamp endOfDayTimestamp = Timestamp.fromDate(endOfDayDate);

      print("[AdminFirestoreService] Query Customer: Asal=${kodeAsal.toUpperCase()}, Tujuan=${kodeTujuan.toUpperCase()}, TglDari=$startOfDayTimestamp, TglSampai=$endOfDayTimestamp");

      query = query
          .where('queryWaktuBerangkatUtama', isGreaterThanOrEqualTo: startOfDayTimestamp)
          .where('queryWaktuBerangkatUtama', isLessThanOrEqualTo: endOfDayTimestamp)
      // PERBAIKAN DI SINI: Menggunakan named parameter 'arrayContains'
          .where('ruteLengkapKodeStasiun', arrayContains: kodeAsal.toUpperCase());
      // .orderBy('queryWaktuBerangkatUtama'); // Dihapus sementara untuk menyederhanakan debug 'array-contains'

      // PENTING: Jika Anda menambahkan orderBy('queryWaktuBerangkatUtama') setelah where dengan arrayContains,
      // Anda mungkin perlu indeks komposit yang sangat spesifik:
      // 1. ruteLengkapKodeStasiun (Array)
      // 2. queryWaktuBerangkatUtama (Ascending/Descending sesuai orderBy)
      // Firebase akan memberi tahu Anda indeks yang tepat jika diperlukan melalui pesan error di konsol.
      // Untuk sekarang, coba tanpa orderBy setelah array-contains untuk melihat apakah data dasar muncul.
    } else {
      print("[AdminFirestoreService] Query Admin: Mengambil semua jadwal, diurutkan berdasarkan queryWaktuBerangkatUtama descending.");
      query = query.orderBy('queryWaktuBerangkatUtama', descending: true);
    }

    return query
        .snapshots()
        .map((snapshot) {
      print("[AdminFirestoreService] Snapshot diterima, jumlah dokumen awal dari Firestore: ${snapshot.docs.length}");

      List<JadwalModel> jadwalList = snapshot.docs.map((doc) {
        try {
          return doc.data();
        } catch (e, s) {
          print("[AdminFirestoreService] Gagal parsing dokumen jadwal ID: ${doc.id}. Error: $e");
          print("StackTrace: $s");
          return null;
        }
      }).whereType<JadwalModel>().toList();

      if (tanggal != null && kodeAsal != null && kodeTujuan != null) {
        jadwalList = jadwalList.where((jadwal) {
          bool mengandungTujuan = jadwal.ruteLengkapKodeStasiun.contains(kodeTujuan.toUpperCase());
          if (!mengandungTujuan) return false;

          int indexAsal = jadwal.ruteLengkapKodeStasiun.indexOf(kodeAsal.toUpperCase());
          int indexTujuan = jadwal.ruteLengkapKodeStasiun.indexOf(kodeTujuan.toUpperCase());

          return indexAsal != -1 && indexTujuan != -1 && indexAsal < indexTujuan;
        }).toList();
        print("[AdminFirestoreService] Jumlah dokumen setelah filter client-side untuk tujuan & urutan: ${jadwalList.length}");
      }
      return jadwalList;
    });
  }

  Future<DocumentReference<JadwalModel>> addJadwal(JadwalModel jadwal) {
    return jadwalCollection.add(jadwal);
  }

  Future<void> updateJadwal(JadwalModel jadwal) {
    return jadwalCollection.doc(jadwal.id).update(jadwal.toFirestore());
  }

  Future<void> deleteJadwal(String jadwalId) {
    return jadwalCollection.doc(jadwalId).delete();
  }
}