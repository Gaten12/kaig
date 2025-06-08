import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kaig/models/transaksi_model.dart';

class TransaksiService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  Stream<List<TransaksiModel>> getTiketSaya(String userId) {
    return _db
        .collection('transaksi')
        .where('userId', isEqualTo: userId)
        .orderBy('tanggalTransaksi', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => TransaksiModel.fromFirestore(doc))
        .toList());
  }

  Future<void> buatTransaksi({
    required TransaksiModel transaksi,
    required String jadwalId,
    required List<String> kursiTerpilih // Format: ["Gerbong 1 - Kursi 1A", "Gerbong 1 - Kursi 1B"]
  }) async {
    final WriteBatch batch = _db.batch();

    final transaksiDocRef = _db.collection('transaksi').doc();
    batch.set(transaksiDocRef, transaksi.toFirestore());

    final kursiQuerySnapshot = await _db
        .collection('jadwal')
        .doc(jadwalId)
        .collection('kursi')
        .get();

    final Map<String, String> mapKursiKeDocId = {};
    for (var doc in kursiQuerySnapshot.docs) {
      final data = doc.data();
      final key = "Gerbong ${data['nomor_gerbong']} - Kursi ${data['nomor_kursi']}";
      mapKursiKeDocId[key] = doc.id;
    }

    for (final kursiString in kursiTerpilih) {
      final docId = mapKursiKeDocId[kursiString];
      if (docId != null) {
        final kursiDocRef = _db.collection('jadwal').doc(jadwalId).collection('kursi').doc(docId);
        batch.update(kursiDocRef, {'status': 'terisi'});
      } else {
        print("Peringatan: Kursi '$kursiString' tidak ditemukan untuk diperbarui.");
      }
    }

    await batch.commit();
  }
}