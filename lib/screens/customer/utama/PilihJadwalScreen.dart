import 'package:cloud_firestore/cloud_firestore.dart'; // Diperlukan untuk Timestamp
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Untuk format harga dan tanggal
import '../../../models/JadwalModel.dart'; // Menggunakan JadwalModel
import '../../../models/jadwal_kelas_info_model.dart'; // Menggunakan JadwalKelasInfoModel
import 'PilihKelasScreen.dart'; // Impor PilihKelasScreen yang benar
import 'datapenumpangscreen.dart';

class PilihJadwalScreen extends StatefulWidget {
  final String stasiunAsal; // Ini adalah display name, misal "BANDUNG (BD)"
  final String stasiunTujuan; // Ini adalah display name
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
  late List<JadwalModel> _jadwalTersedia;
  final currencyFormatter =
  NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  late DateTime _currentSelectedDate;
  final List<DateTime> _dateTabs = [];

  @override
  void initState() {
    super.initState();
    _currentSelectedDate = widget.tanggalBerangkat;
    _generateDateTabs();
    _loadJadwalData();
  }

  void _generateDateTabs() {
    _dateTabs.clear();
    for (int i = 0; i < 3; i++) {
      _dateTabs.add(_currentSelectedDate.add(Duration(days: i)));
    }
  }

  void _onDateTabSelected(DateTime selectedDate) {
    if (!mounted) return;
    setState(() {
      _currentSelectedDate = selectedDate;
      _loadJadwalData();
    });
  }

  void _loadJadwalData() {
    print(
        "Memuat jadwal untuk tanggal: ${DateFormat('yyyy-MM-dd').format(_currentSelectedDate)}");
    print(
        "Asal: ${widget.stasiunAsal}, Tujuan: ${widget.stasiunTujuan}, Dewasa: ${widget.jumlahDewasa}, Bayi: ${widget.jumlahBayi}");

    // Data dummy - pastikan stasiunAsal/Tujuan di JadwalModel menggunakan kode jika widget.stasiunAsal adalah display name
    String kodeAsal = widget.stasiunAsal.split(" ")[0]; // Ambil kode, misal "BD" dari "BANDUNG (BD)"
    String kodeTujuan = widget.stasiunTujuan.split(" ")[0]; // Ambil kode

    _jadwalTersedia = [
      JadwalModel(
        id: "JDW001",
        idKereta: "KAI001",
        idStasiunAsal: "BD",
        idStasiunTujuan: "SLO",
        namaKereta: "LODAYA",
        tanggalBerangkat: Timestamp.fromDate(DateTime(
            _currentSelectedDate.year, _currentSelectedDate.month, _currentSelectedDate.day, 6, 30)),
        jamTiba: Timestamp.fromDate(DateTime(
            _currentSelectedDate.year, _currentSelectedDate.month, _currentSelectedDate.day, 14, 18)),
        daftarKelasHarga: [
          JadwalKelasInfoModel(
              namaKelas: "EKONOMI", subKelas: "CA", harga: 290000, ketersediaan: "Tersedia"),
          JadwalKelasInfoModel(
              namaKelas: "EKSEKUTIF", subKelas: "AA", harga: 430000, ketersediaan: "Tersedia"),
        ],
      ),
      JadwalModel(
        id: "JDW002",
        idKereta: "KAI002",
        idStasiunAsal: "BD",
        idStasiunTujuan: "SGU",
        namaKereta: "ARGO WILIS",
        tanggalBerangkat: Timestamp.fromDate(DateTime(
            _currentSelectedDate.year, _currentSelectedDate.month, _currentSelectedDate.day, 7, 35)),
        jamTiba: Timestamp.fromDate(DateTime(
            _currentSelectedDate.year, _currentSelectedDate.month, _currentSelectedDate.day, 17, 20)),
        daftarKelasHarga: [
          JadwalKelasInfoModel(
              namaKelas: "EKSEKUTIF", subKelas: "A", harga: 680000, ketersediaan: "Tersedia"),
          JadwalKelasInfoModel(
              namaKelas: "PANORAMIC", subKelas: "PA", harga: 1200000, ketersediaan: "2 Kursi"),
        ],
      ),
      if (_currentSelectedDate != widget.tanggalBerangkat) // Contoh jadwal tambahan jika tanggal beda
        JadwalModel(
          id: "JDW003",
          idKereta: "KAI003",
          idStasiunAsal: "BD",
          idStasiunTujuan: "SLO",
          namaKereta: "MALABAR",
          tanggalBerangkat: Timestamp.fromDate(DateTime(_currentSelectedDate.year, _currentSelectedDate.month, _currentSelectedDate.day, 17, 50)),
          jamTiba: Timestamp.fromDate(DateTime(_currentSelectedDate.year, _currentSelectedDate.month, _currentSelectedDate.day +1, 3, 12)), // Hari berikutnya
          daftarKelasHarga: [
            JadwalKelasInfoModel(namaKelas: "EKONOMI", subKelas: "S", harga: 350000, ketersediaan: "Tersedia"),
            JadwalKelasInfoModel(namaKelas: "BISNIS", subKelas: "B", harga: 480000, ketersediaan: "5 Kursi"),
          ],
        ),
    ];

    _jadwalTersedia.removeWhere((jadwal) =>
    jadwal.idStasiunAsal != kodeAsal ||
        jadwal.idStasiunTujuan != kodeTujuan);

    if (mounted) setState(() {});
  }

