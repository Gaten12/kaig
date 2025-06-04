import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/JadwalModel.dart'; // Menggunakan JadwalModel
import 'DataPenumpangScreen.dart'; // Layar selanjutnya

class PilihKelasScreen extends StatelessWidget {
  final JadwalModel jadwalDipesan; // Menggunakan JadwalModel
  // Menambahkan display names untuk stasiun agar tidak bergantung pada lookup di layar ini
  final String stasiunAsalDisplay;
  final String stasiunTujuanDisplay;
  final DateTime tanggalBerangkat;
  final int jumlahDewasa;
  final int jumlahBayi;

  const PilihKelasScreen({
    super.key,
    required this.jadwalDipesan,
    required this.stasiunAsalDisplay,
    required this.stasiunTujuanDisplay,
    required this.tanggalBerangkat,
    required this.jumlahDewasa,
    required this.jumlahBayi,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter =
    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    String penumpangInfo = "${jumlahDewasa} Dewasa";
    if (jumlahBayi > 0) {
      penumpangInfo += ", ${jumlahBayi} Bayi";
    }
    String tanggalInfo =
    DateFormat('EEE, dd MMM yy', 'id_ID').format(tanggalBerangkat);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              // Menggunakan display names yang diterima
              "$stasiunAsalDisplay ❯ $stasiunTujuanDisplay",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              "$tanggalInfo • $penumpangInfo",
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        elevation: 1.0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildRuteKeretaSection(context, jadwalDipesan),
          const SizedBox(height: 24.0),
          Text(
            "Detail Harga",
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8.0),
          if (jadwalDipesan.daftarKelasHarga.isEmpty)
            const Center(
                child:
                Text("Tidak ada detail kelas tersedia untuk jadwal ini."))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: jadwalDipesan.daftarKelasHarga.length,
              itemBuilder: (context, index) {
                // Menggunakan JadwalKelasInfoModel
                final kelas = jadwalDipesan.daftarKelasHarga[index];
                bool isHabis = kelas.ketersediaan.toLowerCase() == "habis";
                return Card(
                  elevation: 1.5,
                  margin: const EdgeInsets.symmetric(vertical: 6.0),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    title: Text(
                      kelas.displayKelasLengkap, // Menggunakan getter dari model
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      "Status: ${kelas.ketersediaan}",
                      style: TextStyle(
                        color: isHabis ? Colors.red : Colors.green,
                      ),
                    ),
                    trailing: Text(
                      currencyFormatter.format(kelas.harga),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isHabis
                            ? Colors.grey
                            : Theme.of(context).primaryColor,
                      ),
                    ),
                    onTap: isHabis
                        ? null
                        : () {
                      print(
                          "Kelas dipilih: ${kelas.displayKelasLengkap}");
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DataPenumpangScreen(
                            jadwalDipesan: jadwalDipesan, // Kirim JadwalModel
                            kelasDipilih: kelas, // Kirim JadwalKelasInfoModel
                            tanggalBerangkat: tanggalBerangkat,
                            jumlahDewasa: jumlahDewasa,
                            jumlahBayi: jumlahBayi,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRuteKeretaSection(BuildContext context, JadwalModel jadwal) { // Menggunakan JadwalModel
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Pilihan Kereta Berangkat",
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16.0),
        Card(
          elevation: 2.0,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  // Menggunakan namaKereta dari JadwalModel
                  "${jadwal.namaKereta.toUpperCase()} (${jadwal.idKereta})", // Asumsi idKereta adalah nomor kereta
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text("Rute Kereta",
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 16.0),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(jadwal.jamBerangkatFormatted, // Menggunakan getter
                            style:
                            const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(jadwal.durasiPerjalanan, // Menggunakan getter
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(jadwal.jamTibaFormatted, // Menggunakan getter
                            style:
                            const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        children: [
                          const Icon(Icons.radio_button_checked,
                              color: Colors.blue, size: 18),
                          Container(
                            height: 40,
                            width: 1.5,
                            color: Colors.grey.shade400,
                            margin: const EdgeInsets.symmetric(vertical: 2),
                          ),
                          const Icon(Icons.train_outlined,
                              color: Colors.black54, size: 24),
                          Container(
                            height: 40,
                            width: 1.5,
                            color: Colors.grey.shade400,
                            margin: const EdgeInsets.symmetric(vertical: 2),
                          ),
                          const Icon(Icons.radio_button_checked,
                              color: Colors.grey, size: 18),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Menggunakan stasiunAsalDisplay dan stasiunTujuanDisplay dari parameter widget
                          Text(stasiunAsalDisplay,
                              style:
                              const TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(
                              height: 60 +
                                  (Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.fontSize ??
                                      14)),
                          Text(stasiunTujuanDisplay,
                              style:
                              const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}