import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // Color constants (sesuaikan dengan tema yang diinginkan)
  static const Color charcoalGray = Color(0xFF374151);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color electricBlue = Color(0xFF3B82F6);

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
    try {
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
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal memuat data master: $e")));
      setState(() { _isLoading = false; });
    }
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

  Future<void> _simpanJadwal() async {
    if (!_formKey.currentState!.validate()) return;
    if (_perhentianList.length < 2 || _perhentianList.any((p) => p.selectedStasiun == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi semua data & minimal ada 2 stasiun perhentian.')),
      );
      return;
    }

    // Validasi jam datang/berangkat
    for (int i = 0; i < _perhentianList.length; i++) {
      final p = _perhentianList[i];
      if (i > 0 && p.jamDatangController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Jam datang untuk stasiun ${p.selectedStasiun?.nama ?? 'ini'} harus diisi.')),
        );
        return;
      }
      if (i < _perhentianList.length - 1 && p.jamBerangkatController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Jam berangkat untuk stasiun ${p.selectedStasiun?.nama ?? 'ini'} harus diisi.')),
        );
        return;
      }
    }

    final jadwalKrl = JadwalKrlModel(
      id: widget.jadwal?.id,
      nomorKa: _nomorKaController.text.trim(),
      relasi: _relasiController.text.trim(),
      harga: int.tryParse(_hargaController.text.trim()) ?? 0,
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

    try {
      if (_isEditing) {
        await _firestoreService.updateJadwalKrl(jadwalKrl);
      } else {
        await _firestoreService.addJadwalKrl(jadwalKrl);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Jadwal KRL berhasil ${ _isEditing ? "diperbarui" : "ditambahkan"}!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan jadwal KRL: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Definisikan border style agar konsisten
    final OutlineInputBorder defaultOutlineInputBorder = OutlineInputBorder(
      borderSide: BorderSide(color: Colors.grey.shade400),
      borderRadius: BorderRadius.circular(8.0),
    );
    final OutlineInputBorder focusedOutlineInputBorder = OutlineInputBorder(
      borderSide: BorderSide(color: electricBlue, width: 2.0),
      borderRadius: BorderRadius.circular(8.0),
    );
    final OutlineInputBorder errorOutlineInputBorder = OutlineInputBorder(
      borderSide: const BorderSide(color: Colors.red, width: 1.0),
      borderRadius: BorderRadius.circular(8.0),
    );

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: charcoalGray,
        title: Text(
          _isEditing ? "Edit Jadwal KRL" : "Tambah Jadwal KRL Baru",
          style: const TextStyle(
            color: pureWhite,
            fontSize: 24,
            fontWeight: FontWeight.w200,
          ),
        ),
        iconTheme: const IconThemeData(color: pureWhite),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _nomorKaController,
                        decoration: InputDecoration(
                          labelText: "Nomor KA (Contoh: 432)",
                          enabledBorder: defaultOutlineInputBorder,
                          focusedBorder: focusedOutlineInputBorder,
                          errorBorder: errorOutlineInputBorder,
                          focusedErrorBorder: focusedOutlineInputBorder.copyWith(borderSide: const BorderSide(color: Colors.red, width: 2.0)),
                          prefixIcon: Icon(Icons.confirmation_number_outlined, color: electricBlue),
                        ),
                        validator: (v) => v!.isEmpty ? "Nomor KA wajib diisi" : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _relasiController,
                        decoration: InputDecoration(
                          labelText: "Relasi (Contoh: SLO-YK)",
                          enabledBorder: defaultOutlineInputBorder,
                          focusedBorder: focusedOutlineInputBorder,
                          errorBorder: errorOutlineInputBorder,
                          focusedErrorBorder: focusedOutlineInputBorder.copyWith(borderSide: const BorderSide(color: Colors.red, width: 2.0)),
                          prefixIcon: Icon(Icons.route_outlined, color: electricBlue),
                        ),
                        validator: (v) => v!.isEmpty ? "Relasi wajib diisi" : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _hargaController,
                        decoration: InputDecoration(
                          labelText: "Harga (Rp)",
                          enabledBorder: defaultOutlineInputBorder,
                          focusedBorder: focusedOutlineInputBorder,
                          errorBorder: errorOutlineInputBorder,
                          focusedErrorBorder: focusedOutlineInputBorder.copyWith(borderSide: const BorderSide(color: Colors.red, width: 2.0)),
                          prefixIcon: Icon(Icons.attach_money_outlined, color: electricBlue),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (v) {
                          if (v!.isEmpty) return "Harga wajib diisi";
                          if (int.tryParse(v) == null || int.parse(v) <= 0) return "Harga harus angka positif";
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedTipeHari,
                        decoration: InputDecoration(
                          labelText: "Tipe Hari",
                          enabledBorder: defaultOutlineInputBorder,
                          focusedBorder: focusedOutlineInputBorder,
                          errorBorder: errorOutlineInputBorder,
                          focusedErrorBorder: focusedOutlineInputBorder.copyWith(borderSide: const BorderSide(color: Colors.red, width: 2.0)),
                          prefixIcon: Icon(Icons.date_range_outlined, color: electricBlue),
                        ),
                        items: ["Weekday", "Weekend"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (val) => setState(() => _selectedTipeHari = val),
                        validator: (v) => v == null ? "Pilih Tipe Hari" : null,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Rute Perhentian",
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: charcoalGray,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _tambahPerhentian,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text("Tambah"),
                            style: TextButton.styleFrom(foregroundColor: electricBlue),
                          )
                        ],
                      ),
                      const SizedBox(height: 12),
                      ..._perhentianList.asMap().entries.map((entry) {
                        int idx = entry.key;
                        PerhentianKrlInput perhentian = entry.value;

                        bool isFirstStation = idx == 0;
                        bool isLastStation = idx == _perhentianList.length - 1 && _perhentianList.length > 1;

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          elevation: 1,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  backgroundColor: electricBlue.withAlpha((255 * 0.1).round()),
                                  foregroundColor: electricBlue,
                                  child: Text("${idx + 1}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 3,
                                  child: DropdownButtonFormField<StasiunModel>(
                                    value: perhentian.selectedStasiun,
                                    hint: const Text("Pilih Stasiun"),
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      enabledBorder: defaultOutlineInputBorder,
                                      focusedBorder: focusedOutlineInputBorder,
                                      errorBorder: errorOutlineInputBorder,
                                      focusedErrorBorder: focusedOutlineInputBorder.copyWith(borderSide: const BorderSide(color: Colors.red, width: 2.0)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      isDense: true,
                                    ),
                                    items: _semuaStasiun.map((s) => DropdownMenuItem(value: s, child: Text(s.nama, overflow: TextOverflow.ellipsis))).toList(),
                                    onChanged: (val) => setState(() => perhentian.selectedStasiun = val),
                                    validator: (v) => v == null ? "Pilih stasiun" : null,
                                  ),
                                ),
                                const SizedBox(width: 8),

                                Expanded(
                                  flex: 2,
                                  child: Visibility(
                                    visible: !isFirstStation,
                                    maintainState: true,
                                    maintainAnimation: true,
                                    maintainSize: true,
                                    child: TextFormField(
                                      controller: perhentian.jamDatangController,
                                      decoration: InputDecoration(
                                        labelText: "Datang",
                                        hintText: "HH:mm",
                                        enabledBorder: defaultOutlineInputBorder,
                                        focusedBorder: focusedOutlineInputBorder,
                                        errorBorder: errorOutlineInputBorder,
                                        focusedErrorBorder: focusedOutlineInputBorder.copyWith(borderSide: const BorderSide(color: Colors.red, width: 2.0)),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        isDense: true,
                                      ),
                                      validator: isFirstStation ? null : (v) {
                                        if (v!.isEmpty) return 'Wajib';
                                        if (!RegExp(r'^\d{2}:\d{2}$').hasMatch(v)) return 'Format HH:mm';
                                        return null;
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                Expanded(
                                  flex: 2,
                                  child: Visibility(
                                    visible: !isLastStation,
                                    maintainState: true,
                                    maintainAnimation: true,
                                    maintainSize: true,
                                    child: TextFormField(
                                      controller: perhentian.jamBerangkatController,
                                      decoration: InputDecoration(
                                        labelText: "Berangkat",
                                        hintText: "HH:mm",
                                        enabledBorder: defaultOutlineInputBorder,
                                        focusedBorder: focusedOutlineInputBorder,
                                        errorBorder: errorOutlineInputBorder,
                                        focusedErrorBorder: focusedOutlineInputBorder.copyWith(borderSide: const BorderSide(color: Colors.red, width: 2.0)),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        isDense: true,
                                      ),
                                      validator: isLastStation ? null : (v) {
                                        if (v!.isEmpty) return 'Wajib';
                                        if (!RegExp(r'^\d{2}:\d{2}$').hasMatch(v)) return 'Format HH:mm';
                                        return null;
                                      },
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _hapusPerhentian(idx),
                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _simpanJadwal,
                        icon: const Icon(Icons.save_alt_outlined),
                        label: Text(_isEditing ? 'Simpan Perubahan' : 'Simpan Jadwal KRL'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: electricBlue,
                          foregroundColor: pureWhite,
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
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