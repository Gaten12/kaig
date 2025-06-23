import 'package:flutter/material.dart';
import '../../../../models/JadwalModel.dart';
import '../../../../models/KeretaModel.dart';
import '../../../../models/gerbong_tipe_model.dart';
import '../../../../models/jadwal_kelas_info_model.dart';
import '../../../../widgets/pilih_kursi_layout_screen.dart';
import '../../../admin/services/admin_firestore_service.dart';
import 'DataPenumpangScreen.dart'; // Untuk mengambil data tipe gerbong


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
  List<GerbongTipeModel> _gerbongTersediaUntukKelasIni = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchKeretaDanGerbong();
  }

  Future<void> _fetchKeretaDanGerbong() async {
    try {
      final keretaSnapshot = await _service.keretaCollection.doc(widget.jadwalDipesan.idKereta).get();
      if (keretaSnapshot.exists) {
        _kereta = keretaSnapshot.data();
        if (_kereta != null) {
          // Ambil semua tipe gerbong
          final semuaTipeGerbong = await _service.getGerbongTipeList().first;
          // Filter gerbong yang sesuai dengan kelas yang dipilih customer
          _gerbongTersediaUntukKelasIni = _kereta!.rangkaian
              .map((rangkaianItem) {
            try {
              final tipeGerbong = semuaTipeGerbong.firstWhere((g) => g.id == rangkaianItem.idTipeGerbong);
              // Cocokkan kelas gerbong dengan kelas yang dipilih customer
              if (tipeGerbong.kelas.name == widget.kelasDipilih.namaKelas.toLowerCase()) {
                return MapEntry(rangkaianItem.nomorGerbong, tipeGerbong);
              }
              return null;
            } catch(e) { return null; }
          })
              .whereType<MapEntry<int, GerbongTipeModel>>()
              .map((entry) => entry.value) // Hanya ambil GerbongTipeModel
              .toList();
        }
      }
    } catch (e) {
      print("Error fetching kereta & gerbong: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _pilihGerbong(GerbongTipeModel gerbong) {
    // TODO: Cari nomor gerbong dari _kereta.rangkaian
    int nomorGerbong = _kereta?.rangkaian.firstWhere((r) => r.idTipeGerbong == gerbong.id).nomorGerbong ?? 0;
    if (nomorGerbong == 0) return; // Error handling

    Navigator.push(context, MaterialPageRoute(
        builder: (context) => PilihKursiLayoutScreen(
          jadwalId: widget.jadwalDipesan.id,
          kelasInfo: widget.kelasDipilih,
          penumpangSaatIni: widget.penumpangSaatIni,
          kursiYangSudahDipilihGrup: widget.kursiYangSudahDipilihGrup,
          gerbong: gerbong, // Kirim GerbongTipeModel
          nomorGerbong: nomorGerbong, // Kirim nomor gerbong
        )
    )).then((hasilPilihKursi) {
      if (hasilPilihKursi != null) {
        // Kembalikan hasil ke layar sebelumnya
        Navigator.pop(context, hasilPilihKursi);
      }
    });
  }

  // Helper method for responsive font sizes
  double _responsiveFontSize(double screenWidth, double baseSize) {
    if (screenWidth < 360) {
      return baseSize * 0.8; // Smaller for very small phones
    } else if (screenWidth < 600) {
      return baseSize; // Base size for phones
    } else if (screenWidth < 900) {
      return baseSize * 1.1; // Slightly larger for tablets
    } else {
      return baseSize * 1.2; // Even larger for desktops
    }
  }

  // Helper method for responsive icon sizes
  double _responsiveIconSize(double screenWidth, double baseSize) {
    if (screenWidth < 600) {
      return baseSize;
    } else if (screenWidth < 900) {
      return baseSize * 1.1;
    } else {
      return baseSize * 1.2;
    }
  }

  // Helper method for responsive horizontal padding
  double _responsiveHorizontalPadding(double screenWidth) {
    if (screenWidth > 1200) {
      return (screenWidth - 1000) / 2; // Center content for very large screens
    } else if (screenWidth > 600) {
      return 24.0; // Medium padding for tablets
    } else {
      return 16.0; // Standard padding for phones
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFC50000),
        foregroundColor: Colors.white,
        title: Text(
          "Pilih Gerbong - ${widget.kelasDipilih.namaKelas}",
          style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 20)),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(strokeWidth: _responsiveIconSize(screenWidth, 3)))
          : _gerbongTersediaUntukKelasIni.isEmpty
          ? Center(
        child: Padding(
          padding: EdgeInsets.all(_responsiveHorizontalPadding(screenWidth)),
          child: Text(
            "Tidak ada gerbong tersedia untuk kelas ini.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: _responsiveFontSize(screenWidth, 16), color: Colors.grey),
          ),
        ),
      )
          : ListView.builder(
        padding: EdgeInsets.all(_responsiveHorizontalPadding(screenWidth)),
        itemCount: _gerbongTersediaUntukKelasIni.length,
        itemBuilder: (context, index) {
          final gerbong = _gerbongTersediaUntukKelasIni[index];
          // Cari nomor gerbong ini di dalam rangkaian
          int nomorGerbong = _kereta?.rangkaian.firstWhere((r) => r.idTipeGerbong == gerbong.id).nomorGerbong ?? 0;

          return Card(
            margin: EdgeInsets.only(bottom: _responsiveFontSize(screenWidth, 12)),
            elevation: _responsiveFontSize(screenWidth, 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_responsiveFontSize(screenWidth, 12))),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(
                horizontal: _responsiveFontSize(screenWidth, 16),
                vertical: _responsiveFontSize(screenWidth, 8),
              ),
              title: Text(
                "${widget.kelasDipilih.namaKelas} ${nomorGerbong}",
                style: TextStyle(
                  fontSize: _responsiveFontSize(screenWidth, 18),
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                "${gerbong.subTipe}, Layout: ${gerbong.tipeLayout.deskripsi}",
                style: TextStyle(
                  fontSize: _responsiveFontSize(screenWidth, 14),
                  color: Colors.grey[700],
                ),
              ),
              trailing: Icon(Icons.arrow_forward_ios, size: _responsiveIconSize(screenWidth, 20)),
              onTap: () => _pilihGerbong(gerbong),
            ),
          );
        },
      ),
    );
  }
}