import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Untuk format harga dan tanggal
import '../../models/jadwal_dummy_model.dart'; // Impor model dummy kita
// Import layar DataPenumpangScreen jika sudah ada untuk navigasi selanjutnya
// import 'data_penumpang_screen.dart';

class PilihJadwalScreen extends StatefulWidget {
  final String stasiunAsal;
  final String stasiunTujuan;
  final DateTime tanggalBerangkat;
  final int jumlahDewasa;
  final int jumlahBayi;

  const PilihJadwalScreen({
    super.key,
    required this.stasiunAsal,
    required this.stasiunTujuan,
    required this.tanggalBerangkat,
    required this.jumlahDewasa,
    required this.jumlahBayi,
  });

  @override
  State<PilihJadwalScreen> createState() => _PilihJadwalScreenState();
}

class _PilihJadwalScreenState extends State<PilihJadwalScreen> {
  late List<JadwalItem> _jadwalTersedia;
  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadJadwalData(); // Muat data jadwal
  }

  void _loadJadwalData() {
    // Di sini Anda akan memanggil service untuk mengambil data dari Firestore/API
    // berdasarkan widget.stasiunAsal, widget.stasiunTujuan, dan widget.tanggalBerangkat.
    // Untuk sekarang, kita gunakan data dummy dan sesuaikan dengan parameter widget.
    print("Memuat jadwal untuk tanggal: ${DateFormat('yyyy-MM-dd').format(widget.tanggalBerangkat)}");
    print("Asal: ${widget.stasiunAsal}, Tujuan: ${widget.stasiunTujuan}, Dewasa: ${widget.jumlahDewasa}, Bayi: ${widget.jumlahBayi}");

    _jadwalTersedia = [
      JadwalItem(
        namaKereta: "LODAYA",
        nomorKereta: "78",
        stasiunAsal: widget.stasiunAsal.toUpperCase(), // Menggunakan data dari widget
        stasiunTujuan: widget.stasiunTujuan.toUpperCase(), // Menggunakan data dari widget
        jamBerangkat: "06:30",
        jamTiba: "14:18",
        durasi: "7j 48m",
        hargaMulaiDari: 290000,
        daftarKelas: [
          KelasKereta(namaKelas: "EKONOMI", subKelas: "(CA)", harga: 290000, ketersediaan: "Tersedia"),
          KelasKereta(namaKelas: "EKSEKUTIF", subKelas: "(AA)", harga: 430000, ketersediaan: "Tersedia"),
        ],
      ),
      JadwalItem(
        namaKereta: "ARGO WILIS",
        nomorKereta: "10",
        stasiunAsal: widget.stasiunAsal.toUpperCase(),
        stasiunTujuan: widget.stasiunTujuan.toUpperCase(),
        jamBerangkat: "07:35",
        jamTiba: "17:20",
        durasi: "9j 45m",
        hargaMulaiDari: 680000,
        daftarKelas: [
          KelasKereta(namaKelas: "EKSEKUTIF", subKelas: "(A)", harga: 680000, ketersediaan: "Tersedia"),
          KelasKereta(namaKelas: "PANORAMIC", subKelas: "(PA)", harga: 1200000, ketersediaan: "2 Kursi"),
        ],
      ),
    ];
    // Jika Anda ingin mensimulasikan jadwal kosong untuk rute tertentu:
    // if (widget.stasiunAsal.toUpperCase() == "BD" && widget.stasiunTujuan.toUpperCase() == "PSE") {
    //   _jadwalTersedia = [];
    // }
    if(mounted) setState(() {});
  }

  void _toggleExpand(int index) {
    setState(() {
      _jadwalTersedia[index].isExpanded = !_jadwalTersedia[index].isExpanded;
    });
  }

  // Helper function untuk format informasi penumpang
  String _formatInfoPenumpang() {
    String tanggalFormatted = DateFormat('EEE, dd MMM yyyy', 'id_ID').format(widget.tanggalBerangkat);
    String dewasaInfo = "${widget.jumlahDewasa} Dewasa";
    String bayiInfo = widget.jumlahBayi > 0 ? ", ${widget.jumlahBayi} Bayi" : "";
    return "$tanggalFormatted  •  $dewasaInfo$bayiInfo";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${widget.stasiunAsal.toUpperCase()}  ❯  ${widget.stasiunTujuan.toUpperCase()}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
            // Menampilkan info tanggal dan penumpang di AppBar juga bisa, atau di bawah seperti sebelumnya
            // Text(
            //   _formatInfoPenumpang(),
            //   style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            // ),
          ],
        ),
        elevation: 1.0,
      ),
      body: Column(
        children: [
          // Bagian untuk informasi tanggal dan penumpang (menggantikan _buildDateTabs yang simpel)
          Container(
            width: double.infinity, // Agar full width
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            color: Colors.blue.shade50,
            child: Text(
              _formatInfoPenumpang(), // Menggunakan helper
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blue),
              textAlign: TextAlign.center, // Atau sesuaikan alignment
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Pilih Kereta Berangkat",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                // Icon(Icons.sort), // Tombol Urutkan (opsional)
              ],
            ),
          ),
          Expanded(
            child: _jadwalTersedia.isEmpty
                ? const Center(child: Text("Tidak ada jadwal tersedia untuk tanggal dan rute ini."))
                : ListView.builder(
              padding: const EdgeInsets.only(bottom: 16.0),
              itemCount: _jadwalTersedia.length,
              itemBuilder: (context, index) {
                final jadwal = _jadwalTersedia[index];
                return _buildJadwalCard(jadwal, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJadwalCard(JadwalItem jadwal, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 2.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    "${jadwal.namaKereta.toUpperCase()} (${jadwal.nomorKereta})",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColorDark),
                  ),
                ),
                Text(
                  "mulai ${currencyFormatter.format(jadwal.hargaMulaiDari)}",
                  style: const TextStyle(fontSize: 13, color: Colors.orange, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(jadwal.jamBerangkat, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(jadwal.stasiunAsal, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.linear_scale, color: Colors.grey.shade400, size: 20),
                      Text(jadwal.durasi, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(jadwal.jamTiba, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(jadwal.stasiunTujuan, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10.0),
            const Divider(),
            InkWell(
              onTap: () => _toggleExpand(index),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      jadwal.isExpanded ? "Tutup Detail Kelas" : "Lihat Detail Kelas",
                      style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    Icon(jadwal.isExpanded ? Icons.expand_less : Icons.expand_more, color: Theme.of(context).primaryColor, size: 20),
                  ],
                ),
              ),
            ),
            if (jadwal.isExpanded)
              Padding(
                padding: const EdgeInsets.only(top: 0.0),
                child: Column(
                  children: jadwal.daftarKelas.map((kelas) {
                    return _buildKelasItem(kelas, jadwal);
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildKelasItem(KelasKereta kelas, JadwalItem jadwalInduk) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: Colors.blueGrey.shade50.withOpacity(0.5),
      margin: const EdgeInsets.symmetric(vertical: 5.0),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        title: Text("${kelas.namaKelas} ${kelas.subKelas}", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Text(kelas.ketersediaan, style: TextStyle(fontSize: 12, color: kelas.ketersediaan.toLowerCase().contains("tersedia") || kelas.ketersediaan.toLowerCase().contains("kursi") ? Colors.green.shade700 : Colors.red.shade700)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(currencyFormatter.format(kelas.harga), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.deepOrangeAccent)),
            const Text("/pax", style: TextStyle(fontSize: 10)),
          ],
        ),
        onTap: () {
          print("Kelas dipilih: ${jadwalInduk.namaKereta} - ${kelas.namaKelas} ${kelas.subKelas} - Harga: ${kelas.harga}");
          // TODO: Navigasi ke layar DataPenumpangScreen
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(
          //     builder: (context) => DataPenumpangScreen(
          //       jadwal: jadwalInduk,
          //       kelasTerpilih: kelas,
          //       tanggalBerangkat: widget.tanggalBerangkat, // Tanggal dari parameter widget
          //       jumlahDewasa: widget.jumlahDewasa,
          //       jumlahBayi: widget.jumlahBayi,
          //     ),
          //   ),
          // );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Memilih ${kelas.namaKelas} ${kelas.subKelas} dari ${jadwalInduk.namaKereta}")),
          );
        },
      ),
    );
  }
}