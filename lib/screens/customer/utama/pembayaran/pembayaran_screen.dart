import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kaig/models/JadwalModel.dart';
import 'package:kaig/models/jadwal_kelas_info_model.dart';
import 'package:kaig/models/keranjang_model.dart';
import 'package:kaig/models/metode_pembayaran_model.dart';
import 'package:kaig/screens/customer/utama/home_screen.dart';
import 'package:kaig/screens/customer/utama/pembayaran/konfirmasi_pembayaran_screen.dart';
import 'package:kaig/screens/customer/utama/pembayaran/pilih_metode_pembayaran_screen.dart';
import 'package:kaig/services/keranjang_service.dart';

import '../tiket/DataPenumpangScreen.dart';

class PembayaranScreen extends StatefulWidget {
  final JadwalModel jadwalDipesan;
  final JadwalKelasInfoModel kelasDipilih;
  final List<PenumpangInputData> dataPenumpangList;
  final int jumlahBayi;
  final Map<int, String> kursiTerpilih;

  const PembayaranScreen({
    super.key,
    required this.jadwalDipesan,
    required this.kelasDipilih,
    required this.dataPenumpangList,
    required this.jumlahBayi, // 2. Tambahkan di constructor
    required this.kursiTerpilih,
  });

  @override
  State<PembayaranScreen> createState() => _PembayaranScreenState();
}

class _PembayaranScreenState extends State<PembayaranScreen> {
  final KeranjangService _keranjangService = KeranjangService();
  bool _setujuSyaratDanKetentuan = false;
  MetodePembayaranModel? _metodePembayaranTerpilih;

  // Define the new colors
  static const Color _darkBlueNumberColor = Color(0xFF0000CD);
  static const Color _buttonBlueColor = Color(0xFF304FFE);


