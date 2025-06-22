import 'package:flutter/material.dart';
import '../../../models/jadwal_kelas_info_model.dart';
import '../models/gerbong_tipe_model.dart';
import '../models/kursi_model.dart';
import '../screens/admin/services/admin_firestore_service.dart';
import '../screens/customer/utama/tiket/DataPenumpangScreen.dart';

class PilihKursiLayoutScreen extends StatefulWidget {
  final String jadwalId;
  final JadwalKelasInfoModel kelasInfo;
  final PenumpangInputData penumpangSaatIni;
  final List<String> kursiYangSudahDipilihGrup;
  final GerbongTipeModel gerbong;
  final int nomorGerbong;

  const PilihKursiLayoutScreen({
    super.key,
    required this.jadwalId,
    required this.kelasInfo,
    required this.penumpangSaatIni,
    required this.kursiYangSudahDipilihGrup,
    required this.gerbong,
    required this.nomorGerbong,
  });

  @override
  State<PilihKursiLayoutScreen> createState() => _PilihKursiLayoutScreenState();
}

class _PilihKursiLayoutScreenState extends State<PilihKursiLayoutScreen> {
  final AdminFirestoreService _firestoreService = AdminFirestoreService();
  String? _kursiDipilihSaatIni; // Format: "1A", "12D", dll.

  void _onKursiTap(String nomorKursi, String status) {
    final kursiPenuhId = "Gerbong ${widget.nomorGerbong} - Kursi $nomorKursi";
    if (status == 'terisi' || widget.kursiYangSudahDipilihGrup.contains(kursiPenuhId)) {
      // Tidak melakukan apa-apa jika kursi tidak tersedia
      return;
    }
    setState(() {
      if (_kursiDipilihSaatIni == nomorKursi) {
        _kursiDipilihSaatIni = null; // Batal memilih
      } else {
        _kursiDipilihSaatIni = nomorKursi; // Memilih kursi baru
      }
    });
  }

