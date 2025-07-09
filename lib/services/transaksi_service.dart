import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kaig/models/JadwalModel.dart';
import 'package:kaig/models/keranjang_model.dart';
import 'package:kaig/models/transaksi_model.dart';
import '../models/jadwal_kelas_info_model.dart';

class TransaksiService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<TransaksiModel>> getTiketSaya(String userId) {
    return _db
        .collection('transaksi')
        .where('userId', isEqualTo: userId)
        .orderBy('tanggalTransaksi', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => TransaksiModel.fromFirestore(doc)).toList());
  }

  // --- ✨ FUNGSI YANG DIPERBAIKI ✨ ---
  Future<void> buatTransaksiBatch({
    required TransaksiModel transaksiPergi,
    TransaksiModel? transaksiPulang,
  }) async {
    final batch = _db.batch();

    // --- PROSES TIKET PERGI ---
    final docPergiRef = _db.collection('transaksi').doc(transaksiPergi.kodeBooking);
    batch.set(docPergiRef, transaksiPergi.toFirestore());
    final jadwalPergiRef = _db.collection('jadwal').doc(transaksiPergi.idJadwal);

    // Update status kursi untuk tiket pergi
    for (var penumpang in transaksiPergi.penumpang) {
      final kursiIdString = penumpang['kursi']; // Format: "Gerbong 4 - Kursi 9B"
      if (kursiIdString != null && kursiIdString.isNotEmpty) {
        final parts = kursiIdString.split(' - Kursi ');
        final gerbongStr = parts[0].replaceAll('Gerbong ', '');
        final nomorGerbong = int.tryParse(gerbongStr);
        final nomorKursi = parts[1];

        if (nomorGerbong != null) {
          // Lakukan query untuk mencari dokumen kursi yang benar
          final kursiQuery = await jadwalPergiRef
              .collection('kursi')
              .where('nomor_gerbong', isEqualTo: nomorGerbong)
              .where('nomor_kursi', isEqualTo: nomorKursi)
              .limit(1)
              .get();

          if (kursiQuery.docs.isNotEmpty) {
            // Jika dokumen ditemukan, gunakan referensinya untuk update
            final kursiDocRef = kursiQuery.docs.first.reference;
            batch.update(kursiDocRef, {'status': 'terisi'});
          } else {
            // Jika tidak ditemukan, lempar error agar transaksi gagal
            throw Exception("Kursi tidak ditemukan: $kursiIdString");
          }
        }
      }
    }

    // --- PROSES TIKET PULANG (JIKA ADA) ---
    if (transaksiPulang != null) {
      final docPulangRef = _db.collection('transaksi').doc(transaksiPulang.kodeBooking);
      batch.set(docPulangRef, transaksiPulang.toFirestore());

      final jadwalPulangRef = _db.collection('jadwal').doc(transaksiPulang.idJadwal);

      for (var penumpang in transaksiPulang.penumpang) {
        final kursiIdString = penumpang['kursi'];
        if (kursiIdString != null && kursiIdString.isNotEmpty) {
          final parts = kursiIdString.split(' - Kursi ');
          final gerbongStr = parts[0].replaceAll('Gerbong ', '');
          final nomorGerbong = int.tryParse(gerbongStr);
          final nomorKursi = parts[1];

          if (nomorGerbong != null) {
            final kursiQuery = await jadwalPulangRef
                .collection('kursi')
                .where('nomor_gerbong', isEqualTo: nomorGerbong)
                .where('nomor_kursi', isEqualTo: nomorKursi)
                .limit(1)
                .get();

            if (kursiQuery.docs.isNotEmpty) {
              final kursiDocRef = kursiQuery.docs.first.reference;
              batch.update(kursiDocRef, {'status': 'terisi'});
            } else {
              throw Exception("Kursi pulang tidak ditemukan: $kursiIdString");
            }
          }
        }
      }
    }

    await batch.commit();
  }


  // --- Fungsi lama dan lainnya tidak diubah ---

  Future<void> buatTransaksi({
    required TransaksiModel transaksi,
    required JadwalKelasInfoModel kelasDipilih,
    required String jadwalId,
    required List<String> kursiTerpilih,
  }) async {
    final jadwalRef = _db.collection('jadwal').doc(jadwalId);
    final transaksiRef = _db.collection('transaksi').doc(transaksi.kodeBooking);

    final kursiQuerySnapshot = await jadwalRef.collection('kursi').get();
    final Map<String, String> mapStatusKursi = {};
    final Map<String, DocumentReference> mapRefKursi = {};

    for (var doc in kursiQuerySnapshot.docs) {
      final data = doc.data();
      final key = "Gerbong ${data['nomor_gerbong']} - Kursi ${data['nomor_kursi']}";
      mapStatusKursi[key] = data['status'];
      mapRefKursi[key] = doc.reference;
    }

    for (final kursiString in kursiTerpilih) {
      if (mapStatusKursi[kursiString] == null) {
        throw Exception("Kursi $kursiString tidak ada dalam data sistem.");
      }
      if (mapStatusKursi[kursiString] == 'terisi') {
        throw Exception("Kursi $kursiString sudah dipesan oleh orang lain.");
      }
    }

    return _db.runTransaction((transaction) async {
      final jadwalSnapshot = await transaction.get(jadwalRef);
      if (!jadwalSnapshot.exists) {
        throw Exception("Jadwal tidak ditemukan!");
      }
      final jadwalData = JadwalModel.fromFirestore(jadwalSnapshot);

      final kelasUntukDiupdate = jadwalData.daftarKelasHarga.firstWhere(
            (k) => k.namaKelas == kelasDipilih.namaKelas && k.subKelas == kelasDipilih.subKelas,
        orElse: () => throw Exception("Sub-kelas ${kelasDipilih.subKelas} tidak ditemukan."),
      );

      if (kelasUntukDiupdate.kuota < transaksi.penumpang.length) {
        throw Exception("Sisa kuota untuk kelas ${transaksi.kelas} tidak mencukupi.");
      }

      final newListKelasHarga = jadwalData.daftarKelasHarga.map((k) {
        if (k.namaKelas == kelasDipilih.namaKelas && k.subKelas == kelasDipilih.subKelas) {
          return k.copyWith(kuota: k.kuota - transaksi.penumpang.length);
        }
        return k;
      }).toList();

      transaction.update(jadwalRef, {'daftar_kelas_harga': newListKelasHarga.map((k) => k.toMap()).toList()});

      for (final kursiString in kursiTerpilih) {
        final kursiRef = mapRefKursi[kursiString];
        if (kursiRef != null) {
          transaction.update(kursiRef, {'status': 'terisi'});
        }
      }

      transaction.set(transaksiRef, transaksi.toFirestore());
    });
  }

  Future<List<String>> buatTransaksiDariKeranjang({
    required String userId,
    required List<KeranjangModel> items,
    required String metodePembayaran,
  }) async {
    List<String> kodeBookings = [];
    for (final item in items) {
      final kodeBooking = _generateKodeBooking();
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
        jumlahBayi: item.jumlahBayi,
        metodePembayaran: metodePembayaran,
        totalBayar: item.totalBayar,
        tanggalTransaksi: Timestamp.now(),
      );

      final kursiTerpilih = item.penumpang.map((p) => p['kursi']!).toList();

      await buatTransaksi(
        transaksi: transaksi,
        kelasDipilih: item.kelasDipilih,
        jadwalId: item.jadwalDipesan.id,
        kursiTerpilih: kursiTerpilih,
      );

      kodeBookings.add(kodeBooking);
      await _db.collection('users').doc(userId).collection('keranjang').doc(item.id).delete();
    }
    return kodeBookings;
  }

  String _generateKodeBooking() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
        8, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }
}