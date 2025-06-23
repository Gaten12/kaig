import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kaig/models/keranjang_model.dart';
import 'package:kaig/models/metode_pembayaran_model.dart';
import 'package:kaig/services/transaksi_service.dart';
import 'package:kaig/screens/customer/utama/home_screen.dart';

class KeranjangKonfirmasiPembayaranScreen extends StatefulWidget {
  final List<KeranjangModel> itemsToCheckout;
  final MetodePembayaranModel metodePembayaran;
  final int totalBayar;

  const KeranjangKonfirmasiPembayaranScreen({
    super.key,
    required this.itemsToCheckout,
    required this.metodePembayaran,
    required this.totalBayar,
  });

  @override
  State<KeranjangKonfirmasiPembayaranScreen> createState() =>
      _KeranjangKonfirmasiPembayaranScreenState();
}

class _KeranjangKonfirmasiPembayaranScreenState
    extends State<KeranjangKonfirmasiPembayaranScreen> {
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

  // Helper method for responsive icon sizes
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error: Pengguna tidak ditemukan.")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final kodeBookings = await _transaksiService.buatTransaksiDariKeranjang(
        userId: user.uid,
        items: widget.itemsToCheckout,
        metodePembayaran: widget.metodePembayaran.namaMetode,
      );

      if (mounted) {
        final screenWidth = MediaQuery.of(context).size.width; // Get screen width for dialog responsiveness
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: Text("Pembayaran Berhasil!", style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 18), fontWeight: FontWeight.bold)),
            content: Text(
                "${kodeBookings.length} tiket telah berhasil diterbitkan. Anda dapat melihatnya di halaman 'Tiket Saya'.",
                style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 14))),
            actions: [
              TextButton(
                child: Text("OK", style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 16), fontWeight: FontWeight.bold)),
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Gagal memproses transaksi: $e", style: TextStyle(fontSize: _responsiveFontSize(MediaQuery.of(context).size.width, 14)))));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final currencyFormatter =
    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    // Logika untuk menampilkan detail pembayaran yang benar
    String infoJudul;
    String infoNomor;

    if (widget.metodePembayaran.tipe == TipeMetodePembayaran.ewallet) {
      infoJudul = "Nomor E-Wallet (${widget.metodePembayaran.namaMetode})";
      infoNomor = widget.metodePembayaran.nomor;
    } else {
      // Asumsi selain e-wallet adalah kartu debit/bank
      infoJudul = "Nomor Kartu (${widget.metodePembayaran.namaMetode})";
      // Samarkan nomor kartu untuk keamanan
      infoNomor =
      "**** **** **** ${widget.metodePembayaran.nomor.substring(widget.metodePembayaran.nomor.length - 4)}";
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
          ? Center(child: CircularProgressIndicator(strokeWidth: _responsiveIconSize(screenWidth, 3)))
          : ListView(
        padding: EdgeInsets.all(_responsiveHorizontalPadding(screenWidth)),
        children: [
          Card(
            elevation: _responsiveFontSize(screenWidth, 2.0),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_responsiveFontSize(screenWidth, 12))),
            child: Padding(
              padding: EdgeInsets.all(_responsiveFontSize(screenWidth, 16.0)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Metode Pembayaran: ${widget.metodePembayaran.namaMetode}",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: _responsiveFontSize(screenWidth, 16)),
                  ),
                  Divider(height: _responsiveFontSize(screenWidth, 20)),
                  // Gunakan variabel dinamis yang sudah disiapkan
                  Text(infoJudul, style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 14))),
                  SelectableText(
                    infoNomor,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: _responsiveFontSize(screenWidth, 20)),
                  ),
                  SizedBox(height: _responsiveFontSize(screenWidth, 16)),
                  Text("Total Pembayaran", style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 14))),
                  Text(
                    currencyFormatter.format(widget.totalBayar),
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: _responsiveFontSize(screenWidth, 20),
                        color: const Color(0xFF0000CD)),
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
              backgroundColor: Color(0xFF304FFE),
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, _responsiveFontSize(screenWidth, 50)), // Responsive height
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_responsiveFontSize(screenWidth, 25)))), // Responsive border radius
          child: Text("KONFIRMASI PEMBAYARAN",
              style: TextStyle(
                  fontSize: _responsiveFontSize(screenWidth, 16),
                  fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}