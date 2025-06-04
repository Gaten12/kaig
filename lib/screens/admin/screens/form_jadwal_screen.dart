import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../models/JadwalModel.dart';
import '../../../models/jadwal_kelas_info_model.dart';
import '../../../models/KeretaModel.dart';
import '../../../models/stasiun_model.dart';
import '../services/admin_firestore_service.dart';

class FormJadwalScreen extends StatefulWidget {
  final JadwalModel? jadwalToEdit;

  const FormJadwalScreen({super.key, this.jadwalToEdit});

  @override
  State<FormJadwalScreen> createState() => _FormJadwalScreenState();
}

class _FormJadwalScreenState extends State<FormJadwalScreen> {
  final _formKey = GlobalKey<FormState>();
  final AdminFirestoreService _adminService = AdminFirestoreService();

  // Controllers & State untuk data jadwal
  KeretaModel? _selectedKereta;
  StasiunModel? _selectedStasiunAsal;
  StasiunModel? _selectedStasiunTujuan;
  DateTime? _selectedTanggalBerangkat;
  TimeOfDay? _selectedJamBerangkat;
  DateTime? _selectedTanggalTiba;
  TimeOfDay? _selectedJamTiba;

  // Untuk daftar kelas harga
  List<JadwalKelasInfoModel> _daftarKelasHarga = [];
  // Controller untuk input kelas baru (opsional, bisa juga langsung tambah objek)
  final _namaKelasController = TextEditingController();
  final _subKelasController = TextEditingController();
  final _hargaKelasController = TextEditingController();
  final _ketersediaanKelasController = TextEditingController();
  final _idGerbongKelasController = TextEditingController();


  bool get _isEditing => widget.jadwalToEdit != null;
  List<KeretaModel> _keretaList = [];
  List<StasiunModel> _stasiunList = [];

  @override
  void initState() {
    super.initState();
    _fetchDropdownData();
    if (_isEditing) {
      final jadwal = widget.jadwalToEdit!;
      // Pre-fill data jika sedang edit
      // _selectedKereta diisi setelah _fetchDropdownData
      // _selectedStasiunAsal diisi setelah _fetchDropdownData
      // _selectedStasiunTujuan diisi setelah _fetchDropdownData
      _selectedTanggalBerangkat = jadwal.tanggalBerangkat.toDate();
      _selectedJamBerangkat = TimeOfDay.fromDateTime(jadwal.tanggalBerangkat.toDate());
      _selectedTanggalTiba = jadwal.jamTiba.toDate(); // jamTiba adalah Timestamp lengkap
      _selectedJamTiba = TimeOfDay.fromDateTime(jadwal.jamTiba.toDate());
      _daftarKelasHarga = List.from(jadwal.daftarKelasHarga); // Salin list
    } else {
      // Default: 1 kelas kosong saat menambah jadwal baru
      // _tambahItemKelas(); // Bisa diaktifkan jika ingin ada 1 form kelas default
    }
  }

  Future<void> _fetchDropdownData() async {
    try {
      _keretaList = await _adminService.getKeretaList().first; // Ambil data sekali
      _stasiunList = await _adminService.getStasiunList().first; // Ambil data sekali
      if (_isEditing && widget.jadwalToEdit != null) {
        // Set selected value untuk dropdowns jika sedang edit
        final jadwal = widget.jadwalToEdit!;
        _selectedKereta = _keretaList.firstWhere((k) => k.id == jadwal.idKereta, orElse: () => _keretaList.isNotEmpty ? _keretaList.first : null as KeretaModel);
        _selectedStasiunAsal = _stasiunList.firstWhere((s) => s.id == jadwal.idStasiunAsal, orElse: () => _stasiunList.isNotEmpty ? _stasiunList.first : null as StasiunModel);
        _selectedStasiunTujuan = _stasiunList.firstWhere((s) => s.id == jadwal.idStasiunTujuan, orElse: () => _stasiunList.isNotEmpty ? _stasiunList.first : null as StasiunModel);
      }
      if(mounted) setState(() {});
    } catch (e) {
      print("Error fetching dropdown data: $e");
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal memuat data kereta/stasiun: $e")));
    }
  }


