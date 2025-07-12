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
          if (mounted) setState(() => _seluruhRangkaianInfo = rangkaianLengkap);
        }
      }
    } catch (e) {
      print("Error fetching kereta & gerbong: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _pilihGerbong(GerbongRangkaianInfo gerbongInfo) {
    if (!gerbongInfo.isSelectable) return;

    Navigator.push(context, MaterialPageRoute(
        builder: (context) =>
            PilihKursiLayoutScreen(
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
      body: Container(
        // Menambahkan ukuran agar Container memenuhi layar
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("images/Simulasi.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _seluruhRangkaianInfo.isEmpty
            ? const Center(child: Text("Rangkaian kereta tidak tersedia."))
            : _buildTrainLayoutVisual(),
      ),
    );
  }

  Widget _buildTrainLayoutVisual() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background image sudah dari parent
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Denah Rangkaian Kereta",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black.withAlpha(204),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Geser untuk melihat semua gerbong. Pilih gerbong yang menyala untuk menentukan kursi.",
                    style: TextStyle(color: Colors.grey.shade800),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 229),
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildLocomotiveWidget(),
                    ..._seluruhRangkaianInfo.map(_buildCarriageImageWidget).toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }


  Widget _buildLocomotiveWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Column(
        children: [
          Image.asset(
            'images/lokomotif.png',
            height: 80,
            fit: BoxFit.contain,
            gaplessPlayback: true,
          ),
          const SizedBox(height: 8),
          const SizedBox(
            height: 35,
            child: Center(
              child: Text(
                "Lokomotif",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarriageImageWidget(GerbongRangkaianInfo info) {
    final bool isSelectable = info.isSelectable;

    return GestureDetector(
      onTap: () => _pilihGerbong(info),
      child: Opacity(
        opacity: isSelectable ? 1.0 : 0.5,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: Column(
            children: [
              Image.asset(
                'images/${info.tipeGerbong.imageAssetPath}',
                height: 80,
                fit: BoxFit.contain,
                gaplessPlayback: true,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 80,
                    width: 120,
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image),
                  );
                },
              ),
              const SizedBox(height: 8),
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