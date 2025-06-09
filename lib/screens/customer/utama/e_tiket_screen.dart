import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kaig/models/transaksi_model.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ETiketScreen extends StatelessWidget {
  final TransaksiModel tiket;

  const ETiketScreen({super.key, required this.tiket});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("E-Tiket"),
        backgroundColor: Colors.red.shade800,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey[200], // Latar belakang abu-abu
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildQrCodeCard(),
          const SizedBox(height: 16),
          _buildDetailPerjalananCard(context),
          const SizedBox(height: 16),
          _buildDetailPenumpangCard(context),
        ],
      ),
    );
  }

  Widget _buildQrCodeCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Widget untuk menampilkan QR Code
            QrImageView(
              data: tiket.kodeBooking, // Data yang di-encode adalah kode booking
              version: QrVersions.auto,
              size: 220.0,
              gapless: false,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Colors.black,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Kode Booking",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            SelectableText(
              tiket.kodeBooking,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 3, // Memberi jarak antar huruf
              ),
            ),
            const SizedBox(height: 12),
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

  Widget _buildDetailPerjalananCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Detail Perjalanan", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const Divider(height: 24),
            _buildInfoRow(Icons.train_outlined, "Kereta", "${tiket.namaKereta} • ${tiket.kelas}"),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.calendar_today_outlined, "Tanggal", DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(tiket.tanggalBerangkat.toDate())),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildWaktuInfo("Berangkat", tiket.waktuBerangkat, tiket.rute.split('❯')[0].trim()),
                const Icon(Icons.arrow_forward, color: Colors.grey),
                _buildWaktuInfo("Tiba", tiket.waktuTiba, tiket.rute.split('❯')[1].trim(),crossAxisAlignment: CrossAxisAlignment.end),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDetailPenumpangCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Detail Penumpang", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const Divider(height: 24),
            // Loop untuk setiap penumpang
            ...tiket.penumpang.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                children: [
                  const Icon(Icons.person_outline, color: Colors.grey, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p['nama'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text("${p['tipeId']} - ${p['nomorId']}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  Text(p['kursi'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey, size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWaktuInfo(String label, String waktu, String stasiun, {CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start}) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 2),
        Text(waktu, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Text(stasiun, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}