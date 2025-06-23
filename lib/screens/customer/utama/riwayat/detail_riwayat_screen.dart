import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kaig/models/transaksi_model.dart';

class DetailRiwayatScreen extends StatelessWidget {
  final TransaksiModel transaksi;
  const DetailRiwayatScreen({super.key, required this.transaksi});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Detail Riwayat",
          style: TextStyle(
              color: Colors.white,
              fontSize: isSmallScreen ? 18 : 20), // Responsive font size
        ),
        backgroundColor: Colors.red.shade800,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey[200],
      body: ListView(
        padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0), // Responsive padding
        children: [
          // Bagian Atas: Kode Pemesanan
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16), // Responsive padding
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12), // Responsive border radius
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Kode Pemesanan",
                    style: TextStyle(
                        color: Colors.grey,
                        fontSize: isSmallScreen ? 12 : null)), // Responsive font size
                SelectableText(
                  transaksi.kodeBooking,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallScreen ? 16 : 18), // Responsive font size
                ),
              ],
            ),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16), // Responsive spacing

          // Gabungkan Detail Kereta dan Penumpang dalam satu Card
          _buildDetailCard(context, isSmallScreen), // Pass isSmallScreen
        ],
      ),
    );
  }

  Widget _buildDetailCard(BuildContext context, bool isSmallScreen) {
    final ruteParts = transaksi.rute.split('❯');
    final stasiunAsal = ruteParts.isNotEmpty ? ruteParts[0].trim() : '';
    final stasiunTujuan = ruteParts.length > 1 ? ruteParts[1].trim() : '';

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(isSmallScreen ? 10 : 12)), // Responsive border radius
      elevation: 2,
      child: Column(
        children: [
          // Bagian Detail Kereta (Merah)
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16), // Responsive padding
            decoration: BoxDecoration(
              color: Colors.red.shade700,
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isSmallScreen ? 10 : 12), // Responsive border radius
                  topRight: Radius.circular(isSmallScreen ? 10 : 12)), // Responsive border radius
            ),
            child: Row(
              children: [
                // Kolom Kiri: Waktu
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(transaksi.waktuBerangkat,
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? 14 : null)), // Responsive font size
                    SizedBox(height: isSmallScreen ? 6 : 8), // Responsive spacing
                    Text(
                      transaksi.durasiPerjalanan,
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: isSmallScreen ? 10 : 12), // Responsive font size
                    ),
                    SizedBox(height: isSmallScreen ? 6 : 8), // Responsive spacing
                    Text(transaksi.waktuTiba,
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? 14 : null)), // Responsive font size
                  ],
                ),
                // Kolom Tengah: Garis dan Ikon
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12.0 : 16.0), // Responsive padding
                  child: Column(
                    children: [
                      Icon(Icons.radio_button_checked,
                          color: Colors.white,
                          size: isSmallScreen ? 16 : 18), // Responsive icon size
                      Container(
                        height: isSmallScreen ? 30 : 40, // Responsive height
                        width: 2,
                        color: Colors.white54,
                      ),
                      Icon(Icons.location_on,
                          color: Colors.white,
                          size: isSmallScreen ? 16 : 18), // Responsive icon size
                    ],
                  ),
                ),
                // Kolom Kanan: Rute dan Nama Kereta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Dari: $stasiunAsal",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: isSmallScreen ? 12 : null)), // Responsive font size
                      Padding(
                        padding:
                        EdgeInsets.symmetric(vertical: isSmallScreen ? 6.0 : 8.0), // Responsive padding
                        child: Row(
                          children: [
                            Icon(Icons.train,
                                color: Colors.white,
                                size: isSmallScreen ? 24 : 28), // Responsive icon size
                            SizedBox(width: isSmallScreen ? 6 : 8), // Responsive spacing
                            Expanded(
                                child: Text(transaksi.namaKereta.toUpperCase(),
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize:
                                        isSmallScreen ? 14 : null))) // Responsive font size
                          ],
                        ),
                      ),
                      Text("Tujuan: $stasiunTujuan",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: isSmallScreen ? 12 : null)), // Responsive font size
                    ],
                  ),
                )
              ],
            ),
          ),

          const Divider(height: 1), // Standard divider

          // Bagian Detail Penumpang (Putih)
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16), // Responsive padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Penumpang",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 16 : 18)), // Responsive font size
                SizedBox(height: isSmallScreen ? 16 : 24), // Responsive spacing
                ...transaksi.penumpang.asMap().entries.map((entry) {
                  final index = entry.key;
                  final p = entry.value;
                  final nama = p['nama'] ?? 'N/A';
                  final nik = p['nomorId'] ?? 'N/A';
                  final kursi = p['kursi'] ?? 'N/A';

                  return Padding(
                    padding: EdgeInsets.only(bottom: isSmallScreen ? 12.0 : 16.0), // Responsive padding
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Penumpang ${index + 1}",
                            style: TextStyle(
                                color: Colors.grey,
                                fontSize: isSmallScreen ? 12 : null)), // Responsive font size
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(nama,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: isSmallScreen ? 14 : null)), // Responsive font size
                            Text("Dewasa",
                                style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: isSmallScreen ? 10 : 12)), // Responsive font size
                          ],
                        ),
                        Text("NIK: $nik",
                            style: TextStyle(
                                color: Colors.grey,
                                fontSize: isSmallScreen ? 10 : 12)), // Responsive font size
                        Text("Gerbong / Nomor Kursi: $kursi",
                            style: TextStyle(
                                color: Colors.grey,
                                fontSize: isSmallScreen ? 10 : 12)), // Responsive font size
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

// Extension untuk menghitung durasi perjalanan (tetap sama)
extension TransaksiModelExtension on TransaksiModel {
  String get durasiPerjalanan {
    final format = DateFormat('HH:mm');
    try {
      final berangkat = format.parse(waktuBerangkat);
      final tiba = format.parse(waktuTiba);

      final dtBerangkat =
      DateTime(2025, 1, 1, berangkat.hour, berangkat.minute);
      final dtTiba = DateTime(2025, 1, (tiba.hour < berangkat.hour ? 2 : 1),
          tiba.hour, tiba.minute);

      final durasi = dtTiba.difference(dtBerangkat);
      final jam = durasi.inHours;
      final menit = durasi.inMinutes.remainder(60);
      return "${jam}j ${menit}m";
    } catch (e) {
      return '-';
    }
  }
}