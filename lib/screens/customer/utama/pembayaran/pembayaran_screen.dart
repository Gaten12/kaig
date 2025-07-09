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
  // --- ✨ PARAMETER DIPERBARUI UNTUK MENDUKUNG PP ✨ ---
  final JadwalModel jadwalPergi;
  final JadwalKelasInfoModel kelasDipilihPergi;
  final Map<int, String> kursiTerpilihPergi;

  final JadwalModel? jadwalPulang;
  final JadwalKelasInfoModel? kelasDipilihPulang;
  final Map<int, String>? kursiTerpilihPulang;

  final List<PenumpangInputData> dataPenumpangList;
  final int jumlahBayi;

  const PembayaranScreen({
    super.key,
    required this.jadwalPergi,
    required this.kelasDipilihPergi,
    required this.kursiTerpilihPergi,
    this.jadwalPulang,
    this.kelasDipilihPulang,
    this.kursiTerpilihPulang,
    required this.dataPenumpangList,
    required this.jumlahBayi,
  });

  @override
  State<PembayaranScreen> createState() => _PembayaranScreenState();
}

class _PembayaranScreenState extends State<PembayaranScreen> {
  final KeranjangService _keranjangService = KeranjangService();
  bool _setujuSyaratDanKetentuan = false;
  MetodePembayaranModel? _metodePembayaranTerpilih;

  // Warna
  static const Color _darkBlueNumberColor = Color(0xFF0000CD);
  static const Color _buttonBlueColor = Color(0xFF304FFE);
  static const Color primaryRed = Color(0xFFC50000);
  static const Color accentBlue = Color(0xFF1976D2);

