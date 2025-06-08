import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:kaig/models/transaksi_model.dart';
import 'package:kaig/services/transaksi_service.dart';

class TiketSayaScreen extends StatefulWidget {
  const TiketSayaScreen({super.key});

  @override
  State<TiketSayaScreen> createState() => _TiketSayaScreenState();
}

class _TiketSayaScreenState extends State<TiketSayaScreen> {
  final TransaksiService _transaksiService = TransaksiService();
  Stream<List<TransaksiModel>>? _tiketStream;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _tiketStream = _transaksiService.getTiketSaya(user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<TransaksiModel>>(
        stream: _tiketStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text("Belum Ada Tiket", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text("Semua tiket yang berhasil Anda pesan akan muncul di sini.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            );
          }

          final tiketList = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tiketList.length,
            itemBuilder: (context, index) {
              final tiket = tiketList[index];
              return _buildTiketCard(tiket);
            },
          );
        },
      ),
    );
  }

  Widget _buildTiketCard(TransaksiModel tiket) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(tiket.namaKereta, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(tiket.status, style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold)),
              ],
            ),
            Text(tiket.kelas, style: const TextStyle(color: Colors.grey)),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tiket.waktuBerangkat, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text(tiket.rute.split('❯')[0].trim(), style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                const Icon(Icons.arrow_forward, color: Colors.grey),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(tiket.waktuTiba, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text(tiket.rute.split('❯')[1].trim(), style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(tiket.tanggalBerangkat.toDate()), style: const TextStyle(fontWeight: FontWeight.w500)),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("KODE BOOKING", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    SelectableText(tiket.kodeBooking, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    // TODO: Arahkan ke halaman detail tiket dengan QR Code
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fitur detail tiket belum diimplementasikan.")));
                  },
                  child: const Text("Lihat Tiket"),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}