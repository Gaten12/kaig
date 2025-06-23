import 'package:flutter/material.dart';
import 'package:kaig/models/metode_pembayaran_model.dart';
import 'package:kaig/screens/customer/utama/pembayaran/tambah_ewallet_screen.dart';
import 'package:kaig/screens/customer/utama/pembayaran/tambah_kartu_screen.dart';

class PilihJenisPembayaranScreen extends StatelessWidget {
  final TipeMetodePembayaran tipe;
  const PilihJenisPembayaranScreen({super.key, required this.tipe});

  @override
  Widget build(BuildContext context) {
    final bool isKartu = tipe == TipeMetodePembayaran.kartuDebit;
    final String title = isKartu ? "Pilih Kartu ATM / Mobile" : "Pilih E-Wallet";
    final List<String> options = isKartu
        ? ["BCA", "BTN", "BRI", "CIMB", "BNI"]
        : ["GOPAY", "OVO", "DANA", "SHOPEE-PAY", "LINK AJA"];

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: TextStyle(color: Colors.white, fontSize: isSmallScreen ? 18 : 20),
        ),
        backgroundColor: const Color(0xFFC50000),
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 24), // Responsive padding
        itemCount: options.length,
        itemBuilder: (context, index) {
          final namaMetode = options[index];
          return Card(
            margin: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16), // Responsive margin
            elevation: 2, // Added subtle elevation
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12)),
            child: InkWell( // Use InkWell for tap effect
              onTap: () {
                final Widget nextPage = isKartu
                    ? TambahKartuScreen(namaBank: namaMetode)
                    : TambahEwalletScreen(namaEwallet: namaMetode);
                Navigator.push(context, MaterialPageRoute(builder: (context) => nextPage));
              },
              borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 16, horizontal: isSmallScreen ? 16 : 20), // Responsive padding
                decoration: BoxDecoration(
                  color: Colors.blue.shade400, // Changed to Electric Blue
                  borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                ),
                child: Row(
                  children: [
                    // Icon and Text
                    Icon(
                      isKartu ? Icons.credit_card : Icons.account_balance_wallet_outlined,
                      color: Colors.white, // Icon color is white
                      size: isSmallScreen ? 24 : 28, // Responsive icon size
                    ),
                    SizedBox(width: isSmallScreen ? 12 : 16),
                    Expanded(
                      child: Text(
                        namaMetode,
                        style: TextStyle(
                            color: Colors.white, // Text color is white
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? 16 : 18 // Responsive font size
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white, // Icon color is white
                      size: isSmallScreen ? 18 : 20, // Responsive icon size
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
