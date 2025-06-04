import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Diperlukan untuk Timestamp
import '../../../models/JadwalModel.dart'; // Menggunakan JadwalModel (Pastikan casing nama file konsisten)
import '../../../models/jadwal_kelas_info_model.dart'; // Untuk daftarKelasHarga
import '../../../models/jadwal_perhentian_model.dart'; // Untuk detailPerhentian
// import '../services/customer_firestore_service.dart'; // Jika ada service customer
import '../../admin/services/admin_firestore_service.dart';
import 'PilihKelasScreen.dart';

class PilihJadwalScreen extends StatefulWidget {
  final String stasiunAsal; // Display name, misal "BANDUNG (BD)"
  final String stasiunTujuan; // Display name
  final DateTime tanggalBerangkat; // Tanggal awal pencarian
  final int jumlahDewasa;
  final int jumlahBayi;
  // isAdminMode tidak lagi diperlukan jika layar ini khusus customer
  // final bool isAdminMode;

  const PilihJadwalScreen({
    super.key,
    required this.stasiunAsal,
    required this.stasiunTujuan,
    required this.tanggalBerangkat,
    required this.jumlahDewasa,
    required this.jumlahBayi,
    // this.isAdminMode = false, // Default ke mode customer
  });

  @override
  State<PilihJadwalScreen> createState() => _PilihJadwalScreenState();
}

class _PilihJadwalScreenState extends State<PilihJadwalScreen> {
  final AdminFirestoreService _firestoreService = AdminFirestoreService();
  final currencyFormatter =
  NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  late DateTime _currentSelectedDate;
  final List<DateTime> _dateTabs = [];
  Stream<List<JadwalModel>>? _jadwalStream;

  @override
  void initState() {
    super.initState();
    _currentSelectedDate = widget.tanggalBerangkat;
    _generateDateTabs();
    _updateJadwalStream();
    print("[PilihJadwalScreen] initState: Customer Mode");
  }

  void _generateDateTabs() {
    _dateTabs.clear();
    DateTime baseDate = _currentSelectedDate;
    for (int i = 0; i < 3; i++) {
      _dateTabs.add(baseDate.add(Duration(days: i)));
    }
    if (!_dateTabs.any((d) => d.year == _currentSelectedDate.year && d.month == _currentSelectedDate.month && d.day == _currentSelectedDate.day)) {
      _currentSelectedDate = _dateTabs.isNotEmpty ? _dateTabs.first : baseDate;
    }
  }

  void _onDateTabSelected(DateTime selectedDate) {
    if (!mounted) return;
    setState(() {
      _currentSelectedDate = selectedDate;
      _updateJadwalStream();
    });
  }