  Future<void> _tambahKeKeranjang() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Anda harus login untuk menggunakan keranjang.")));
      return;
    }

    final totalHarga = widget.kelasDipilih.harga * widget.dataPenumpangList.length;
    final List<Map<String, String>> penumpangData = [];
    widget.kursiTerpilih.forEach((index, kursi) {
      final dataInput = widget.dataPenumpangList[index];
      penumpangData.add({
        'nama': dataInput.namaLengkap,
        'tipeId': dataInput.tipeId,
        'nomorId': dataInput.nomorId,
        'kursi': kursi,
      });
    });

    final itemKeranjang = KeranjangModel(
      userId: user.uid,
      jadwalDipesan: widget.jadwalDipesan,
      kelasDipilih: widget.kelasDipilih,
      penumpang: penumpangData,
      jumlahBayi: widget.jumlahBayi,
      totalBayar: totalHarga,
      waktuDitambahkan: Timestamp.now(),
      batasWaktuPembayaran: Timestamp.fromDate(DateTime.now().add(const Duration(hours: 1))),
    );

    try {
      await _keranjangService.tambahKeKeranjang(itemKeranjang);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Pesanan berhasil ditambahkan ke keranjang.")),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal menambahkan ke keranjang: $e")),
        );
      }
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
    final currencyFormatter =
    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final totalHarga = widget.kelasDipilih.harga * widget.dataPenumpangList.length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFC50000),
        foregroundColor: Colors.white,
        title: Text(
          "Pesan Tiket",
          style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 20)),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(_responsiveFontSize(screenWidth, 4.0)),
          child: LinearProgressIndicator(
            value: 1.0,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(_responsiveHorizontalPadding(screenWidth)),
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: _responsiveFontSize(screenWidth, 10.0), horizontal: _responsiveFontSize(screenWidth, 16.0)),
            decoration: BoxDecoration(
              color: Colors.deepOrange,
              borderRadius: BorderRadius.circular(_responsiveFontSize(screenWidth, 8.0)),
            ),
            child: Text(
              "3. Pembayaran Tiket",
              style: TextStyle(
                fontSize: _responsiveFontSize(screenWidth, 18),
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: _responsiveFontSize(screenWidth, 16)),
          _buildInfoKeretaCard(screenWidth),
          SizedBox(height: _responsiveFontSize(screenWidth, 16)),
          _buildRincianHarga(totalHarga, currencyFormatter, screenWidth),
          SizedBox(height: _responsiveFontSize(screenWidth, 24)),
          _buildPilihMetodePembayaran(screenWidth),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(totalHarga, currencyFormatter, screenWidth),
    );
  }

  Widget _buildInfoKeretaCard(double screenWidth) {
    return Card(
      elevation: _responsiveFontSize(screenWidth, 2.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_responsiveFontSize(screenWidth, 12))),
      child: Padding(
        padding: EdgeInsets.all(_responsiveFontSize(screenWidth, 16.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Kereta Pergi",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: _responsiveFontSize(screenWidth, 18),
              ),
            ),
            Divider(height: _responsiveFontSize(screenWidth, 20)),
            Text(
              "${DateFormat('EEE, dd MMM yy', 'id_ID').format(widget.jadwalDipesan.tanggalBerangkatUtama.toDate())}  •  ${widget.jadwalDipesan.jamBerangkatFormatted}",
              style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 14), color: Colors.grey),
            ),
            SizedBox(height: _responsiveFontSize(screenWidth, 4)),
            Text(
              "${widget.jadwalDipesan.idStasiunAsal} ❯ ${widget.jadwalDipesan.idStasiunTujuan}",
              style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 16), fontWeight: FontWeight.w600),
            ),
            SizedBox(height: _responsiveFontSize(screenWidth, 4)),
            Text(
              "${widget.jadwalDipesan.namaKereta} • ${widget.kelasDipilih.displayKelasLengkap}",
              style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 14)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRincianHarga(int totalHarga, NumberFormat formatter, double screenWidth) {
    return Card(
      elevation: _responsiveFontSize(screenWidth, 2.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_responsiveFontSize(screenWidth, 12))),
      child: Padding(
        padding: EdgeInsets.all(_responsiveFontSize(screenWidth, 16.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Rincian Harga",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: _responsiveFontSize(screenWidth, 18),
              ),
            ),
            SizedBox(height: _responsiveFontSize(screenWidth, 12)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Tiket (${widget.dataPenumpangList.length}x)",
                  style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 14)),
                ),
                Text(
                  formatter.format(totalHarga),
                  style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 14), color: _darkBlueNumberColor), // Number color
                ),
              ],
            ),
            Divider(height: _responsiveFontSize(screenWidth, 24)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total Pembayaran",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: _responsiveFontSize(screenWidth, 16)),
                ),
                Text(
                  formatter.format(totalHarga),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _darkBlueNumberColor, // Number color
                    fontSize: _responsiveFontSize(screenWidth, 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPilihMetodePembayaran(double screenWidth) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: _responsiveFontSize(screenWidth, 16), vertical: _responsiveFontSize(screenWidth, 8)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_responsiveFontSize(screenWidth, 12)), side: BorderSide(color: Colors.grey.shade300)),
      leading: Icon(Icons.payment, size: _responsiveIconSize(screenWidth, 24)),
      title: Text("Metode Pembayaran", style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 16))),
      subtitle: Text(_metodePembayaranTerpilih?.namaMetode ?? "Pilih metode pembayaran", style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 14))),
      trailing: Icon(Icons.arrow_forward_ios, size: _responsiveIconSize(screenWidth, 20)),
      onTap: () async {
        final result = await Navigator.push<MetodePembayaranModel>(
          context,
          MaterialPageRoute(builder: (context) => const PilihMetodePembayaranScreen()),
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
          BoxShadow(color: Colors.black.withOpacity(0.1), spreadRadius: _responsiveFontSize(screenWidth, 1), blurRadius: _responsiveFontSize(screenWidth, 5)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Checkbox(
                value: _setujuSyaratDanKetentuan,
                activeColor: _darkBlueNumberColor, // Checkbox active color
                onChanged: (value) {
                  setState(() {
                    _setujuSyaratDanKetentuan = value!;
                  });
                },
              ),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 12), color: Colors.black),
                    children: [
                      const TextSpan(text: "Saya telah membaca dan setuju terhadap "),
                      TextSpan(
                        text: "Syarat dan Ketentuan pembelian tiket.",
                        style: TextStyle(color: Colors.blue, fontSize: _responsiveFontSize(screenWidth, 12)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: _responsiveFontSize(screenWidth, 8)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, _responsiveFontSize(screenWidth, 50)),
              backgroundColor: _setujuSyaratDanKetentuan && _metodePembayaranTerpilih != null
                  ? _buttonBlueColor // Button color
                  : Colors.grey,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_responsiveFontSize(screenWidth, 25))),
            ),
            onPressed: (_setujuSyaratDanKetentuan && _metodePembayaranTerpilih != null)
                ? () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => KonfirmasiPembayaranScreen(
                  jadwalDipesan: widget.jadwalDipesan,
                  kelasDipilih: widget.kelasDipilih,
                  dataPenumpangList: widget.dataPenumpangList,
                  jumlahBayi: widget.jumlahBayi,
                  kursiTerpilih: widget.kursiTerpilih,
                  metodePembayaran: _metodePembayaranTerpilih!,
                  totalBayar: totalHarga,
                )),
              );
            } : null,
            child: Text(
              "BAYAR SEKARANG",
              style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 16), fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: _responsiveFontSize(screenWidth, 8)),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: Size(double.infinity, _responsiveFontSize(screenWidth, 50)),
              side: BorderSide(color: _buttonBlueColor), // Border color
              foregroundColor: _buttonBlueColor, // Text color
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_responsiveFontSize(screenWidth, 25))),
            ),
            onPressed: _tambahKeKeranjang,
            child: Text(
              "TAMBAH KE KERANJANG",
              style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 16)),
            ),
          ),
        ],
      ),
    );
  }
}