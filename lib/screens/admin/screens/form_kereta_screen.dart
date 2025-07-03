import 'package:flutter/material.dart';
import '../../../models/KeretaModel.dart';
import '../../../models/gerbong_tipe_model.dart';
import '../../../models/rangkaian_gerbong_model.dart';
import '../../../models/stasiun_model.dart';
import '../../../models/kereta_rute_template_model.dart';
import '../services/admin_firestore_service.dart';

class FormKeretaScreen extends StatefulWidget {
  final KeretaModel? kereta;
  final bool isDuplicating;

  const FormKeretaScreen({
    super.key,
    this.kereta,
    this.isDuplicating = false,
  });

  @override
  State<FormKeretaScreen> createState() => _FormKeretaScreenState();
}

class _FormKeretaScreenState extends State<FormKeretaScreen> {
  final _formKey = GlobalKey<FormState>();
  final AdminFirestoreService _adminService = AdminFirestoreService();

  late TextEditingController _namaController;

  List<RangkaianGerbongInput> _rangkaianGerbongInput = [];
  List<KeretaRuteTemplateInput> _templateRuteInput = [];

  List<GerbongTipeModel> _semuaTipeGerbong = [];
  List<StasiunModel> _semuaStasiun = [];

  // Logika _isEditing diubah untuk menangani kasus duplikasi
  bool get _isEditing => widget.kereta != null && !widget.isDuplicating;
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(); // Inisialisasi kosong dulu
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

      if (widget.kereta != null) {
        final kereta = widget.kereta!;

        // Jika tidak sedang menyalin, isi nama kereta. Jika menyalin, biarkan kosong.
        if (!widget.isDuplicating) {
          _namaController.text = kereta.nama;
        }

        // Salin rangkaian gerbong dan rute untuk kedua kasus (edit dan salin)
        _rangkaianGerbongInput = kereta.rangkaian.map((rg) {
          try {
            return RangkaianGerbongInput(
              nomorGerbong: rg.nomorGerbong,
              selectedTipeGerbong: _semuaTipeGerbong.firstWhere((g) => g.id == rg.idTipeGerbong),
            );
          } catch (e) { return null; }
        }).whereType<RangkaianGerbongInput>().toList();

        _templateRuteInput = kereta.templateRute.map((rute) {
          try {
            final stasiun = _semuaStasiun.firstWhere((s) => s.kode == rute.stasiunId);
            return KeretaRuteTemplateInput(
              selectedStasiun: stasiun,
              jamTiba: rute.jamTiba,
              jamBerangkat: rute.jamBerangkat,
              urutan: rute.urutan,
            );
          } catch (e) { return null; }
        }).whereType<KeretaRuteTemplateInput>().toList();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal memuat data master: $e")));
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    for (var item in _templateRuteInput) {
      item.dispose();
    }
    super.dispose();
  }

