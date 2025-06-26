import 'package:flutter/material.dart';
import '../../../../models/JadwalModel.dart';
import '../../../../models/KeretaModel.dart';
import '../../../../models/gerbong_tipe_model.dart';
import '../../../../models/jadwal_kelas_info_model.dart';
import '../../../../widgets/pilih_kursi_layout_screen.dart';
import '../../../admin/services/admin_firestore_service.dart';
import 'DataPenumpangScreen.dart';

// Helper class ini tidak perlu diubah
class GerbongRangkaianInfo {
  final int nomorGerbong;
  final GerbongTipeModel tipeGerbong;
  final bool isSelectable;

  GerbongRangkaianInfo({
    required this.nomorGerbong,
    required this.tipeGerbong,
    required this.isSelectable,
  });
}

class PilihGerbongScreen extends StatefulWidget {
  final JadwalModel jadwalDipesan;
  final JadwalKelasInfoModel kelasDipilih;
  final PenumpangInputData penumpangSaatIni;
  final List<String> kursiYangSudahDipilihGrup;

  const PilihGerbongScreen({
    super.key,
    required this.jadwalDipesan,
    required this.kelasDipilih,
    required this.penumpangSaatIni,
    required this.kursiYangSudahDipilihGrup,
  });

  @override
  State<PilihGerbongScreen> createState() => _PilihGerbongScreenState();
}

class _PilihGerbongScreenState extends State<PilihGerbongScreen> {
  final AdminFirestoreService _service = AdminFirestoreService();
  KeretaModel? _kereta;
  List<GerbongRangkaianInfo> _seluruhRangkaianInfo = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchKeretaDanRangkaianLengkap();
  }

  // Fungsi ini tidak perlu diubah, logikanya sudah benar
  Future<void> _fetchKeretaDanRangkaianLengkap() async {
    try {
      final keretaSnapshot = await _service.keretaCollection.doc(widget.jadwalDipesan.idKereta).get();
      if (keretaSnapshot.exists) {
        _kereta = keretaSnapshot.data();
        if (_kereta != null) {
          final semuaTipeGerbong = await _service.getGerbongTipeList().first;

          List<GerbongRangkaianInfo> rangkaianLengkap = [];
          for (var rangkaianItem in _kereta!.rangkaian) {
            try {
              final tipeGerbong = semuaTipeGerbong.firstWhere((g) => g.id == rangkaianItem.idTipeGerbong);
              // Logika penting untuk menentukan gerbong mana yang bisa dipilih berdasarkan kelas
              final bool bisaDipilih = tipeGerbong.kelas.toLowerCase() == widget.kelasDipilih.namaKelas.toLowerCase();

              rangkaianLengkap.add(
                  GerbongRangkaianInfo(
                    nomorGerbong: rangkaianItem.nomorGerbong,
                    tipeGerbong: tipeGerbong,
                    isSelectable: bisaDipilih,
                  )
              );
            } catch (e) {
              print('Tipe gerbong untuk ${rangkaianItem.idTipeGerbong} tidak ditemukan. Dilewati.');
            }
          }
          setState(() => _seluruhRangkaianInfo = rangkaianLengkap);
        }
      }
    } catch (e) {
      print("Error fetching kereta & gerbong: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Fungsi ini tidak perlu diubah, navigasi sudah benar
  void _pilihGerbong(GerbongRangkaianInfo gerbongInfo) {
    if (!gerbongInfo.isSelectable) return;

    Navigator.push(context, MaterialPageRoute(
        builder: (context) => PilihKursiLayoutScreen(
          jadwalId: widget.jadwalDipesan.id,
          kelasInfo: widget.kelasDipilih,
          penumpangSaatIni: widget.penumpangSaatIni,
          kursiYangSudahDipilihGrup: widget.kursiYangSudahDipilihGrup,
          gerbong: gerbongInfo.tipeGerbong,
          nomorGerbong: gerbongInfo.nomorGerbong,
        )
    )).then((hasilPilihKursi) {
      if (hasilPilihKursi != null) {
        Navigator.pop(context, hasilPilihKursi);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: const Color(0xFFC50000),
          foregroundColor: Colors.white,
          title: Text("Pilih Gerbong - ${widget.kelasDipilih.namaKelas}")
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _seluruhRangkaianInfo.isEmpty
          ? const Center(child: Text("Rangkaian kereta tidak tersedia."))
      // [MODIFIKASI] Kita panggil widget _buildTrainLayoutVisual yang baru
          : _buildTrainLayoutVisual(),
    );
  }

  // --- WIDGET YANG DIMODIFIKASI UNTUK TAMPILAN VISUAL BARU ---

  Widget _buildTrainLayoutVisual() {
    return Container(
      alignment: Alignment.center,
      color: Colors.blueGrey.shade50,
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Denah Rangkaian Kereta", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                // [MODIFIKASI] Teks instruksi disesuaikan
                Text("Geser untuk melihat semua gerbong. Pilih gerbong yang menyala untuk menentukan kursi.", style: TextStyle(color: Colors.grey.shade700)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // [MODIFIKASI] Menggunakan SingleChildScrollView untuk menampung gambar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // [BARU] Widget lokomotif menggunakan gambar
                Image.asset('images/lokomotif.png', height: 80, fit: BoxFit.contain),
                const SizedBox(width: 8),
                // [MODIFIKASI] Mapping ke widget visual yang baru
                ..._seluruhRangkaianInfo.map((info) => _buildCarriageImageWidget(info)).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // [BARU] Widget untuk menampilkan gambar gerbong
  Widget _buildCarriageImageWidget(GerbongRangkaianInfo info) {
    final bool isSelectable = info.isSelectable;

    return GestureDetector(
      onTap: () => _pilihGerbong(info),
      child: Opacity(
        // Gerbong yang tidak bisa dipilih akan diredupkan
        opacity: isSelectable ? 1.0 : 0.5,
        child: Container(
          width: 150,
          height: 110,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Gambar Gerbong
              Expanded(
                child: Image.asset(
                  'images/${info.tipeGerbong.imageAssetPath}',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback jika gambar tidak ditemukan
                    return Image.asset('images/gerbong_default.png');
                  },
                ),
              ),
              const SizedBox(height: 4),
              // Teks Label di bawah gambar
              Text(
                "${info.tipeGerbong.kelas.toUpperCase()} ${info.nomorGerbong}",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  // Warna teks lebih kontras
                  color: isSelectable ? Colors.black87 : Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}