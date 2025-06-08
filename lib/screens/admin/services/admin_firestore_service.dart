import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/JadwalModel.dart';
import '../../../models/KeretaModel.dart';
import '../../../models/gerbong_tipe_model.dart'; // Menggunakan model baru
import '../../../models/stasiun_model.dart';


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
    return gerbongTipeCollection
        .orderBy('kelas')
        .orderBy('subTipe')
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

    return query.snapshots().map((snapshot) {
      List<JadwalModel> jadwalList = snapshot.docs.map((doc) {
        try { return doc.data(); }
        catch (e) { print("Error parsing jadwal ID: ${doc.id}. Error: $e"); return null; }
      }).whereType<JadwalModel>().toList();

      if (tanggal != null && kodeAsal != null && kodeTujuan != null) {
        // Filter tambahan di client untuk stasiun tujuan dan urutan
        jadwalList = jadwalList.where((jadwal) {
          bool mengandungTujuan = jadwal.ruteLengkapKodeStasiun.contains(kodeTujuan.toUpperCase());
          if (!mengandungTujuan) return false;
          int indexAsal = jadwal.ruteLengkapKodeStasiun.indexOf(kodeAsal.toUpperCase());
          int indexTujuan = jadwal.ruteLengkapKodeStasiun.indexOf(kodeTujuan.toUpperCase());
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
  Future<void> generateKursiUntukJadwal(String jadwalId, List<GerbongTipeModel> gerbongList) async {
    final WriteBatch batch = _db.batch();
    // Path ke subkoleksi 'kursi' di dalam dokumen jadwal yang spesifik
    final kursiCollection = _db.collection('jadwal').doc(jadwalId).collection('kursi');

    for (final gerbong in gerbongList) {
      List<String> nomorKursiGenerated = [];
      // Logika untuk generate nomor kursi berdasarkan tipe layout
      switch (gerbong.tipeLayout) {
        case TipeLayoutGerbong.layout_2_2:
        // Contoh: Untuk 50 kursi, bisa 12 baris x 4 (48) + 1 baris x 2
          int barisPenuh = (gerbong.jumlahKursi / 4).floor();
          int sisa = gerbong.jumlahKursi % 4;
          for (int i = 1; i <= barisPenuh; i++) {
            nomorKursiGenerated.addAll(['${i}A', '${i}B', '${i}C', '${i}D']);
          }
          if (sisa > 0) {
            final sisaKursi = ['A', 'B', 'C', 'D'].take(sisa);
            for (var kursiSisa in sisaKursi) {
              nomorKursiGenerated.add('${barisPenuh + 1}$kursiSisa');
            }
          }
          break;
        case TipeLayoutGerbong.layout_3_2:
          int barisPenuh = (gerbong.jumlahKursi / 5).floor();
          int sisa = gerbong.jumlahKursi % 5;
          for (int i = 1; i <= barisPenuh; i++) {
            nomorKursiGenerated.addAll(['${i}A', '${i}B', '${i}C', '${i}D', '${i}E']);
          }
          if (sisa > 0) {
            final sisaKursi = ['A', 'B', 'C', 'D', 'E'].take(sisa);
            for (var kursiSisa in sisaKursi) {
              nomorKursiGenerated.add('${barisPenuh + 1}$kursiSisa');
            }
          }
          break;
      // Tambahkan case untuk layout_2_1 dan layout_1_1 jika perlu
        default: // case TipeLayoutGerbong.lainnya:
          for (int i = 1; i <= gerbong.jumlahKursi; i++) {
            nomorKursiGenerated.add('$i');
          }
      }

      for (final nomorKursi in nomorKursiGenerated) {
        final kursiDocRef = kursiCollection.doc(); // Firestore generate ID untuk setiap kursi
        batch.set(kursiDocRef, {
          'id_jadwal': jadwalId,
          'id_gerbong': gerbong.id, // ID dari master tipe gerbong
          'nomor_kursi': nomorKursi,
          'status': 'tersedia', // Status awal saat di-generate
          'segmenTerisi': [], // Array kosong untuk menampung segmen yg dipesan
        });
      }
    }

    await batch.commit();
    print("Batch write untuk ${gerbongList.length} gerbong berhasil di-commit.");
  }
}
