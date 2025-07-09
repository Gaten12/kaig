import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kaig/models/JadwalModel.dart';
import 'package:kaig/models/jadwal_kelas_info_model.dart';
import 'package:kaig/models/metode_pembayaran_model.dart';
import 'package:kaig/models/transaksi_model.dart';
import 'package:kaig/services/transaksi_service.dart';
import '../home_screen.dart';
import '../tiket/DataPenumpangScreen.dart';

class KonfirmasiPembayaranScreen extends StatefulWidget {
  // --- ✨ PARAMETER DIPERBARUI UNTUK MENDUKUNG PP ✨ ---
  final JadwalModel jadwalPergi;
  final JadwalKelasInfoModel kelasDipilihPergi;
  final Map<int, String> kursiTerpilihPergi;

  final JadwalModel? jadwalPulang;
  final JadwalKelasInfoModel? kelasDipilihPulang;
  final Map<int, String>? kursiTerpilihPulang;

  final List<PenumpangInputData> dataPenumpangList;
  final int jumlahBayi;
  final MetodePembayaranModel metodePembayaran;
  final int totalBayar;

  const KonfirmasiPembayaranScreen({
    super.key,
    required this.jadwalPergi,
    required this.kelasDipilihPergi,
    required this.kursiTerpilihPergi,
    this.jadwalPulang,
    this.kelasDipilihPulang,
    this.kursiTerpilihPulang,
    required this.dataPenumpangList,
    required this.jumlahBayi,
    required this.metodePembayaran,
    required this.totalBayar,
  });

  @override
  State<KonfirmasiPembayaranScreen> createState() =>
      _KonfirmasiPembayaranScreenState();
}

