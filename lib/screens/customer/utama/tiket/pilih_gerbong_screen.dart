import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import '../../../../models/JadwalModel.dart';
import '../../../../models/KeretaModel.dart';
import '../../../../models/gerbong_tipe_model.dart';
import '../../../../models/jadwal_kelas_info_model.dart';
import '../../../../widgets/pilih_kursi_layout_screen.dart';
import '../../../admin/services/admin_firestore_service.dart';
import 'DataPenumpangScreen.dart';

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
              final bool bisaDipilih = tipeGerbong.kelas.name.toLowerCase() == widget.kelasDipilih.namaKelas.toLowerCase();

              rangkaianLengkap.add(
                  GerbongRangkaianInfo(
                    nomorGerbong: rangkaianItem.nomorGerbong,
                    tipeGerbong: tipeGerbong,
                    isSelectable: bisaDipilih,
                  )
              );
            } catch (e) {
              // Abaikan jika tipe gerbong tidak ditemukan
            }
          }
          _seluruhRangkaianInfo = rangkaianLengkap;
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
          : _buildTrainLayout(),
    );
  }

  Widget _buildTrainLayout() {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Denah Rangkaian Kereta", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text("Geser untuk melihat semua gerbong. Pilih gerbong berwarna untuk menentukan kursi.", style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                _buildLocomotiveWidget(),
                ..._seluruhRangkaianInfo.map((info) => _buildCarriageWidget(info)).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocomotiveWidget() {
    return Row(
      children: [
        Container(
          width: 120,
          height: 80,
          decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  bottomLeft: Radius.circular(15),
                  topRight: Radius.circular(5),
                  bottomRight: Radius.circular(5)
              ),
              border: Border.all(color: Colors.black54, width: 2)
          ),
          child: const Center(child: Text("LOKO\nMOTIF", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ),
        _buildCoupler(),
      ],
    );
  }

  Widget _buildCarriageWidget(GerbongRangkaianInfo info) {
    final bool isSelectable = info.isSelectable;
    final Color primaryColor = isSelectable ? const Color(0xFFC50000) : Colors.grey.shade500;
    final Color secondaryColor = isSelectable ? Colors.red.shade100 : Colors.grey.shade300;

    return Row(
      children: [
        GestureDetector(
          onTap: () => _pilihGerbong(info),
          child: Container(
            width: 120,
            height: 80,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: secondaryColor,
              border: Border.all(color: primaryColor, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "${info.tipeGerbong.kelas.name.toUpperCase()} ${info.nomorGerbong}",
                  style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  info.tipeGerbong.subTipe,
                  style: TextStyle(
                    color: primaryColor.withAlpha((255 * 0.8).round()),
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                )
              ],
            ),
          ),
        ),
        _buildCoupler(),
      ],
    );
  }

  Widget _buildCoupler() {
    // KODE YANG SUDAH DIPERBAIKI (TANPA MARGIN NEGATIF)
    return Container(
      width: 10,
      height: 20,
      decoration: BoxDecoration(
        color: Colors.grey.shade600,
        border: Border.all(color: Colors.black54),
      ),
    );
  }
}