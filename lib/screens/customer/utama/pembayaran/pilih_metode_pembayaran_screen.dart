import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kaig/models/metode_pembayaran_model.dart';
import 'package:kaig/screens/customer/utama/pembayaran/pilih_tautkan_pembayaran_screen.dart';
import 'package:kaig/services/metode_pembayaran_service.dart';

class PilihMetodePembayaranScreen extends StatefulWidget {
  const PilihMetodePembayaranScreen({super.key});

  @override
  State<PilihMetodePembayaranScreen> createState() =>
      _PilihMetodePembayaranScreenState();
}

class _PilihMetodePembayaranScreenState
    extends State<PilihMetodePembayaranScreen> {
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

  // Helper-helper responsif
  double _responsiveFontSize(double screenWidth, double baseSize) {
    if (screenWidth < 360) {
      return baseSize * 0.85;
    } else if (screenWidth < 600) {
      return baseSize;
    } else {
      return baseSize * 1.1;
    }
  }

  double _responsiveIconSize(double screenWidth, double baseSize) {
    if (screenWidth < 600) {
      return baseSize;
    } else {
      return baseSize * 1.1;
    }
  }

  double _responsiveHorizontalPadding(double screenWidth) {
    if (screenWidth > 1200) {
      return (screenWidth - 1000) / 2;
    } else if (screenWidth > 600) {
      return 24.0;
    } else {
      return 16.0;
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
          style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 18)),
        ),
      ),
      body: StreamBuilder<List<MetodePembayaranModel>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(
                    strokeWidth: _responsiveIconSize(screenWidth, 3)));
          }
          if (snapshot.hasError) {
            return Center(
                child: Text("Error: ${snapshot.error}",
                    style:
                    TextStyle(fontSize: _responsiveFontSize(screenWidth, 16))));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            // --- PERBAIKAN UTAMA ADA DI SINI ---
            // Bungkus _buildEmptyState dengan SingleChildScrollView
            // agar kontennya bisa di-scroll jika tidak muat.
            return SingleChildScrollView(
              child: _buildEmptyState(screenWidth),
            );
          }

          final metodeList = snapshot.data!;
          return ListView(
            padding: EdgeInsets.fromLTRB(
              _responsiveHorizontalPadding(screenWidth),
              20, // Beri jarak dari atas
              _responsiveHorizontalPadding(screenWidth),
              100, // Beri jarak di bawah agar tidak tertutup tombol
            ),
            children: [
              Text(
                "Pembayaran Tersimpan",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: _responsiveFontSize(screenWidth, 18),
                ),
              ),
              SizedBox(height: _responsiveFontSize(screenWidth, 12)),
              ...metodeList
                  .map((metode) => _buildMetodeItem(metode, screenWidth)),
              Divider(height: _responsiveFontSize(screenWidth, 32)),
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
      // Menyamarkan nomor kartu
      nomorTersamar =
      "**** **** **** ${metode.nomor.substring(metode.nomor.length - 4)}";
      subtitle = "Kartu Debit";
    } else {
      iconData = Icons.account_balance_wallet_outlined;
      nomorTersamar = metode.nomor;
      subtitle = "E-Wallet";
    }

    return Card(
      color: Colors.blue.shade400,
      elevation: _responsiveFontSize(screenWidth, 4),
      shadowColor: Colors.blue.withOpacity(0.3),
      margin: EdgeInsets.only(bottom: _responsiveFontSize(screenWidth, 12)),
      shape: RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(_responsiveFontSize(screenWidth, 12))),
      child: ListTile(
        iconColor: Colors.white,
        textColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(
            horizontal: _responsiveFontSize(screenWidth, 16),
            vertical: _responsiveFontSize(screenWidth, 8)),
        leading: Icon(iconData, size: _responsiveIconSize(screenWidth, 28)),
        title: Text(metode.namaMetode,
            style: TextStyle(
                fontSize: _responsiveFontSize(screenWidth, 16),
                fontWeight: FontWeight.bold)),
        subtitle: Text("$subtitle • $nomorTersamar",
            style: TextStyle(
                fontSize: _responsiveFontSize(screenWidth, 14),
                color: Colors.white70)),
        onTap: () {
          // Kembalikan objek MetodePembayaranModel yang dipilih ke layar sebelumnya
          Navigator.pop(context, metode);
        },
      ),
    );
  }

  Widget _buildTambahMetodeButton(double screenWidth) {
    return ElevatedButton.icon(
      icon: Icon(Icons.add,
          color: Colors.white, size: _responsiveIconSize(screenWidth, 22)),
      label: Text(
        "Tambah metode pembayaran baru",
        style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: _responsiveFontSize(screenWidth, 15)),
      ),
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PilihTautkanPembayaranScreen(),
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF304FFE),
        padding:
        EdgeInsets.symmetric(vertical: _responsiveFontSize(screenWidth, 16)),
        shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(_responsiveFontSize(screenWidth, 12))),
        minimumSize:
        Size(double.infinity, _responsiveFontSize(screenWidth, 50)),
      ),
    );
  }

  Widget _buildEmptyState(double screenWidth) {
    // Pastikan Padding cukup agar konten tidak mepet ke tepi layar
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: _responsiveHorizontalPadding(screenWidth) + 16,
          vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: _responsiveFontSize(screenWidth, 40)),
          Icon(Icons.payment,
              size: _responsiveIconSize(screenWidth, 80), color: Colors.grey),
          SizedBox(height: _responsiveFontSize(screenWidth, 24)),
          Text("Belum Ada Metode Pembayaran",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: _responsiveFontSize(screenWidth, 20),
                  fontWeight: FontWeight.bold)),
          SizedBox(height: _responsiveFontSize(screenWidth, 8)),
          Text(
            "Anda belum memiliki metode pembayaran yang tersimpan.",
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.grey,
                fontSize: _responsiveFontSize(screenWidth, 14)),
          ),
          SizedBox(height: _responsiveFontSize(screenWidth, 32)),
          _buildTambahMetodeButton(screenWidth),
          SizedBox(height: _responsiveFontSize(screenWidth, 20)),
        ],
      ),
    );
  }
}