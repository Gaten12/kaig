import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/JadwalModel.dart';
import '../../../models/jadwal_kelas_info_model.dart';
import '../../../models/user_model.dart';
import '../../../models/passenger_model.dart'; // Impor PassengerModel
import '../../../services/auth_service.dart'; // Impor AuthService

class PenumpangInputData {
  String namaLengkap;
  String? tipeId;
  String? nomorId;
  // Tambahkan field lain jika perlu disalin dari PassengerModel
  // String? jenisKelamin;
  // DateTime? tanggalLahir;

  PenumpangInputData({
    this.namaLengkap = "",
    this.tipeId,
    this.nomorId,
    // this.jenisKelamin,
    // this.tanggalLahir
  });
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
  late List<GlobalKey<FormState>> _formKeysPenumpang;

  final List<String> _tipeIdOptions = ['KTP', 'Paspor', 'SIM', 'Lainnya'];

  // Tidak lagi menyimpan _currentUserModel secara langsung jika data utama dari passenger
  // Cukup simpan data yang akan disalin ke penumpang pertama
  String? _dataPemesanNamaLengkap;
  String? _dataPemesanTipeId;
  String? _dataPemesanNomorId;
  // Tambahkan state lain jika perlu dari PassengerModel (misal tanggal lahir, jenis kelamin)

  final AuthService _authService = AuthService(); // Instance AuthService

  @override
  void initState() {
    super.initState();
    _initializeDataPenumpang();
    _loadDataPemesanDanPenumpangUtama();
  }

  Future<void> _loadDataPemesanDanPenumpangUtama() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    bool dataPemesananBerubah = false;

    if (firebaseUser != null) {
      // 1. Isi email dari FirebaseAuth
      if (_emailPemesanController.text != (firebaseUser.email ?? "")) {
        _emailPemesanController.text = firebaseUser.email ?? "";
        dataPemesananBerubah = true;
      }

      // 2. Ambil UserModel untuk nama dan telepon pemesan
      try {
        UserModel? userModel = await _authService.getUserModel(firebaseUser.uid);
        if (userModel != null) {
          if (_namaPemesanController.text != userModel.namaLengkap) {
            _namaPemesanController.text = userModel.namaLengkap;
            dataPemesananBerubah = true;
          }
          if (_teleponPemesanController.text != userModel.noTelepon) {
            _teleponPemesanController.text = userModel.noTelepon;
            dataPemesananBerubah = true;
          }
          // Simpan nama pemesan untuk disalin jika switch aktif
          _dataPemesanNamaLengkap = userModel.namaLengkap;
        } else {
          print("Dokumen UserModel tidak ditemukan untuk UID: ${firebaseUser.uid}");
          if (_namaPemesanController.text != (firebaseUser.displayName ?? "")) {
            _namaPemesanController.text = firebaseUser.displayName ?? "";
            _dataPemesanNamaLengkap = firebaseUser.displayName ?? "";
            dataPemesananBerubah = true;
          }
        }
      } catch (e) {
        print("Error memuat UserModel dari Firestore: $e");
        if (_namaPemesanController.text != (firebaseUser.displayName ?? "")) {
          _namaPemesanController.text = firebaseUser.displayName ?? "";
          _dataPemesanNamaLengkap = firebaseUser.displayName ?? "";
          dataPemesananBerubah = true;
        }
      }

      // 3. Ambil data penumpang utama (isPrimary: true) dari subkoleksi 'passengers'
      try {
        PassengerModel? primaryPassenger = await _authService.getPrimaryPassenger(firebaseUser.uid);
        if (primaryPassenger != null) {
          // Simpan data penumpang utama untuk disalin jika switch aktif
          // Jika nama pemesan di UserModel berbeda dengan nama di primaryPassenger,
          // Anda bisa pilih salah satu sebagai sumber utama untuk _namaPemesanController,
          // atau biarkan _namaPemesanController dari UserModel.
          // Untuk sinkronisasi ke form penumpang, kita gunakan data dari primaryPassenger.
          _dataPemesanNamaLengkap = primaryPassenger.namaLengkap; // Timpa jika ada dari passenger
          _dataPemesanTipeId = primaryPassenger.tipeId;
          _dataPemesanNomorId = primaryPassenger.nomorId;
          // Anda juga bisa mengambil primaryPassenger.tanggalLahir, primaryPassenger.jenisKelamin jika perlu

          // Jika nama pemesan belum terisi dari UserModel, isi dari primaryPassenger
          if (_namaPemesanController.text.isEmpty && primaryPassenger.namaLengkap.isNotEmpty) {
            _namaPemesanController.text = primaryPassenger.namaLengkap;
            dataPemesananBerubah = true;
          }
          // Tandai bahwa data pemesan (terutama ID) mungkin berubah
          dataPemesananBerubah = true;
        } else {
          print("Data Penumpang Utama (isPrimary:true) tidak ditemukan.");
          // Jika tidak ada primary passenger, _dataPemesanTipeId dan _dataPemesanNomorId akan tetap null
        }
      } catch (e) {
        print("Error memuat Primary Passenger dari Firestore: $e");
      }
    }

