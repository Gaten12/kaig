import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kaig/models/JadwalModel.dart';
import 'package:kaig/models/jadwal_kelas_info_model.dart';
import 'package:kaig/models/metode_pembayaran_model.dart';
import 'package:kaig/models/transaksi_model.dart';
import 'package:kaig/services/transaksi_service.dart';
import '../home_screen.dart';
import '../tiket/DataPenumpangScreen.dart';

class KonfirmasiPembayaranScreen extends StatefulWidget {
  final JadwalModel jadwalDipesan;
  final JadwalKelasInfoModel kelasDipilih;
  final List<PenumpangInputData> dataPenumpangList;
  final int jumlahBayi;
  final Map<int, String> kursiTerpilih;
  final MetodePembayaranModel metodePembayaran;
  final int totalBayar;

  const KonfirmasiPembayaranScreen({
    super.key,
    required this.jadwalDipesan,
    required this.kelasDipilih,
    required this.dataPenumpangList,
    required this.jumlahBayi,
    required this.kursiTerpilih,
    required this.metodePembayaran,
    required this.totalBayar,
  });

  @override
  State<KonfirmasiPembayaranScreen> createState() => _KonfirmasiPembayaranScreenState();
}

class _KonfirmasiPembayaranScreenState extends State<KonfirmasiPembayaranScreen> {
  final TransaksiService _transaksiService = TransaksiService();
  bool _isLoading = false;

  Future<void> _prosesKonfirmasi() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error: Pengguna tidak ditemukan.")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final kodeBooking = _generateKodeBooking();

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

      final transaksi = TransaksiModel(
        userId: user.uid,
        kodeBooking: kodeBooking,
        idJadwal: widget.jadwalDipesan.id,
        namaKereta: widget.jadwalDipesan.namaKereta,
        rute: "${widget.jadwalDipesan.idStasiunAsal} ❯ ${widget.jadwalDipesan.idStasiunTujuan}",
        kelas: widget.kelasDipilih.displayKelasLengkap,
        tanggalBerangkat: widget.jadwalDipesan.tanggalBerangkatUtama,
        waktuBerangkat: widget.jadwalDipesan.jamBerangkatFormatted,
        waktuTiba: widget.jadwalDipesan.jamTibaFormatted,
        penumpang: penumpangData,
        jumlahBayi: widget.jumlahBayi,
        metodePembayaran: widget.metodePembayaran.namaMetode,
        totalBayar: widget.totalBayar,
        tanggalTransaksi: Timestamp.now(),
      );

      // --- PERBAIKAN UTAMA DI SINI ---
      // Tambahkan parameter 'kelasDipilih' yang hilang
      await _transaksiService.buatTransaksi(
        transaksi: transaksi,
        kelasDipilih: widget.kelasDipilih, // <-- Baris ini ditambahkan
        jadwalId: widget.jadwalDipesan.id,
        kursiTerpilih: widget.kursiTerpilih.values.toList(),
      );
      // --- AKHIR PERBAIKAN ---

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text("Pembayaran Berhasil!"),
            content: Text("Tiket Anda dengan kode booking $kodeBooking telah berhasil diterbitkan. Anda dapat melihatnya di halaman 'Tiket Saya'."),
            actions: [
              TextButton(
                child: const Text("OK"),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const HomeScreen(initialIndex: 2)),
                        (Route<dynamic> route) => false,
                  );
                },
              )
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal memproses transaksi: $e")));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _generateKodeBooking() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
        8, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    String infoJudul;
    String infoNomor;

    if (widget.metodePembayaran.tipe == TipeMetodePembayaran.ewallet) {
      infoJudul = "Nomor E-Wallet (${widget.metodePembayaran.namaMetode})";
      infoNomor = widget.metodePembayaran.nomor;
    } else {
      infoJudul = "Nomor Kartu (${widget.metodePembayaran.namaMetode})";
      infoNomor = "**** **** **** ${widget.metodePembayaran.nomor.substring(widget.metodePembayaran.nomor.length - 4)}";
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFC50000),
        foregroundColor: Colors.white,
        title: const Text("Konfirmasi Pembayaran")
        ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.orange)))
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoKeretaCard(),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Metode Pembayaran: ${widget.metodePembayaran.namaMetode}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Divider(height: 20),

                  Text(infoJudul),
                  SelectableText(
                    infoNomor,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 16),
                  const Text("Total Pembayaran"),
                  Text(
                    currencyFormatter.format(widget.totalBayar),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Color(0xFF0000CD)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _prosesKonfirmasi,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0000CD),
            minimumSize: const Size(double.infinity, 50)
            ),
          child: const Text("KONFIRMASI PEMBAYARAN"),
        ),
      ),
    );
  }

  Widget _buildInfoKeretaCard() {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Kereta Pergi", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const Divider(height: 20),
            Text(
              "${DateFormat('EEE, dd MMM yy', 'id_ID').format(widget.jadwalDipesan.tanggalBerangkatUtama.toDate())}  •  ${widget.jadwalDipesan.jamBerangkatFormatted}",
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              "${widget.jadwalDipesan.idStasiunAsal} ❯ ${widget.jadwalDipesan.idStasiunTujuan}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              "${widget.jadwalDipesan.namaKereta} • ${widget.kelasDipilih.displayKelasLengkap}",
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}