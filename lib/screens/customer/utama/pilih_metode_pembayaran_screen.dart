import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kaig/models/metode_pembayaran_model.dart';
import 'package:kaig/screens/customer/utama/pilih_tautkan_pembayaran_screen.dart';
import 'package:kaig/services/metode_pembayaran_service.dart';

class PilihMetodePembayaranScreen extends StatefulWidget {
  const PilihMetodePembayaranScreen({super.key});

  @override
  State<PilihMetodePembayaranScreen> createState() => _PilihMetodePembayaranScreenState();
}

class _PilihMetodePembayaranScreenState extends State<PilihMetodePembayaranScreen> {
  final MetodePembayaranService _service = MetodePembayaranService();
  Stream<List<MetodePembayaranModel>>? _stream;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _stream = _service.getMetodePembayaranStream(user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pilih Metode Pembayaran"),
      ),
      body: StreamBuilder<List<MetodePembayaranModel>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final metodeList = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text("Pembayaran Tersimpan", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...metodeList.map((metode) => _buildMetodeItem(metode)),
              const Divider(height: 24),
              _buildTambahMetodeButton(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetodeItem(MetodePembayaranModel metode) {
    String nomorTersamar = "";
    String subtitle = "";
    IconData iconData = Icons.wallet;

    if (metode.tipe == TipeMetodePembayaran.kartuDebit) {
      iconData = Icons.credit_card;
      nomorTersamar = "**** **** **** ${metode.nomor.substring(metode.nomor.length - 4)}";
      subtitle = "Kartu Debit";
    } else {
      iconData = Icons.account_balance_wallet_outlined;
      nomorTersamar = metode.nomor;
      subtitle = "E-Wallet";
    }

    return Card(
      child: ListTile(
        leading: Icon(iconData, color: Theme.of(context).primaryColor),
        title: Text(metode.namaMetode),
        subtitle: Text("$subtitle • $nomorTersamar"),
        onTap: () {
          // Kembalikan objek MetodePembayaranModel yang dipilih
          Navigator.pop(context, metode);
        },
      ),
    );
  }

  Widget _buildTambahMetodeButton() {
    return ListTile(
      leading: const Icon(Icons.add_circle_outline, color: Colors.blue),
      title: const Text("Tambah metode pembayaran", style: TextStyle(color: Colors.blue)),
      onTap: () async {
        // Arahkan ke alur penambahan metode pembayaran
        await Navigator.push(context, MaterialPageRoute(builder: (context) => const PilihTautkanPembayaranScreen()));
        // Ketika kembali dari alur penambahan, state akan otomatis diperbarui oleh StreamBuilder
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.payment, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text("Belum Ada Metode Pembayaran",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              "Anda belum memiliki metode pembayaran yang tersimpan.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text("Tambah Sekarang"),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const PilihTautkanPembayaranScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }
}