  void _updateJadwalStream() {
    String kodeAsal = widget.stasiunAsal.contains("(") && widget.stasiunAsal.contains(")")
        ? widget.stasiunAsal.substring(widget.stasiunAsal.indexOf("(") + 1, widget.stasiunAsal.indexOf(")"))
        : widget.stasiunAsal;
    String kodeTujuan = widget.stasiunTujuan.contains("(") && widget.stasiunTujuan.contains(")")
        ? widget.stasiunTujuan.substring(widget.stasiunTujuan.indexOf("(") + 1, widget.stasiunTujuan.indexOf(")"))
        : widget.stasiunTujuan;

    print(
        "[PilihJadwalScreen] Memperbarui stream untuk tanggal: ${DateFormat('yyyy-MM-dd').format(_currentSelectedDate)}");
    print(
        "Asal: $kodeAsal (dari ${widget.stasiunAsal}), Tujuan: $kodeTujuan (dari ${widget.stasiunTujuan})");

    setState(() {
      _jadwalStream = _firestoreService.getJadwalList(
          tanggal: _currentSelectedDate,
          kodeAsal: kodeAsal.toUpperCase(),
          kodeTujuan: kodeTujuan.toUpperCase()
      );
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
    print("[PilihJadwalScreen] Build method dipanggil.");
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
            child: StreamBuilder<List<JadwalModel>>(
              stream: _jadwalStream,
              builder: (context, snapshot) {
                print("[PilihJadwalScreen] StreamBuilder: ConnectionState = ${snapshot.connectionState}");

                if (snapshot.hasError) {
                  print("------------------------------------------------------------");
                  print("[PilihJadwalScreen] STREAMBUILDER ERROR DETECTED!");
                  print("Error: ${snapshot.error}");
                  print("StackTrace: ${snapshot.stackTrace}");
                  print("------------------------------------------------------------");
                  return Center(child: Text("Terjadi Error: ${snapshot.error.toString()}\nSilakan cek konsol debug dan pastikan Firestore Index sudah dibuat jika diperlukan oleh query."));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  print("[PilihJadwalScreen] StreamBuilder: Menunggu data...");
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data == null) {
                  print("[PilihJadwalScreen] StreamBuilder: Tidak ada data (snapshot.hasData: ${snapshot.hasData}, snapshot.data: ${snapshot.data}).");
                  return const Center(child: Text("Tidak ada data jadwal tersedia saat ini."));
                }

                final jadwalList = snapshot.data!;
                print("[PilihJadwalScreen] StreamBuilder: Data diterima, jumlah item = ${jadwalList.length}");

                if (jadwalList.isEmpty) {
                  print("[PilihJadwalScreen] StreamBuilder: Daftar jadwal kosong.");
                  return const Center(child: Text("Tidak ada jadwal untuk rute dan tanggal ini."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  itemCount: jadwalList.length,
                  itemBuilder: (context, index) {
                    final jadwal = jadwalList[index];
                    return _buildJadwalCard(jadwal);
                  },
                );
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : Colors.grey[700],
                    ),
                  ),
                  Text(
                    DateFormat('dd', 'id_ID').format(date),
                    style: TextStyle(
                      fontSize: 14,
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

  Widget _buildJadwalCard(JadwalModel jadwal) {
    // Untuk customer, kita tampilkan stasiun asal dan tujuan sesuai yang mereka cari (dari widget parameter)
    // Detail perhentian lengkap akan ada di PilihKelasScreen.
    // Waktu berangkat dan tiba yang ditampilkan di card ini adalah waktu keseluruhan perjalanan kereta.
    String stasiunAsalCardDisplay = widget.stasiunAsal;
    String stasiunTujuanCardDisplay = widget.stasiunTujuan;

    // Namun, jika ingin menampilkan stasiun awal dan akhir dari rute kereta itu sendiri:
    // String stasiunAsalKereta = jadwal.detailPerhentian.isNotEmpty ? jadwal.stasiunAwal.namaStasiun : jadwal.idStasiunAsal;
    // String stasiunTujuanKereta = jadwal.detailPerhentian.isNotEmpty ? jadwal.stasiunAkhir.namaStasiun : jadwal.idStasiunTujuan;


    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 2.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PilihKelasScreen(
                jadwalDipesan: jadwal,
                stasiunAsalDisplay: widget.stasiunAsal, // Kirim display name yang dicari customer
                stasiunTujuanDisplay: widget.stasiunTujuan, // Kirim display name yang dicari customer
                tanggalBerangkat: _currentSelectedDate,
                jumlahDewasa: widget.jumlahDewasa,
                jumlahBayi: widget.jumlahBayi,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12.0),
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
                      Text(jadwal.jamBerangkatFormatted, // Waktu berangkat keseluruhan kereta
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(jadwal.idStasiunAsal, // Stasiun awal keseluruhan rute kereta
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
                        Text(jadwal.durasiPerjalananTotal, // Durasi total perjalanan kereta
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(jadwal.jamTibaFormatted, // Waktu tiba keseluruhan kereta
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(jadwal.idStasiunTujuan, // Stasiun akhir keseluruhan rute kereta
                          style: const TextStyle(
                              fontSize: 13, color: Colors.black54)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

