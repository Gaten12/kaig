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
      final kodeBookings = await _transaksiService.buatTransaksiDariKeranjang(
        userId: user.uid,
        items: widget.itemsToCheckout,
        metodePembayaran: widget.metodePembayaran.namaMetode,
      );

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text("Pembayaran Berhasil!"),
            content: Text(
                "${kodeBookings.length} tiket telah berhasil diterbitkan. Anda dapat melihatnya di halaman 'Tiket Saya'."),
            actions: [
              TextButton(
                child: const Text("OK"),
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
            SnackBar(content: Text("Gagal memproses transaksi: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text("Konfirmasi Pembayaran")
        ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      "Metode Pembayaran: ${widget.metodePembayaran.namaMetode}",
                      style:
                      const TextStyle(fontWeight: FontWeight.bold)),
                  const Divider(height: 20),
                  // Gunakan variabel dinamis yang sudah disiapkan
                  Text(infoJudul),
                  SelectableText(
                    infoNomor,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text("Total Pembayaran"),
                  Text(
                    currencyFormatter.format(widget.totalBayar),
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(
                        fontWeight: FontWeight.bold,
                        color:Color(0xFF0000CD)
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _prosesKonfirmasi,
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0000CD), 
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50)),
          child: const Text("KONFIRMASI PEMBAYARAN"),
        ),
      ),
    );
  }
}