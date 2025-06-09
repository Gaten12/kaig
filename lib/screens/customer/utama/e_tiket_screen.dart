import 'package:flutter/material.dart';
import 'package:kaig/models/transaksi_model.dart';
import 'package:kaig/screens/customer/utama/detail_riwayat_screen.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ETiketScreen extends StatelessWidget {
  final TransaksiModel tiket;

  const ETiketScreen({super.key, required this.tiket});

  @override
  Widget build(BuildContext context) {
    // Gunakan tema yang sama dengan Riwayat Transaksi agar konsisten
    final appBarColor = Colors.red.shade800;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detail Tiket"),
        backgroundColor: appBarColor,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey[200],
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Bagian Atas: Kode Pemesanan & QR Code
          _buildQrCodeCard(),
          const SizedBox(height: 16),
          // Gabungkan Detail Perjalanan dan Penumpang dalam satu Card
          _buildDetailCard(context),
        ],
      ),
    );
  }

  Widget _buildQrCodeCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        child: Column(
          children: [
            if (tiket.status == "LUNAS") // Hanya tampilkan QR jika status Lunas
              QrImageView(
                data: tiket.kodeBooking,
                version: QrVersions.auto,
                size: 200.0,
              ),
            if (tiket.status != "LUNAS") // Tampilkan info jika belum lunas
              Container(
                height: 200,
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.timer, size: 40, color: Colors.grey),
                    const SizedBox(height: 8),
                    Text("Status: ${tiket.status}", style: const TextStyle(fontSize: 18)),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            const Text("Kode Pemesanan", style: TextStyle(color: Colors.grey)),
            SelectableText(
              tiket.kodeBooking,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Tunjukkan QR Code ini kepada petugas saat proses boarding.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(BuildContext context) {
    final ruteParts = tiket.rute.split('❯');
    final stasiunAsal = ruteParts.isNotEmpty ? ruteParts[0].trim() : '';
    final stasiunTujuan = ruteParts.length > 1 ? ruteParts[1].trim() : '';

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Column(
        children: [
          // Bagian Detail Kereta
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Kolom Kiri: Waktu
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tiket.waktuBerangkat, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      tiket.durasiPerjalanan,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Text(tiket.waktuTiba, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                // Kolom Tengah: Garis
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      const Icon(Icons.radio_button_checked, color: Colors.blue, size: 18),
                      Container(
                        height: 40,
                        width: 2,
                        color: Colors.grey.shade300,
                      ),
                      const Icon(Icons.location_on, color: Colors.orange, size: 18),
                    ],
                  ),
                ),
                // Kolom Kanan: Rute dan Nama Kereta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Dari: $stasiunAsal"),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            const Icon(Icons.train, color: Colors.grey, size: 28),
                            const SizedBox(width: 8),
                            Expanded(child: Text(tiket.namaKereta.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)))
                          ],
                        ),
                      ),
                      Text("Tujuan: $stasiunTujuan"),
                    ],
                  ),
                )
              ],
            ),
          ),

          const Divider(height: 1),

          // Bagian Detail Penumpang
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Penumpang", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const Divider(height: 24),
                ...tiket.penumpang.asMap().entries.map((entry) {
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