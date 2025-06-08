import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kaig/models/JadwalModel.dart';
import 'package:kaig/models/jadwal_kelas_info_model.dart';
import 'package:kaig/screens/customer/utama/DataPenumpangScreen.dart';
import 'package:kaig/screens/customer/utama/konfirmasi_pembayaran_screen.dart';
import 'package:kaig/screens/customer/utama/pilih_metode_pembayaran_screen.dart';

class PembayaranScreen extends StatefulWidget {
  final JadwalModel jadwalDipesan;
  final JadwalKelasInfoModel kelasDipilih;
  final List<PenumpangInputData> dataPenumpangList;
  final Map<int, String> kursiTerpilih;

  const PembayaranScreen({
    super.key,
    required this.jadwalDipesan,
    required this.kelasDipilih,
    required this.dataPenumpangList,
    required this.kursiTerpilih,
  });

  @override
  State<PembayaranScreen> createState() => _PembayaranScreenState();
}

class _PembayaranScreenState extends State<PembayaranScreen> {
  bool _setujuSyaratDanKetentuan = false;
  String? _metodePembayaranTerpilih;

  @override
  Widget build(BuildContext context) {
    final currencyFormatter =
    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final totalHarga = widget.kelasDipilih.harga * widget.dataPenumpangList.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pesan Tiket"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: LinearProgressIndicator(
            value: 1.0, // Step 3 dari 3
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text("3. Pembayaran Tiket", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildInfoKeretaCard(),
          const SizedBox(height: 16),
          _buildRincianHarga(totalHarga, currencyFormatter),
          const SizedBox(height: 24),
          _buildPilihMetodePembayaran(),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(totalHarga, currencyFormatter),
    );
  }

  Widget _buildInfoKeretaCard() {
    // ... (Sama seperti di `pilih_kursi_step_screen.dart`)
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

  Widget _buildRincianHarga(int totalHarga, NumberFormat formatter) {
    return Card(
        elevation: 2.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Rincian Harga", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Tiket (${widget.dataPenumpangList.length}x)"),
                    Text(formatter.format(totalHarga)),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Total Pembayaran", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      formatter.format(totalHarga),
                      style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor, fontSize: 16),
                    ),
                  ],
                ),
              ],
            )));
  }

  Widget _buildPilihMetodePembayaran() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
      leading: const Icon(Icons.payment),
      title: const Text("Metode Pembayaran"),
      subtitle: Text(_metodePembayaranTerpilih ?? "Pilih metode pembayaran"),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: () async {
        final result = await Navigator.push<String>(
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

  Widget _buildBottomBar(int totalHarga, NumberFormat formatter) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), spreadRadius: 1, blurRadius: 5),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Checkbox(
                value: _setujuSyaratDanKetentuan,
                onChanged: (value) {
                  setState(() {
                    _setujuSyaratDanKetentuan = value!;
                  });
                },
              ),
              Expanded(
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 12, color: Colors.black),
                    children: [
                      TextSpan(text: "Saya telah membaca dan setuju terhadap "),
                      TextSpan(
                        text: "Syarat dan Ketentuan pembelian tiket.",
                        style: TextStyle(color: Colors.blue),
                        // recognizer: TapGestureRecognizer()..onTap = () { ... },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: _setujuSyaratDanKetentuan && _metodePembayaranTerpilih != null ? Theme.of(context).primaryColor : Colors.grey,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            ),
            onPressed: (_setujuSyaratDanKetentuan && _metodePembayaranTerpilih != null)
                ? () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => KonfirmasiPembayaranScreen(
                  jadwalDipesan: widget.jadwalDipesan,
                  kelasDipilih: widget.kelasDipilih,
                  dataPenumpangList: widget.dataPenumpangList,
                  kursiTerpilih: widget.kursiTerpilih,
                  metodePembayaran: _metodePembayaranTerpilih!,
                  totalBayar: totalHarga,
                )),
              );
            } : null,
            child: const Text("BAYAR SEKARANG", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