  void _simpanPilihan() {
    if (_kursiDipilihSaatIni != null) {
      final kursiTerpilihLengkap = "Gerbong ${widget.nomorGerbong} - Kursi ${_kursiDipilihSaatIni!}";
      Navigator.pop(context, kursiTerpilihLengkap);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih satu kursi terlebih dahulu.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Pilih Kursi", style: TextStyle(fontSize: 18, color: Colors.white)),
            Text(
              "${widget.gerbong.namaTipeLengkap} - Gerbong ${widget.nomorGerbong}",
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFC50000),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildPassengerHeader(),
          _buildLegendaKursi(),
          Expanded(
            child: StreamBuilder<List<KursiModel>>(
              stream: _firestoreService.getKursiListForJadwal(widget.jadwalId, widget.nomorGerbong),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error memuat data kursi: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("Denah kursi tidak tersedia untuk gerbong ini."));
                }

                final statusKursiMap = {for (var k in snapshot.data!) k.nomorKursi: k.status};

                return _buildVisualSeatLayout(statusKursiMap);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // --- WIDGET-WIDGET BARU UNTUK TAMPILAN VISUAL ---

  Widget _buildVisualSeatLayout(Map<String, String> statusKursi) {
    List<String> kolomKiri, kolomKanan;
    int totalBaris;

    switch (widget.gerbong.tipeLayout) {
      case TipeLayoutGerbong.layout_2_2:
        kolomKiri = ['A', 'B']; kolomKanan = ['C', 'D'];
        totalBaris = (widget.gerbong.jumlahKursi / 4).ceil();
        break;
      case TipeLayoutGerbong.layout_3_2:
        kolomKiri = ['A', 'B', 'C']; kolomKanan = ['D', 'E'];
        totalBaris = (widget.gerbong.jumlahKursi / 5).ceil();
        break;
      case TipeLayoutGerbong.layout_2_1:
        kolomKiri = ['A', 'B']; kolomKanan = ['C'];
        totalBaris = (widget.gerbong.jumlahKursi / 3).ceil();
        break;
      case TipeLayoutGerbong.layout_1_1:
        kolomKiri = ['A']; kolomKanan = ['B'];
        totalBaris = (widget.gerbong.jumlahKursi / 2).ceil();
        break;
      default:
        return const Center(child: Text("Layout kursi tidak dikenali."));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
            color: Colors.blueGrey[50],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blueGrey.shade100)
        ),
        child: Column(
          children: [
            // Label depan gerbong
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8)
              ),
              child: const Text("DEPAN", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
            ),
            const SizedBox(height: 16),
            // Denah kursi
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSeatColumn(kolomKiri, totalBaris, statusKursi), // Kolom Kiri
                _buildSeatColumn(kolomKanan, totalBaris, statusKursi), // Kolom Kanan
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeatColumn(List<String> columns, int totalRows, Map<String, String> statusKursi) {
    return Column(
      children: List.generate(totalRows, (rowIndex) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: columns.map((col) {
              final seatNumber = "${rowIndex + 1}$col";
              // Jika nomor kursi tidak ada di data (misal: gerbong 72 kursi, baris terakhir hanya ada 2 kursi)
              if (!statusKursi.containsKey(seatNumber)) {
                // Tampilkan kotak kosong sebagai placeholder
                return Container(margin: const EdgeInsets.all(4.0), width: 40, height: 40);
              }

              return _buildSeatWidget(seatNumber, statusKursi[seatNumber]!);
            }).toList(),
          ),
        );
      }),
    );
  }

  Widget _buildSeatWidget(String nomorKursi, String status) {
    final kursiPenuhId = "Gerbong ${widget.nomorGerbong} - Kursi $nomorKursi";
    final isSelectedByMe = _kursiDipilihSaatIni == nomorKursi;
    final isSelectedByGroup = !isSelectedByMe && widget.kursiYangSudahDipilihGrup.contains(kursiPenuhId);
    final isTaken = status == 'terisi';
    final isAvailable = !isTaken && !isSelectedByGroup && !isSelectedByMe;

    Color seatColor;
    Color borderColor;
    Color textColor;

    if (isTaken || isSelectedByGroup) {
      seatColor = Colors.grey.shade400;
      borderColor = Colors.grey.shade500;
      textColor = Colors.white;
    } else if (isSelectedByMe) {
      seatColor = Colors.orange;
      borderColor = Colors.deepOrange;
      textColor = Colors.white;
    } else { // Tersedia
      seatColor = Colors.white;
      borderColor = Colors.blue.shade300;
      textColor = Colors.blue.shade800;
    }

    return GestureDetector(
      onTap: () => _onKursiTap(nomorKursi, status),
      child: Container(
        margin: const EdgeInsets.all(4.0),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
            color: seatColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              if(isAvailable)
                BoxShadow(
                  color: Colors.blue.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
            ]
        ),
        child: Center(
          child: Text(
            nomorKursi,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGET HELPER LAINNYA ---

  Widget _buildPassengerHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Memilih Kursi Untuk:", style: TextStyle(color: Colors.black54, fontSize: 12)),
                Text(
                  widget.penumpangSaatIni.namaLengkap,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendaKursi() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      color: Colors.white,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 16.0,
        runSpacing: 8.0,
        children: [
          _legendaItem(Colors.white, Colors.blue.shade300, "Tersedia"),
          _legendaItem(Colors.orange, Colors.deepOrange, "Pilihan Anda"),
          _legendaItem(Colors.grey.shade400, Colors.grey.shade500, "Terisi"),
        ],
      ),
    );
  }

  Widget _legendaItem(Color bgColor, Color borderColor, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18, height: 18,
          decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: borderColor)
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildBottomBar(){
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Kursi Dipilih", style: TextStyle(color: Colors.grey)),
              Text(
                _kursiDipilihSaatIni ?? "Belum dipilih",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.check_circle),
            label: const Text("Simpan"),
            onPressed: _simpanPilihan,
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))
            ),
          ),
        ],
      ),
    );
  }
}