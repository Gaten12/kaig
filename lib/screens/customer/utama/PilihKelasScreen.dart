import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/JadwalModel.dart'; // Menggunakan JadwalModel
import '../../../models/jadwal_kelas_info_model.dart';
import 'DataPenumpangScreen.dart'; // Layar selanjutnya

class PilihKelasScreen extends StatelessWidget {
  final JadwalModel jadwalDipesan;
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
    String tanggalInfo = DateFormat('EEE, dd MMM yy', 'id_ID')
        .format(jadwalDipesan.tanggalBerangkatUtama.toDate());

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
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
          _buildRuteKeretaSection(context, jadwalDipesan, stasiunAsalDisplay, stasiunTujuanDisplay),
          const SizedBox(height: 24.0),
          Text(
            "Pilih Kelas & Harga",
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
                final kelas = jadwalDipesan.daftarKelasHarga[index];
                // Ketersediaan sekarang dicek berdasarkan kuota
                bool isTersedia = kelas.kuota > 0;
                String ketersediaanText = isTersedia ? "Tersedia (${kelas.kuota} kursi)" : "Habis";

                return Card(
                  elevation: 1.5,
                  margin: const EdgeInsets.symmetric(vertical: 6.0),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    title: Text(
                      kelas.displayKelasLengkap,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      ketersediaanText,
                      style: TextStyle(
                        color: isTersedia ? Colors.green.shade700 : Colors.red,
                      ),
                    ),
                    trailing: Text(
                      currencyFormatter.format(kelas.harga),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: !isTersedia
                            ? Colors.grey
                            : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    onTap: !isTersedia
                        ? null
                        : () {
                      print(
                          "Kelas dipilih: ${kelas.displayKelasLengkap}");
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DataPenumpangScreen(
                            jadwalDipesan: jadwalDipesan,
                            kelasDipilih: kelas,
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

  Widget _buildRuteKeretaSection(BuildContext context, JadwalModel jadwal, String asalDisplay, String tujuanDisplay) {
    List<Widget> ruteWidgets = [];
    if (jadwal.detailPerhentian.isEmpty) {
      ruteWidgets.add(const Center(child: Text("Detail rute tidak tersedia.")));
    } else {
      for (int i = 0; i < jadwal.detailPerhentian.length; i++) {
        final perhentian = jadwal.detailPerhentian[i];
        bool isStasiunAwalRute = i == 0;
        bool isStasiunAkhirRute = i == jadwal.detailPerhentian.length - 1;

        ruteWidgets.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 100,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        if (!isStasiunAwalRute && perhentian.waktuTiba != null)
                          Text(DateFormat('HH:mm').format(perhentian.waktuTiba!.toDate()), style: const TextStyle(fontSize: 13, color: Colors.black54)),
                        if (!isStasiunAkhirRute && perhentian.waktuBerangkat != null)
                          Text(DateFormat('HH:mm').format(perhentian.waktuBerangkat!.toDate()), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                        if (isStasiunAwalRute && perhentian.waktuBerangkat != null)
                          Text(DateFormat('HH:mm').format(perhentian.waktuBerangkat!.toDate()), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                        if (isStasiunAkhirRute && perhentian.waktuTiba != null && !isStasiunAwalRute)
                          Text(DateFormat('HH:mm').format(perhentian.waktuTiba!.toDate()), style: const TextStyle(fontSize: 14, color: Colors.black54)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Icon(
                          isStasiunAwalRute ? Icons.radio_button_checked : (isStasiunAkhirRute ? Icons.location_on : Icons.fiber_manual_record),
                          color: isStasiunAwalRute ? Theme.of(context).primaryColor : (isStasiunAkhirRute ? Colors.red.shade700 : Colors.grey.shade400),
                          size: 20,
                        ),
                        if (!isStasiunAkhirRute)
                          Container(
                            height: 30,
                            width: 1.5,
                            color: Colors.grey.shade300,
                            margin: const EdgeInsets.symmetric(vertical: 2),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 1.0),
                      child: Text(
                        perhentian.namaStasiun.isNotEmpty ? perhentian.namaStasiun.toUpperCase() : perhentian.idStasiun.toUpperCase(),
                        style: TextStyle(
                            fontWeight: (isStasiunAwalRute || isStasiunAkhirRute) ? FontWeight.bold : FontWeight.normal,
                            fontSize: 14,
                            color: Colors.black87
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Rute Perjalanan ${jadwal.namaKereta.toUpperCase()} (${jadwal.idKereta})",
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text("Durasi Total: ${jadwal.durasiPerjalananTotal}",
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 16.0),
        Card(
          elevation: 1.5,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: ruteWidgets,
            ),
          ),
        ),
      ],
    );
  }
}
