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
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Metode Pembayaran",
          style: TextStyle(color: Colors.white, fontSize: isSmallScreen ? 18 : 20),
        ),
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
            return _buildEmptyState(isSmallScreen);
          }

          final metodeList = snapshot.data!;
          return ListView(
            padding: EdgeInsets.fromLTRB(isSmallScreen ? 12 : 16, isSmallScreen ? 12 : 16, isSmallScreen ? 12 : 16, isSmallScreen ? 80 : 100), // Responsive padding, increased bottom for FAB
            children: [
              Text(
                "Pembayaran Tersimpan",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: isSmallScreen ? 16 : 18), // Responsive font size
              ),
              SizedBox(height: isSmallScreen ? 8 : 12), // Responsive spacing
              ...metodeList.map((metode) => _buildMetodeCard(metode, isSmallScreen)),
              SizedBox(height: isSmallScreen ? 12 : 16), // Responsive spacing
              ElevatedButton.icon(
                icon: Icon(Icons.add, size: isSmallScreen ? 20 : 24), // Responsive icon size
                label: Text(
                  "Tambah metode pembayaran",
                  style: TextStyle(fontSize: isSmallScreen ? 15 : 16), // Responsive font size
                ),
                onPressed: _tambahMetode,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, isSmallScreen ? 45 : 50), // Responsive button height
                  backgroundColor: Color(0xFF304FFE),
                  foregroundColor: Colors.white,
                ),
              )
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isSmallScreen) {
    return SingleChildScrollView( // Wrapped with SingleChildScrollView
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0), // Responsive padding
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: isSmallScreen ? 20 : 40), // Responsive spacing
            Icon(Icons.wallet, size: isSmallScreen ? 80 : 100, color: const Color(0xFF0000CD)), // Responsive icon size
            SizedBox(height: isSmallScreen ? 16 : 24), // Responsive spacing
            Text(
              "Metode Pembayaran Belum Tersedia",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: isSmallScreen ? 18 : 20, // Responsive font size
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(height: isSmallScreen ? 8 : 12), // Responsive spacing
            Text(
              "Silahkan tambahkan kartu debit atau e-wallet anda untuk mempermudah saat proses pembayaran tiket anda",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: isSmallScreen ? 12 : 14), // Responsive font size
            ),
            SizedBox(height: isSmallScreen ? 24 : 32), // Responsive spacing
            ElevatedButton.icon(
              icon: Icon(Icons.add, size: isSmallScreen ? 20 : 24), // Responsive icon size
              label: Text(
                "Tambah Sekarang",
                style: TextStyle(fontSize: isSmallScreen ? 15 : 16), // Responsive font size
              ),
              onPressed: _tambahMetode,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF304FFE),
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, isSmallScreen ? 45 : 50), // Responsive button height
              ),
            ),
            SizedBox(height: isSmallScreen ? 20 : 30), // Increased bottom padding to avoid overflow
          ],
        ),
      ),
    );
  }

  Widget _buildMetodeCard(MetodePembayaranModel metode, bool isSmallScreen) {
    String nomorTersamar = "";
    if (metode.nomor.length > 4) {
      nomorTersamar = "**** **** **** ${metode.nomor.substring(metode.nomor.length - 4)}";
    } else {
      nomorTersamar = metode.nomor;
    }

    return Card(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 12), // Responsive margin
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12)), // Responsive border radius
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16), // Responsive padding
        decoration: BoxDecoration(
          color: Colors.blue.shade400,
          borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  metode.namaMetode,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: isSmallScreen ? 16 : 18), // Responsive font size
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.white, size: isSmallScreen ? 20 : 24), // Responsive icon size
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      await _service.hapusMetodePembayaran(user.uid, metode.id!);
                    }
                  },
                )
              ],
            ),
            SizedBox(height: isSmallScreen ? 12 : 16), // Responsive spacing
            Text(
              nomorTersamar,
              style: TextStyle(color: Colors.white, fontSize: isSmallScreen ? 16 : 18, letterSpacing: 2), // Responsive font size
            ),
            if (metode.masaBerlaku != null) ...[
              SizedBox(height: isSmallScreen ? 6 : 8), // Responsive spacing
              Text(
                "Berlaku s/d: ${metode.masaBerlaku}",
                style: TextStyle(color: Colors.white70, fontSize: isSmallScreen ? 12 : 14), // Responsive font size
              ),
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