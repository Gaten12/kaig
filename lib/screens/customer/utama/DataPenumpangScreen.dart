import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Diperlukan jika Anda format tanggal atau angka
import '../../../models/JadwalModel.dart'; // Menggunakan JadwalModel
import '../../../models/jadwal_kelas_info_model.dart'; // Menggunakan JadwalKelasInfoModel

// Model sederhana untuk menampung data input penumpang, tetap lokal di file ini.
class PenumpangInputData {
  String namaLengkap;
  String? tipeId; // Misal KTP, Paspor
  String? nomorId;
  // bool isDewasa; // Tidak secara eksplisit digunakan di form, tapi bisa berguna untuk logika lain

  PenumpangInputData({
    this.namaLengkap = "",
    this.tipeId,
    this.nomorId,
    // required this.isDewasa,
  });
}

class DataPenumpangScreen extends StatefulWidget {
  final JadwalModel jadwalDipesan; // Menggunakan JadwalModel
  final JadwalKelasInfoModel kelasDipilih; // Menggunakan JadwalKelasInfoModel
  final DateTime tanggalBerangkat; // Tetap DateTime
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
  final _formKeyPemesanan = GlobalKey<FormState>(); // Key untuk form pemesan

  final _namaPemesanController = TextEditingController();
  final _emailPemesanController = TextEditingController();
  final _teleponPemesanController = TextEditingController();
  bool _pemesanSebagaiPenumpang = true;

  late List<PenumpangInputData> _dataPenumpangList;
  late List<GlobalKey<FormState>> _formKeysPenumpang;

  // Daftar opsi untuk Tipe ID
  final List<String> _tipeIdOptions = ['KTP', 'Paspor', 'SIM', 'Lainnya'];


