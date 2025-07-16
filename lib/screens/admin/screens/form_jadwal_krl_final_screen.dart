import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kaig/models/jadwal_krl_model.dart';
import 'package:kaig/models/perhentian_krl_model.dart';
import 'package:kaig/models/stasiun_model.dart';
import 'package:kaig/screens/admin/services/admin_firestore_service.dart';

// Helper class untuk input di UI, dikembalikan untuk mengakomodasi jam datang
class PerhentianKrlInput {
  StasiunModel? selectedStasiun;
  TextEditingController jamBerangkatController;
  TextEditingController jamDatangController; // Ditambahkan kembali

  PerhentianKrlInput({
    this.selectedStasiun,
    String? jamBerangkat,
    String? jamDatang, // Ditambahkan kembali
  })  : jamBerangkatController = TextEditingController(text: jamBerangkat),
        jamDatangController = TextEditingController(text: jamDatang); // Ditambahkan kembali

  void dispose() {
    jamBerangkatController.dispose();
    jamDatangController.dispose(); // Ditambahkan kembali
  }
}

class FormJadwalKrlFinalScreen extends StatefulWidget {
  final JadwalKrlModel? jadwal;
  final bool isDuplicating;
  const FormJadwalKrlFinalScreen({super.key, this.jadwal, this.isDuplicating = false});

  @override
  _FormJadwalKrlFinalScreenState createState() => _FormJadwalKrlFinalScreenState();
}

