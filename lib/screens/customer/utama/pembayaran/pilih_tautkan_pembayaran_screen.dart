import 'package:flutter/material.dart';
import 'package:kaig/screens/customer/utama/pembayaran/pilih_jenis_pembayaran_screen.dart';
import 'package:kaig/models/metode_pembayaran_model.dart';

class PilihTautkanPembayaranScreen extends StatelessWidget {
  const PilihTautkanPembayaranScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Tautkan Pembayaran",
          style: TextStyle(color: Colors.white, fontSize: isSmallScreen ? 18 : 20), // Responsive title font size
        ),
        backgroundColor: const Color(0xFFC50000),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView( // Wrapped with SingleChildScrollView for scrollability
        padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0), // Responsive padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Pilih Tautkan Pembayaran",
              style: TextStyle(fontSize: isSmallScreen ? 18 : 22, fontWeight: FontWeight.bold), // Responsive font size
            ),
            SizedBox(height: isSmallScreen ? 16 : 24), // Responsive spacing
            _buildOption(
                context,
                "Tambah Kartu ATM / Mobile",
                    () => Navigator.push(context, MaterialPageRoute(
                    builder: (context) => const PilihJenisPembayaranScreen(tipe: TipeMetodePembayaran.kartuDebit))
                ),
                isSmallScreen
            ),
            SizedBox(height: isSmallScreen ? 12 : 16), // Responsive spacing
            _buildOption(
                context,
                "Tambah E-Wallet",
                    () => Navigator.push(context, MaterialPageRoute(
                    builder: (context) => const PilihJenisPembayaranScreen(tipe: TipeMetodePembayaran.ewallet))
                ),
                isSmallScreen
            ),
            SizedBox(height: isSmallScreen ? 16 : 24), // Add some bottom padding for smaller screens
          ],
        ),
      ),
    );
  }

  Widget _buildOption(BuildContext context, String title, VoidCallback onTap, bool isSmallScreen) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isSmallScreen ? 18 : 24), // Responsive padding
        decoration: BoxDecoration(
            color: Colors.blue.shade400,
            borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12) // Responsive border radius
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: isSmallScreen ? 15 : 16)), // Responsive font size
            Icon(Icons.arrow_forward_ios, color: Colors.white, size: isSmallScreen ? 18 : 20) // Responsive icon size
          ],
        ),
      ),
    );
  }
}