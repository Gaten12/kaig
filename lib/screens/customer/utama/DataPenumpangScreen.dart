// --- File Utama: data_penumpang_screen.dart (Revisi Besar) ---
// Path: lib/src/pembelian_tiket/screens/data_penumpang_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/JadwalModel.dart';
import '../../../models/jadwal_kelas_info_model.dart';
import '../../../models/user_model.dart';
import '../../../models/passenger_model.dart';
import '../../../services/auth_service.dart';
// Impor widget bottom sheet dari file terpisah
import '../../../widgets/pilih_penumpang_bottom_sheet.dart';
// Impor layar selanjutnya
import 'pilih_kursi_step_screen.dart';

class PenumpangInputData {
  PassengerModel? passenger;

  PenumpangInputData({
    this.passenger,
  });

  String get namaLengkap => passenger?.namaLengkap ?? "";
  String get tipeId => passenger?.tipeId ?? "";
  String get nomorId => passenger?.nomorId ?? "";
  bool get isFilled => passenger != null;
}

class DataPenumpangScreen extends StatefulWidget {
  final JadwalModel jadwalDipesan;
  final JadwalKelasInfoModel kelasDipilih;
  final DateTime tanggalBerangkat;
  final int jumlahDewasa;
  final int jumlahBayi;

  const DataPenumpangScreen({
    super.key,
    required this.jadwalDipesan,
    required this.kelasDipilih,
    required this.tanggalBerangkat,
    required this.jumlahDewasa,
    required this.jumlahBayi,
  });

  @override
  State<DataPenumpangScreen> createState() => _DataPenumpangScreenState();
}

class _DataPenumpangScreenState extends State<DataPenumpangScreen> {
  final _formKeyPemesanan = GlobalKey<FormState>();

  final _namaPemesanController = TextEditingController();
  final _emailPemesanController = TextEditingController();
  final _teleponPemesanController = TextEditingController();
  bool _pemesanSebagaiPenumpang = true;

  late List<PenumpangInputData> _dataPenumpangList;

  final AuthService _authService = AuthService();
  PassengerModel? _primaryPassenger;

  @override
  void initState() {
    super.initState();
    _initializeDataPenumpang();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return;

    try {
      final results = await Future.wait([
        _authService.getUserModel(firebaseUser.uid),
        _authService.getPrimaryPassenger(firebaseUser.uid),
      ]);

      final userModel = results[0] as UserModel?;
      final primaryPassenger = results[1] as PassengerModel?;

      if (!mounted) return;

      // Isi Detail Pemesan
      _emailPemesanController.text = firebaseUser.email ?? '';
      _teleponPemesanController.text = userModel?.noTelepon ?? '';
      // PERBAIKAN: Nama pemesan diambil dari primaryPassenger, dengan fallback ke display name
      // Tidak lagi menggunakan userModel.namaLengkap
      _namaPemesanController.text = primaryPassenger?.namaLengkap ?? firebaseUser.displayName ?? (firebaseUser.email?.split('@')[0] ?? '');

      // Simpan data penumpang utama untuk pengisian otomatis
      _primaryPassenger = primaryPassenger;

      // Isi penumpang pertama jika switch aktif
      if (_pemesanSebagaiPenumpang) {
        _updatePenumpangPertamaDenganDataPrimaryPassenger();
      }
    } catch (e) {
      print("Error memuat data awal: $e");
      if(mounted) {
        // Fallback jika terjadi error saat pengambilan data
        _emailPemesanController.text = firebaseUser.email ?? '';
        _namaPemesanController.text = firebaseUser.displayName ?? '';
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _initializeDataPenumpang() {
    _dataPenumpangList = List.generate(
      widget.jumlahDewasa,
          (index) => PenumpangInputData(),
    );
  }

  void _updatePenumpangPertamaDenganDataPrimaryPassenger() {
    if (widget.jumlahDewasa > 0 && _dataPenumpangList.isNotEmpty && _primaryPassenger != null) {
      setState(() {
        _dataPenumpangList[0] = PenumpangInputData(passenger: _primaryPassenger);
      });
    }
  }

  void _clearPenumpangPertama() {
    if (widget.jumlahDewasa > 0 && _dataPenumpangList.isNotEmpty) {
      setState(() {
        _dataPenumpangList[0] = PenumpangInputData();
      });
    }
  }


  @override
  void dispose() {
    _namaPemesanController.dispose();
    _emailPemesanController.dispose();
    _teleponPemesanController.dispose();
    super.dispose();
  }

  void _showPilihPenumpangSheet(int indexPenumpangForm) async {
    final PassengerModel? selectedPassenger = await showModalBottomSheet<PassengerModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (_, controller) {
            return PilihPenumpangBottomSheet(
              scrollController: controller,
              penumpangSudahDipilih: _dataPenumpangList
                  .map((p) => p.passenger)
                  .whereType<PassengerModel>()
                  .toList(),
            );
          },
        );
      },
    );

    if (selectedPassenger != null && mounted) {
      setState(() {
        _dataPenumpangList[indexPenumpangForm] = PenumpangInputData(passenger: selectedPassenger);

        if (indexPenumpangForm == 0) {
          if (selectedPassenger.id != _primaryPassenger?.id) {
            _pemesanSebagaiPenumpang = false;
          } else {
            _pemesanSebagaiPenumpang = true;
          }
        }
      });
    }
  }