  @override
  void initState() {
    super.initState();
    _initializeDataPenumpang();

    // Pertimbangkan untuk memuat data pemesan dari profil pengguna yang login jika ada
    // Contoh:
    // final user = FirebaseAuth.instance.currentUser;
    // if (user != null) {
    //   _namaPemesanController.text = user.displayName ?? "";
    //   _emailPemesanController.text = user.email ?? "";
    //   // _teleponPemesanController.text = user.phoneNumber ?? ""; // Perlu cara untuk dapat nomor telepon
    // }

    // Jika pemesan adalah penumpang, update data penumpang pertama setelah frame pertama
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _pemesanSebagaiPenumpang && widget.jumlahDewasa > 0) {
        _updatePenumpangPertamaDariPemesan();
      }
    });
  }

  void _initializeDataPenumpang() {
    _dataPenumpangList = List.generate(
      widget.jumlahDewasa,
          (index) => PenumpangInputData(),
    );
    _formKeysPenumpang =
        List.generate(widget.jumlahDewasa, (index) => GlobalKey<FormState>());
  }

  void _updatePenumpangPertamaDariPemesan() {
    if (widget.jumlahDewasa > 0 && _dataPenumpangList.isNotEmpty) {
      // Hanya update jika field nama penumpang pertama kosong atau sama dengan nama pemesan sebelumnya
      // Ini untuk menghindari menimpa input manual pengguna di field penumpang pertama
      // jika mereka mengubah data pemesan setelahnya.
      // Namun, untuk sinkronisasi langsung, kita update saja.
      setState(() {
        _dataPenumpangList[0].namaLengkap = _namaPemesanController.text;
        // Jika ada field lain yang relevan (misal tipe ID, No ID dari profil pemesan)
        // bisa ditambahkan di sini juga, tapi perlu state di PenumpangInputData
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

  void _lanjutkan() {
    bool isFormPemesananValid = _formKeyPemesanan.currentState?.validate() ?? false;
    bool semuaFormPenumpangValid = true;
    for (var key in _formKeysPenumpang) {
      if (!(key.currentState?.validate() ?? false)) {
        semuaFormPenumpangValid = false;
        // Tidak break agar semua error validasi muncul
      }
    }

    if (isFormPemesananValid && semuaFormPenumpangValid) {
      _formKeyPemesanan.currentState!.save();
      for (var key in _formKeysPenumpang) {
        key.currentState!.save();
      }

      print("--- Detail Pemesanan ---");
      print("Nama Pemesan: ${_namaPemesanController.text}");
      print("Email Pemesan: ${_emailPemesanController.text}");
      print("Telepon Pemesan: ${_teleponPemesanController.text}");
      print("Pemesan sebagai penumpang: $_pemesanSebagaiPenumpang");

      print("\n--- Detail Penumpang (Dewasa) ---");
      for (int i = 0; i < _dataPenumpangList.length; i++) {
        final data = _dataPenumpangList[i];
        print("Penumpang ${i + 1}:");
        print("  Nama: ${data.namaLengkap}");
        print("  Tipe ID: ${data.tipeId ?? 'N/A'}");
        print("  No ID: ${data.nomorId ?? 'N/A'}");
      }

      print("\n--- Detail Perjalanan ---");
      print("Kereta: ${widget.jadwalDipesan.namaKereta}");
      print("Kelas: ${widget.kelasDipilih.displayKelasLengkap}");
      print("Harga per tiket: ${widget.kelasDipilih.harga}");
      print("Tanggal Berangkat: ${DateFormat('EEE, dd MMM yyyy', 'id_ID').format(widget.tanggalBerangkat)}");
      print("Jam Berangkat: ${widget.jadwalDipesan.jamBerangkatFormatted}");
      print("Jam Tiba: ${widget.jadwalDipesan.jamTibaFormatted}");
      print("Total Penumpang Dewasa: ${widget.jumlahDewasa}");
      print("Total Penumpang Bayi: ${widget.jumlahBayi}");

      // TODO: Navigasi ke layar review atau pembayaran
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Data berhasil divalidasi! Lanjut ke pembayaran (belum diimplementasikan).')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Harap lengkapi semua data yang diperlukan dengan benar.')),
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
              onChanged: (value) {
                if (_pemesanSebagaiPenumpang) {
                  _updatePenumpangPertamaDariPemesan();
                }
              },
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
                    _updatePenumpangPertamaDariPemesan();
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
                key: ValueKey('nama_penumpang_$index'), // Disederhanakan, ValueKey cukup dengan index jika initialValue di-handle controller
                initialValue: _dataPenumpangList[index].namaLengkap,
                decoration: const InputDecoration(
                    labelText: "Nama Lengkap", border: OutlineInputBorder()),
                validator: (value) =>
                (value == null || value.isEmpty) ? "Nama tidak boleh kosong" : null,
                onSaved: (value) => _dataPenumpangList[index].namaLengkap = value ?? "",
              ),
              const SizedBox(height: 12.0),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                    labelText: "Tipe ID", border: OutlineInputBorder()),
                value: _dataPenumpangList[index].tipeId,
                items: _tipeIdOptions.map((String value) {
                  return DropdownMenuItem<String>(
                      value: value, child: Text(value));
                }).toList(),
                onChanged: (value) {
                  // Tidak perlu setState di sini jika onSaved yang akan menyimpan nilainya
                  // Namun jika ingin nilai dropdown langsung tersimpan di model, setState diperlukan
                  setState(() {
                    _dataPenumpangList[index].tipeId = value;
                  });
                },
                onSaved: (value) => _dataPenumpangList[index].tipeId = value,
                validator: (value) =>
                (value == null || value.isEmpty) ? "Pilih tipe ID" : null,
              ),
              const SizedBox(height: 12.0),
              TextFormField(
                initialValue: _dataPenumpangList[index].nomorId,
                decoration: const InputDecoration(
                    labelText: "Nomor ID", border: OutlineInputBorder()),
                validator: (value) =>
                (value == null || value.isEmpty) ? "Nomor ID tidak boleh kosong" : null,
                onSaved: (value) => _dataPenumpangList[index].nomorId = value ?? "",
              ),
            ],
          ),
        ),
      ),
    );
  }
}