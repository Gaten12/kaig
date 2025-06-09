import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:kaig/models/transaksi_model.dart';
import 'package:kaig/services/transaksi_service.dart';
import 'detail_riwayat_screen.dart';
import 'e_tiket_screen.dart';

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
    // Halaman "Tiket Saya" tidak memerlukan AppBar sendiri karena
    // AppBar sudah di-handle oleh HomeScreen.
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80), // Padding bawah agar tidak tertutup nav bar
            itemCount: tiketList.length,
            itemBuilder: (context, index) {
              final tiket = tiketList[index];
              return _buildTiketCard(context, tiket);
            },
          );
        },
      ),
    );
  }

  Widget _buildTiketCard(BuildContext context, TransaksiModel tiket) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp. ', decimalDigits: 0);
    final ruteParts = tiket.rute.split('❯');
    final stasiunAsal = ruteParts.isNotEmpty ? ruteParts[0].trim() : '';
    final stasiunTujuan = ruteParts.length > 1 ? ruteParts[1].trim() : '';

    String infoPenumpang = "${tiket.penumpang.length} Dewasa";
    if (tiket.jumlahBayi > 0) {
      infoPenumpang += ", ${tiket.jumlahBayi} Bayi";
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Aksi default saat kartu di-tap adalah melihat E-Tiket
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ETiketScreen(tiket: tiket)),
          );
        },
        child: Column(
          children: [
            // Header Kartu
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.shade700,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Kode Pemesanan: ${tiket.kodeBooking}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text(tiket.status, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            // Body Kartu
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.train, color: Colors.black54, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("KERETA ANTAR KOTA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(tiket.namaKereta.toUpperCase(), style: const TextStyle(color: Colors.black54)),
                        const SizedBox(height: 4),
                        Text(infoPenumpang, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(stasiunAsal, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                              child: Icon(Icons.arrow_forward, size: 16),
                            ),
                            Text(stasiunTujuan, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Footer Kartu
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Total Harga", style: TextStyle(color: Colors.black54)),
                      Text(
                        currencyFormatter.format(tiket.totalBayar),
                        style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => DetailRiwayatScreen(transaksi: tiket)),
                          );
                        },
                        child: const Text("Detail"),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ETiketScreen(tiket: tiket)),
                          );
                        },
                        child: const Text("Lihat E-Tiket"),
                      )
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}