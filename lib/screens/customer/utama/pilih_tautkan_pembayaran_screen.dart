import 'package:flutter/material.dart';
import 'package:kaig/screens/customer/utama/pilih_jenis_pembayaran_screen.dart';
import 'package:kaig/models/metode_pembayaran_model.dart';

class PilihTautkanPembayaranScreen extends StatelessWidget {
  const PilihTautkanPembayaranScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tautkan Pembayaran"),
        backgroundColor: Colors.red.shade800,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Pilih Tautkan Pembayaran", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildOption(
                context,
                "Tambah Kartu ATM / Mobile",
                    () => Navigator.push(context, MaterialPageRoute(
                    builder: (context) => const PilihJenisPembayaranScreen(tipe: TipeMetodePembayaran.kartuDebit))
                )
            ),
            const SizedBox(height: 12),
            _buildOption(
                context,
                "Tambah E-Wallet",
                    () => Navigator.push(context, MaterialPageRoute(
                    builder: (context) => const PilihJenisPembayaranScreen(tipe: TipeMetodePembayaran.ewallet))
                )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(BuildContext context, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: Colors.orange.shade600,
            borderRadius: BorderRadius.circular(12)
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const Icon(Icons.arrow_forward_ios, color: Colors.white)
          ],
        ),
      ),
    );
  }
}