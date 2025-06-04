import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/JadwalModel.dart';
import '../../../models/jadwal_kelas_info_model.dart';
import '../../../models/user_model.dart';
import '../../../models/passenger_model.dart';
import '../../../services/auth_service.dart';

class PenumpangInputData {
  String namaLengkap;
  String? tipeId;
  String? nomorId;

  PenumpangInputData({
    this.namaLengkap = "",
    this.tipeId,
    this.nomorId,
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

  // Variabel untuk menyimpan data dari PassengerModel utama (isPrimary: true)
  String? _primaryPassengerNamaLengkap;
  String? _primaryPassengerTipeId;
  String? _primaryPassengerNomorId;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _initializeDataPenumpang();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    bool needsViewUpdate = false;

    if (firebaseUser != null) {
      // 1. Isi email pemesan dari FirebaseAuth
      if (_emailPemesanController.text != (firebaseUser.email ?? "")) {
        _emailPemesanController.text = firebaseUser.email ?? "";
        needsViewUpdate = true;
      }

      // 2. Ambil UserModel untuk no telepon pemesan (Nama Pemesan akan dari primary passenger)
      try {
        UserModel? userModel = await _authService.getUserModel(firebaseUser.uid);
        if (userModel != null) {
          if (_teleponPemesanController.text != userModel.noTelepon) {
            _teleponPemesanController.text = userModel.noTelepon;
            needsViewUpdate = true;
          }
          // Nama pemesan di controller akan diisi dari primary passenger nanti
        } else {
          print("Dokumen UserModel tidak ditemukan untuk UID: ${firebaseUser.uid}");
        }
      } catch (e) {
        print("Error memuat UserModel dari Firestore: $e");
      }

      // 3. Ambil data penumpang utama (isPrimary: true) dari subkoleksi 'passengers'
      try {
        PassengerModel? primaryPassenger = await _authService.getPrimaryPassenger(firebaseUser.uid);
        if (primaryPassenger != null) {
          _primaryPassengerNamaLengkap = primaryPassenger.namaLengkap;
          _primaryPassengerTipeId = primaryPassenger.tipeId;
          _primaryPassengerNomorId = primaryPassenger.nomorId;

          // Isi Nama Pemesan Controller dengan nama dari primary passenger
          if (_namaPemesanController.text != primaryPassenger.namaLengkap) {
            _namaPemesanController.text = primaryPassenger.namaLengkap;
            needsViewUpdate = true;
          }
          print("Data Penumpang Utama ditemukan: Nama: ${_primaryPassengerNamaLengkap}, TipeID: ${_primaryPassengerTipeId}, NoID: ${_primaryPassengerNomorId}");
        } else {
          print("Data Penumpang Utama (isPrimary:true) tidak ditemukan.");
          // Jika tidak ada primary passenger, isi Nama Pemesan dari displayName sebagai fallback
          if (_namaPemesanController.text != (firebaseUser.displayName ?? "")) {
            _namaPemesanController.text = firebaseUser.displayName ?? "";
            _primaryPassengerNamaLengkap = firebaseUser.displayName ?? ""; // Gunakan ini untuk penumpang pertama
            needsViewUpdate = true;
          }
        }
      } catch (e) {
        print("Error memuat Primary Passenger dari Firestore: $e");
        if (_namaPemesanController.text != (firebaseUser.displayName ?? "")) {
          _namaPemesanController.text = firebaseUser.displayName ?? "";
          _primaryPassengerNamaLengkap = firebaseUser.displayName ?? "";
          needsViewUpdate = true;
        }
      }
    }

    // Panggil update untuk penumpang pertama setelah semua data potensial dimuat
    if (_pemesanSebagaiPenumpang && widget.jumlahDewasa > 0) {
      // panggilSetState: false karena setState akan dipanggil di akhir _loadInitialData
      _updatePenumpangPertamaDenganDataPrimaryPassenger(panggilSetState: false);
    }

    if (mounted && needsViewUpdate) {
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

  void _updatePenumpangPertamaDenganDataPrimaryPassenger({bool panggilSetState = true}) {
    if (widget.jumlahDewasa > 0 && _dataPenumpangList.isNotEmpty) {
      bool changed = false;

      // Selalu gunakan data dari _primaryPassenger... untuk penumpang pertama jika switch aktif
      if (_dataPenumpangList[0].namaLengkap != (_primaryPassengerNamaLengkap ?? "")) {
        _dataPenumpangList[0].namaLengkap = _primaryPassengerNamaLengkap ?? "";
        changed = true;
      }

      String? validTipeId = _primaryPassengerTipeId;
      if (_primaryPassengerTipeId != null && !_tipeIdOptions.contains(_primaryPassengerTipeId)) {
        print("Peringatan: Tipe ID penumpang utama '$_primaryPassengerTipeId' tidak ada di opsi dropdown. Menggunakan null.");
        validTipeId = null;
      }
      if (_dataPenumpangList[0].tipeId != validTipeId) {
        _dataPenumpangList[0].tipeId = validTipeId;
        changed = true;
      }

      if (_dataPenumpangList[0].nomorId != (_primaryPassengerNomorId ?? "")) {
        _dataPenumpangList[0].nomorId = _primaryPassengerNomorId;
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

  void _lanjutkan() {
    bool isFormPemesananValid = _formKeyPemesanan.currentState?.validate() ?? false;
    bool semuaFormPenumpangValid = true;
    for (var key in _formKeysPenumpang) {
      if (!(key.currentState?.validate() ?? false)) {
        semuaFormPenumpangValid = false;
      }
    }

    if (isFormPemesananValid && semuaFormPenumpangValid) {
      _formKeyPemesanan.currentState!.save();
      for (var key in _formKeysPenumpang) {
        key.currentState!.save();
      }

      // Logika print tetap sama
      print("--- Detail Pemesanan ---");
      print("Nama Pemesan: ${_namaPemesanController.text}");
      print("Email Pemesan: ${_emailPemesanController.text}");
      print("Telepon Pemesan: ${_teleponPemesanController.text}");
      print("Pemesan sebagai penumpang: $_pemesanSebagaiPenumpang");
      print("\n--- Detail Penumpang (Dewasa) ---");
      for (int i = 0; i < _dataPenumpangList.length; i++) {
        final data = _dataPenumpangList[i];
        print("Penumpang ${i + 1}: Nama: ${data.namaLengkap}, Tipe ID: ${data.tipeId ?? 'N/A'}, No ID: ${data.nomorId ?? 'N/A'}");
      }
      print("\n--- Detail Perjalanan ---"); // dst.

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data berhasil divalidasi! Lanjut ke pembayaran (belum diimplementasikan).')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Harap lengkapi semua data yang diperlukan dengan benar.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
              // onChanged pada nama pemesan tidak lagi langsung update penumpang pertama
              // karena sumber data penumpang pertama adalah _primaryPassenger...
            ),
            const SizedBox(height: 12.0),
            TextFormField(
              controller: _emailPemesanController,
              decoration: const InputDecoration(
                  labelText: "Email", border: OutlineInputBorder()),
              keyboardType: TextInputType.emailAddress,
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
                    // Salin data dari _primaryPassenger... ke form penumpang pertama
                    _updatePenumpangPertamaDenganDataPrimaryPassenger(panggilSetState: false);
                  } else {
                    // Jika switch dimatikan, reset data penumpang pertama agar diisi manual
                    if (widget.jumlahDewasa > 0 && _dataPenumpangList.isNotEmpty) {
                      _dataPenumpangList[0] = PenumpangInputData();
                    }
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
                  _dataPenumpangList[index].namaLengkap = value;
                  // Jika pengguna mengedit manual penumpang pertama saat switch aktif,
                  // dan nilainya berbeda dari data primary passenger, nonaktifkan switch.
                  if (index == 0 && _pemesanSebagaiPenumpang && value != _primaryPassengerNamaLengkap) {
                    if (mounted) {
                      setState(() {
                        _pemesanSebagaiPenumpang = false;
                      });
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
                      if (index == 0 && _pemesanSebagaiPenumpang && value != _primaryPassengerTipeId) {
                        setState(() { _pemesanSebagaiPenumpang = false; });
                      }
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
                  if (index == 0 && _pemesanSebagaiPenumpang && value != _primaryPassengerNomorId) {
                    if (mounted) {
                      setState(() { _pemesanSebagaiPenumpang = false; });
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}