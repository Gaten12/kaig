import 'package:flutter/material.dart';
import 'package:kaig/models/jadwal_krl_model.dart';
import 'package:kaig/models/perhentian_krl_model.dart';
import 'package:kaig/models/stasiun_model.dart';
import 'package:kaig/screens/admin/services/admin_firestore_service.dart';

// Helper class untuk input di UI
class PerhentianKrlInput {
  StasiunModel? selectedStasiun;
  TextEditingController jamDatangController;
  TextEditingController jamBerangkatController;

  PerhentianKrlInput({
    this.selectedStasiun,
    String? jamDatang,
    String? jamBerangkat,
  })  : jamDatangController = TextEditingController(text: jamDatang),
        jamBerangkatController = TextEditingController(text: jamBerangkat);

  void dispose() {
    jamDatangController.dispose();
    jamBerangkatController.dispose();
  }
}


class FormJadwalKrlFinalScreen extends StatefulWidget {
  final JadwalKrlModel? jadwal;
  const FormJadwalKrlFinalScreen({super.key, this.jadwal});

  @override
  _FormJadwalKrlFinalScreenState createState() => _FormJadwalKrlFinalScreenState();
}

class _FormJadwalKrlFinalScreenState extends State<FormJadwalKrlFinalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = AdminFirestoreService();

  late TextEditingController _nomorKaController;
  late TextEditingController _relasiController;
  late TextEditingController _hargaController;
  String? _selectedTipeHari;
  List<PerhentianKrlInput> _perhentianList = [];
  List<StasiunModel> _semuaStasiun = [];
  bool _isLoading = true;

  bool get _isEditing => widget.jadwal != null;

  @override
  void initState() {
    super.initState();
    _nomorKaController = TextEditingController(text: widget.jadwal?.nomorKa ?? '');
    _relasiController = TextEditingController(text: widget.jadwal?.relasi ?? '');
    _hargaController = TextEditingController(text: widget.jadwal?.harga.toString() ?? '');
    _selectedTipeHari = widget.jadwal?.tipeHari;

    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final stasiunList = await _firestoreService.getStasiunList().first;
    if (!mounted) return;

    List<PerhentianKrlInput> initialPerhentian = [];
    if (_isEditing) {
      initialPerhentian = widget.jadwal!.perhentian.map<PerhentianKrlInput>((p) {
        final stasiunTerpilih = stasiunList.firstWhere(
              (s) => s.kode == p.kodeStasiun,
          orElse: () => StasiunModel(id: p.kodeStasiun, kode: p.kodeStasiun, nama: p.namaStasiun, kota: ''),
        );

        return PerhentianKrlInput(
          selectedStasiun: stasiunTerpilih,
          jamDatang: p.jamDatang,
          jamBerangkat: p.jamBerangkat,
        );
      }).toList();
    }

    setState(() {
      _semuaStasiun = stasiunList;
      _perhentianList = initialPerhentian;
      _isLoading = false;
    });
  }

  void _tambahPerhentian() {
    setState(() {
      _perhentianList.add(PerhentianKrlInput());
    });
  }

  void _hapusPerhentian(int index) {
    setState(() {
      _perhentianList[index].dispose();
      _perhentianList.removeAt(index);
    });
  }

  void _simpanJadwal() {
    if (!_formKey.currentState!.validate() || _perhentianList.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi semua data & minimal ada 2 stasiun perhentian.')),
      );
      return;
    }

    final jadwalKrl = JadwalKrlModel(
      id: widget.jadwal?.id,
      nomorKa: _nomorKaController.text,
      relasi: _relasiController.text,
      harga: int.tryParse(_hargaController.text) ?? 0,
      tipeHari: _selectedTipeHari!,
      perhentian: _perhentianList.asMap().entries.map((entry) {
        int idx = entry.key;
        PerhentianKrlInput p = entry.value;
        return PerhentianKrlModel(
          kodeStasiun: p.selectedStasiun!.kode,
          namaStasiun: p.selectedStasiun!.nama,
          jamDatang: p.jamDatangController.text.isNotEmpty ? p.jamDatangController.text : null,
          jamBerangkat: p.jamBerangkatController.text.isNotEmpty ? p.jamBerangkatController.text : null,
          urutan: idx,
        );
      }).toList(),
    );

    if (_isEditing) {
      _firestoreService.updateJadwalKrl(jadwalKrl);
    } else {
      _firestoreService.addJadwalKrl(jadwalKrl);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? "Edit Jadwal KRL" : "Tambah Jadwal KRL")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(controller: _nomorKaController, decoration: const InputDecoration(labelText: "Nomor KA"), validator: (v) => v!.isEmpty ? "Wajib" : null),
            TextFormField(controller: _relasiController, decoration: const InputDecoration(labelText: "Relasi (Contoh: SLO-YK)"), validator: (v) => v!.isEmpty ? "Wajib" : null),
            TextFormField(controller: _hargaController, decoration: const InputDecoration(labelText: "Harga"), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? "Wajib" : null),
            DropdownButtonFormField<String>(
              value: _selectedTipeHari,
              decoration: const InputDecoration(labelText: "Tipe Hari"),
              items: ["Weekday", "Weekend"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => setState(() => _selectedTipeHari = val),
              validator: (v) => v == null ? "Pilih Tipe Hari" : null,
            ),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text("Rute Perhentian", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(onPressed: _tambahPerhentian, icon: const Icon(Icons.add), label: const Text("Tambah"))
            ]),
            ..._perhentianList.asMap().entries.map((entry) {
              int idx = entry.key;
              PerhentianKrlInput perhentian = entry.value;

              // --- LOGIKA BARU UNTUK KONDISI TAMPILAN ---
              bool isFirstStation = idx == 0;
              bool isLastStation = idx == _perhentianList.length - 1 && _perhentianList.length > 1;
              // ---------------------------------------------

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(children: [
                    CircleAvatar(child: Text("${idx + 1}")),
                    const SizedBox(width: 8),
                    Expanded(flex: 3, child: DropdownButtonFormField<StasiunModel>(
                      value: perhentian.selectedStasiun,
                      hint: const Text("Pilih Stasiun"),
                      isExpanded: true,
                      // --- PERBAIKAN DI SINI ---
                      items: _semuaStasiun.map((s) => DropdownMenuItem(value: s, child: Text(s.nama, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (val) => setState(() => perhentian.selectedStasiun = val),
                      validator: (v) => v == null ? "Pilih" : null,
                    )),
                    const SizedBox(width: 8),

                    // --- WIDGET JAM DATANG (KONDISIONAL) ---
                    Expanded(flex: 2, child: Visibility(
                      // Terlihat jika BUKAN stasiun pertama
                      visible: !isFirstStation,
                      // Tetap ambil ruang agar layout tidak rusak
                      maintainState: true, maintainAnimation: true, maintainSize: true,
                      child: TextFormField(
                        controller: perhentian.jamDatangController,
                        decoration: const InputDecoration(labelText: "Datang", hintText: "HH:mm"),
                        validator: isFirstStation ? null : (v) => v!.isEmpty ? 'Wajib' : null,
                      ),
                    )),
                    const SizedBox(width: 8),

                    // --- WIDGET JAM BERANGKAT (KONDISIONAL) ---
                    Expanded(flex: 2, child: Visibility(
                      // Terlihat jika BUKAN stasiun terakhir
                      visible: !isLastStation,
                      maintainState: true, maintainAnimation: true, maintainSize: true,
                      child: TextFormField(
                        controller: perhentian.jamBerangkatController,
                        decoration: const InputDecoration(labelText: "Berangkat", hintText: "HH:mm"),
                        validator: isLastStation ? null : (v) => v!.isEmpty ? 'Wajib' : null,
                      ),
                    )),
                    IconButton(onPressed: () => _hapusPerhentian(idx), icon: const Icon(Icons.close, color: Colors.red)),
                  ]),
                ),
              );
            }),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _simpanJadwal, child: const Text("SIMPAN JADWAL"))
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nomorKaController.dispose();
    _relasiController.dispose();
    _hargaController.dispose();
    for (var p in _perhentianList) {
      p.dispose();
    }
    super.dispose();
  }
}