class _KonfirmasiPembayaranScreenState
    extends State<KonfirmasiPembayaranScreen> {
  final TransaksiService _transaksiService = TransaksiService();
  bool _isLoading = false;

  // Helper-helper responsive (tidak berubah)
  double _responsiveFontSize(double screenWidth, double baseSize) {
    if (screenWidth < 360) return baseSize * 0.8;
    if (screenWidth < 600) return baseSize;
    return baseSize * 1.1;
  }

  double _responsiveIconSize(double screenWidth, double baseSize) {
    if (screenWidth < 600) return baseSize;
    return baseSize * 1.1;
  }

  double _responsiveHorizontalPadding(double screenWidth) {
    if (screenWidth > 1200) return (screenWidth - 1000) / 2;
    if (screenWidth > 600) return 24.0;
    return 16.0;
  }

  // --- ✨ LOGIKA UTAMA: MEMPROSES SATU ATAU DUA TRANSAKSI ✨ ---
  Future<void> _prosesKonfirmasi() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Error: Pengguna tidak ditemukan.")));
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Buat transaksi untuk tiket pergi
      final transaksiPergi = _buatTransaksiModel(
        userId: user.uid,
        jadwal: widget.jadwalPergi,
        kelas: widget.kelasDipilihPergi,
        kursi: widget.kursiTerpilihPergi,
      );

      // Siapkan transaksi untuk tiket pulang jika ada
      TransaksiModel? transaksiPulang;
      if (widget.jadwalPulang != null &&
          widget.kelasDipilihPulang != null &&
          widget.kursiTerpilihPulang != null) {
        transaksiPulang = _buatTransaksiModel(
          userId: user.uid,
          jadwal: widget.jadwalPulang!,
          kelas: widget.kelasDipilihPulang!,
          kursi: widget.kursiTerpilihPulang!,
        );
      }

      // Gunakan batch write untuk memastikan kedua transaksi berhasil atau keduanya gagal
      await _transaksiService.buatTransaksiBatch(
        transaksiPergi: transaksiPergi,
        transaksiPulang: transaksiPulang, // Bisa null
      );

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Gagal memproses transaksi: $e",
                style: TextStyle(
                    fontSize: _responsiveFontSize(
                        MediaQuery.of(context).size.width, 14)))));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Helper untuk membuat objek TransaksiModel
  TransaksiModel _buatTransaksiModel({
    required String userId,
    required JadwalModel jadwal,
    required JadwalKelasInfoModel kelas,
    required Map<int, String> kursi,
  }) {
    final List<Map<String, String>> penumpangData = [];
    kursi.forEach((index, kursi) {
      final dataInput = widget.dataPenumpangList[index];
      penumpangData.add({
        'nama': dataInput.namaLengkap,
        'tipeId': dataInput.tipeId,
        'nomorId': dataInput.nomorId,
        'kursi': kursi,
      });
    });

    return TransaksiModel(
      userId: userId,
      kodeBooking: _generateKodeBooking(),
      idJadwal: jadwal.id,
      namaKereta: jadwal.namaKereta,
      rute: "${jadwal.idStasiunAsal} ❯ ${jadwal.idStasiunTujuan}",
      kelas: kelas.displayKelasLengkap,
      tanggalBerangkat: jadwal.tanggalBerangkatUtama,
      waktuBerangkat: jadwal.jamBerangkatFormatted,
      waktuTiba: jadwal.jamTibaFormatted,
      penumpang: penumpangData,
      jumlahBayi: widget.jumlahBayi,
      metodePembayaran: widget.metodePembayaran.namaMetode,
      totalBayar: kelas.harga * widget.dataPenumpangList.length,
      tanggalTransaksi: Timestamp.now(),
    );
  }

  String _generateKodeBooking() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
        8, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

  void _showSuccessDialog() {
    final screenWidth = MediaQuery.of(context).size.width;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text("Pembayaran Berhasil!",
            style: TextStyle(
                fontSize: _responsiveFontSize(screenWidth, 18),
                fontWeight: FontWeight.bold)),
        content: Text(
            "Tiket Anda telah berhasil diterbitkan. Anda dapat melihatnya di halaman 'Tiket Saya'.",
            style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 14))),
        actions: [
          TextButton(
            child: Text("OK",
                style: TextStyle(
                    fontSize: _responsiveFontSize(screenWidth, 16),
                    fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                    builder: (context) => const HomeScreen(initialIndex: 2)),
                    (Route<dynamic> route) => false,
              );
            },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    bool isRoundTrip = widget.jadwalPulang != null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFC50000),
        foregroundColor: Colors.white,
        title: Text("Konfirmasi Pembayaran", style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 20))),
      ),
      body: _isLoading
          ? Center(
          child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Colors.orange),
              strokeWidth: _responsiveIconSize(screenWidth, 3)))
          : ListView(
        padding: EdgeInsets.all(_responsiveHorizontalPadding(screenWidth)),
        children: [
          _buildInfoKeretaCard(
            screenWidth,
            widget.jadwalPergi,
            widget.kelasDipilihPergi,
            "Kereta Pergi",
            const Color(0xFFC50000),
          ),
          if (isRoundTrip) ...[
            SizedBox(height: _responsiveFontSize(screenWidth, 16)),
            _buildInfoKeretaCard(
              screenWidth,
              widget.jadwalPulang!,
              widget.kelasDipilihPulang!,
              "Kereta Pulang",
              const Color(0xFF1976D2),
            ),
          ],
          SizedBox(height: _responsiveFontSize(screenWidth, 16)),
          _buildPaymentDetailsCard(screenWidth, currencyFormatter),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(_responsiveHorizontalPadding(screenWidth)),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _prosesKonfirmasi,
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF304FFE),
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, _responsiveFontSize(screenWidth, 50)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_responsiveFontSize(screenWidth, 25)))),
          child: Text("KONFIRMASI PEMBAYARAN",
              style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 16), fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildInfoKeretaCard(double screenWidth, JadwalModel jadwal, JadwalKelasInfoModel kelas, String title, Color color) {
    return Card(
      elevation: _responsiveFontSize(screenWidth, 2.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_responsiveFontSize(screenWidth, 12))),
      child: Padding(
        padding: EdgeInsets.all(_responsiveFontSize(screenWidth, 16.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: _responsiveFontSize(screenWidth, 18), color: color)),
            Divider(height: _responsiveFontSize(screenWidth, 20)),
            Text(
              "${DateFormat('EEE, dd MMM yy', 'id_ID').format(jadwal.tanggalBerangkatUtama.toDate())}  •  ${jadwal.jamBerangkatFormatted}",
              style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 14), color: Colors.grey),
            ),
            SizedBox(height: _responsiveFontSize(screenWidth, 4)),
            Text(
              "${jadwal.idStasiunAsal} ❯ ${jadwal.idStasiunTujuan}",
              style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 16), fontWeight: FontWeight.w600),
            ),
            SizedBox(height: _responsiveFontSize(screenWidth, 4)),
            Text(
              "${jadwal.namaKereta} • ${kelas.displayKelasLengkap}",
              style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 14)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetailsCard(double screenWidth, NumberFormat currencyFormatter) {
    String infoJudul;
    String infoNomor;

    if (widget.metodePembayaran.tipe == TipeMetodePembayaran.ewallet) {
      infoJudul = "Nomor E-Wallet (${widget.metodePembayaran.namaMetode})";
      infoNomor = widget.metodePembayaran.nomor;
    } else {
      infoJudul = "Nomor Kartu (${widget.metodePembayaran.namaMetode})";
      infoNomor = "**** **** **** ${widget.metodePembayaran.nomor.substring(widget.metodePembayaran.nomor.length - 4)}";
    }

    return Card(
      elevation: _responsiveFontSize(screenWidth, 2.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_responsiveFontSize(screenWidth, 12))),
      child: Padding(
        padding: EdgeInsets.all(_responsiveFontSize(screenWidth, 16.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Metode Pembayaran: ${widget.metodePembayaran.namaMetode}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: _responsiveFontSize(screenWidth, 16))),
            Divider(height: _responsiveFontSize(screenWidth, 20)),
            Text(infoJudul, style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 14))),
            SelectableText(
              infoNomor,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: _responsiveFontSize(screenWidth, 20)),
            ),
            SizedBox(height: _responsiveFontSize(screenWidth, 16)),
            Text("Total Pembayaran", style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 14))),
            Text(
              currencyFormatter.format(widget.totalBayar),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0000CD),
                  fontSize: _responsiveFontSize(screenWidth, 20)),
            ),
          ],
        ),
      ),
    );
  }
}
