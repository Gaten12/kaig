import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kaig/models/transaksi_model.dart';

import '../models/keranjang_model.dart';

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

  Future<List<String>> buatTransaksiDariKeranjang({
    required String userId,
    required List<KeranjangModel> items,
    required String metodePembayaran,
  }) async {
    final WriteBatch batch = _db.batch();
    final List<String> kodeBookings = [];
    final List<String> itemKeranjangIds = [];

    final kursiRefsToUpdate = <DocumentReference, Map<String, dynamic>>{};

    for (final item in items) {
      final kodeBooking = _generateKodeBooking();
      kodeBookings.add(kodeBooking);
      itemKeranjangIds.add(item.id!);

      // 1. Siapkan dokumen transaksi baru
      final transaksiDocRef = _db.collection('transaksi').doc();
      final transaksi = TransaksiModel(
        userId: userId,
        kodeBooking: kodeBooking,
        namaKereta: item.jadwalDipesan.namaKereta,
        idJadwal: item.jadwalDipesan.id,
        rute: "${item.jadwalDipesan.idStasiunAsal} ❯ ${item.jadwalDipesan.idStasiunTujuan}",
        kelas: item.kelasDipilih.displayKelasLengkap,
        tanggalBerangkat: item.jadwalDipesan.tanggalBerangkatUtama,
        waktuBerangkat: item.jadwalDipesan.jamBerangkatFormatted,
        waktuTiba: item.jadwalDipesan.jamTibaFormatted,
        penumpang: item.penumpang,
        metodePembayaran: metodePembayaran,
        totalBayar: item.totalBayar,
        tanggalTransaksi: Timestamp.now(),
      );
      batch.set(transaksiDocRef, transaksi.toFirestore());

      // 2. Siapkan update untuk status kursi
      final kursiQuerySnapshot = await _db.collection('jadwal').doc(item.jadwalDipesan.id).collection('kursi').get();
      final Map<String, String> mapKursiKeDocId = {
        for (var doc in kursiQuerySnapshot.docs)
          "Gerbong ${doc.data()['nomor_gerbong']} - Kursi ${doc.data()['nomor_kursi']}": doc.id
      };

      for (final p in item.penumpang) {
        final kursiString = p['kursi']!;
        final docId = mapKursiKeDocId[kursiString];
        if (docId != null) {
          final kursiDocRef = _db.collection('jadwal').doc(item.jadwalDipesan.id).collection('kursi').doc(docId);
          kursiRefsToUpdate[kursiDocRef] = {'status': 'terisi'};
        }
      }
    }

    // Terapkan update kursi ke batch
    kursiRefsToUpdate.forEach((ref, data) {
      batch.update(ref, data);
    });

    // 3. Siapkan penghapusan item dari keranjang
    final keranjangCollection = _db.collection('users').doc(userId).collection('keranjang');
    for (final itemId in itemKeranjangIds) {
      batch.delete(keranjangCollection.doc(itemId));
    }

    // 4. Commit semua operasi
    await batch.commit();

    return kodeBookings;
  }

  String _generateKodeBooking() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
        8, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
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