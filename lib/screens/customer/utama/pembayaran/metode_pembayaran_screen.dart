import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kaig/models/metode_pembayaran_model.dart';
import 'package:kaig/screens/customer/utama/pembayaran/pilih_tautkan_pembayaran_screen.dart';
import 'package:kaig/services/metode_pembayaran_service.dart';

class MetodePembayaranScreen extends StatefulWidget {
  const MetodePembayaranScreen({super.key});

  @override
  State<MetodePembayaranScreen> createState() => _MetodePembayaranScreenState();
}

class _MetodePembayaranScreenState extends State<MetodePembayaranScreen> {
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
        title: const Text("Metode Pembayaran"),
        backgroundColor: const Color(0xFFC50000),
        foregroundColor: Colors.white,
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
              ...metodeList.map((metode) => _buildMetodeCard(metode)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("Tambah metode pembayaran"),
                onPressed: _tambahMetode,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: const Color(0xFF0000CD),
                  foregroundColor: Colors.white,
                ),
              )
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wallet, size: 100, color: Color(0xFF0000CD)),
            const Text("Metode Pembayaran Belum Tersedia",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              "Silahkan tambahkan kartu debit atau e-wallet anda untuk mempermudah saat proses pembayaran tiket anda",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _tambahMetode,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0000CD), foregroundColor: Colors.white),
              child: const Text("Tambah metode pembayaran"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetodeCard(MetodePembayaranModel metode) {
    String nomorTersamar = "";
    if (metode.nomor.length > 4) {
      nomorTersamar = "**** **** **** ${metode.nomor.substring(metode.nomor.length - 4)}";
    } else {
      nomorTersamar = metode.nomor;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 157, 4, 4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(metode.namaMetode, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.white),
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      await _service.hapusMetodePembayaran(user.uid, metode.id!);
                    }
                  },
                )
              ],
            ),
            const SizedBox(height: 16),
            Text(nomorTersamar, style: const TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 2)),
            if (metode.masaBerlaku != null) ...[
              const SizedBox(height: 8),
              Text("Berlaku s/d: ${metode.masaBerlaku}", style: const TextStyle(color: Colors.white70)),
            ]
          ],
        ),
      ),
    );
  }

  void _tambahMetode() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const PilihTautkanPembayaranScreen()));
  }
}