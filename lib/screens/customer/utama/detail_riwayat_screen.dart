import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kaig/models/transaksi_model.dart';

class DetailRiwayatScreen extends StatelessWidget {
  final TransaksiModel transaksi;
  const DetailRiwayatScreen({super.key, required this.transaksi});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detail Riwayat"),
        backgroundColor: Colors.red.shade800,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey[200],
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Bagian Atas: Kode Pemesanan
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Kode Pemesanan", style: TextStyle(color: Colors.grey)),
                SelectableText(
                  transaksi.kodeBooking,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Gabungkan Detail Kereta dan Penumpang dalam satu Card
          _buildDetailCard(context),
        ],
      ),
    );
  }

  Widget _buildDetailCard(BuildContext context) {
    final ruteParts = transaksi.rute.split('❯');
    final stasiunAsal = ruteParts.isNotEmpty ? ruteParts[0].trim() : '';
    final stasiunTujuan = ruteParts.length > 1 ? ruteParts[1].trim() : '';

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Column(
        children: [
          // Bagian Detail Kereta (Merah)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade700,
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12)
              ),
            ),
            child: Row(
              children: [
                // Kolom Kiri: Waktu
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(transaksi.waktuBerangkat, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      transaksi.durasiPerjalanan,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Text(transaksi.waktuTiba, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
                // Kolom Tengah: Garis dan Ikon
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      const Icon(Icons.radio_button_checked, color: Colors.white, size: 18),
                      Container(
                        height: 40,
                        width: 2,
                        color: Colors.white54,
                      ),
                      const Icon(Icons.location_on, color: Colors.white, size: 18),
                    ],
                  ),
                ),
                // Kolom Kanan: Rute dan Nama Kereta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Dari: $stasiunAsal", style: const TextStyle(color: Colors.white)),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            const Icon(Icons.train, color: Colors.white, size: 28),
                            const SizedBox(width: 8),
                            Expanded(child: Text(transaksi.namaKereta.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))
                          ],
                        ),
                      ),
                      Text("Tujuan: $stasiunTujuan", style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                )
              ],
            ),
          ),

          // Bagian Detail Penumpang (Putih)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Penumpang", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const Divider(height: 24),
                ...transaksi.penumpang.asMap().entries.map((entry) {
                  final index = entry.key;
                  final p = entry.value;
                  final nama = p['nama'] ?? 'N/A';
                  final nik = p['nomorId'] ?? 'N/A';
                  final kursi = p['kursi'] ?? 'N/A';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Penumpang ${index + 1}", style: const TextStyle(color: Colors.grey)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const Text("Dewasa", style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                        Text("NIK: $nik", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        Text("Gerbong / Nomor Kursi: $kursi", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Extension untuk menghitung durasi perjalanan
extension TransaksiModelExtension on TransaksiModel {
  String get durasiPerjalanan {
    final format = DateFormat('HH:mm');
    try {
      final berangkat = format.parse(waktuBerangkat);
      final tiba = format.parse(waktuTiba);

      final dtBerangkat = DateTime(2025, 1, 1, berangkat.hour, berangkat.minute);
      final dtTiba = DateTime(2025, 1, (tiba.hour < berangkat.hour ? 2 : 1), tiba.hour, tiba.minute);

      final durasi = dtTiba.difference(dtBerangkat);
      final jam = durasi.inHours;
      final menit = durasi.inMinutes.remainder(60);
      return "${jam}j ${menit}m";
    } catch(e) {
      return '-';
    }
  }
}