  Future<void> _pilihTanggalWaktu(BuildContext context, bool isBerangkat) async {
    DateTime initialDate = (isBerangkat ? _selectedTanggalBerangkat : _selectedTanggalTiba) ?? DateTime.now();
    TimeOfDay initialTime = (isBerangkat ? _selectedJamBerangkat : _selectedJamTiba) ?? TimeOfDay.now();

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: initialTime,
      );
      if (pickedTime != null && mounted) {
        setState(() {
          if (isBerangkat) {
            _selectedTanggalBerangkat = pickedDate;
            _selectedJamBerangkat = pickedTime;
          } else {
            _selectedTanggalTiba = pickedDate;
            _selectedJamTiba = pickedTime;
          }
        });
      }
    }
  }

  void _tambahItemKelas() {
    // Validasi input kelas sebelum menambah (jika ada form input aktif)
    if (_namaKelasController.text.isNotEmpty && _hargaKelasController.text.isNotEmpty) {
      final harga = int.tryParse(_hargaKelasController.text);
      if (harga == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Harga kelas harus angka.")));
        return;
      }
      setState(() {
        _daftarKelasHarga.add(JadwalKelasInfoModel(
          namaKelas: _namaKelasController.text,
          subKelas: _subKelasController.text.isEmpty ? null : _subKelasController.text,
          harga: harga,
          ketersediaan: _ketersediaanKelasController.text.isEmpty ? "Tersedia" : _ketersediaanKelasController.text,
          idGerbong: _idGerbongKelasController.text.isEmpty ? null : _idGerbongKelasController.text,
        ));
      });
      // Kosongkan controller setelah menambah
      _namaKelasController.clear();
      _subKelasController.clear();
      _hargaKelasController.clear();
      _ketersediaanKelasController.clear();
      _idGerbongKelasController.clear();
    } else {
      // Atau tambahkan kelas kosong jika tidak ada form input aktif
      // setState(() {
      //   _daftarKelasHarga.add(JadwalKelasInfoModel(namaKelas: '', harga: 0, ketersediaan: 'Tersedia'));
      // });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nama kelas dan harga harus diisi.")));
    }
  }

  void _hapusItemKelas(int index) {
    setState(() {
      _daftarKelasHarga.removeAt(index);
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedKereta == null || _selectedStasiunAsal == null || _selectedStasiunTujuan == null ||
        _selectedTanggalBerangkat == null || _selectedJamBerangkat == null ||
        _selectedTanggalTiba == null || _selectedJamTiba == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Harap lengkapi semua field utama jadwal.")));
      return;
    }
    if (_daftarKelasHarga.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Harap tambahkan minimal satu detail kelas dan harga.")));
      return;
    }

    _formKey.currentState!.save();

    final Timestamp tanggalBerangkatTimestamp = Timestamp.fromDate(DateTime(
      _selectedTanggalBerangkat!.year, _selectedTanggalBerangkat!.month, _selectedTanggalBerangkat!.day,
      _selectedJamBerangkat!.hour, _selectedJamBerangkat!.minute,
    ));
    final Timestamp tanggalTibaTimestamp = Timestamp.fromDate(DateTime(
      _selectedTanggalTiba!.year, _selectedTanggalTiba!.month, _selectedTanggalTiba!.day,
      _selectedJamTiba!.hour, _selectedJamTiba!.minute,
    ));

    if (tanggalTibaTimestamp.toDate().isBefore(tanggalBerangkatTimestamp.toDate())) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tanggal & Jam tiba tidak boleh sebelum tanggal & jam berangkat.")));
      return;
    }


    final jadwal = JadwalModel(
      id: _isEditing ? widget.jadwalToEdit!.id : '', // ID akan di-generate oleh Firestore jika baru
      idKereta: _selectedKereta!.id,
      namaKereta: _selectedKereta!.nama, // Ambil dari KeretaModel yang dipilih
      idStasiunAsal: _selectedStasiunAsal!.kode, // Kirim kode stasiun
      idStasiunTujuan: _selectedStasiunTujuan!.kode, // Kirim kode stasiun
      tanggalBerangkat: tanggalBerangkatTimestamp,
      jamTiba: tanggalTibaTimestamp,
      daftarKelasHarga: _daftarKelasHarga,
    );

    try {
      if (_isEditing) {
        await _adminService.updateJadwal(jadwal);
      } else {
        await _adminService.addJadwal(jadwal);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Jadwal berhasil ${ _isEditing ? "diperbarui" : "ditambahkan"}!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan jadwal: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? "Edit Jadwal" : "Tambah Jadwal Baru"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              // Pemilihan Kereta
              DropdownButtonFormField<KeretaModel>(
                value: _selectedKereta,
                items: _keretaList.map((KeretaModel kereta) {
                  return DropdownMenuItem<KeretaModel>(
                    value: kereta,
                    child: Text("${kereta.nama} (${kereta.kelasUtama})"),
                  );
                }).toList(),
                onChanged: (KeretaModel? newValue) {
                  setState(() { _selectedKereta = newValue; });
                },
                decoration: const InputDecoration(labelText: 'Pilih Kereta', border: OutlineInputBorder()),
                validator: (value) => value == null ? 'Kereta harus dipilih' : null,
              ),
              const SizedBox(height: 16.0),

              // Stasiun Asal
              DropdownButtonFormField<StasiunModel>(
                value: _selectedStasiunAsal,
                items: _stasiunList.map((StasiunModel stasiun) {
                  return DropdownMenuItem<StasiunModel>(
                    value: stasiun,
                    child: Text(stasiun.displayName),
                  );
                }).toList(),
                onChanged: (StasiunModel? newValue) {
                  setState(() { _selectedStasiunAsal = newValue; });
                },
                decoration: const InputDecoration(labelText: 'Pilih Stasiun Asal', border: OutlineInputBorder()),
                validator: (value) => value == null ? 'Stasiun asal harus dipilih' : null,
              ),
              const SizedBox(height: 16.0),

              // Stasiun Tujuan
              DropdownButtonFormField<StasiunModel>(
                value: _selectedStasiunTujuan,
                items: _stasiunList.map((StasiunModel stasiun) {
                  return DropdownMenuItem<StasiunModel>(
                    value: stasiun,
                    child: Text(stasiun.displayName),
                  );
                }).toList(),
                onChanged: (StasiunModel? newValue) {
                  setState(() { _selectedStasiunTujuan = newValue; });
                },
                decoration: const InputDecoration(labelText: 'Pilih Stasiun Tujuan', border: OutlineInputBorder()),
                validator: (value) {
                  if (value == null) return 'Stasiun tujuan harus dipilih';
                  if (_selectedStasiunAsal != null && value.id == _selectedStasiunAsal!.id) {
                    return 'Stasiun tujuan tidak boleh sama dengan stasiun asal';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),

              // Tanggal & Jam Berangkat
              ListTile(
                title: Text("Tanggal & Jam Berangkat: ${_selectedTanggalBerangkat == null || _selectedJamBerangkat == null ? 'Belum dipilih' : DateFormat('EEE, dd MMM yyyy HH:mm', 'id_ID').format(DateTime(_selectedTanggalBerangkat!.year, _selectedTanggalBerangkat!.month, _selectedTanggalBerangkat!.day, _selectedJamBerangkat!.hour, _selectedJamBerangkat!.minute))}"),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: () => _pilihTanggalWaktu(context, true),
              ),
              const SizedBox(height: 16.0),

              // Tanggal & Jam Tiba
              ListTile(
                title: Text("Tanggal & Jam Tiba: ${_selectedTanggalTiba == null || _selectedJamTiba == null ? 'Belum dipilih' : DateFormat('EEE, dd MMM yyyy HH:mm', 'id_ID').format(DateTime(_selectedTanggalTiba!.year, _selectedTanggalTiba!.month, _selectedTanggalTiba!.day, _selectedJamTiba!.hour, _selectedJamTiba!.minute))}"),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: () => _pilihTanggalWaktu(context, false),
              ),
              const SizedBox(height: 24.0),

              // Input Detail Kelas Harga
              Text("Detail Kelas & Harga", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8.0),
              _buildFormTambahKelas(), // Form untuk input kelas baru
              const SizedBox(height: 8.0),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_circle_outline),
                label: const Text("Tambah Detail Kelas"),
                onPressed: _tambahItemKelas,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
              ),
              const SizedBox(height: 16.0),
              _buildDaftarKelasHargaItems(), // Menampilkan list kelas yang sudah ditambahkan

              const SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12.0), minimumSize: const Size(double.infinity, 50)),
                child: Text(_isEditing ? 'Simpan Perubahan Jadwal' : 'Tambah Jadwal', style: const TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormTambahKelas() {
    // Form kecil untuk menambah satu item kelas baru
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Form Kelas Baru", style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(controller: _namaKelasController, decoration: const InputDecoration(labelText: "Nama Kelas (mis: EKONOMI)")),
            TextFormField(controller: _subKelasController, decoration: const InputDecoration(labelText: "Sub Kelas (mis: CA, opsional)")),
            TextFormField(controller: _hargaKelasController, decoration: const InputDecoration(labelText: "Harga (angka)"), keyboardType: TextInputType.number),
            TextFormField(controller: _ketersediaanKelasController, decoration: const InputDecoration(labelText: "Ketersediaan (mis: Tersedia, 5 Kursi)"), ),
            TextFormField(controller: _idGerbongKelasController, decoration: const InputDecoration(labelText: "ID Gerbong (opsional)")),
          ],
        ),
      ),
    );
  }

  Widget _buildDaftarKelasHargaItems() {
    if (_daftarKelasHarga.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text("Belum ada detail kelas ditambahkan.", style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _daftarKelasHarga.length,
      itemBuilder: (context, index) {
        final kelas = _daftarKelasHarga[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: ListTile(
            title: Text("${kelas.displayKelasLengkap} - ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(kelas.harga)}"),
            subtitle: Text("Ketersediaan: ${kelas.ketersediaan}${kelas.idGerbong != null ? ', Gerbong: ${kelas.idGerbong}' : ''}"),
            trailing: IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
              onPressed: () => _hapusItemKelas(index),
            ),
            // TODO: Tambahkan fungsi edit untuk item kelas ini jika perlu
          ),
        );
      },
    );
  }
}