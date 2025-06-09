import 'package:flutter/material.dart';
import '../../../models/KeretaModel.dart';
import '../../../models/gerbong_tipe_model.dart';
import '../../../models/stasiun_model.dart';
import '../../../models/kereta_rute_template_model.dart';
import '../services/admin_firestore_service.dart';

class FormKeretaScreen extends StatefulWidget {
  final KeretaModel? keretaToEdit;

  const FormKeretaScreen({super.key, this.keretaToEdit});

  @override
  State<FormKeretaScreen> createState() => _FormKeretaScreenState();
}

class _FormKeretaScreenState extends State<FormKeretaScreen> {
  final _formKey = GlobalKey<FormState>();
  final AdminFirestoreService _adminService = AdminFirestoreService();

  late TextEditingController _namaController;

  List<GerbongTipeModel> _rangkaianGerbong = [];
  List<KeretaRuteTemplateInput> _templateRuteInput = [];

  List<GerbongTipeModel> _semuaTipeGerbong = [];
  List<StasiunModel> _semuaStasiun = [];

  bool get _isEditing => widget.keretaToEdit != null;
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _namaController =
        TextEditingController(text: widget.keretaToEdit?.nama ?? '');
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    try {
      final results = await Future.wait([
        _adminService.getGerbongTipeList().first,
        _adminService.getStasiunList().first,
      ]);
      _semuaTipeGerbong = results[0] as List<GerbongTipeModel>;
      _semuaStasiun = results[1] as List<StasiunModel>;

      if (_isEditing && widget.keretaToEdit != null) {
        final kereta = widget.keretaToEdit!;
        _rangkaianGerbong = kereta.idRangkaianGerbong.map((idGerbong) {
          try {
            return _semuaTipeGerbong.firstWhere((g) => g.id == idGerbong);
          } catch (e) {
            // Handle jika gerbong tidak ditemukan, bisa log atau return null
            print('Gerbong dengan ID $idGerbong tidak ditemukan di data master.');
            return null;
          }
        }).whereType<GerbongTipeModel>().toList();

        _templateRuteInput = kereta.templateRute.map((rute) {
          try {
            final stasiun =
            _semuaStasiun.firstWhere((s) => s.kode == rute.stasiunId);
            return KeretaRuteTemplateInput(
              selectedStasiun: stasiun,
              jamTiba: rute.jamTiba,
              jamBerangkat: rute.jamBerangkat,
              urutan: rute.urutan,
            );
          } catch (e) {
            // Handle jika stasiun tidak ditemukan
            print('Stasiun dengan kode ${rute.stasiunId} tidak ditemukan di data master.');
            return null;
          }
        }).whereType<KeretaRuteTemplateInput>().toList();
        // Pastikan urutan template rute benar setelah load
        _templateRuteInput.sort((a, b) => a.urutan.compareTo(b.urutan));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Gagal memuat data master: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    super.dispose();
  }

  Future<void> _showPilihGerbongDialog() async {
    final GerbongTipeModel? gerbongTerpilih =
    await showDialog<GerbongTipeModel>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Pilih Tipe Gerbong"),
          content: SizedBox(
              width: double.maxFinite,
              child: _semuaTipeGerbong.isEmpty
                  ? const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                    "Tidak ada data tipe gerbong. Harap tambah tipe gerbong di menu 'Kelola Tipe Gerbong' terlebih dahulu.",
                    textAlign: TextAlign.center),
              )
                  : ListView.builder(
                shrinkWrap: true,
                itemCount: _semuaTipeGerbong.length,
                itemBuilder: (context, index) {
                  final gerbong = _semuaTipeGerbong[index];
                  return ListTile(
                    title: Text(gerbong.namaTipeLengkap),
                    subtitle: Text(
                        "Layout: ${gerbong.tipeLayout.deskripsi}, Kursi: ${gerbong.jumlahKursi}"),
                    onTap: () =>
                        Navigator.of(context).pop(gerbong),
                  );
                },
              )),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Batal"))
          ],
        ));
    if (gerbongTerpilih != null) {
      setState(() => _rangkaianGerbong.add(gerbongTerpilih));
    }
  }

  void _addRuteField() => setState(() => _templateRuteInput
      .add(KeretaRuteTemplateInput(urutan: _templateRuteInput.length)));

  void _removeRuteField(int index) {
    setState(() {
      _templateRuteInput.removeAt(index);
      // Update urutan setelah menghapus
      for (int i = 0; i < _templateRuteInput.length; i++) {
        _templateRuteInput[i].urutan = i;
      }
    });
  }


  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_rangkaianGerbong.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Rangkaian gerbong tidak boleh kosong.')));
      return;
    }

    if (_templateRuteInput.length < 2 ||
        _templateRuteInput.any((s) => s.selectedStasiun == null)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Harap lengkapi rute dengan minimal 2 stasiun (asal & tujuan).')));
      return;
    }

    // Validasi jam untuk setiap rute
    for (int i = 0; i < _templateRuteInput.length; i++) {
      final rute = _templateRuteInput[i];
      bool isStasiunAwal = i == 0;
      bool isStasiunAkhir = i == _templateRuteInput.length - 1;

      if (!isStasiunAwal && rute.jamTiba == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Jam tiba untuk ${rute.selectedStasiun?.nama ?? "Stasiun ${i+1}"} belum diisi.')));
        return;
      }
      if (!isStasiunAkhir && rute.jamBerangkat == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Jam berangkat untuk ${rute.selectedStasiun?.nama ?? "Stasiun ${i+1}"} belum diisi.')));
        return;
      }
    }


    final totalKursi =
    _rangkaianGerbong.fold<int>(0, (sum, item) => sum + item.jumlahKursi);

    final kereta = KeretaModel(
      id: _isEditing ? widget.keretaToEdit!.id : '',
      nama: _namaController.text.trim(),
      idRangkaianGerbong: _rangkaianGerbong.map((g) => g.id).toList(),
      templateRute: _templateRuteInput
          .map((input) => KeretaRuteTemplateModel(
        stasiunId: input.selectedStasiun!.kode,
        namaStasiun: input.selectedStasiun!.nama,
        jamTiba: input.jamTiba,
        jamBerangkat: input.jamBerangkat,
        urutan: input.urutan,
      ))
          .toList(),
      totalKursi: totalKursi,
    );

    try {
      if (_isEditing) {
        await _adminService.updateKereta(kereta);
      } else {
        await _adminService.addKereta(kereta);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Kereta berhasil ${_isEditing ? "diperbarui" : "ditambahkan"}!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal menyimpan kereta: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalKursiDisplay =
    _rangkaianGerbong.fold<int>(0, (sum, item) => sum + item.jumlahKursi);

    // Definisikan BorderSide yang akan digunakan berulang kali
    final BorderSide defaultBorderSide =
    BorderSide(color: Colors.grey.shade400);
    final BorderSide focusedBorderSide =
    BorderSide(color: Colors.blueGrey.shade700, width: 2.0);
    const BorderSide errorBorderSide =
    BorderSide(color: Colors.red, width: 1.0);

    // Definisikan InputBorder untuk konsistensi
    final OutlineInputBorder defaultOutlineInputBorder = OutlineInputBorder(
      borderSide: defaultBorderSide,
      borderRadius: BorderRadius.circular(8.0),
    );

    final OutlineInputBorder focusedOutlineInputBorder = OutlineInputBorder(
      borderSide: focusedBorderSide,
      borderRadius: BorderRadius.circular(8.0),
    );

    final OutlineInputBorder errorOutlineInputBorder = OutlineInputBorder(
      borderSide: errorBorderSide,
      borderRadius: BorderRadius.circular(8.0),
    );

    final OutlineInputBorder focusedErrorOutlineInputBorder = OutlineInputBorder(
      borderSide: errorBorderSide.copyWith(width: 2.0),
      borderRadius: BorderRadius.circular(8.0),
    );

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Colors.blueGrey,
        title: Text(
          _isEditing ? "Edit Kereta" : "Tambah Kereta Baru",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w200,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: <Widget>[
            Card(
              elevation: 2.0,
              margin: const EdgeInsets.only(bottom: 24.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Bagian Nama Kereta ---
                    TextFormField(
                      controller: _namaController,
                      decoration: InputDecoration(
                        labelText: 'Nama Kereta (e.g., KA Taksaka)',
                        enabledBorder: defaultOutlineInputBorder,
                        focusedBorder: focusedOutlineInputBorder,
                        errorBorder: errorOutlineInputBorder,
                        focusedErrorBorder: focusedErrorOutlineInputBorder,
                        prefixIcon: Icon(Icons.train_outlined, color: Colors.blueGrey.shade700),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nama kereta tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24.0),

                    // --- Bagian Template Rute & Waktu ---
                    _buildSectionHeader("Template Rute & Waktu (Minimal 2 Stasiun)"),
                    _buildRuteList(), // Ini sudah Card di dalamnya
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: TextButton.icon(
                          onPressed: _addRuteField,
                          icon: const Icon(Icons.add_road_outlined),
                          label: const Text("Tambah Stasiun Rute"),
                          style: TextButton.styleFrom(
                              foregroundColor: Colors.blueGrey.shade700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24.0),

                    // --- Bagian Rangkaian Gerbong ---
                    _buildSectionHeader(
                        "Rangkaian Gerbong (Total: $totalKursiDisplay kursi)"),
                    _buildGerbongList(), // Ini sudah Card di dalamnya
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: TextButton.icon(
                          onPressed: _showPilihGerbongDialog,
                          icon: const Icon(Icons.add_shopping_cart_outlined),
                          label: const Text("Tambah Gerbong"),
                          style: TextButton.styleFrom(
                              foregroundColor: Colors.blueGrey.shade700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Text(
                _isEditing ? 'Simpan Perubahan Kereta' : 'Tambah Kereta Baru',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(fontWeight: FontWeight.w500, color: Colors.blueGrey.shade800),
      ),
    );
  }

  Widget _buildGerbongList() {
    // Card sudah ada di sini, jadi tidak perlu diubah
    return Card(
      elevation: 1.0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
          side: BorderSide(color: Colors.grey.shade300)
      ),
      child: Container(
        child: _rangkaianGerbong.isEmpty
            ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
            child: Center(
                child: Text("Belum ada gerbong ditambahkan ke rangkaian.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600))))
            : ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _rangkaianGerbong.length,
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) newIndex -= 1;
              final item = _rangkaianGerbong.removeAt(oldIndex);
              _rangkaianGerbong.insert(newIndex, item);
            });
          },
          itemBuilder: (context, index) {
            final gerbong = _rangkaianGerbong[index];
            final key = ValueKey('gerbong_${gerbong.id}_$index');
            return ListTile(
              key: key,
              leading: Icon(Icons.drag_handle, color: Colors.grey.shade500),
              title: Text(gerbong.namaTipeLengkap, style: const TextStyle(fontWeight: FontWeight.w500)),
              subtitle: Text(
                  "Layout: ${gerbong.tipeLayout.deskripsi}, Kursi: ${gerbong.jumlahKursi}"),
              trailing: IconButton(
                icon: Icon(Icons.remove_circle_outline,
                    color: Colors.red.shade400),
                onPressed: () =>
                    setState(() => _rangkaianGerbong.removeAt(index)),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRuteList() {
    // Card sudah ada di sini, jadi tidak perlu diubah
    final UnderlineInputBorder ruteInputBorder = UnderlineInputBorder(
      borderSide: BorderSide(color: Colors.grey.shade400),
    );
    final UnderlineInputBorder ruteFocusedInputBorder = UnderlineInputBorder(
      borderSide: BorderSide(color: Colors.blueGrey.shade700, width: 1.5),
    );

    return Card(
      elevation: 1.0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
          side: BorderSide(color: Colors.grey.shade300)
      ),
      child: Container(
        child: _templateRuteInput.isEmpty
            ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
            child: Center(
                child: Text("Tambahkan stasiun untuk memulai template rute.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600))))
            : ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _templateRuteInput.length,
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) newIndex -= 1;
              final item = _templateRuteInput.removeAt(oldIndex);
              _templateRuteInput.insert(newIndex, item);
              // Update urutan setelah reorder
              for (int i = 0; i < _templateRuteInput.length; i++) {
                _templateRuteInput[i].urutan = i;
              }
            });
          },
          itemBuilder: (context, index) {
            final key = ValueKey('rute_stasiun_form_$index');
            final ruteInput = _templateRuteInput[index];
            bool isStasiunAwal = index == 0;
            bool isStasiunAkhir =
                index == _templateRuteInput.length - 1;

            return Padding(
              key: key,
              padding:
              const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Icon(Icons.drag_handle, color: Colors.grey.shade500),
                  ),
                  Expanded(
                    flex: 4,
                    child: DropdownButtonFormField<StasiunModel>(
                      value: ruteInput.selectedStasiun,
                      isExpanded: true,
                      items: _semuaStasiun
                          .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s.displayName,
                              overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (value) => setState(
                              () => ruteInput.selectedStasiun = value),
                      decoration: InputDecoration(
                          hintText: "Pilih Stasiun ${index + 1}",
                          border: ruteInputBorder,
                          focusedBorder: ruteFocusedInputBorder,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
                          isDense: true),
                      validator: (v) => v == null ? "Pilih Stasiun" : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (!isStasiunAwal)
                    Expanded(
                      flex: 3,
                      child: _buildTimePickerField(
                          "Tiba", ruteInput.jamTiba, ruteInputBorder, ruteFocusedInputBorder,
                              (newTime) =>
                              setState(() => ruteInput.jamTiba = newTime)),
                    ),
                  if (!isStasiunAwal && !isStasiunAkhir) const SizedBox(width: 10),
                  if (!isStasiunAkhir)
                    Expanded(
                      flex: 3,
                      child: _buildTimePickerField("Berangkat",
                          ruteInput.jamBerangkat, ruteInputBorder, ruteFocusedInputBorder, (newTime) =>
                              setState(() => ruteInput.jamBerangkat = newTime)),
                    ),
                  IconButton(
                      icon: Icon(Icons.delete_outline,
                          color: Colors.red.shade400),
                      onPressed: () => _removeRuteField(index)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTimePickerField(String label, TimeOfDay? currentTime, InputBorder border, InputBorder focusedBorder, Function(TimeOfDay) onTimeChanged) {
    return InkWell(
      onTap: () async {
        final TimeOfDay? pickedTime = await showTimePicker(
            context: context,
            initialTime: currentTime ?? TimeOfDay.now(),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: Colors.blueGrey,
                    onPrimary: Colors.white,
                    onSurface: Colors.blueGrey.shade700,
                  ),
                  textButtonTheme: TextButtonThemeData(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blueGrey.shade700,
                    ),
                  ),
                ),
                child: child!,
              );
            }
        );
        if (pickedTime != null) {
          onTimeChanged(pickedTime);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade700, fontSize: 14),
          border: border,
          focusedBorder: focusedBorder,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
        ),
        child: Text(
          currentTime?.format(context) ?? 'Pilih Jam',
          style: TextStyle(
              fontWeight: FontWeight.w500,
              color: currentTime != null ? Colors.black87 : Colors.grey.shade600),
        ),
      ),
    );
  }
}

// Helper class untuk state UI form
class KeretaRuteTemplateInput {
  StasiunModel? selectedStasiun;
  TimeOfDay? jamTiba;
  TimeOfDay? jamBerangkat;
  int urutan; // Tetap diperlukan untuk ordering dan mapping ke model

  KeretaRuteTemplateInput({
    this.selectedStasiun,
    this.jamTiba,
    this.jamBerangkat,
    required this.urutan,
  });
}