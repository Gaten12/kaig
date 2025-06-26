import 'package:flutter/material.dart';
import '../../../../models/JadwalModel.dart';
import '../../../../models/KeretaModel.dart';
import '../../../../models/gerbong_tipe_model.dart';
import '../../../../models/jadwal_kelas_info_model.dart';
import '../../../../widgets/pilih_kursi_layout_screen.dart';
import '../../../admin/services/admin_firestore_service.dart';
import 'DataPenumpangScreen.dart';

// Helper class (TIDAK PERLU DIUBAH)
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

  // Fungsi ini tidak perlu diubah
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
              final bool bisaDipilih = tipeGerbong.kelas.toLowerCase() == widget.kelasDipilih.namaKelas.toLowerCase();
              rangkaianLengkap.add(GerbongRangkaianInfo(
                nomorGerbong: rangkaianItem.nomorGerbong,
                tipeGerbong: tipeGerbong,
                isSelectable: bisaDipilih,
              ));
            } catch (e) {
              print('Tipe gerbong untuk ${rangkaianItem.idTipeGerbong} tidak ditemukan. Dilewati.');
            }
          }
          if (mounted) setState(() => _seluruhRangkaianInfo = rangkaianLengkap);
        }
      }
    } catch (e) {
      print("Error fetching kereta & gerbong: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Fungsi ini tidak perlu diubah
  void _pilihGerbong(GerbongRangkaianInfo gerbongInfo) {
    if (!gerbongInfo.isSelectable) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PilihKursiLayoutScreen(
          jadwalId: widget.jadwalDipesan.id,
          kelasInfo: widget.kelasDipilih,
          penumpangSaatIni: widget.penumpangSaatIni,
          kursiYangSudahDipilihGrup: widget.kursiYangSudahDipilihGrup,
          gerbong: gerbongInfo.tipeGerbong,
          nomorGerbong: gerbongInfo.nomorGerbong,
        ),
      ),
    ).then((hasilPilihKursi) {
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
        title: Text("Pilih Gerbong - ${widget.kelasDipilih.namaKelas}"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _seluruhRangkaianInfo.isEmpty
          ? const Center(child: Text("Rangkaian kereta tidak tersedia."))
          : _buildTrainLayoutVisual(),
    );
  }

  // WIDGET UTAMA UNTUK LAYOUT
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
                Text("Geser untuk melihat semua gerbong. Pilih gerbong yang menyala untuk menentukan kursi.", style: TextStyle(color: Colors.grey.shade700)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              // FIX 1: Gunakan CrossAxisAlignment.end agar semua item rata di bagian bawah.
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // FIX 2: Bungkus lokomotif dengan struktur yang sama seperti gerbong agar tingginya konsisten.
                _buildLocomotiveWidget(),
                const SizedBox(width: 8),
                ..._seluruhRangkaianInfo.map((info) => _buildCarriageImageWidget(info)).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET BARU UNTUK LOKOMOTIF
  Widget _buildLocomotiveWidget() {
    return Container(
      width: 150,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Container(
            height: 80,
            width: 150,
            child: Image.asset(
              'images/lokomotif.png',
              fit: BoxFit.contain, // Agar gambar tidak penyok
            ),
          ),
          const SizedBox(height: 8),
          // Sediakan ruang kosong yang sama tingginya dengan area label gerbong
          const SizedBox(
            height: 35,
            child: Text(
              "Lokomotif",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black54, // Warna sedikit redup
              ),
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET YANG DISEMPURNAKAN UNTUK GERBONG
  Widget _buildCarriageImageWidget(GerbongRangkaianInfo info) {
    final bool isSelectable = info.isSelectable;

    return GestureDetector(
      onTap: () => _pilihGerbong(info),
      child: Opacity(
        opacity: isSelectable ? 1.0 : 0.5,
        child: Container(
          width: 150, // Konsisten untuk setiap item
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            children: [
              // FIX 3: Gunakan Container dengan tinggi dan lebar tetap.
              // Lalu gunakan BoxFit.contain agar gambar pas tanpa distorsi.
              Container(
                height: 80,
                width: 150,
                child: Image.asset(
                  'images/${info.tipeGerbong.imageAssetPath}',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset('images/gerbong_default.png', fit: BoxFit.contain);
                  },
                ),
              ),
              const SizedBox(height: 8),

              // FIX 4: Bungkus Text dengan SizedBox bertinggi tetap.
              // Ini mencegah label yang panjang mendorong gambar ke atas.
              SizedBox(
                height: 35,
                child: Center(
                  child: Text(
                    "${info.tipeGerbong.kelas.toUpperCase()} ${info.nomorGerbong}",
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isSelectable ? Colors.black87 : Colors.grey.shade800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}