import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kaig/models/keranjang_model.dart';
import 'package:kaig/models/metode_pembayaran_model.dart';

import '../pembayaran/pilih_metode_pembayaran_screen.dart';
import 'keranjang_konfirmasi_pembayaran_screen.dart';

class KeranjangPembayaranScreen extends StatefulWidget {
  final List<KeranjangModel> itemsToCheckout;

  const KeranjangPembayaranScreen({super.key, required this.itemsToCheckout});

  @override
  State<KeranjangPembayaranScreen> createState() =>
      _KeranjangPembayaranScreenState();
}

class _KeranjangPembayaranScreenState extends State<KeranjangPembayaranScreen> {
  // State untuk menyimpan objek metode pembayaran yang dipilih
  MetodePembayaranModel? _metodePembayaranTerpilih;

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
    final int totalPembayaran =
    widget.itemsToCheckout.fold(0, (sum, item) => sum + item.totalBayar);
    final currencyFormatter =
    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFC50000),
        foregroundColor: Colors.white,
        title: Text(
          "Ringkasan Checkout",
          style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 20)),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(_responsiveHorizontalPadding(screenWidth)),
        children: [
          Text(
            "Pesanan yang akan dibayar (${widget.itemsToCheckout.length} item)",
            style: TextStyle(
                fontSize: _responsiveFontSize(screenWidth, 18),
                fontWeight: FontWeight.bold),
          ),
          SizedBox(height: _responsiveFontSize(screenWidth, 12)),
          Card(
            elevation: _responsiveFontSize(screenWidth, 2.0),
            shape: RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(_responsiveFontSize(screenWidth, 12))),
            child: Padding(
              padding: EdgeInsets.all(_responsiveFontSize(screenWidth, 16.0)),
              child: Column(
                children: widget.itemsToCheckout
                    .map((item) => _buildItemRingkasan(item, currencyFormatter, screenWidth))
                    .toList(),
              ),
            ),
          ),
          SizedBox(height: _responsiveFontSize(screenWidth, 16)),
          _buildPilihMetodePembayaran(screenWidth),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(totalPembayaran, currencyFormatter, screenWidth),
    );
  }

  Widget _buildItemRingkasan(
      KeranjangModel item, NumberFormat formatter, double screenWidth) {
    return Padding(
      padding: EdgeInsets.only(bottom: _responsiveFontSize(screenWidth, 8.0)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              "${item.jadwalDipesan.namaKereta} (${item.penumpang.length} org)",
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 14)),
            ),
          ),
          Text(
            formatter.format(item.totalBayar),
            style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildPilihMetodePembayaran(double screenWidth) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(
          horizontal: _responsiveFontSize(screenWidth, 16),
          vertical: _responsiveFontSize(screenWidth, 8)),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_responsiveFontSize(screenWidth, 12)),
          side: BorderSide(color: Colors.grey.shade300)),
      leading: Icon(Icons.payment, size: _responsiveIconSize(screenWidth, 24)),
      title: Text("Metode Pembayaran",
          style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 16))),
      subtitle: Text(
          _metodePembayaranTerpilih?.namaMetode ?? "Pilih metode pembayaran",
          style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 14))),
      trailing: Icon(Icons.arrow_forward_ios, size: _responsiveIconSize(screenWidth, 20)),
      onTap: () async {
        final result = await Navigator.push<MetodePembayaranModel>(
          context,
          MaterialPageRoute(
              builder: (context) => const PilihMetodePembayaranScreen()),
        );
        if (result != null && mounted) {
          setState(() {
            _metodePembayaranTerpilih = result;
          });
        }
      },
    );
  }

  Widget _buildBottomBar(int totalHarga, NumberFormat formatter, double screenWidth) {
    return Container(
      padding: EdgeInsets.all(_responsiveHorizontalPadding(screenWidth)),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: _responsiveFontSize(screenWidth, 1),
              blurRadius: _responsiveFontSize(screenWidth, 5))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Total Pembayaran",
                  style: TextStyle(
                      fontSize: _responsiveFontSize(screenWidth, 16),
                      fontWeight: FontWeight.bold)),
              Text(formatter.format(totalHarga),
                  style: TextStyle(
                      fontSize: _responsiveFontSize(screenWidth, 18),
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0000CD))),
            ],
          ),
          SizedBox(height: _responsiveFontSize(screenWidth, 12)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, _responsiveFontSize(screenWidth, 50)),
              backgroundColor: _metodePembayaranTerpilih != null
                  ? Color(0xFF304FFE)
                  : Colors.grey,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(_responsiveFontSize(screenWidth, 25))),
            ),
            onPressed: _metodePembayaranTerpilih != null
                ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => KeranjangKonfirmasiPembayaranScreen(
                      itemsToCheckout: widget.itemsToCheckout,
                      metodePembayaran: _metodePembayaranTerpilih!,
                      totalBayar: totalHarga,
                    )),
              );
            }
                : null,
            child: Text(
              "LANJUTKAN KE PEMBAYARAN",
              style: TextStyle(
                  fontSize: _responsiveFontSize(screenWidth, 16),
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}