  void _lanjutkan() {
    if (!(_formKeyPemesanan.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap lengkapi Detail Pemesan dengan benar.')),
      );
      return;
    }

    for (int i = 0; i < _dataPenumpangList.length; i++) {
      if (!_dataPenumpangList[i].isFilled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Harap lengkapi data untuk Penumpang Dewasa ${i + 1}.')),
        );
        return;
      }
    }

    print("VALIDASI BERHASIL, LANJUT KE PILIH KURSI");

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PilihKursiStepScreen(
          jadwalDipesan: widget.jadwalDipesan,
          kelasDipilih: widget.kelasDipilih,
          dataPenumpangList: _dataPenumpangList,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pesan Tiket"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: LinearProgressIndicator(
            value: 0.5,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
          ),
        ),
      ),
      body: Form(
        key: _formKeyPemesanan,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            const Text("1. Data Penumpang", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20.0),
            _buildDetailPemesananSection(),
            const SizedBox(height: 24.0),
            _buildDetailPenumpangSection(),
            const SizedBox(height: 32.0),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25)),
              ),
              onPressed: _lanjutkan,
              child: const Text("LANJUTKAN",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDetailPemesananSection() {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Detail Pemesan",
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: _namaPemesanController,
              decoration: const InputDecoration(labelText: "Nama Lengkap", border: OutlineInputBorder()),
              validator: (value) => (value == null || value.isEmpty) ? "Nama tidak boleh kosong" : null,
            ),
            const SizedBox(height: 12.0),
            TextFormField(
              controller: _emailPemesanController,
              decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder()),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) return "Email tidak boleh kosong";
                if (!value.contains('@') || !value.contains('.')) return "Format email tidak valid";
                return null;
              },
            ),
            const SizedBox(height: 12.0),
            TextFormField(
              controller: _teleponPemesanController,
              decoration: const InputDecoration(labelText: "No. Telepon", border: OutlineInputBorder()),
              keyboardType: TextInputType.phone,
              validator: (value) => (value == null || value.isEmpty) ? "No. telepon tidak boleh kosong" : null,
            ),
            SwitchListTile(
              title: const Text("Tambahkan sebagai penumpang"),
              value: _pemesanSebagaiPenumpang,
              onChanged: (bool value) {
                setState(() {
                  _pemesanSebagaiPenumpang = value;
                  if (_pemesanSebagaiPenumpang) {
                    _updatePenumpangPertamaDenganDataPrimaryPassenger();
                  } else {
                    _clearPenumpangPertama();
                  }
                });
              },
              contentPadding: EdgeInsets.zero,
              activeColor: Theme.of(context).primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailPenumpangSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Detail Penumpang",
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8.0),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.jumlahDewasa,
          itemBuilder: (context, index) {
            return _buildPenumpangCard(index);
          },
        ),
        if (widget.jumlahBayi > 0)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Text(
              "Catatan: Data untuk ${widget.jumlahBayi} bayi akan diisi setelah ini.",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
      ],
    );
  }

  Widget _buildPenumpangCard(int index) {
    final penumpangData = _dataPenumpangList[index];
    bool isDataFilled = penumpangData.isFilled;

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Penumpang ${index + 1} (Dewasa)", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 4),
                  if (isDataFilled) ...[
                    Text(penumpangData.namaLengkap, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text("${penumpangData.tipeId} - ${penumpangData.nomorId}", style: const TextStyle(fontSize: 14, color: Colors.black54)),
                  ] else ...[
                    const Text("Informasi Penumpang", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
                  ]
                ],
              ),
            ),
            TextButton(
              onPressed: () => _showPilihPenumpangSheet(index),
              child: Text(isDataFilled ? "Ubah" : "Pilih"),
            )
          ],
        ),
      ),
    );
  }
}
