import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kaig/models/metode_pembayaran_model.dart';
import 'package:kaig/screens/customer/utama/pembayaran/pilih_tautkan_pembayaran_screen.dart';
import 'package:kaig/services/metode_pembayaran_service.dart';

class PilihMetodePembayaranScreen extends StatefulWidget {
  const PilihMetodePembayaranScreen({super.key});

  @override
  State<PilihMetodePembayaranScreen> createState() => _PilihMetodePembayaranScreenState();
}

class _PilihMetodePembayaranScreenState extends State<PilihMetodePembayaranScreen> {
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

  // Helper method for responsive font sizes
  double _responsiveFontSize(double screenWidth, double baseSize) {
    if (screenWidth < 360) {
      return baseSize * 0.8; // Smaller for very small phones
    } else if (screenWidth < 600) {
      return baseSize; // Base size for phones
    } else if (screenWidth < 900) {
      return baseSize * 1.1; // Slightly larger for tablets
    } else {
      return baseSize * 1.2; // Even larger for desktops
    }
  }

  // Helper method for responsive icon sizes
  double _responsiveIconSize(double screenWidth, double baseSize) {
    if (screenWidth < 600) {
      return baseSize;
    } else if (screenWidth < 900) {
      return baseSize * 1.1;
    } else {
      return baseSize * 1.2;
    }
  }

  // Helper method for responsive horizontal padding
  double _responsiveHorizontalPadding(double screenWidth) {
    if (screenWidth > 1200) {
      return (screenWidth - 1000) / 2; // Center content for very large screens
    } else if (screenWidth > 600) {
      return 24.0; // Medium padding for tablets
    } else {
      return 16.0; // Standard padding for phones
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFC50000),
        foregroundColor: Colors.white,
        title: Text(
          "Pilih Metode Pembayaran",
          style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 20)),
        ),
      ),
      body: StreamBuilder<List<MetodePembayaranModel>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(strokeWidth: _responsiveIconSize(screenWidth, 3)));
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 16))));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState(screenWidth);
          }

          final metodeList = snapshot.data!;
          return ListView(
            padding: EdgeInsets.all(_responsiveHorizontalPadding(screenWidth)),
            children: [
              Text(
                "Pembayaran Tersimpan",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: _responsiveFontSize(screenWidth, 18),
                ),
              ),
              SizedBox(height: _responsiveFontSize(screenWidth, 12)),
              ...metodeList.map((metode) => _buildMetodeItem(metode, screenWidth)),
              Divider(height: _responsiveFontSize(screenWidth, 24)),
              _buildTambahMetodeButton(screenWidth),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetodeItem(MetodePembayaranModel metode, double screenWidth) {
    String nomorTersamar = "";
    String subtitle = "";
    IconData iconData = Icons.wallet;

    if (metode.tipe == TipeMetodePembayaran.kartuDebit) {
      iconData = Icons.credit_card;
      nomorTersamar = "**** **** **** ${metode.nomor.substring(metode.nomor.length - 4)}";
      subtitle = "Kartu Debit";
    } else {
      iconData = Icons.account_balance_wallet_outlined;
      nomorTersamar = metode.nomor;
      subtitle = "E-Wallet";
    }

    return Card(
      // 1. Mengubah warna latar belakang Card menjadi merah tua
      color: Colors.blue.shade400,

      // Opsional: Menambahkan bayangan agar lebih menonjol
      elevation: _responsiveFontSize(screenWidth, 3), // Responsive elevation
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_responsiveFontSize(screenWidth, 8))), // Responsive border radius

      child: ListTile(
        // 2. Mengubah warna ikon menjadi putih
        iconColor: Colors.white,

        // 3. Mengubah warna teks (title dan subtitle) menjadi putih
        textColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: _responsiveFontSize(screenWidth, 16), vertical: _responsiveFontSize(screenWidth, 8)), // Responsive padding


        // Pastikan tidak ada warna yang di-set manual di dalam Icon lagi
        leading: Icon(iconData, size: _responsiveIconSize(screenWidth, 24)), // Responsive icon size

        title: Text(metode.namaMetode, style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 16), fontWeight: FontWeight.bold)), // Responsive font size
        subtitle: Text("$subtitle • $nomorTersamar", style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 14))), // Responsive font size
        onTap: () {
          // Kembalikan objek MetodePembayaranModel yang dipilih
          Navigator.pop(context, metode);
        },
      ),
    );
  }

  Widget _buildTambahMetodeButton(double screenWidth) {
    return Padding(
      // Memberi sedikit jarak dari tepi layar
      padding: EdgeInsets.symmetric(horizontal: _responsiveHorizontalPadding(screenWidth), vertical: _responsiveFontSize(screenWidth, 8.0)), // Responsive padding
      child: SizedBox(
        width: double.infinity, // Membuat tombol membentang selebar mungkin
        child: ElevatedButton.icon(
          icon: Icon(Icons.add, color: Colors.white, size: _responsiveIconSize(screenWidth, 24)), // Responsive icon size
          label: Text(
            "Tambah metode pembayaran",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: _responsiveFontSize(screenWidth, 16)), // Responsive font size
          ),
          onPressed: () async {
            // Arahkan ke alur penambahan metode pembayaran
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PilihTautkanPembayaranScreen(),
              ),
            );
            // State akan otomatis diperbarui oleh StreamBuilder setelah kembali
          },
          style: ElevatedButton.styleFrom(
            // Warna latar tombol biru solid seperti di gambar
            backgroundColor: Color(0xFF304FFE),
            // Bentuk tombol menjadi kapsul (sudut sangat bulat)
            shape: StadiumBorder(),
            // Padding di dalam tombol untuk membuatnya lebih tinggi
            padding: EdgeInsets.symmetric(vertical: _responsiveFontSize(screenWidth, 16)), // Responsive padding
            minimumSize: Size(double.infinity, _responsiveFontSize(screenWidth, 50)), // Ensure minimum size is responsive
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(double screenWidth) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(_responsiveHorizontalPadding(screenWidth)), // Responsive padding
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payment, size: _responsiveIconSize(screenWidth, 80), color: Colors.grey), // Responsive icon size
            SizedBox(height: _responsiveFontSize(screenWidth, 16)), // Responsive spacing
            Text(
                "Belum Ada Metode Pembayaran",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 20), fontWeight: FontWeight.bold)), // Responsive font size
            SizedBox(height: _responsiveFontSize(screenWidth, 8)), // Responsive spacing
            Text(
              "Anda belum memiliki metode pembayaran yang tersimpan.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: _responsiveFontSize(screenWidth, 14)), // Responsive font size
            ),
            SizedBox(height: _responsiveFontSize(screenWidth, 24)), // Responsive spacing
            ElevatedButton.icon(
              icon: Icon(Icons.add, size: _responsiveIconSize(screenWidth, 20)), // Responsive icon size
              label: Text("Tambah Sekarang", style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 16))), // Responsive font size
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const PilihTautkanPembayaranScreen()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF304FFE), // Ensure consistent button color
                shape: StadiumBorder(),
                padding: EdgeInsets.symmetric(vertical: _responsiveFontSize(screenWidth, 12), horizontal: _responsiveFontSize(screenWidth, 24)), // Responsive padding
                minimumSize: Size(_responsiveFontSize(screenWidth, 180), _responsiveFontSize(screenWidth, 45)), // Responsive minimum size
              ),
            ),
          ],
        ),
      ),
    );
  }
}