  // ============== DIALOG UNTUK MEMILIH TIPE GERBONG ==============
  Future<void> _showPilihGerbongDialog() async {
    final GerbongTipeModel? gerbongTerpilih = await showDialog<GerbongTipeModel>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Pilih Tipe Gerbong"),
          content: SizedBox(
              width: double.maxFinite,
              child: _semuaTipeGerbong.isEmpty
                  ? const Text("Tidak ada data. Harap tambah tipe gerbong di menu 'Kelola Tipe Gerbong'.")
                  : ListView.builder(
                shrinkWrap: true,
                itemCount: _semuaTipeGerbong.length,
                itemBuilder: (context, index) {
                  final gerbong = _semuaTipeGerbong[index];
                  return ListTile(
                    leading: Image.asset(
                      'images/${gerbong.imageAssetPath}',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.image_not_supported, size: 50, color: Colors.grey);
                      },
                    ),
                    title: Text(gerbong.namaTipeLengkap),
                    subtitle: Text("Layout: ${gerbong.tipeLayout.deskripsi}, Kursi: ${gerbong.jumlahKursi}"),
                    onTap: () => Navigator.of(context).pop(gerbong),
                  );
                },
              )),
          actions: [ TextButton(onPressed: () => Navigator.of(context)  .pop(), child: const Text("Batal")) ],
        )
    );
    if (gerbongTerpilih != null) {
      setState(() => _rangkaianGerbongInput.add(RangkaianGerbongInput(nomorGerbong: _rangkaianGerbongInput.length + 1, selectedTipeGerbong: gerbongTerpilih)));
      _updateNomorGerbong();
    }
  }

  // ============== DIALOG UNTUK MENCARI & MEMILIH STASIUN ==============
  Future<StasiunModel?> _showPilihStasiunDialog() async {
    String searchQuery = '';
    List<StasiunModel> filteredStasiun = _semuaStasiun;

    return showDialog<StasiunModel>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Pilih Stasiun'),
              content: SizedBox(
                width: double.maxFinite,
                height: MediaQuery.of(context).size.height * 0.6,
                child: Column(
                  children: [
                    TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Cari Stasiun',
                        hintText: 'Ketik nama atau kode stasiun...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      onChanged: (value) {
                        setDialogState(() {
                          searchQuery = value.toLowerCase();
                          filteredStasiun = _semuaStasiun.where((stasiun) {
                            final nameMatch = stasiun.nama.toLowerCase().contains(searchQuery);
                            final codeMatch = stasiun.kode.toLowerCase().contains(searchQuery);
                            final cityMatch = stasiun.kota.toLowerCase().contains(searchQuery);
                            return nameMatch || codeMatch || cityMatch;
                          }).toList();
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredStasiun.length,
                        itemBuilder: (context, index) {
                          final stasiun = filteredStasiun[index];
                          return ListTile(
                            title: Text(stasiun.nama),
                            subtitle: Text("${stasiun.kode} - ${stasiun.kota}"),
                            onTap: () => Navigator.of(context).pop(stasiun),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Batal'),
                ),
              ],
            );
          },
        );
      },
    );
  }


  void _addRuteField() {
    setState(() {
      _templateRuteInput.add(KeretaRuteTemplateInput(urutan: _templateRuteInput.length));
    });
  }

  void _removeRuteField(int index) {
    setState(() {
      _templateRuteInput.removeAt(index);
      _updateUrutanRute();
    });
  }

  void _updateUrutanRute() {
    for (int i = 0; i < _templateRuteInput.length; i++) {
      _templateRuteInput[i].urutan = i;
    }
  }

  void _removeGerbongField(int index) {
    setState(() {
      _rangkaianGerbongInput.removeAt(index);
      _updateNomorGerbong();
    });
  }

  void _updateNomorGerbong() {
    for (int i = 0; i < _rangkaianGerbongInput.length; i++) {
      _rangkaianGerbongInput[i].nomorGerbong = i + 1;
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_templateRuteInput.length < 2 || _templateRuteInput.any((s) => s.selectedStasiun == null)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harap lengkapi rute dengan minimal 2 stasiun (asal & tujuan).')));
      return;
    }
    if (_rangkaianGerbongInput.isEmpty || _rangkaianGerbongInput.any((g) => g.selectedTipeGerbong == null)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rangkaian kereta tidak boleh kosong dan semua gerbong harus dipilih tipenya.')));
      return;
    }

    final totalKursi = _rangkaianGerbongInput.fold<int>(0, (sum, item) => sum + (item.selectedTipeGerbong?.jumlahKursi ?? 0));

    final kereta = KeretaModel(
      id: _isEditing ? widget.kereta!.id : '', // Hanya gunakan ID jika sedang mengedit
      nama: _namaController.text,
      rangkaian: _rangkaianGerbongInput.map((input) => RangkaianGerbongModel(
        nomorGerbong: input.nomorGerbong,
        idTipeGerbong: input.selectedTipeGerbong!.id,
      )).toList(),
      templateRute: _templateRuteInput.map((input) => KeretaRuteTemplateModel(
        stasiunId: input.selectedStasiun!.kode,
        namaStasiun: input.selectedStasiun!.nama,
        jamTiba: input.jamTiba,
        jamBerangkat: input.jamBerangkat,
        urutan: input.urutan,
      )).toList(),
      totalKursi: totalKursi,
    );

    try {
      if (_isEditing) {
        await _adminService.updateKereta(kereta);
      } else {
        // Kasus ini berlaku untuk menambah baru dan menyalin
        await _adminService.addKereta(kereta);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kereta berhasil ${ _isEditing ? "diperbarui" : "disimpan"}!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan kereta: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalKursiDisplay = _rangkaianGerbongInput.fold<int>(0, (sum, item) => sum + (item.selectedTipeGerbong?.jumlahKursi ?? 0));

    // Definisikan border style agar konsisten
    final OutlineInputBorder defaultOutlineInputBorder = OutlineInputBorder(
      borderSide: BorderSide(color: Colors.grey.shade400),
      borderRadius: BorderRadius.circular(8.0),
    );
    final OutlineInputBorder focusedOutlineInputBorder = OutlineInputBorder(
      borderSide: BorderSide(color: Colors.blueGrey.shade700, width: 2.0),
      borderRadius: BorderRadius.circular(8.0),
    );

    // --- MENENTUKAN JUDUL DAN TEKS TOMBOL SECARA DINAMIS ---
    String appBarTitle;
    String submitButtonText;
    if (widget.isDuplicating) {
      appBarTitle = "Salin Data Kereta";
      submitButtonText = "Simpan Salinan";
    } else if (_isEditing) {
      appBarTitle = "Edit Kereta";
      submitButtonText = "Simpan Perubahan";
    } else {
      appBarTitle = "Tambah Kereta Baru";
      submitButtonText = "Tambah Kereta";
    }

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Colors.blueGrey,
        title: Text(
          appBarTitle,
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
                    children: <Widget>[
                      TextFormField(
                        controller: _namaController,
                        decoration: InputDecoration(
                          labelText: 'Nama Kereta (e.g., KA Taksaka)',
                          hintText: widget.isDuplicating ? 'Wajib isi nama kereta baru' : 'Nama kereta',
                          enabledBorder: defaultOutlineInputBorder,
                          focusedBorder: focusedOutlineInputBorder,
                          prefixIcon: Icon(Icons.train_outlined, color: Colors.blueGrey.shade700),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Nama tidak boleh kosong' : null,
                      ),
                      const SizedBox(height: 24.0),

                      _buildSectionHeader("Template Rute & Waktu"),
                      const SizedBox(height: 8.0),
                      _buildRuteList(),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: _addRuteField,
                          icon: const Icon(Icons.add),
                          label: const Text("Tambah Stasiun Rute"),
                          style: TextButton.styleFrom(foregroundColor: Colors.blueGrey.shade800),
                        ),
                      ),
                      const SizedBox(height: 24.0),

                      _buildSectionHeader("Rangkaian Gerbong (Total: $totalKursiDisplay kursi)"),
                      const SizedBox(height: 8.0),
                      _buildGerbongList(),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: _showPilihGerbongDialog,
                          icon: const Icon(Icons.add),
                          label: const Text("Tambah Gerbong"),
                          style: TextButton.styleFrom(foregroundColor: Colors.blueGrey.shade800),
                        ),
                      ),
                      const SizedBox(height: 32.0),
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
                          submitButtonText,
                          style: const TextStyle(fontSize: 16),
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

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: Colors.blueGrey.shade800,
      ),
    );
  }

  Widget _buildGerbongList() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: _rangkaianGerbongInput.isEmpty
          ? const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text("Belum ada gerbong ditambahkan.", textAlign: TextAlign.center)),
      )
          : ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _rangkaianGerbongInput.length,
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (newIndex > oldIndex) newIndex -= 1;
            final item = _rangkaianGerbongInput.removeAt(oldIndex);
            _rangkaianGerbongInput.insert(newIndex, item);
            _updateNomorGerbong();
          });
        },
        itemBuilder: (context, index) {
          final gerbongInput = _rangkaianGerbongInput[index];
          final key = ValueKey('gerbong_input_${gerbongInput.hashCode}');
          return ListTile(
            key: key,
            leading: ReorderableDragStartListener(index: index, child: const Icon(Icons.drag_handle, color: Colors.grey)),
            title: Text("Gerbong ${gerbongInput.nomorGerbong}"),
            subtitle: DropdownButtonFormField<GerbongTipeModel>(
              value: gerbongInput.selectedTipeGerbong,
              isExpanded: true,
              items: _semuaTipeGerbong.map((g) => DropdownMenuItem(value: g, child: Text(g.namaTipeLengkap, overflow: TextOverflow.ellipsis,))).toList(),
              onChanged: (value) => setState(() => gerbongInput.selectedTipeGerbong = value),
              decoration: const InputDecoration(hintText: "Pilih Tipe", border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
              validator: (v) => v == null ? "Pilih tipe" : null,
            ),
            trailing: IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
              onPressed: () => _removeGerbongField(index),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRuteList() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: _templateRuteInput.isEmpty
          ? const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text("Tambahkan stasiun untuk memulai rute.", textAlign: TextAlign.center)),
      )
          : ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _templateRuteInput.length,
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (newIndex > oldIndex) newIndex -= 1;
            final item = _templateRuteInput.removeAt(oldIndex);
            _templateRuteInput.insert(newIndex, item);
            _updateUrutanRute();
          });
        },
        itemBuilder: (context, index) {
          final key = ValueKey('rute_stasiun_$index');
          final ruteInput = _templateRuteInput[index];
          bool isStasiunAwal = index == 0;
          bool isStasiunAkhir = index == _templateRuteInput.length - 1;

          return Padding(
            key: key,
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ReorderableDragStartListener(index: index, child: const Icon(Icons.drag_handle, color: Colors.grey)),
                const SizedBox(width: 8),
                Expanded(
                  flex: 5,
                  child: FormField<StasiunModel>(
                    validator: (v) => ruteInput.selectedStasiun == null ? "Pilih" : null,
                    builder: (formFieldState) {
                      return InkWell(
                        onTap: () async {
                          final StasiunModel? stasiunTerpilih = await _showPilihStasiunDialog();
                          if (stasiunTerpilih != null) {
                            if (_templateRuteInput.where((r) => r.urutan != ruteInput.urutan).any((r) => r.selectedStasiun?.id == stasiunTerpilih.id)) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('${stasiunTerpilih.nama} sudah ada di dalam rute.', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.orange,)
                                );
                              }
                            } else {
                              setState(() => ruteInput.selectedStasiun = stasiunTerpilih);
                            }
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            hintText: "Stasiun ${index + 1}",
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
                            errorText: formFieldState.errorText,
                          ),
                          child: Text(
                            ruteInput.selectedStasiun?.displayName ?? 'Ketuk untuk memilih',
                            style: TextStyle(
                                color: ruteInput.selectedStasiun != null ? Colors.black87 : Colors.grey.shade600,
                                overflow: TextOverflow.ellipsis
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                if (!isStasiunAwal)
                  Expanded(
                    flex: 3,
                    child: _buildTimePickerField("Tiba", ruteInput.jamTiba, (newTime) => setState(() => ruteInput.jamTiba = newTime)),
                  ),
                if (!isStasiunAkhir)
                  Expanded(
                    flex: 3,
                    child: _buildTimePickerField("Berangkat", ruteInput.jamBerangkat, (newTime) => setState(() => ruteInput.jamBerangkat = newTime)),
                  ),
                IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _removeRuteField(index)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimePickerField(String label, TimeOfDay? currentTime, Function(TimeOfDay) onTimeChanged) {
    return InkWell(
      onTap: () async {
        final TimeOfDay? pickedTime = await showTimePicker(
          context: context,
          initialTime: currentTime ?? TimeOfDay.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Colors.blueGrey,
                  onPrimary: Colors.white,
                ),
              ),
              child: child!,
            );
          },
        );
        if (pickedTime != null) {
          onTimeChanged(pickedTime);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
        child: Text(
          currentTime?.format(context) ?? '--:--',
          style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.blueGrey),
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
  int urutan;

  KeretaRuteTemplateInput({this.selectedStasiun, this.jamTiba, this.jamBerangkat, required this.urutan});

  void dispose() {} // Tidak ada controller untuk di-dispose
}

class RangkaianGerbongInput {
  int nomorGerbong;
  GerbongTipeModel? selectedTipeGerbong;
  RangkaianGerbongInput({required this.nomorGerbong, this.selectedTipeGerbong});
}