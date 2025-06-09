import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kaig/models/keranjang_model.dart';
import 'package:kaig/models/transaksi_model.dart';

class TransaksiService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Fungsi ini untuk mengambil data tiket di halaman "Tiket Saya"
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

  // Fungsi ini untuk membuat transaksi dari alur pemesanan tunggal
  Future<void> buatTransaksi({
    required TransaksiModel transaksi,
    required String jadwalId,
    required List<String> kursiTerpilih
  }) async {
    final WriteBatch batch = _db.batch();
    final transaksiDocRef = _db.collection('transaksi').doc();
    batch.set(transaksiDocRef, transaksi.toFirestore());

    final kursiQuerySnapshot = await _db
        .collection('jadwal')
        .doc(jadwalId)
        .collection('kursi')
        .get();

    final Map<String, String> mapKursiKeDocId = {
      for (var doc in kursiQuerySnapshot.docs)
        "Gerbong ${doc.data()['nomor_gerbong']} - Kursi ${doc.data()['nomor_kursi']}": doc.id
    };

    for (final kursiString in kursiTerpilih) {
      final docId = mapKursiKeDocId[kursiString];
      if (docId != null) {
        final kursiDocRef = _db.collection('jadwal').doc(jadwalId).collection('kursi').doc(docId);
        batch.update(kursiDocRef, {'status': 'terisi'});
      }
    }
    await batch.commit();
  }

  // Fungsi ini untuk checkout dari keranjang
  Future<List<String>> buatTransaksiDariKeranjang({
    required String userId,
    required List<KeranjangModel> items,
    required String metodePembayaran,
  }) async {
    final WriteBatch batch = _db.batch();
    final List<String> kodeBookings = [];
    final List<String> itemKeranjangIds = [];

    final Map<String, QuerySnapshot<Map<String, dynamic>>> kursiSnapshots = {};
    for (final item in items) {
      if (item.jadwalDipesan.id.isEmpty) {
        throw Exception("Data keranjang tidak valid (ID Jadwal kosong). Harap hapus item ini dari keranjang.");
      }
      if (!kursiSnapshots.containsKey(item.jadwalDipesan.id)) {
        kursiSnapshots[item.jadwalDipesan.id] = await _db.collection('jadwal').doc(item.jadwalDipesan.id).collection('kursi').get();
      }
    }

    for (final item in items) {
      final kodeBooking = _generateKodeBooking();
      kodeBookings.add(kodeBooking);
      itemKeranjangIds.add(item.id!);

      final transaksiDocRef = _db.collection('transaksi').doc();
      final transaksi = TransaksiModel(
        userId: userId,
        kodeBooking: kodeBooking,
        idJadwal: item.jadwalDipesan.id,
        namaKereta: item.jadwalDipesan.namaKereta,
        rute: "${item.jadwalDipesan.idStasiunAsal} ❯ ${item.jadwalDipesan.idStasiunTujuan}",
        kelas: item.kelasDipilih.displayKelasLengkap,
        tanggalBerangkat: item.jadwalDipesan.tanggalBerangkatUtama,
        waktuBerangkat: item.jadwalDipesan.jamBerangkatFormatted,
        waktuTiba: item.jadwalDipesan.jamTibaFormatted,
        penumpang: item.penumpang,
        jumlahBayi: item.jumlahBayi, // <-- PERBAIKAN DI SINI
        metodePembayaran: metodePembayaran,
        totalBayar: item.totalBayar,
        tanggalTransaksi: Timestamp.now(),
      );
      batch.set(transaksiDocRef, transaksi.toFirestore());

      final kursiSnapshot = kursiSnapshots[item.jadwalDipesan.id]!;
      final Map<String, String> mapKursiKeDocId = {
        for (var doc in kursiSnapshot.docs)
          "Gerbong ${doc.data()['nomor_gerbong']} - Kursi ${doc.data()['nomor_kursi']}": doc.id
      };

      for (final p in item.penumpang) {
        final kursiString = p['kursi'];
        if (kursiString == null) continue;
        final docId = mapKursiKeDocId[kursiString];
        if (docId != null) {
          final kursiDocRef = _db.collection('jadwal').doc(item.jadwalDipesan.id).collection('kursi').doc(docId);
          batch.update(kursiDocRef, {'status': 'terisi'});
        }
      }
    }

    final keranjangCollection = _db.collection('users').doc(userId).collection('keranjang');
    for (final itemId in itemKeranjangIds) {
      batch.delete(keranjangCollection.doc(itemId));
    }

    await batch.commit();

    return kodeBookings;
  }

  String _generateKodeBooking() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
        8, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }
}