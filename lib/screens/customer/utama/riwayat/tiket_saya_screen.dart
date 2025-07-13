import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:kaig/models/transaksi_model.dart';
import 'package:kaig/services/transaksi_service.dart';
import '../tiket/e_tiket_screen.dart';
import 'detail_riwayat_screen.dart';

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
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

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
            return Center(
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0), // Responsive padding
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long_outlined,
                        size: isSmallScreen ? 60 : 80,
                        color: Colors.grey), // Responsive icon size
                    SizedBox(height: isSmallScreen ? 12 : 16), // Responsive spacing
                    Text("Belum Ada Tiket",
                        style: TextStyle(
                            fontSize: isSmallScreen ? 18 : 20,
                            fontWeight: FontWeight.bold)), // Responsive font size
                    SizedBox(height: isSmallScreen ? 6 : 8), // Responsive spacing
                    Text(
                      "Semua tiket yang berhasil Anda pesan akan muncul di sini.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.grey,
                          fontSize: isSmallScreen ? 12 : 14), // Responsive font size
                    ),
                  ],
                ),
              ),
            );
          }

          final tiketList = snapshot.data!;
          return ListView.builder(
            padding: EdgeInsets.fromLTRB(
                isSmallScreen ? 12 : 16,
                isSmallScreen ? 12 : 16,
                isSmallScreen ? 12 : 16,
                isSmallScreen ? 70 : 80), // Responsive bottom padding
            itemCount: tiketList.length,
            itemBuilder: (context, index) {
              final tiket = tiketList[index];
              return _buildTiketCard(context, tiket, isSmallScreen); // Pass isSmallScreen
            },
          );
        },
      ),
    );
  }

  Widget _buildTiketCard(
      BuildContext context, TransaksiModel tiket, bool isSmallScreen) {
    final currencyFormatter =
    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp. ', decimalDigits: 0);
    final ruteParts = tiket.rute.split('❯');
    final stasiunAsal = ruteParts.isNotEmpty ? ruteParts[0].trim() : '';
    final stasiunTujuan = ruteParts.length > 1 ? ruteParts[1].trim() : '';

    String infoPenumpang = "${tiket.penumpang.length} Dewasa";
    if (tiket.jumlahBayi > 0) {
      infoPenumpang += ", ${tiket.jumlahBayi} Bayi";
    }

    return Card(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 10 : 12), // Responsive margin
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
              padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16, vertical: isSmallScreen ? 6 : 8), // Responsive padding
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
                  Text("Kode Pemesanan: ${tiket.kodeBooking}",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 12 : 14)), // Responsive font size
                  Text(tiket.status,
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 12 : 14)), // Responsive font size
                ],
              ),
            ),
            // Body Kartu
            Padding(
              padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0), // Responsive padding
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.train,
                      color: Colors.black54,
                      size: isSmallScreen ? 32 : 40), // Responsive icon size
                  SizedBox(width: isSmallScreen ? 12 : 16), // Responsive spacing
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("KERETA ANTAR KOTA",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize:
                                isSmallScreen ? 14 : 16)), // Responsive font size
                        Text(tiket.namaKereta.toUpperCase(),
                            style: TextStyle(
                                color: Colors.black54,
                                fontSize:
                                isSmallScreen ? 12 : null)), // Responsive font size
                        SizedBox(height: isSmallScreen ? 2 : 4), // Responsive spacing
                        Text(infoPenumpang,
                            style: TextStyle(
                                fontSize: isSmallScreen ? 10 : 12,
                                color: Colors.black54)), // Responsive font size
                        SizedBox(height: isSmallScreen ? 6 : 8), // Responsive spacing
                        Row(
                          children: [
                            Text(stasiunAsal,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize:
                                    isSmallScreen ? 14 : null)), // Responsive font size
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 6.0 : 8.0), // Responsive padding
                              child: Icon(Icons.arrow_forward,
                                  size: isSmallScreen ? 14 : 16), // Responsive icon size
                            ),
                            Text(stasiunTujuan,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize:
                                    isSmallScreen ? 14 : null)), // Responsive font size
                          ],
                        ),
                        SizedBox(height: 8),
                        Text('Tgl Transaksi: ${DateFormat('dd MMM yyyy, HH:mm').format(tiket.tanggalTransaksi.toDate())}', style: TextStyle(color: Colors.grey, fontSize: 10)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Footer Kartu
            Padding(
              padding: EdgeInsets.fromLTRB(
                  isSmallScreen ? 12 : 16,
                  0,
                  isSmallScreen ? 12 : 16,
                  isSmallScreen ? 12 : 16), // Responsive padding
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded( // Use Expanded to give priority to price column
                    flex: 2, // Adjust flex as needed
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Total Harga",
                            style: TextStyle(
                                color: Colors.black54,
                                fontSize:
                                isSmallScreen ? 12 : null)), // Responsive font size
                        Text(
                          currencyFormatter.format(tiket.totalBayar),
                          style: TextStyle(
                              color: const Color(0xFF0000CD),
                              fontWeight: FontWeight.bold,
                              fontSize:
                              isSmallScreen ? 16 : 18), // Responsive font size
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 8 : 12), // Responsive spacing
                  Expanded( // Use Expanded for the buttons row
                    flex: 3, // Adjust flex as needed
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end, // Align buttons to the end
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      DetailRiwayatScreen(transaksi: tiket)),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 12, vertical: isSmallScreen ? 4 : 8), // Responsive padding
                            textStyle: TextStyle(fontSize: isSmallScreen ? 12 : 14), // Responsive font size
                            foregroundColor: const Color(0xFF304FFE),
                          ),
                          child: const Text("Detail"),
                        ),
                        SizedBox(width: isSmallScreen ? 4 : 8), // Responsive spacing
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 12, vertical: isSmallScreen ? 4 : 8), // Responsive padding
                            textStyle: TextStyle(fontSize: isSmallScreen ? 12 : 14), // Responsive font size
                            minimumSize: Size(isSmallScreen ? 90 : 110, isSmallScreen ? 30 : 35), // Responsive minimum size
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ETiketScreen(tiket: tiket)),
                            );
                          },
                          child: const Text("Lihat E-Tiket"),
                        )
                      ],
                    ),
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

// Extension for TransaksiModel (already exists and remains unchanged)
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