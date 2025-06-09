import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kaig/models/JadwalModel.dart';
import 'package:kaig/models/jadwal_kelas_info_model.dart';
import 'package:kaig/screens/customer/utama/DataPenumpangScreen.dart';
import 'package:kaig/screens/customer/utama/pembayaran_screen.dart';
import 'package:kaig/screens/customer/utama/pilih_gerbong_screen.dart';

class PilihKursiStepScreen extends StatefulWidget {
  final JadwalModel jadwalDipesan;
  final JadwalKelasInfoModel kelasDipilih;
  final List<PenumpangInputData> dataPenumpangList;
  final int jumlahBayi; // Parameter yang ditambahkan

  const PilihKursiStepScreen({
    super.key,
    required this.jadwalDipesan,
    required this.kelasDipilih,
    required this.dataPenumpangList,
    required this.jumlahBayi, // Ditambahkan di constructor
  });

  @override
  State<PilihKursiStepScreen> createState() => _PilihKursiStepScreenState();
}

class _PilihKursiStepScreenState extends State<PilihKursiStepScreen> {
  // Menyimpan kursi yang dipilih untuk setiap penumpang, map dari index ke nomor kursi
  late Map<int, String> _kursiTerpilih;

  @override
  void initState() {
    super.initState();
    // Inisialisasi map kursi terpilih
    _kursiTerpilih = {};
  }

  void _pilihKursiUntukPenumpang(int indexPenumpang) async {
    // Navigasi ke PilihGerbongScreen
    final String? hasilPilihKursi = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => PilihGerbongScreen(
          jadwalDipesan: widget.jadwalDipesan,
          kelasDipilih: widget.kelasDipilih,
          penumpangSaatIni: widget.dataPenumpangList[indexPenumpang],
          kursiYangSudahDipilihGrup: _kursiTerpilih.values.where((k) => k != _kursiTerpilih[indexPenumpang]).toList(),
        ),
      ),
    );

    if (hasilPilihKursi != null && mounted) {
      setState(() {
        _kursiTerpilih.removeWhere((key, value) => value == hasilPilihKursi);
        _kursiTerpilih[indexPenumpang] = hasilPilihKursi;
      });
    }
  }

  void _lanjutkanKePembayaran() {
    // Validasi: pastikan semua penumpang sudah memilih kursi
    if (_kursiTerpilih.length < widget.dataPenumpangList.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap pilih kursi untuk semua penumpang.')),
      );
      return;
    }

    // Navigasi ke halaman pembayaran dengan membawa semua data yang diperlukan
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PembayaranScreen(
          jadwalDipesan: widget.jadwalDipesan,
          kelasDipilih: widget.kelasDipilih,
          dataPenumpangList: widget.dataPenumpangList,
          kursiTerpilih: _kursiTerpilih,
          jumlahBayi: widget.jumlahBayi, // Teruskan nilai jumlahBayi
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pesan Tiket"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: LinearProgressIndicator(
            value: 0.75, // Step 2 dari 3 (Kursi)
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text("2. Kursi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16.0),
          _buildInfoKeretaCard(),
          const SizedBox(height: 16.0),
          ..._buildListPenumpang(),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25)
            ),
          ),
          onPressed: _lanjutkanKePembayaran,
          child: const Text("LANJUTKAN", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
            Text(
              "Kereta Pergi",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
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

  List<Widget> _buildListPenumpang() {
    return List.generate(widget.dataPenumpangList.length, (index) {
      final penumpang = widget.dataPenumpangList[index];
      final kursiDipilih = _kursiTerpilih[index];

      return Card(
        margin: const EdgeInsets.only(top: 16.0),
        elevation: 1.5,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Penumpang ${index + 1} (Dewasa)"),
                    const SizedBox(height: 4),
                    Text(
                      penumpang.namaLengkap,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      kursiDipilih ?? "Belum memilih kursi",
                      style: TextStyle(
                        fontSize: 14,
                        color: kursiDipilih != null ? Theme.of(context).primaryColor : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () => _pilihKursiUntukPenumpang(index),
                child: Text(kursiDipilih != null ? "Ubah Kursi" : "Pilih Kursi"),
              ),
            ],
          ),
        ),
      );
    });
  }
}