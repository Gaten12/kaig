import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kaig/models/keranjang_model.dart';
import 'package:kaig/screens/customer/utama/keranjang_konfirmasi_pembayaran_screen.dart';
import 'package:kaig/screens/customer/utama/pilih_metode_pembayaran_screen.dart';

class KeranjangPembayaranScreen extends StatefulWidget {
  final List<KeranjangModel> itemsToCheckout;

  const KeranjangPembayaranScreen({super.key, required this.itemsToCheckout});

  @override
  State<KeranjangPembayaranScreen> createState() => _KeranjangPembayaranScreenState();
}

class _KeranjangPembayaranScreenState extends State<KeranjangPembayaranScreen> {
  String? _metodePembayaranTerpilih;

  @override
  Widget build(BuildContext context) {
    final int totalPembayaran = widget.itemsToCheckout.fold(0, (sum, item) => sum + item.totalBayar);
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text("Ringkasan Checkout")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text("Pesanan yang akan dibayar (${widget.itemsToCheckout.length} item)", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          // Widget untuk menampilkan ringkasan setiap item
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: widget.itemsToCheckout.map((item) => _buildItemRingkasan(item, currencyFormatter)).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildPilihMetodePembayaran(), // Panggil widget yang sudah diperbaiki
        ],
      ),
      bottomNavigationBar: _buildBottomBar(totalPembayaran, currencyFormatter),
    );
  }

  Widget _buildItemRingkasan(KeranjangModel item, NumberFormat formatter) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              "${item.jadwalDipesan.namaKereta} (${item.penumpang.length} org)",
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(formatter.format(item.totalBayar)),
        ],
      ),
    );
  }

  // --- IMPLEMENTASI YANG HILANG ADA DI SINI ---
  Widget _buildPilihMetodePembayaran() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade300)),
      leading: const Icon(Icons.payment),
      title: const Text("Metode Pembayaran"),
      subtitle: Text(_metodePembayaranTerpilih ?? "Pilih metode pembayaran"),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: () async {
        final result = await Navigator.push<String>(
          context,
          MaterialPageRoute(builder: (context) => const PilihMetodePembayaranScreen()),
        );
        if (result != null && mounted) {
          setState(() {
            _metodePembayaranTerpilih = result;
          });
        }
      },
    );
  }
  // --- AKHIR DARI PERBAIKAN ---

  Widget _buildBottomBar(int totalHarga, NumberFormat formatter) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), spreadRadius: 1, blurRadius: 5)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total Pembayaran", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text(formatter.format(totalHarga), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: _metodePembayaranTerpilih != null ? Theme.of(context).primaryColor : Colors.grey,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            ),
            onPressed: _metodePembayaranTerpilih != null ? () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => KeranjangKonfirmasiPembayaranScreen(
                itemsToCheckout: widget.itemsToCheckout,
                metodePembayaran: _metodePembayaranTerpilih!,
                totalBayar: totalHarga,
              )));
            } : null,
            child: const Text("LANJUTKAN KE PEMBAYARAN"),
          ),
        ],
      ),
    );
  }
}