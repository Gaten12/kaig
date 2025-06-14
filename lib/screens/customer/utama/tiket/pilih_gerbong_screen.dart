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
          : _gerbongTersediaUntukKelasIni.isEmpty
          ? const Center(child: Text("Tidak ada gerbong tersedia untuk kelas ini."))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _gerbongTersediaUntukKelasIni.length,
        itemBuilder: (context, index) {
          final gerbong = _gerbongTersediaUntukKelasIni[index];
          // Cari nomor gerbong ini di dalam rangkaian
          int nomorGerbong = _kereta?.rangkaian.firstWhere((r) => r.idTipeGerbong == gerbong.id).nomorGerbong ?? 0;

          return Card(
            child: ListTile(
              title: Text("${widget.kelasDipilih.namaKelas} ${nomorGerbong}"),
              subtitle: Text("${gerbong.subTipe}, Layout: ${gerbong.tipeLayout.deskripsi}"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _pilihGerbong(gerbong),
            ),
          );
        },
      ),
    );
  }
}