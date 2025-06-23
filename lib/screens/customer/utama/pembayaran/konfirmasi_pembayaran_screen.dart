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
  final JadwalModel jadwalDipesan;
  final JadwalKelasInfoModel kelasDipilih;
  final List<PenumpangInputData> dataPenumpangList;
  final int jumlahBayi;
  final Map<int, String> kursiTerpilih;
  final MetodePembayaranModel metodePembayaran;
  final int totalBayar;

  const KonfirmasiPembayaranScreen({
    super.key,
    required this.jadwalDipesan,
    required this.kelasDipilih,
    required this.dataPenumpangList,
    required this.jumlahBayi,
    required this.kursiTerpilih,
    required this.metodePembayaran,
    required this.totalBayar,
  });

  @override
  State<KonfirmasiPembayaranScreen> createState() => _KonfirmasiPembayaranScreenState();
}

class _KonfirmasiPembayaranScreenState extends State<KonfirmasiPembayaranScreen> {
  final TransaksiService _transaksiService = TransaksiService();
  bool _isLoading = false;

  // Helper method for responsive font sizes
  double _responsiveFontSize(double screenWidth, double baseSize) {
    if (screenWidth < 360) {
      return baseSize * 0.8; // Smaller for very small phones
    } else if (screenWidth < 600) {
      return baseSize; // Base size for phones
    } else if (screenWidth < 900) {
      return baseSize * 1.1; // Slightly larger for tablets
    } else {
      return baseSize * 1.2; // Even larger for desktops
    }
  }

  // Helper method for responsive icon sizes (not directly used in this screen but good to have)
  double _responsiveIconSize(double screenWidth, double baseSize) {
    if (screenWidth < 600) {
      return baseSize;
    } else if (screenWidth < 900) {
      return baseSize * 1.1;
    } else {
      return baseSize * 1.2;
    }
  }

  // Helper method for responsive horizontal padding
  double _responsiveHorizontalPadding(double screenWidth) {
    if (screenWidth > 1200) {
      return (screenWidth - 1000) / 2; // Center content for very large screens
    } else if (screenWidth > 600) {
      return 24.0; // Medium padding for tablets
    } else {
      return 16.0; // Standard padding for phones
    }
  }

  Future<void> _prosesKonfirmasi() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error: Pengguna tidak ditemukan.")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final kodeBooking = _generateKodeBooking();

      final List<Map<String, String>> penumpangData = [];
      widget.kursiTerpilih.forEach((index, kursi) {
        final dataInput = widget.dataPenumpangList[index];
        penumpangData.add({
          'nama': dataInput.namaLengkap,
          'tipeId': dataInput.tipeId,
          'nomorId': dataInput.nomorId,
          'kursi': kursi,
        });
      });

      final transaksi = TransaksiModel(
        userId: user.uid,
        kodeBooking: kodeBooking,
        idJadwal: widget.jadwalDipesan.id,
        namaKereta: widget.jadwalDipesan.namaKereta,
        rute: "${widget.jadwalDipesan.idStasiunAsal} ❯ ${widget.jadwalDipesan.idStasiunTujuan}",
        kelas: widget.kelasDipilih.displayKelasLengkap,
        tanggalBerangkat: widget.jadwalDipesan.tanggalBerangkatUtama,
        waktuBerangkat: widget.jadwalDipesan.jamBerangkatFormatted,
        waktuTiba: widget.jadwalDipesan.jamTibaFormatted,
        penumpang: penumpangData,
        jumlahBayi: widget.jumlahBayi,
        metodePembayaran: widget.metodePembayaran.namaMetode,
        totalBayar: widget.totalBayar,
        tanggalTransaksi: Timestamp.now(),
      );

      // --- PERBAIKAN UTAMA DI SINI ---
      // Tambahkan parameter 'kelasDipilih' yang hilang
      await _transaksiService.buatTransaksi(
        transaksi: transaksi,
        kelasDipilih: widget.kelasDipilih, // <-- Baris ini ditambahkan
        jadwalId: widget.jadwalDipesan.id,
        kursiTerpilih: widget.kursiTerpilih.values.toList(),
      );
      // --- AKHIR PERBAIKAN ---

      if (mounted) {
        final screenWidth = MediaQuery.of(context).size.width; // Get screen width for dialog responsiveness
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: Text("Pembayaran Berhasil!", style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 18), fontWeight: FontWeight.bold)),
            content: Text(
                "Tiket Anda dengan kode booking $kodeBooking telah berhasil diterbitkan. Anda dapat melihatnya di halaman 'Tiket Saya'.",
                style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 14))),
            actions: [
              TextButton(
                child: Text("OK", style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 16), fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const HomeScreen(initialIndex: 2)),
                        (Route<dynamic> route) => false,
                  );
                },
              )
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal memproses transaksi: $e", style: TextStyle(fontSize: _responsiveFontSize(MediaQuery.of(context).size.width, 14)))));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _generateKodeBooking() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
        8, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    String infoJudul;
    String infoNomor;

    if (widget.metodePembayaran.tipe == TipeMetodePembayaran.ewallet) {
      infoJudul = "Nomor E-Wallet (${widget.metodePembayaran.namaMetode})";
      infoNomor = widget.metodePembayaran.nomor;
    } else {
      infoJudul = "Nomor Kartu (${widget.metodePembayaran.namaMetode})";
      infoNomor = "**** **** **** ${widget.metodePembayaran.nomor.substring(widget.metodePembayaran.nomor.length - 4)}";
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFC50000),
        foregroundColor: Colors.white,
        title: Text(
          "Konfirmasi Pembayaran",
          style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 20)),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.orange), strokeWidth: _responsiveIconSize(screenWidth, 3)))
          : ListView(
        padding: EdgeInsets.all(_responsiveHorizontalPadding(screenWidth)),
        children: [
          _buildInfoKeretaCard(screenWidth),
          SizedBox(height: _responsiveFontSize(screenWidth, 16)),
          Card(
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
                        fontSize: _responsiveFontSize(screenWidth, 20)
                    ),
                  ),
                ],
              ),
            ),
          ),
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

  Widget _buildInfoKeretaCard(double screenWidth) {
    return Card(
      elevation: _responsiveFontSize(screenWidth, 2.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_responsiveFontSize(screenWidth, 12))),
      child: Padding(
        padding: EdgeInsets.all(_responsiveFontSize(screenWidth, 16.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Kereta Pergi", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: _responsiveFontSize(screenWidth, 18))),
            Divider(height: _responsiveFontSize(screenWidth, 20)),
            Text(
              "${DateFormat('EEE, dd MMM yy', 'id_ID').format(widget.jadwalDipesan.tanggalBerangkatUtama.toDate())}  •  ${widget.jadwalDipesan.jamBerangkatFormatted}",
              style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 14), color: Colors.grey),
            ),
            SizedBox(height: _responsiveFontSize(screenWidth, 4)),
            Text(
              "${widget.jadwalDipesan.idStasiunAsal} ❯ ${widget.jadwalDipesan.idStasiunTujuan}",
              style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 16), fontWeight: FontWeight.w600),
            ),
            SizedBox(height: _responsiveFontSize(screenWidth, 4)),
            Text(
              "${widget.jadwalDipesan.namaKereta} • ${widget.kelasDipilih.displayKelasLengkap}",
              style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 14)),
            ),
          ],
        ),
      ),
    );
  }
}