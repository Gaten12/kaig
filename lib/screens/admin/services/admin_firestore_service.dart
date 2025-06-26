import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/JadwalModel.dart';
import '../../../models/KeretaModel.dart';
import '../../../models/gerbong_tipe_model.dart';
import '../../../models/perhentian_krl_model.dart';
import 'package:kaig/models/jadwal_krl_model.dart';
import '../../../models/kursi_model.dart';
import '../../../models/stasiun_model.dart';
import '../../../models/user_model.dart'; // Import the UserModel

class AdminFirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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

  Future<DocumentReference<KeretaModel>> addKereta(KeretaModel kereta) {
    return keretaCollection.add(kereta);
  }

  Future<void> updateKereta(KeretaModel kereta) {
    return keretaCollection.doc(kereta.id).update(kereta.toFirestore());
  }

  Future<void> deleteKereta(String keretaId) {
    return keretaCollection.doc(keretaId).delete();
  }


  // --- Tipe Gerbong CRUD ---
  CollectionReference<GerbongTipeModel> get gerbongTipeCollection =>
      _db.collection('tipeGerbong').withConverter<GerbongTipeModel>(
        fromFirestore: (snapshots, _) => GerbongTipeModel.fromFirestore(snapshots),
        toFirestore: (gerbong, _) => gerbong.toFirestore(),
      );

  Stream<List<GerbongTipeModel>> getGerbongTipeList() {
    // [PERBAIKAN] Mengubah 'subTipe' menjadi 'nama_tipe' karena field 'subTipe' sudah tidak ada.
    return gerbongTipeCollection
        .orderBy('kelas')
        .orderBy('nama_tipe') // Mengurutkan berdasarkan nama_tipe
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<DocumentReference<GerbongTipeModel>> addGerbongTipe(GerbongTipeModel gerbong) {
    return gerbongTipeCollection.add(gerbong);
  }

  Future<void> updateGerbongTipe(GerbongTipeModel gerbong) {
    return gerbongTipeCollection.doc(gerbong.id).update(gerbong.toFirestore());
  }

  Future<void> deleteGerbongTipe(String gerbongId) {
    return gerbongTipeCollection.doc(gerbongId).delete();
  }


  // --- Jadwal CRUD ---
  CollectionReference<JadwalModel> get jadwalCollection =>
      _db.collection('jadwal').withConverter<JadwalModel>(
        fromFirestore: (snapshots, _) => JadwalModel.fromFirestore(snapshots),
        toFirestore: (jadwal, _) => jadwal.toFirestore(),
      );

  Stream<List<JadwalModel>> getJadwalList({DateTime? tanggal, String? kodeAsal, String? kodeTujuan}) {
    Query<JadwalModel> query = jadwalCollection;

    if (tanggal != null && kodeAsal != null && kodeTujuan != null) {
      // Query untuk customer
      DateTime startOfDayDate = DateTime(tanggal.year, tanggal.month, tanggal.day, 0, 0, 0);
      DateTime endOfDayDate = DateTime(tanggal.year, tanggal.month, tanggal.day, 23, 59, 59, 999);
      Timestamp startOfDayTimestamp = Timestamp.fromDate(startOfDayDate);
      Timestamp endOfDayTimestamp = Timestamp.fromDate(endOfDayDate);

      query = query
          .where('queryWaktuBerangkatUtama', isGreaterThanOrEqualTo: startOfDayTimestamp)
          .where('queryWaktuBerangkatUtama', isLessThanOrEqualTo: endOfDayTimestamp)
          .where('ruteLengkapKodeStasiun', arrayContains: kodeAsal.toUpperCase());
    } else {
      // Query default untuk admin
      query = query.orderBy('queryWaktuBerangkatUtama', descending: true);
    }

    return query
        .snapshots()
        .map((snapshot) {
      List<JadwalModel> jadwalList = snapshot.docs.map((doc) {
        try { return doc.data(); }
        catch (e) { print("Error parsing dokumen jadwal ID: ${doc.id}. Error: $e"); return null; }
      }).whereType<JadwalModel>().toList();

      if (tanggal != null && kodeAsal != null && kodeTujuan != null) {
        // Filter tambahan di client
        jadwalList = jadwalList.where((jadwal) {
          final rute = jadwal.ruteLengkapKodeStasiun.map((k) => k.toUpperCase()).toList();
          if (!rute.contains(kodeTujuan.toUpperCase())) return false;
          int indexAsal = rute.indexOf(kodeAsal.toUpperCase());
          int indexTujuan = rute.indexOf(kodeTujuan.toUpperCase());
          return indexAsal < indexTujuan;
        }).toList();
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

  // --- Kursi CRUD ---
  Stream<List<KursiModel>> getKursiListForJadwal(String jadwalId, int nomorGerbong) {
    final kursiCollection = _db
        .collection('jadwal')
        .doc(jadwalId)
        .collection('kursi')
        .withConverter<KursiModel>(
      fromFirestore: (snapshots, _) => KursiModel.fromFirestore(snapshots),
      toFirestore: (kursi, _) => kursi.toFirestore(),
    );

    return kursiCollection
        .where('nomor_gerbong', isEqualTo: nomorGerbong)
        .orderBy('nomor_kursi')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<void> generateKursiUntukJadwal(String jadwalId, List<GerbongTipeModel> rangkaianGerbong) async {
    final WriteBatch batch = _db.batch();
    final kursiCollection = _db.collection('jadwal').doc(jadwalId).collection('kursi');

    for (int i = 0; i < rangkaianGerbong.length; i++) {
      final gerbong = rangkaianGerbong[i];
      final nomorGerbongSaatIni = i + 1;

      List<String> nomorKursiGenerated = [];
      switch (gerbong.tipeLayout) {
        case TipeLayoutGerbong.layout_2_2:
          int baris = (gerbong.jumlahKursi / 4).ceil();
          for (int r = 1; r <= baris; r++) { nomorKursiGenerated.addAll(['${r}A', '${r}B', '${r}C', '${r}D']); }
          break;
        case TipeLayoutGerbong.layout_3_2:
          int baris = (gerbong.jumlahKursi / 5).ceil();
          for (int r = 1; r <= baris; r++) { nomorKursiGenerated.addAll(['${r}A', '${r}B', '${r}C', '${r}D', '${r}E']); }
          break;
        case TipeLayoutGerbong.layout_2_1:
          int baris = (gerbong.jumlahKursi / 3).ceil();
          for (int r = 1; r <= baris; r++) { nomorKursiGenerated.addAll(['${r}A', '${r}B', '${r}C']); }
          break;
        case TipeLayoutGerbong.layout_1_1:
          int baris = (gerbong.jumlahKursi / 2).ceil();
          for (int r = 1; r <= baris; r++) { nomorKursiGenerated.addAll(['${r}A', '${r}B']); }
          break;
        default:
          for (int k = 1; k <= gerbong.jumlahKursi; k++) { nomorKursiGenerated.add('$k'); }
      }

      // Ambil hanya sejumlah kursi yang seharusnya ada
      final kursiFinal = nomorKursiGenerated.take(gerbong.jumlahKursi);

      for (final nomorKursi in kursiFinal) {
        final kursiDocRef = kursiCollection.doc();
        batch.set(kursiDocRef, {
          'id_jadwal': jadwalId,
          'id_tipe_gerbong': gerbong.id,
          'nomor_gerbong': nomorGerbongSaatIni,
          'nomor_kursi': nomorKursi,
          'status': 'tersedia',
          'segmenTerisi': [],
        });
      }
    }

    await batch.commit();
    print("Batch write untuk ${rangkaianGerbong.length} gerbong berhasil di-commit.");
  }
  CollectionReference<JadwalKrlModel> get krlJadwalCollection =>
      _db.collection('jadwal_krl').withConverter<JadwalKrlModel>(
        fromFirestore: (snapshots, _) => JadwalKrlModel.fromFirestore(snapshots),
        toFirestore: (jadwal, _) => jadwal.toFirestore(),
      );

  Future<void> addJadwalKrl(JadwalKrlModel jadwal) {
    return krlJadwalCollection.add(jadwal);
  }

  Future<void> updateJadwalKrl(JadwalKrlModel jadwal) {
    return krlJadwalCollection.doc(jadwal.id).update(jadwal.toFirestore());
  }

  Future<void> deleteJadwalKrl(String jadwalId) {
    return krlJadwalCollection.doc(jadwalId).delete();
  }

  Stream<List<JadwalKrlModel>> getJadwalKrlList() {
    return krlJadwalCollection
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

// Query untuk Customer
  Stream<List<JadwalKrlModel>> findJadwalKrl(String kodeAsal, String kodeTujuan, String tipeHari) {
    return krlJadwalCollection
        .where('tipeHari', isEqualTo: tipeHari)
        .where('stasiunTersedia', arrayContains: kodeAsal)
        .snapshots()
        .map((snapshot) {
      // Filter kedua di sisi client
      return snapshot.docs.map((doc) => doc.data()).where((jadwal) {
        final stasiunList = jadwal.perhentian;
        final indexAsal = stasiunList.indexWhere((p) => p.kodeStasiun == kodeAsal);
        final indexTujuan = stasiunList.indexWhere((p) => p.kodeStasiun == kodeTujuan);

        // Pastikan stasiun tujuan ada di rute DAN urutannya setelah stasiun asal
        return indexTujuan != -1 && indexAsal < indexTujuan;
      }).toList();
    });
  }


  // --- User CRUD ---
  CollectionReference<UserModel> get userCollection =>
      _db.collection('users').withConverter<UserModel>(
        fromFirestore: (snapshots, _) => UserModel.fromFirestore(snapshots),
        toFirestore: (user, _) => user.toFirestore(),
      );

  Stream<List<UserModel>> getUserList() {
    return userCollection.orderBy('email').snapshots().map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
  Future<void> addUser(UserModel user) {
    return userCollection.add(user);
  }

  Future<void> updateUser(UserModel user) {
    return userCollection.doc(user.id).update(user.toFirestore());
  }
  Future<void> deleteUser(String userId) {
    return userCollection.doc(userId).delete();
  }
}