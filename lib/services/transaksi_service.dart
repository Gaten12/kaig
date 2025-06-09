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

  // --- FUNGSI UTAMA YANG DIPERBARUI TOTAL ---
  Future<void> buatTransaksi({
    required TransaksiModel transaksi,
    required JadwalKelasInfoModel kelasDipilih,
    required String jadwalId,
    required List<String> kursiTerpilih,
  }) async {
    final jadwalRef = _db.collection('jadwal').doc(jadwalId);
    final transaksiRef = _db.collection('transaksi').doc(transaksi.kodeBooking);

    // 1. Baca semua data kursi untuk jadwal ini di luar transaction (lebih efisien)
    final kursiQuerySnapshot = await jadwalRef.collection('kursi').get();

    // 2. Buat Peta untuk Status dan Referensi Dokumen Kursi
    final Map<String, String> mapStatusKursi = {};
    final Map<String, DocumentReference> mapRefKursi = {};

    for (var doc in kursiQuerySnapshot.docs) {
      // Pastikan casting tipe data dilakukan dengan aman
      final data = doc.data() as Map<String, dynamic>;
      final key = "Gerbong ${data['nomor_gerbong']} - Kursi ${data['nomor_kursi']}";
      mapStatusKursi[key] = data['status'];
      mapRefKursi[key] = doc.reference;
    }

    // 3. Periksa Ketersediaan Kursi SEBELUM memulai transaction
    for (final kursiString in kursiTerpilih) {
      if (mapStatusKursi[kursiString] == null) {
        throw Exception("Kursi $kursiString tidak ada dalam data sistem.");
      }
      if (mapStatusKursi[kursiString] == 'terisi') {
        throw Exception("Kursi $kursiString sudah dipesan oleh orang lain. Silakan pilih kursi lain.");
      }
    }

    // 4. Jalankan Transaction HANYA untuk operasi tulis
    return _db.runTransaction((transaction) async {
      final jadwalSnapshot = await transaction.get(jadwalRef);
      if (!jadwalSnapshot.exists) {
        throw Exception("Jadwal tidak ditemukan!");
      }
      final jadwalData = JadwalModel.fromFirestore(jadwalSnapshot);

      // Periksa ulang kuota kelas di dalam transaction
      final kelasUntukDiupdate = jadwalData.daftarKelasHarga.firstWhere(
            (k) => k.namaKelas == kelasDipilih.namaKelas && k.subKelas == kelasDipilih.subKelas,
        orElse: () => throw Exception("Sub-kelas ${kelasDipilih.subKelas} tidak ditemukan."),
      );

      if (kelasUntukDiupdate.kuota < transaksi.penumpang.length) {
        throw Exception("Sisa kuota untuk kelas ${transaksi.kelas} tidak mencukupi.");
      }

      // Siapkan update kuota
      final newListKelasHarga = jadwalData.daftarKelasHarga.map((k) {
        if (k.namaKelas == kelasDipilih.namaKelas && k.subKelas == kelasDipilih.subKelas) {
          return k.copyWith(kuota: k.kuota - transaksi.penumpang.length);
        }
        return k;
      }).toList();

      // Tambahkan semua operasi tulis ke transaction
      // A. Update Kuota Jadwal
      transaction.update(jadwalRef, {'daftar_kelas_harga': newListKelasHarga.map((k) => k.toMap()).toList()});

      // B. Update Status Kursi
      for (final kursiString in kursiTerpilih) {
        final kursiRef = mapRefKursi[kursiString];
        if (kursiRef != null) {
          transaction.update(kursiRef, {'status': 'terisi'});
        }
      }

      // C. Buat Dokumen Transaksi Baru
      transaction.set(transaksiRef, transaksi.toFirestore());
    });
  }

  // Fungsi checkout keranjang sekarang lebih sederhana karena hanya memanggil fungsi di atas
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

      // Panggil fungsi utama yang sudah aman dan efisien
      await buatTransaksi(
        transaksi: transaksi,
        kelasDipilih: item.kelasDipilih,
        jadwalId: item.jadwalDipesan.id,
        kursiTerpilih: kursiTerpilih,
      );

      kodeBookings.add(kodeBooking);
      // Hapus item dari keranjang setelah transaksi berhasil
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