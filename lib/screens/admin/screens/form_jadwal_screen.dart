import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../models/JadwalModel.dart';
import '../../../models/jadwal_kelas_info_model.dart';
import '../../../models/jadwal_perhentian_model.dart'; // Impor model perhentian
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

  KeretaModel? _selectedKereta;

  List<JadwalKelasInfoModel> _daftarKelasHarga = [];
  final _namaKelasController = TextEditingController();
  final _subKelasController = TextEditingController();
  final _hargaKelasController = TextEditingController();
  final _ketersediaanKelasController = TextEditingController();
  final _idGerbongKelasController = TextEditingController();

  // State untuk detail perhentian
  List<JadwalPerhentianInput> _detailPerhentianInputList = [];

  bool get _isEditing => widget.jadwalToEdit != null;
  List<KeretaModel> _keretaList = [];
  List<StasiunModel> _stasiunListAll = [];

  @override
  void initState() {
    super.initState();
    _fetchDropdownData();
  }

  @override
  void dispose() {
    _namaKelasController.dispose();
    _subKelasController.dispose();
    _hargaKelasController.dispose();
    _ketersediaanKelasController.dispose();
    _idGerbongKelasController.dispose();
    for (var item in _detailPerhentianInputList) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchDropdownData() async {
    try {
      _keretaList = await _adminService.getKeretaList().first;
      _stasiunListAll = await _adminService.getStasiunList().first;
      _initializeFormFields();
      if(mounted) setState(() {});
    } catch (e) {
      print("Error fetching dropdown data: $e");
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal memuat data kereta/stasiun: $e")));
    }
  }

  void _initializeFormFields() {
    if (_isEditing && widget.jadwalToEdit != null) {
      final jadwal = widget.jadwalToEdit!;
      try {
        _selectedKereta = _keretaList.firstWhere((k) => k.id == jadwal.idKereta);
      } catch (e) { _selectedKereta = null; }

      _daftarKelasHarga = List.from(jadwal.daftarKelasHarga);

      _detailPerhentianInputList = jadwal.detailPerhentian.map((p) {
        StasiunModel? stasiun;
        try { stasiun = _stasiunListAll.firstWhere((s) => s.kode == p.idStasiun); } catch (e) { stasiun = null;}
        return JadwalPerhentianInput(
          selectedStasiun: stasiun,
          tanggalTiba: p.waktuTiba?.toDate(),
          jamTiba: p.waktuTiba != null ? TimeOfDay.fromDateTime(p.waktuTiba!.toDate()) : null,
          tanggalBerangkat: p.waktuBerangkat?.toDate(),
          jamBerangkat: p.waktuBerangkat != null ? TimeOfDay.fromDateTime(p.waktuBerangkat!.toDate()) : null,
          urutan: p.urutan,
        );
      }).toList();

    } else {
      // Default 2 field perhentian (asal & tujuan) saat menambah baru
      _addDetailPerhentianField(isAsal: true); // Asal
      _addDetailPerhentianField(isTujuan: true); // Tujuan
    }
    if(mounted) setState(() {});
  }

  void _addDetailPerhentianField({bool isAsal = false, bool isTujuan = false, int? insertAtIndex}) {
    setState(() {
      int urutanBaru = _detailPerhentianInputList.length;
      if (isAsal && _detailPerhentianInputList.isNotEmpty) urutanBaru = 0; // Selalu di awal
      else if (isTujuan && _detailPerhentianInputList.length > 1) urutanBaru = _detailPerhentianInputList.length; // Selalu di akhir

      final newItem = JadwalPerhentianInput(urutan: urutanBaru);

      if (insertAtIndex != null && insertAtIndex < _detailPerhentianInputList.length) {
        _detailPerhentianInputList.insert(insertAtIndex, newItem);
      } else if (isAsal) {
        _detailPerhentianInputList.insert(0, newItem);
      }
      else {
        _detailPerhentianInputList.add(newItem);
      }
      _updateUrutanPerhentian();
    });
  }

  void _removeDetailPerhentianField(int index) {
    // Minimal harus ada 2 perhentian (asal dan tujuan)
    if (_detailPerhentianInputList.length <= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Minimal harus ada stasiun asal dan tujuan.")),
      );
      return;
    }
    setState(() {
      _detailPerhentianInputList[index].dispose(); // Jika ada controller di dalamnya
      _detailPerhentianInputList.removeAt(index);
      _updateUrutanPerhentian();
    });
  }

  void _updateUrutanPerhentian() {
    for (int i = 0; i < _detailPerhentianInputList.length; i++) {
      _detailPerhentianInputList[i].urutan = i;
    }
  }


  Future<void> _pilihTanggalWaktuPerhentian(BuildContext context, int index, bool isTiba) async {
    final perhentian = _detailPerhentianInputList[index];
    DateTime? initialDate = (isTiba ? perhentian.tanggalTiba : perhentian.tanggalBerangkat) ?? DateTime.now();
    TimeOfDay? initialTime = (isTiba ? perhentian.jamTiba : perhentian.jamBerangkat) ?? TimeOfDay.now();

    final DateTime? pickedDate = await showDatePicker(context: context, initialDate: initialDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(context: context, initialTime: initialTime);
      if (pickedTime != null && mounted) {
        setState(() {
          if (isTiba) {
            perhentian.tanggalTiba = pickedDate;
            perhentian.jamTiba = pickedTime;
          } else {
            perhentian.tanggalBerangkat = pickedDate;
            perhentian.jamBerangkat = pickedTime;
          }
        });
      }
    }
  }


  void _tambahItemKelas() {
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
      _namaKelasController.clear(); _subKelasController.clear(); _hargaKelasController.clear();
      _ketersediaanKelasController.clear(); _idGerbongKelasController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nama kelas dan harga harus diisi.")));
    }
  }

  void _hapusItemKelas(int index) {
    setState(() { _daftarKelasHarga.removeAt(index); });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedKereta == null ) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Harap pilih kereta.")));
      return;
    }
    if (_detailPerhentianInputList.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Harap tentukan minimal stasiun asal dan tujuan.")));
      return;
    }
    if (_daftarKelasHarga.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Harap tambahkan minimal satu detail kelas dan harga.")));
      return;
    }

    // Validasi input perhentian
    List<JadwalPerhentianModel> perhentianFinalList = [];
    for (int i = 0; i < _detailPerhentianInputList.length; i++) {
      final input = _detailPerhentianInputList[i];
      if (input.selectedStasiun == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Stasiun pada perhentian ke-${i+1} belum dipilih.")));
        return;
      }
      // Stasiun awal tidak perlu waktu tiba
      if (i > 0 && (input.tanggalTiba == null || input.jamTiba == null)) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Waktu tiba untuk stasiun ${input.selectedStasiun!.nama} (perhentian ke-${i+1}) belum diisi.")));
        return;
      }
      // Stasiun akhir tidak perlu waktu berangkat
      if (i < _detailPerhentianInputList.length - 1 && (input.tanggalBerangkat == null || input.jamBerangkat == null)) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Waktu berangkat untuk stasiun ${input.selectedStasiun!.nama} (perhentian ke-${i+1}) belum diisi.")));
        return;
      }

      Timestamp? tsTiba = (i > 0 && input.tanggalTiba != null && input.jamTiba != null)
          ? Timestamp.fromDate(DateTime(input.tanggalTiba!.year, input.tanggalTiba!.month, input.tanggalTiba!.day, input.jamTiba!.hour, input.jamTiba!.minute))
          : null;
      Timestamp? tsBerangkat = (i < _detailPerhentianInputList.length - 1 && input.tanggalBerangkat != null && input.jamBerangkat != null)
          ? Timestamp.fromDate(DateTime(input.tanggalBerangkat!.year, input.tanggalBerangkat!.month, input.tanggalBerangkat!.day, input.jamBerangkat!.hour, input.jamBerangkat!.minute))
          : null;

      // Validasi waktu berangkat harus setelah waktu tiba di stasiun yang sama (jika bukan stasiun awal/akhir)
      if (tsTiba != null && tsBerangkat != null && tsBerangkat.toDate().isBefore(tsTiba.toDate())) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Di stasiun ${input.selectedStasiun!.nama}, waktu berangkat tidak boleh sebelum waktu tiba.")));
        return;
      }
      // Validasi waktu tiba di stasiun berikutnya harus setelah waktu berangkat dari stasiun sebelumnya
      if (i > 0) {
        final prevPerhentianInput = _detailPerhentianInputList[i-1];
        if (prevPerhentianInput.tanggalBerangkat != null && prevPerhentianInput.jamBerangkat != null && tsTiba != null) {
          final prevTsBerangkat = Timestamp.fromDate(DateTime(prevPerhentianInput.tanggalBerangkat!.year, prevPerhentianInput.tanggalBerangkat!.month, prevPerhentianInput.tanggalBerangkat!.day, prevPerhentianInput.jamBerangkat!.hour, prevPerhentianInput.jamBerangkat!.minute));
          if (tsTiba.toDate().isBefore(prevTsBerangkat.toDate())) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Waktu tiba di ${input.selectedStasiun!.nama} tidak boleh sebelum waktu berangkat dari stasiun sebelumnya.")));
            return;
          }
        }
      }


      perhentianFinalList.add(JadwalPerhentianModel(
        idStasiun: input.selectedStasiun!.kode,
        namaStasiun: input.selectedStasiun!.nama, // Simpan nama stasiunnya juga
        waktuTiba: tsTiba,
        waktuBerangkat: tsBerangkat,
        urutan: input.urutan,
      ));
    }

    // Stasiun awal harus punya waktu berangkat, stasiun akhir harus punya waktu tiba
    if (perhentianFinalList.first.waktuBerangkat == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Stasiun awal harus memiliki waktu berangkat.")));
      return;
    }
    if (perhentianFinalList.last.waktuTiba == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Stasiun akhir harus memiliki waktu tiba.")));
      return;
    }


    _formKey.currentState!.save();

    final jadwal = JadwalModel(
      id: _isEditing ? widget.jadwalToEdit!.id : '',
      idKereta: _selectedKereta!.id,
      namaKereta: _selectedKereta!.nama,
      detailPerhentian: perhentianFinalList,
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
              DropdownButtonFormField<KeretaModel>(
                value: _selectedKereta,
                items: _keretaList.map((KeretaModel kereta) => DropdownMenuItem<KeretaModel>(value: kereta, child: Text("${kereta.nama} (${kereta.kelasUtama})"))).toList(),
                onChanged: (KeretaModel? newValue) => setState(() => _selectedKereta = newValue),
                decoration: const InputDecoration(labelText: 'Pilih Kereta', border: OutlineInputBorder()),
                validator: (value) => value == null ? 'Kereta harus dipilih' : null,
              ),
              const SizedBox(height: 24.0),

              Text("Detail Rute & Perhentian", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8.0),
              _buildDaftarPerhentianFields(),
              const SizedBox(height: 8.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                      icon: const Icon(Icons.add_circle_outline, color: Colors.orange),
                      label: const Text("Tambah Perhentian Antara", style: TextStyle(color: Colors.orange)),
                      onPressed: () {
                        // Tambah sebelum item terakhir (tujuan)
                        if (_detailPerhentianInputList.length >= 2) {
                          _addDetailPerhentianField(insertAtIndex: _detailPerhentianInputList.length - 1);
                        } else {
                          _addDetailPerhentianField(); // Jika hanya ada 0 atau 1, tambah di akhir
                        }
                      }
                  ),
                ],
              ),
              const SizedBox(height: 24.0),

              Text("Detail Kelas & Harga", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8.0),
              _buildFormTambahKelas(),
              const SizedBox(height: 8.0),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_circle_outline),
                label: const Text("Tambah Detail Kelas"),
                onPressed: _tambahItemKelas,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
              ),
              const SizedBox(height: 16.0),
              _buildDaftarKelasHargaItems(),

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

  Widget _buildFormTambahKelas() { /* ... (implementasi tetap sama) ... */
    return Card(elevation: 1, child: Padding(padding: const EdgeInsets.all(12.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text("Form Kelas Baru", style: TextStyle(fontWeight: FontWeight.w600)), const SizedBox(height: 8),
      TextFormField(controller: _namaKelasController, decoration: const InputDecoration(labelText: "Nama Kelas (mis: EKONOMI)")),
      TextFormField(controller: _subKelasController, decoration: const InputDecoration(labelText: "Sub Kelas (mis: CA, opsional)")),
      TextFormField(controller: _hargaKelasController, decoration: const InputDecoration(labelText: "Harga (angka)"), keyboardType: TextInputType.number),
      TextFormField(controller: _ketersediaanKelasController, decoration: const InputDecoration(labelText: "Ketersediaan (mis: Tersedia, 5 Kursi)"), ),
      TextFormField(controller: _idGerbongKelasController, decoration: const InputDecoration(labelText: "ID Gerbong (opsional)")),
    ],),),);
  }

  Widget _buildDaftarKelasHargaItems() { /* ... (implementasi tetap sama) ... */
    if (_daftarKelasHarga.isEmpty) return const Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Text("Belum ada detail kelas ditambahkan.", style: TextStyle(color: Colors.grey)),);
    return ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _daftarKelasHarga.length, itemBuilder: (context, index) {
      final kelas = _daftarKelasHarga[index];
      return Card(margin: const EdgeInsets.symmetric(vertical: 4.0), child: ListTile(
        title: Text("${kelas.displayKelasLengkap} - ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(kelas.harga)}"),
        subtitle: Text("Ketersediaan: ${kelas.ketersediaan}${kelas.idGerbong != null ? ', Gerbong: ${kelas.idGerbong}' : ''}"),
        trailing: IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.red), onPressed: () => _hapusItemKelas(index)),
      ));
    });
  }

  Widget _buildDaftarPerhentianFields() {
    if (_detailPerhentianInputList.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text("Harap tambahkan stasiun asal dan tujuan.", style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _detailPerhentianInputList.length,
      itemBuilder: (context, index) {
        final perhentianInput = _detailPerhentianInputList[index];
        bool isStasiunAwal = index == 0;
        bool isStasiunAkhir = index == _detailPerhentianInputList.length - 1;
        String labelStasiun = "Stasiun Perhentian ${index + 1}";
        if (isStasiunAwal) labelStasiun = "Stasiun Asal (Keberangkatan)";
        if (isStasiunAkhir && !isStasiunAwal) labelStasiun = "Stasiun Tujuan (Kedatangan)";


        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          elevation: 1.5,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(labelStasiun, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    if (!isStasiunAwal && !isStasiunAkhir) // Hanya bisa hapus stasiun antara
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _removeDetailPerhentianField(index),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<StasiunModel?>(
                  value: perhentianInput.selectedStasiun,
                  items: _stasiunListAll.map((StasiunModel stasiun) {
                    return DropdownMenuItem<StasiunModel>(
                      value: stasiun,
                      child: Text(stasiun.displayName, style: const TextStyle(fontSize: 14)),
                    );
                  }).toList(),
                  onChanged: (StasiunModel? newValue) {
                    setState(() {
                      perhentianInput.selectedStasiun = newValue;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Pilih Stasiun',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                  validator: (value) => value == null ? 'Stasiun harus dipilih' : null,
                  hint: perhentianInput.selectedStasiun == null ? const Text("Pilih stasiun") : null,
                ),
                const SizedBox(height: 12),
                // Waktu Tiba (tidak untuk stasiun awal)
                if (!isStasiunAwal)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text("Waktu Tiba: ${perhentianInput.tanggalTiba == null || perhentianInput.jamTiba == null ? 'Belum dipilih' : DateFormat('EEE, dd MMM yy HH:mm', 'id_ID').format(DateTime(perhentianInput.tanggalTiba!.year, perhentianInput.tanggalTiba!.month, perhentianInput.tanggalTiba!.day, perhentianInput.jamTiba!.hour, perhentianInput.jamTiba!.minute))}"),
                    trailing: const Icon(Icons.edit_calendar_outlined, size: 20),
                    onTap: () => _pilihTanggalWaktuPerhentian(context, index, true), // true untuk isTiba
                  ),
                // Waktu Berangkat (tidak untuk stasiun akhir)
                if (!isStasiunAkhir)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text("Waktu Berangkat: ${perhentianInput.tanggalBerangkat == null || perhentianInput.jamBerangkat == null ? 'Belum dipilih' : DateFormat('EEE, dd MMM yy HH:mm', 'id_ID').format(DateTime(perhentianInput.tanggalBerangkat!.year, perhentianInput.tanggalBerangkat!.month, perhentianInput.tanggalBerangkat!.day, perhentianInput.jamBerangkat!.hour, perhentianInput.jamBerangkat!.minute))}"),
                    trailing: const Icon(Icons.edit_calendar_outlined, size: 20),
                    onTap: () => _pilihTanggalWaktuPerhentian(context, index, false), // false untuk isBerangkat
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Helper class untuk menampung state input perhentian di form
class JadwalPerhentianInput {
  StasiunModel? selectedStasiun;
  DateTime? tanggalTiba;
  TimeOfDay? jamTiba;
  DateTime? tanggalBerangkat;
  TimeOfDay? jamBerangkat;
  int urutan; // Untuk menjaga urutan saat disimpan

  JadwalPerhentianInput({
    this.selectedStasiun,
    this.tanggalTiba,
    this.jamTiba,
    this.tanggalBerangkat,
    this.jamBerangkat,
    required this.urutan,
  });

  // Jika ada controller di sini, tambahkan dispose method
  void dispose() {
    // Tidak ada controller di sini saat ini
  }
}