  void _toggleExpand(int index) {
    if (!mounted) return;
    setState(() {
      _jadwalTersedia[index].isExpanded = !_jadwalTersedia[index].isExpanded;
    });
  }

  String _formatInfoPenumpangAppBar() {
    String tanggalFormatted =
    DateFormat('EEE, dd MMM yy', 'id_ID').format(widget.tanggalBerangkat);
    String dewasaInfo = "${widget.jumlahDewasa} Dewasa";
    String bayiInfo =
    widget.jumlahBayi > 0 ? ", ${widget.jumlahBayi} Bayi" : "";
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
            Text(
              _formatInfoPenumpangAppBar(),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        elevation: 1.0,
      ),
      body: Column(
        children: [
          _buildDateTabsWidget(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Pilih Kereta Berangkat",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: _jadwalTersedia.isEmpty
                ? const Center(
                child: Text(
                    "Tidak ada jadwal tersedia untuk tanggal dan rute ini."))
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

  Widget _buildDateTabsWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      color: Colors.grey[100],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: _dateTabs.map((date) {
          bool isSelected = date.year == _currentSelectedDate.year &&
              date.month == _currentSelectedDate.month &&
              date.day == _currentSelectedDate.day;
          return InkWell(
            onTap: () => _onDateTabSelected(date),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('EEE', 'id_ID').format(date).toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : Colors.grey[700],
                    ),
                  ),
                  Text(
                    DateFormat('dd', 'id_ID').format(date),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Theme.of(context).primaryColorDark,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildJadwalCard(JadwalModel jadwal, int index) {
    // Untuk stasiunAsalDisplay dan stasiunTujuanDisplay di dalam card,
    // kita bisa menggunakan widget.stasiunAsal dan widget.stasiunTujuan
    // karena jadwal.idStasiunAsal/Tujuan adalah kode.
    // Atau, Anda perlu service untuk mengambil nama stasiun berdasarkan kode jika diperlukan.
    // Untuk sekarang, kita gunakan widget.stasiunAsal/Tujuan untuk konsistensi tampilan.
    String stasiunAsalCardDisplay = widget.stasiunAsal;
    String stasiunTujuanCardDisplay = widget.stasiunTujuan;
    // Jika ingin menampilkan kode stasiun dari jadwal:
    // String stasiunAsalCardDisplay = jadwal.idStasiunAsal;
    // String stasiunTujuanCardDisplay = jadwal.idStasiunTujuan;


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
                    "${jadwal.namaKereta.toUpperCase()} (${jadwal.idKereta})",
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColorDark),
                  ),
                ),
                Text(
                  "mulai ${currencyFormatter.format(jadwal.hargaMulaiDari)}",
                  style: const TextStyle(
                      fontSize: 13,
                      color: Colors.orange,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(jadwal.jamBerangkatFormatted,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(stasiunAsalCardDisplay, // Menggunakan variabel yang disiapkan
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black54)),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.linear_scale,
                          color: Colors.grey.shade400, size: 20),
                      Text(jadwal.durasiPerjalanan,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(jadwal.jamTibaFormatted,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(stasiunTujuanCardDisplay, // Menggunakan variabel yang disiapkan
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black54)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10.0),
            const Divider(),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PilihKelasScreen(
                      jadwalDipesan: jadwal,
                      stasiunAsalDisplay: widget.stasiunAsal, // Meneruskan display name
                      stasiunTujuanDisplay: widget.stasiunTujuan, // Meneruskan display name
                      tanggalBerangkat: _currentSelectedDate, // Menggunakan tanggal yang aktif dipilih di tab
                      jumlahDewasa: widget.jumlahDewasa,
                      jumlahBayi: widget.jumlahBayi,
                    ),
                  ),
                );
              },
              child: Padding( // Tambahkan Padding agar area tap lebih luas dan teks terlihat baik
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      // Tombol ini sekarang selalu "Pilih Kereta & Lihat Kelas"
                      // karena detail kelas akan ada di layar berikutnya.
                      // Atau bisa juga "Lihat Detail Kelas" jika isExpanded masih digunakan
                      // untuk menampilkan sesuatu di card ini sebelum navigasi.
                      // Untuk alur ke PilihKelasScreen, teks ini mungkin lebih cocok:
                      "PILIH KERETA & KELAS",
                      style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                        Icons.arrow_forward_ios, // Icon yang lebih mengindikasikan navigasi
                        color: Theme.of(context).primaryColor,
                        size: 16),
                  ],
                ),
              ),
            ),
            // Bagian if (jadwal.isExpanded) bisa dihapus jika semua detail kelas
            // hanya akan ditampilkan di PilihKelasScreen.
            // Jika Anda masih ingin ada expand/collapse di sini, maka _toggleExpand dan
            // _buildKelasItem perlu dipertahankan dan disesuaikan.
            // Untuk sekarang, saya hapus asumsi semua detail kelas ada di PilihKelasScreen.
            // if (jadwal.isExpanded)
            //   Padding(
            //     padding: const EdgeInsets.only(top: 0.0),
            //     child: Column(
            //       children: jadwal.daftarKelasHarga.map((kelas) {
            //         return _buildKelasItem(kelas, jadwal);
            //       }).toList(),
            //     ),
            //   ),
          ],
        ),
      ),
    );
  }

// Widget _buildKelasItem dihilangkan karena detail kelas akan ada di PilihKelasScreen
// Jika Anda masih ingin ada preview kelas di sini, Anda bisa mengembalikan dan menyesuaikannya.
}