    // Panggil update setelah semua data pemesan (nama, email, telepon, TipeID, NoID) terkumpul
    if (dataPemesananBerubah) {
      if (_pemesanSebagaiPenumpang && widget.jumlahDewasa > 0) {
        _updatePenumpangPertamaDariDataPemesan(panggilSetState: false);
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
    _formKeysPenumpang =
        List.generate(widget.jumlahDewasa, (index) => GlobalKey<FormState>());
  }

  // Diubah namanya agar lebih jelas
  void _updatePenumpangPertamaDariDataPemesan({bool panggilSetState = true}) {
    if (widget.jumlahDewasa > 0 && _dataPenumpangList.isNotEmpty) {
      bool changed = false;
      // Salin dari _dataPemesanNamaLengkap, _dataPemesanTipeId, _dataPemesanNomorId
      if (_dataPenumpangList[0].namaLengkap != (_dataPemesanNamaLengkap ?? "")) {
        _dataPenumpangList[0].namaLengkap = _dataPemesanNamaLengkap ?? "";
        changed = true;
      }

      String? validPemesanTipeId = _dataPemesanTipeId;
      if (_dataPemesanTipeId != null && !_tipeIdOptions.contains(_dataPemesanTipeId)) {
        print("Peringatan: Tipe ID pemesan '$_dataPemesanTipeId' tidak ada di opsi dropdown.");
        validPemesanTipeId = null;
      }
      if (_dataPenumpangList[0].tipeId != validPemesanTipeId) {
        _dataPenumpangList[0].tipeId = validPemesanTipeId;
        changed = true;
      }

      if (_dataPenumpangList[0].nomorId != (_dataPemesanNomorId ?? "")) {
        _dataPenumpangList[0].nomorId = _dataPemesanNomorId; // Bisa null
        changed = true;
      }

      if (changed && panggilSetState && mounted) {
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _namaPemesanController.dispose();
    _emailPemesanController.dispose();
    _teleponPemesanController.dispose();
    super.dispose();
  }

  void _lanjutkan() { /* ... (logika _lanjutkan tetap sama) ... */ }

  @override
  Widget build(BuildContext context) { /* ... (Widget build bagian atas tetap sama) ... */
    return Scaffold(
      appBar: AppBar(
        title: const Text("Data Penumpang"),
        elevation: 1.0,
      ),
      body: Form(
        key: _formKeyPemesanan,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Text(
              "Lengkapi Detail Pemesan & Penumpang",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor),
            ),
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
              decoration: const InputDecoration(
                  labelText: "Nama Lengkap", border: OutlineInputBorder()),
              validator: (value) =>
              (value == null || value.isEmpty) ? "Nama tidak boleh kosong" : null,
              onChanged: (value) {
                // Update _dataPemesanNamaLengkap jika pengguna mengedit field pemesan
                _dataPemesanNamaLengkap = value;
                if (_pemesanSebagaiPenumpang) {
                  _updatePenumpangPertamaDariDataPemesan();
                }
              },
            ),
            const SizedBox(height: 12.0),
            TextFormField(
              controller: _emailPemesanController,
              decoration: const InputDecoration(
                  labelText: "Email", border: OutlineInputBorder()),
              keyboardType: TextInputType.emailAddress,
              // Email biasanya tidak diubah oleh pengguna di sini, jadi onChanged tidak perlu
              validator: (value) {
                if (value == null || value.isEmpty) return "Email tidak boleh kosong";
                if (!value.contains('@') || !value.contains('.')) {
                  return "Format email tidak valid";
                }
                return null;
              },
            ),
            const SizedBox(height: 12.0),
            TextFormField(
              controller: _teleponPemesanController,
              decoration: const InputDecoration(
                  labelText: "No. Telepon", border: OutlineInputBorder()),
              keyboardType: TextInputType.phone,
              validator: (value) => (value == null || value.isEmpty)
                  ? "No. telepon tidak boleh kosong"
                  : null,
            ),
            SwitchListTile(
              title: const Text("Data pemesan sama dengan penumpang pertama"),
              value: _pemesanSebagaiPenumpang,
              onChanged: (bool value) {
                setState(() {
                  _pemesanSebagaiPenumpang = value;
                  if (_pemesanSebagaiPenumpang) {
                    // Panggil update dengan panggilSetState: false karena setState luar sudah ada
                    _updatePenumpangPertamaDariDataPemesan(panggilSetState: false);
                  }
                  // Jika switch dimatikan, penumpang pertama tidak lagi disinkronkan.
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

  Widget _buildDetailPenumpangSection() { /* ... (Tetap sama) ... */
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Detail Penumpang Dewasa",
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8.0),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.jumlahDewasa,
          itemBuilder: (context, index) {
            return _buildFormInputPenumpang(index);
          },
          separatorBuilder: (context, index) => const SizedBox(height: 16),
        ),
        if (widget.jumlahBayi > 0)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Text(
              "Catatan: ${widget.jumlahBayi} penumpang bayi tidak memerlukan input data detail di tahap ini (tidak mendapat kursi sendiri). Nama bayi mungkin akan diminta pada tahap selanjutnya.",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
      ],
    );
  }

  Widget _buildFormInputPenumpang(int index) {
    String title = "Penumpang Dewasa ${index + 1}";

    // ValueKey sekarang menggunakan _dataPenumpangList untuk memicu rebuild
    Key namaPenumpangKey = ValueKey('nama_penumpang_$index${_dataPenumpangList[index].namaLengkap}');
    Key tipeIdPenumpangKey = ValueKey('tipe_id_penumpang_$index${_dataPenumpangList[index].tipeId}');
    Key nomorIdPenumpangKey = ValueKey('nomor_id_penumpang_$index${_dataPenumpangList[index].nomorId}');

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKeysPenumpang[index],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              TextFormField(
                key: namaPenumpangKey,
                initialValue: _dataPenumpangList[index].namaLengkap,
                decoration: const InputDecoration(
                    labelText: "Nama Lengkap", border: OutlineInputBorder()),
                validator: (value) =>
                (value == null || value.isEmpty) ? "Nama tidak boleh kosong" : null,
                onSaved: (value) => _dataPenumpangList[index].namaLengkap = value ?? "",
                onChanged: (value){
                  // Update model langsung
                  _dataPenumpangList[index].namaLengkap = value;
                  // Jika ini penumpang pertama dan switch aktif, tapi pengguna mengubahnya,
                  // kita bisa nonaktifkan switch untuk mencegah penimpaan otomatis lebih lanjut
                  // atau biarkan saja, tergantung UX yang diinginkan.
                  if (index == 0 && _pemesanSebagaiPenumpang && value != _dataPemesanNamaLengkap) {
                    if (mounted) {
                      // setState(() {
                      //   _pemesanSebagaiPenumpang = false;
                      // });
                    }
                  }
                },
              ),
              const SizedBox(height: 12.0),
              DropdownButtonFormField<String>(
                key: tipeIdPenumpangKey,
                decoration: const InputDecoration(
                    labelText: "Tipe ID", border: OutlineInputBorder()),
                value: _dataPenumpangList[index].tipeId,
                items: _tipeIdOptions.map((String value) {
                  return DropdownMenuItem<String>(
                      value: value, child: Text(value));
                }).toList(),
                onChanged: (value) {
                  if (mounted) {
                    setState(() {
                      _dataPenumpangList[index].tipeId = value;
                    });
                  }
                },
                onSaved: (value) => _dataPenumpangList[index].tipeId = value,
                validator: (value) =>
                (value == null || value.isEmpty) ? "Pilih tipe ID" : null,
              ),
              const SizedBox(height: 12.0),
              TextFormField(
                key: nomorIdPenumpangKey,
                initialValue: _dataPenumpangList[index].nomorId,
                decoration: const InputDecoration(
                    labelText: "Nomor ID", border: OutlineInputBorder()),
                validator: (value) =>
                (value == null || value.isEmpty) ? "Nomor ID tidak boleh kosong" : null,
                onSaved: (value) => _dataPenumpangList[index].nomorId = value ?? "",
                onChanged: (value){
                  _dataPenumpangList[index].nomorId = value;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
