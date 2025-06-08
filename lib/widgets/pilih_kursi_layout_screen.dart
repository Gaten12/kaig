import 'package:flutter/material.dart';
import '../../../models/jadwal_kelas_info_model.dart';
import '../screens/customer/utama/DataPenumpangScreen.dart';

class PilihKursiLayoutScreen extends StatefulWidget {
  final String jadwalId;
  final JadwalKelasInfoModel kelasInfo;
  final PenumpangInputData penumpangSaatIni;
  final List<String> kursiYangSudahDipilihGrup; // Kursi yang dipilih penumpang lain di grup pemesanan ini

  const PilihKursiLayoutScreen({
    super.key,
    required this.jadwalId,
    required this.kelasInfo,
    required this.penumpangSaatIni,
    required this.kursiYangSudahDipilihGrup,
  });

  @override
  State<PilihKursiLayoutScreen> createState() => _PilihKursiLayoutScreenState();
}

class _PilihKursiLayoutScreenState extends State<PilihKursiLayoutScreen> {
  // Simulasi data kursi dan statusnya. Idealnya ini dari Firestore.
  // Kunci adalah nomor kursi ("1A"), value adalah status ("tersedia", "terisi").
  Map<String, String> _statusKursiSemua = {};
  String? _kursiDipilihSaatIni;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatusKursi();
  }

  Future<void> _loadStatusKursi() async {
    setState(() => _isLoading = true);
    // TODO: Implementasi pengambilan data kursi dari Firestore
    // Stream<List<KursiModel>> stream = _firestoreService.getKursiList(widget.jadwalId, widget.kelasInfo.idGerbong);
    // Untuk sekarang, kita gunakan data dummy
    await Future.delayed(const Duration(milliseconds: 500)); // Simulasi loading

    // Contoh denah eksekutif (11 baris, ABCD)
    final dummyStatus = <String, String>{};
    for (var row in List.generate(11, (i) => i + 1)) {
      for (var col in ['A', 'B', 'C', 'D']) {
        final seatNumber = "$row$col";
        // Simulasi beberapa kursi terisi
        if ((row == 2 && col == 'B') || (row == 5 && col == 'C') || (row == 8 && col == 'A')) {
          dummyStatus[seatNumber] = "terisi";
        } else {
          dummyStatus[seatNumber] = "tersedia";
        }
      }
    }

    if (mounted) {
      setState(() {
        _statusKursiSemua = dummyStatus;
        _isLoading = false;
      });
    }
  }

  void _onKursiTap(String nomorKursi, String status) {
    if (status != "tersedia") {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kursi $nomorKursi tidak tersedia.')),
      );
      return;
    }
    setState(() {
      _kursiDipilihSaatIni = nomorKursi;
    });
  }

  void _simpanPilihan() {
    if (_kursiDipilihSaatIni != null) {
      Navigator.pop(context, _kursiDipilihSaatIni);
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
              "${widget.kelasInfo.displayKelasLengkap}",
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _buildPassengerHeader(),
          _buildLegendaKursi(),
          Expanded(child: _buildSeatLayout()),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
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
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              ),
              child: const Text("Simpan"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPassengerHeader() {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).primaryColor),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            widget.penumpangSaatIni.namaLengkap,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const Text("Nomor Kursi", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildLegendaKursi() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _legendaItem(Colors.grey.shade200, "Tersedia"),
          _legendaItem(Theme.of(context).primaryColor, "Dipilih"),
          _legendaItem(Colors.grey.shade500, "Terisi"),
        ],
      ),
    );
  }

  Widget _legendaItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 18, height: 18, color: color),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }

  Widget _buildSeatLayout() {
    // Denah dummy sederhana 2-2 (ABCD)
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSeatColumn(['A', 'B']),
          const SizedBox(width: 24), // Gang
          _buildSeatColumn(['C', 'D']),
        ],
      ),
    );
  }

  Widget _buildSeatColumn(List<String> columns) {
    return Column(
      children: List.generate(11, (rowIndex) { // 11 baris kursi
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: columns.map((col) {
              final seatNumber = "${rowIndex + 1}$col";
              final status = _statusKursiSemua[seatNumber] ?? "terisi";
              bool isSelectedByMe = _kursiDipilihSaatIni == seatNumber;
              bool isSelectedByGroup = !isSelectedByMe && widget.kursiYangSudahDipilihGrup.contains(seatNumber);

              Color seatColor = Colors.grey.shade200; // Tersedia
              Color borderColor = Colors.grey.shade400;

              if (status == 'terisi') {
                seatColor = Colors.grey.shade500;
              } else if (isSelectedByGroup) {
                seatColor = Colors.orange.shade300; // Contoh warna untuk pilihan teman
              } else if (isSelectedByMe) {
                seatColor = Theme.of(context).primaryColor;
                borderColor = Theme.of(context).primaryColorDark;
              }

              return GestureDetector(
                onTap: () => _onKursiTap(seatNumber, status),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: seatColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      seatNumber,
                      style: TextStyle(
                        color: isSelectedByMe ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }),
    );
  }
}