  Future<void> _tambahKeKeranjang() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Anda harus login untuk menggunakan keranjang.")));
      return;
    }

    try {
      // Buat item untuk tiket pergi
      final itemPergi = _buatItemKeranjang(
        user.uid,
        widget.jadwalPergi,
        widget.kelasDipilihPergi,
        widget.kursiTerpilihPergi,
      );
      await _keranjangService.tambahKeKeranjang(itemPergi);

      // Jika ada tiket pulang, buat item terpisah untuk tiket pulang
      if (widget.jadwalPulang != null && widget.kelasDipilihPulang != null && widget.kursiTerpilihPulang != null) {
        final itemPulang = _buatItemKeranjang(
          user.uid,
          widget.jadwalPulang!,
          widget.kelasDipilihPulang!,
          widget.kursiTerpilihPulang!,
        );
        await _keranjangService.tambahKeKeranjang(itemPulang);
      }

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

  KeranjangModel _buatItemKeranjang(String userId, JadwalModel jadwal, JadwalKelasInfoModel kelas, Map<int, String> kursi) {
    final totalHarga = kelas.harga * widget.dataPenumpangList.length;
    final List<Map<String, String>> penumpangData = [];
    kursi.forEach((index, kursi) {
      final dataInput = widget.dataPenumpangList[index];
      penumpangData.add({
        'nama': dataInput.namaLengkap,
        'tipeId': dataInput.tipeId,
        'nomorId': dataInput.nomorId,
        'kursi': kursi,
      });
    });

    return KeranjangModel(
      userId: userId,
      jadwalDipesan: jadwal,
      kelasDipilih: kelas,
      penumpang: penumpangData,
      jumlahBayi: widget.jumlahBayi,
      totalBayar: totalHarga,
      waktuDitambahkan: Timestamp.now(),
      batasWaktuPembayaran: Timestamp.fromDate(DateTime.now().add(const Duration(hours: 1))),
    );
  }

  // Helper-helper responsive (tidak berubah)
  double _responsiveFontSize(double screenWidth, double baseSize) { /* ... */ return baseSize; }
  double _responsiveIconSize(double screenWidth, double baseSize) { /* ... */ return baseSize; }
  double _responsiveHorizontalPadding(double screenWidth) { /* ... */ return 16.0; }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    // --- ✨ Hitung total harga dari kedua perjalanan ✨ ---
    final hargaPergi = widget.kelasDipilihPergi.harga * widget.dataPenumpangList.length;
    final hargaPulang = (widget.kelasDipilihPulang?.harga ?? 0) * widget.dataPenumpangList.length;
    final totalHarga = hargaPergi + hargaPulang;
    bool isRoundTrip = widget.jadwalPulang != null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFC50000),
        foregroundColor: Colors.white,
        title: Text("Pembayaran", style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 20))),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(_responsiveFontSize(screenWidth, 4.0)),
          child: LinearProgressIndicator(
            value: 1.0, // Langkah terakhir
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
              "4. Pembayaran",
              style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 18), fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          SizedBox(height: _responsiveFontSize(screenWidth, 16)),
          _buildInfoKeretaCard(screenWidth, widget.jadwalPergi, widget.kelasDipilihPergi, "Kereta Pergi", primaryRed),
          if (isRoundTrip) ...[
            SizedBox(height: _responsiveFontSize(screenWidth, 16)),
            _buildInfoKeretaCard(screenWidth, widget.jadwalPulang!, widget.kelasDipilihPulang!, "Kereta Pulang", accentBlue),
          ],
          SizedBox(height: _responsiveFontSize(screenWidth, 16)),
          _buildRincianHarga(hargaPergi, hargaPulang, totalHarga, currencyFormatter, screenWidth),
          SizedBox(height: _responsiveFontSize(screenWidth, 24)),
          _buildPilihMetodePembayaran(screenWidth),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(totalHarga, currencyFormatter, screenWidth),
    );
  }

  Widget _buildInfoKeretaCard(double screenWidth, JadwalModel jadwal, JadwalKelasInfoModel kelas, String title, Color color) {
    return Card(
      elevation: _responsiveFontSize(screenWidth, 2.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_responsiveFontSize(screenWidth, 12))),
      child: Padding(
        padding: EdgeInsets.all(_responsiveFontSize(screenWidth, 16.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: _responsiveFontSize(screenWidth, 18),
                color: color,
              ),
            ),
            Divider(height: _responsiveFontSize(screenWidth, 20)),
            Text(
              "${DateFormat('EEE, dd MMM yy', 'id_ID').format(jadwal.tanggalBerangkatUtama.toDate())}  •  ${jadwal.jamBerangkatFormatted}",
              style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 14), color: Colors.grey),
            ),
            SizedBox(height: _responsiveFontSize(screenWidth, 4)),
            Text(
              "${jadwal.idStasiunAsal} ❯ ${jadwal.idStasiunTujuan}",
              style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 16), fontWeight: FontWeight.w600),
            ),
            SizedBox(height: _responsiveFontSize(screenWidth, 4)),
            Text(
              "${jadwal.namaKereta} • ${kelas.displayKelasLengkap}",
              style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 14)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRincianHarga(int hargaPergi, int hargaPulang, int totalHarga, NumberFormat formatter, double screenWidth) {
    bool isRoundTrip = widget.jadwalPulang != null;
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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: _responsiveFontSize(screenWidth, 18)),
            ),
            SizedBox(height: _responsiveFontSize(screenWidth, 12)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Tiket Pergi (${widget.dataPenumpangList.length}x)",
                  style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 14)),
                ),
                Text(
                  formatter.format(hargaPergi),
                  style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 14), color: _darkBlueNumberColor),
                ),
              ],
            ),
            if (isRoundTrip) ...[
              SizedBox(height: _responsiveFontSize(screenWidth, 8)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Tiket Pulang (${widget.dataPenumpangList.length}x)",
                    style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 14)),
                  ),
                  Text(
                    formatter.format(hargaPulang),
                    style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 14), color: _darkBlueNumberColor),
                  ),
                ],
              ),
            ],
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
                  style: TextStyle(fontWeight: FontWeight.bold, color: _darkBlueNumberColor, fontSize: _responsiveFontSize(screenWidth, 16)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

// DENGAN FUNGSI BARU INI
  Widget _buildPilihMetodePembayaran(double screenWidth) {
    return Card(
      elevation: _responsiveFontSize(screenWidth, 2.0),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_responsiveFontSize(screenWidth, 12))),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: _responsiveFontSize(screenWidth, 16.0),
          vertical: _responsiveFontSize(screenWidth, 8.0),
        ),
        leading: Icon(
          Icons.payment,
          color: Theme.of(context).primaryColor,
          size: _responsiveIconSize(screenWidth, 28),
        ),
        title: Text(
          "Metode Pembayaran",
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: _responsiveFontSize(screenWidth, 16)),
        ),
        subtitle: Text(
          // Tampilkan metode yang dipilih atau teks default
          _metodePembayaranTerpilih?.namaMetode ?? "Pilih metode pembayaran",
          style: TextStyle(
            fontSize: _responsiveFontSize(screenWidth, 14),
            color: _metodePembayaranTerpilih == null ? Colors.red : Colors.black54,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: _responsiveIconSize(screenWidth, 16),
        ),
        onTap: () async {
          // Navigasi ke halaman pilih metode dan tunggu hasilnya
          final result = await Navigator.push<MetodePembayaranModel>(
            context,
            MaterialPageRoute(
              builder: (context) => const PilihMetodePembayaranScreen(),
            ),
          );

          // Jika ada hasil yang dipilih, perbarui state
          if (result != null) {
            setState(() {
              _metodePembayaranTerpilih = result;
            });
          }
        },
      ),
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
                activeColor: _darkBlueNumberColor,
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
              backgroundColor: _setujuSyaratDanKetentuan && _metodePembayaranTerpilih != null ? _buttonBlueColor : Colors.grey,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_responsiveFontSize(screenWidth, 25))),
            ),
            onPressed: (_setujuSyaratDanKetentuan && _metodePembayaranTerpilih != null)
                ? () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => KonfirmasiPembayaranScreen(
                  jadwalPergi: widget.jadwalPergi,
                  kelasDipilihPergi: widget.kelasDipilihPergi,
                  kursiTerpilihPergi: widget.kursiTerpilihPergi,
                  jadwalPulang: widget.jadwalPulang,
                  kelasDipilihPulang: widget.kelasDipilihPulang,
                  kursiTerpilihPulang: widget.kursiTerpilihPulang,
                  dataPenumpangList: widget.dataPenumpangList,
                  jumlahBayi: widget.jumlahBayi,
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
              side: const BorderSide(color: _buttonBlueColor),
              foregroundColor: _buttonBlueColor,
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