import 'package:flutter/material.dart';
import '../../../models/jadwal_kelas_info_model.dart';
import '../models/gerbong_tipe_model.dart';
import '../models/kursi_model.dart';
import '../screens/admin/services/admin_firestore_service.dart';
import '../screens/customer/utama/DataPenumpangScreen.dart';

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
  String? _kursiDipilihSaatIni;

  void _onKursiTap(String nomorKursi, String status) {
    final fullSeatId = "Gerbong ${widget.nomorGerbong} - Kursi $nomorKursi";
    if (status == "terisi" || widget.kursiYangSudahDipilihGrup.contains(fullSeatId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kursi $nomorKursi tidak tersedia.')),
      );
      return;
    }
    setState(() {
      if (_kursiDipilihSaatIni == nomorKursi) {
        _kursiDipilihSaatIni = null;
      } else {
        _kursiDipilihSaatIni = nomorKursi;
      }
    });
  }

  void _simpanPilihan() {
    if (_kursiDipilihSaatIni != null) {
      final kursiTerpilihLengkap = "Gerbong ${widget.nomorGerbong} - Kursi ${_kursiDipilihSaatIni}";
      Navigator.pop(context, kursiTerpilihLengkap);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih satu kursi.')),
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
            const Text("Pilih Kursi", style: TextStyle(fontSize: 18)),
            Text(
              "${widget.gerbong.namaTipeLengkap} - Gerbong ${widget.nomorGerbong}",
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
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

                final statusKursiSemua = { for (var k in snapshot.data!) k.nomorKursi : k.status };

                return _buildSeatLayout(statusKursiSemua);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Theme.of(context).canvasColor,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), spreadRadius: 1, blurRadius: 5)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Kursi yang dipilih", style: TextStyle(color: Colors.grey)),
                Text(
                  _kursiDipilihSaatIni ?? "Belum dipilih",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: _simpanPilihan,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
              ),
              child: const Text("Simpan"),
            ),
          ],
        ),
      ),
    );
  }

  // --- IMPLEMENTASI METODE HELPER YANG HILANG ---
  Widget _buildPassengerHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).primaryColor),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              widget.penumpangSaatIni.namaLengkap,
              style: const TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Text("Nomor Kursi", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildLegendaKursi() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 16.0,
        runSpacing: 8.0,
        children: [
          _legendaItem(Colors.grey.shade200, "Tersedia"),
          _legendaItem(Theme.of(context).primaryColor, "Dipilih"),
          _legendaItem(Colors.orange.shade300, "Pilihan Anda"),
          _legendaItem(Colors.grey.shade500, "Terisi"),
        ],
      ),
    );
  }

  Widget _legendaItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16, height: 16,
          decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4)
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildSeatLayout(Map<String, String> statusKursi) {
    List<String> kolomKiri = [];
    List<String> kolomKanan = [];
    int totalBaris = 0;

    switch(widget.gerbong.tipeLayout) {
      case TipeLayoutGerbong.layout_2_2:
        kolomKiri = ['A', 'B'];
        kolomKanan = ['C', 'D'];
        totalBaris = (widget.gerbong.jumlahKursi / 4).ceil();
        break;
      case TipeLayoutGerbong.layout_3_2:
        kolomKiri = ['A', 'B', 'C'];
        kolomKanan = ['D', 'E'];
        totalBaris = (widget.gerbong.jumlahKursi / 5).ceil();
        break;
      case TipeLayoutGerbong.layout_2_1:
        kolomKiri = ['A', 'B'];
        kolomKanan = ['C'];
        totalBaris = (widget.gerbong.jumlahKursi / 3).ceil();
        break;
      case TipeLayoutGerbong.layout_1_1:
        kolomKiri = ['A'];
        kolomKanan = ['B'];
        totalBaris = (widget.gerbong.jumlahKursi / 2).ceil();
        break;
      default:
        return const Center(child: Text("Layout kursi tidak dikenali."));
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSeatColumn(kolomKiri, totalBaris, statusKursi),
            _buildSeatColumn(kolomKanan, totalBaris, statusKursi),
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
              if (!statusKursi.containsKey(seatNumber)) {
                return Container(margin: const EdgeInsets.symmetric(horizontal: 4.0), width: 40, height: 40);
              }

              final status = statusKursi[seatNumber]!;
              final fullSeatId = "Gerbong ${widget.nomorGerbong} - Kursi $seatNumber";
              bool isSelectedByMe = _kursiDipilihSaatIni == seatNumber;
              bool isSelectedByGroup = !isSelectedByMe && widget.kursiYangSudahDipilihGrup.contains(fullSeatId);

              Color seatColor = Colors.grey.shade200;
              Color borderColor = Colors.grey.shade400;
              Color textColor = Colors.black87;

              if (status == 'terisi') {
                seatColor = Colors.grey.shade500; textColor = Colors.white70;
              } else if (isSelectedByGroup) {
                seatColor = Colors.orange.shade300;
              } else if (isSelectedByMe) {
                seatColor = Theme.of(context).primaryColor;
                borderColor = Theme.of(context).primaryColorDark;
                textColor = Colors.white;
              }

              return GestureDetector(
                onTap: () => _onKursiTap(seatNumber, status),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: seatColor, borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor, width: 1.5),
                  ),
                  child: Center(child: Text(seatNumber, style: TextStyle(color: textColor, fontWeight: FontWeight.bold))),
                ),
              );
            }).toList(),
          ),
        );
      }),
    );
  }
}