class _FormJadwalKrlFinalScreenState extends State<FormJadwalKrlFinalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = AdminFirestoreService();

  late TextEditingController _nomorKaController;
  late TextEditingController _hargaController;
  String? _selectedRelasi;
  String? _selectedTipeHari;
  List<PerhentianKrlInput> _perhentianList = [];
  List<StasiunModel> _semuaStasiun = [];
  bool _isLoading = true;

  // Opsi relasi menggunakan singkatan
  final List<String> _relasiOptions = ["YK - PL", "PL - YK"];

  bool get _isEditing => widget.jadwal != null && !widget.isDuplicating;

  static const Color charcoalGray = Color(0xFF374151);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color electricBlue = Color(0xFF3B82F6);

  @override
  void initState() {
    super.initState();
    _nomorKaController = TextEditingController();
    _hargaController = TextEditingController();

    if (widget.jadwal != null) {
      final jadwal = widget.jadwal!;
      _nomorKaController.text = jadwal.nomorKa + (widget.isDuplicating ? " (Salinan)" : "");
      _selectedRelasi = jadwal.relasi;
      _hargaController.text = jadwal.harga.toString();
      _selectedTipeHari = jadwal.tipeHari;
    }

    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final stasiunList = await _firestoreService.getStasiunList().first;
      if (!mounted) return;

      List<PerhentianKrlInput> initialPerhentian = [];
      if (widget.jadwal != null) {
        initialPerhentian = widget.jadwal!.perhentian.map<PerhentianKrlInput>((p) {
          final stasiunTerpilih = stasiunList.firstWhere(
                (s) => s.kode == p.kodeStasiun,
            orElse: () => StasiunModel(id: p.kodeStasiun, kode: p.kodeStasiun, nama: p.namaStasiun, kota: ''),
          );

          return PerhentianKrlInput(
            selectedStasiun: stasiunTerpilih,
            jamBerangkat: p.jamBerangkat,
            jamDatang: p.jamDatang, // Memuat jam datang
          );
        }).toList();
      }

      setState(() {
        _semuaStasiun = stasiunList;
        _perhentianList = initialPerhentian.isEmpty ? [PerhentianKrlInput()] : initialPerhentian;
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
    if (_perhentianList.length > 1) {
      setState(() {
        _perhentianList[index].dispose();
        _perhentianList.removeAt(index);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimal harus ada satu stasiun perhentian.')),
      );
    }
  }

  /// Menampilkan time picker dan mengisi controller dengan waktu yang dipilih
  Future<void> _selectTime(BuildContext context, TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        // Memastikan format 24 jam
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null) {
      // Format TimeOfDay ke string "HH:mm"
      final localizations = MaterialLocalizations.of(context);
      final formattedTime = localizations.formatTimeOfDay(picked, alwaysUse24HourFormat: true);
      controller.text = formattedTime;
    }
  }

  Future<void> _simpanJadwal() async {
    if (!_formKey.currentState!.validate()) return;
    if (_perhentianList.length < 2 || _perhentianList.any((p) => p.selectedStasiun == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi data & pastikan minimal ada 2 stasiun perhentian.')),
      );
      return;
    }

    final jadwalKrl = JadwalKrlModel(
      id: _isEditing ? widget.jadwal?.id : null,
      nomorKa: _nomorKaController.text.trim(),
      relasi: _selectedRelasi!,
      harga: int.tryParse(_hargaController.text.trim()) ?? 0,
      tipeHari: _selectedTipeHari!,
      perhentian: _perhentianList.asMap().entries.map((entry) {
        int idx = entry.key;
        PerhentianKrlInput p = entry.value;
        bool isLastStation = idx == _perhentianList.length - 1;

        return PerhentianKrlModel(
          kodeStasiun: p.selectedStasiun!.kode,
          namaStasiun: p.selectedStasiun!.nama,
          jamDatang: isLastStation ? (p.jamDatangController.text.trim().isNotEmpty ? p.jamDatangController.text.trim() : null) : null,
          jamBerangkat: isLastStation ? null : (p.jamBerangkatController.text.trim().isNotEmpty ? p.jamBerangkatController.text.trim() : null),
          urutan: idx,
        );
      }).toList(),
    );

    try {
      String message;
      if (_isEditing) {
        await _firestoreService.updateJadwalKrl(jadwalKrl);
        message = "Jadwal KRL berhasil diperbarui!";
      } else {
        await _firestoreService.addJadwalKrl(jadwalKrl);
        message = "Jadwal KRL berhasil ditambahkan!";
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan jadwal: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    String appBarTitle;
    String submitButtonText;
    IconData submitButtonIcon;

    if (widget.isDuplicating) {
      appBarTitle = "Salin Jadwal KRL";
      submitButtonText = "Simpan Salinan";
      submitButtonIcon = Icons.copy_rounded;
    } else if (_isEditing) {
      appBarTitle = "Edit Jadwal KRL";
      submitButtonText = "Simpan Perubahan";
      submitButtonIcon = Icons.save_alt_outlined;
    } else {
      appBarTitle = "Tambah Jadwal Baru";
      submitButtonText = "Simpan Jadwal";
      submitButtonIcon = Icons.add_circle_outline;
    }

    final OutlineInputBorder defaultOutlineInputBorder = OutlineInputBorder(
      borderSide: BorderSide(color: Colors.grey.shade400),
      borderRadius: BorderRadius.circular(8.0),
    );
    final OutlineInputBorder focusedOutlineInputBorder = OutlineInputBorder(
      borderSide: const BorderSide(color: electricBlue, width: 2.0),
      borderRadius: BorderRadius.circular(8.0),
    );
    final OutlineInputBorder errorOutlineInputBorder = OutlineInputBorder(
      borderSide: const BorderSide(color: Colors.red, width: 1.0),
      borderRadius: BorderRadius.circular(8.0),
    );

    /// Helper widget untuk membuat input waktu dengan time picker
    Widget _buildTimePickerField({
      required TextEditingController controller,
      required String label,
    }) {
      return TextFormField(
        controller: controller,
        readOnly: true, // Membuat field tidak bisa diketik manual
        decoration: InputDecoration(
          labelText: label,
          hintText: "HH:mm",
          enabledBorder: defaultOutlineInputBorder,
          focusedBorder: focusedOutlineInputBorder,
          errorBorder: errorOutlineInputBorder,
          focusedErrorBorder: errorOutlineInputBorder.copyWith(borderSide: const BorderSide(color: Colors.red, width: 2.0)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          isDense: true,
          suffixIcon: Icon(Icons.access_time_filled_rounded, color: electricBlue.withAlpha(150)),
        ),
        onTap: () => _selectTime(context, controller), // Memanggil time picker saat diketuk
        validator: (v) {
          if (v == null || v.isEmpty) return 'Wajib';
          if (!RegExp(r'^\d{2}:\d{2}$').hasMatch(v)) return 'Format HH:mm';
          return null;
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: charcoalGray,
        title: Text(
          appBarTitle,
          style: const TextStyle(color: pureWhite, fontSize: 24, fontWeight: FontWeight.w200),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
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
                          prefixIcon: const Icon(Icons.confirmation_number_outlined, color: electricBlue),
                        ),
                        validator: (v) => v!.isEmpty ? "Nomor KA wajib diisi" : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedRelasi,
                        decoration: InputDecoration(
                          labelText: "Relasi",
                          enabledBorder: defaultOutlineInputBorder,
                          focusedBorder: focusedOutlineInputBorder,
                          errorBorder: errorOutlineInputBorder,
                          focusedErrorBorder: focusedOutlineInputBorder.copyWith(borderSide: const BorderSide(color: Colors.red, width: 2.0)),
                          prefixIcon: const Icon(Icons.route_outlined, color: electricBlue),
                        ),
                        items: _relasiOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (val) => setState(() => _selectedRelasi = val),
                        validator: (v) => v == null ? "Pilih relasi" : null,
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
                          prefixIcon: const Icon(Icons.attach_money_outlined, color: electricBlue),
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
                          prefixIcon: const Icon(Icons.date_range_outlined, color: electricBlue),
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
                        bool isLastStation = idx == _perhentianList.length - 1;

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
                                  backgroundColor: electricBlue.withAlpha(26),
                                  foregroundColor: electricBlue,
                                  child: Text("${idx + 1}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 5,
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
                                // Input Jam Tiba (hanya untuk stasiun terakhir)
                                if (isLastStation)
                                  Expanded(
                                    flex: 3,
                                    child: _buildTimePickerField(
                                      controller: perhentian.jamDatangController,
                                      label: "Tiba",
                                    ),
                                  ),
                                // Input Jam Berangkat (untuk semua kecuali stasiun terakhir)
                                if (!isLastStation)
                                  Expanded(
                                    flex: 3,
                                    child: _buildTimePickerField(
                                      controller: perhentian.jamBerangkatController,
                                      label: "Berangkat",
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
                        icon: Icon(submitButtonIcon),
                        label: Text(submitButtonText),
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
    _hargaController.dispose();
    for (var p in _perhentianList) {
      p.dispose();
    }
    super.dispose();
  }
}
