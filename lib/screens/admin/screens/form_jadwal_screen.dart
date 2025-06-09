import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:table_calendar/table_calendar.dart'; // Package untuk multi-date picker
import '../../../models/JadwalModel.dart';
import '../../../models/KeretaModel.dart';
import '../../../models/jadwal_kelas_info_model.dart';
import '../../../models/gerbong_tipe_model.dart';
import '../../../models/jadwal_perhentian_model.dart';
import '../../../models/rangkaian_gerbong_model.dart';
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

  List<KeretaModel> _keretaList = [];
  List<GerbongTipeModel> _semuaTipeGerbong = [];
  KeretaModel? _selectedKereta;
  List<DateTime> _selectedDates = [];
  Map<String, List<KelasHargaInput>> _hargaPerKelas = {};
  bool _isLoading = true;
  bool _isSubmitting = false;

  bool get _isEditing => widget.jadwalToEdit != null;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  @override
  void dispose() {
    _hargaPerKelas.forEach((_, inputs) {
      for (var input in inputs) {
        input.dispose();
      }
    });
    super.dispose();
  }

  Future<void> _fetchInitialData() async {
    try {
      final results = await Future.wait([
        _adminService.getKeretaList().first,
        _adminService.getGerbongTipeList().first,
      ]);
      _keretaList = results[0] as List<KeretaModel>;
      _semuaTipeGerbong = results[1] as List<GerbongTipeModel>;

      if (_isEditing) {
        _initializeForEditMode();
      }

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal memuat data master: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _initializeForEditMode() {
    final jadwal = widget.jadwalToEdit!;
    try {
      _selectedKereta = _keretaList.firstWhere((k) => k.id == jadwal.idKereta);
    } catch (e) {
      print("Gagal menemukan kereta yang akan di-edit: $e");
    }

    _selectedDates = [jadwal.tanggalBerangkatUtama.toDate()];

    _hargaPerKelas.clear();
    final kelasDiRangkaian = _getKelasFromRangkaian(_selectedKereta?.rangkaian ?? []);
    for (var kelas in kelasDiRangkaian) {
      _hargaPerKelas[kelas.name] = [];
    }
    for (var hargaInfo in jadwal.daftarKelasHarga) {
      _hargaPerKelas[hargaInfo.namaKelas]?.add(
          KelasHargaInput(
              subKelas: hargaInfo.subKelas ?? '',
              harga: hargaInfo.harga.toString(),
              kuota: hargaInfo.kuota.toString()
          )
      );
    }
  }

  void _onKeretaSelected(KeretaModel? kereta) {
    if (kereta == null) return;
    setState(() {
      _selectedKereta = kereta;
      _hargaPerKelas.clear();

      final kelasDiRangkaian = _getKelasFromRangkaian(kereta.rangkaian);
      for (var kelas in kelasDiRangkaian) {
        _hargaPerKelas[kelas.name] = [KelasHargaInput()];
      }
    });
  }

  Set<KelasUtama> _getKelasFromRangkaian(List<RangkaianGerbongModel> rangkaian) {
    Set<KelasUtama> kelasSet = {};
    for (var rg in rangkaian) {
      try {
        final gerbong = _semuaTipeGerbong.firstWhere((g) => g.id == rg.idTipeGerbong);
        kelasSet.add(gerbong.kelas);
      } catch (e) {
        print("Gerbong dengan ID ${rg.idTipeGerbong} tidak ditemukan di master data.");
      }
    }
    return kelasSet;
  }

  void _showMultiDatePicker() async {
    if (_isEditing) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tanggal tidak dapat diubah pada mode edit.")));
      return;
    }
    await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Pilih Tanggal Keberangkatan"),
          content: SizedBox(
            width: double.maxFinite,
            child: MultiDatePicker(
              initialDates: _selectedDates,
              onDatesSelected: (dates) {
                if(mounted) {
                  setState(() {
                    _selectedDates = dates;
                  });
                }
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Selesai"))
          ],
        )
    );
  }

  void _addHargaSubKelas(String namaKelas) {
    setState(() {
      _hargaPerKelas[namaKelas]?.add(KelasHargaInput());
    });
  }

  void _removeHargaSubKelas(String namaKelas, int index) {
    setState(() {
      _hargaPerKelas[namaKelas]?[index].dispose();
      _hargaPerKelas[namaKelas]?.removeAt(index);
    });
  }

  Future<void> _submitForm() async {
    if (_isLoading || _isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;
    if (_selectedKereta == null || _selectedDates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Harap pilih kereta dan minimal satu tanggal.")));
      return;
    }

    List<JadwalKelasInfoModel> daftarKelasHargaFinal = [];
    try {
      _hargaPerKelas.forEach((namaKelas, inputs) {
        if (inputs.isEmpty) {
          throw Exception("Setiap kelas harus memiliki minimal satu harga sub-kelas.");
        }
        int totalKuotaSubKelas = 0;
        for (var input in inputs) {
          if (input.subKelasController.text.isEmpty || input.hargaController.text.isEmpty || input.kuotaController.text.isEmpty) {
            throw Exception("Lengkapi semua field (Sub-Kelas, Harga, Kuota) untuk kelas $namaKelas.");
          }
          final harga = int.tryParse(input.hargaController.text);
          final kuota = int.tryParse(input.kuotaController.text);
          if (harga == null || kuota == null || harga <= 0 || kuota <= 0) {
            throw Exception("Harga dan Kuota harus berupa angka positif.");
          }
          totalKuotaSubKelas += kuota;
          daftarKelasHargaFinal.add(JadwalKelasInfoModel(
            namaKelas: namaKelas,
            subKelas: input.subKelasController.text.toUpperCase(),
            harga: harga,
            kuota: kuota,
          ));
        }

        int totalKursiFisikKelasIni = _selectedKereta!.rangkaian
            .map((rg) {
          try { return _semuaTipeGerbong.firstWhere((g) => g.id == rg.idTipeGerbong); }
          catch(e) { return null; }
        })
            .whereType<GerbongTipeModel>()
            .where((g) => g.kelas.name == namaKelas)
            .fold(0, (sum, g) => sum + g.jumlahKursi);

        if (totalKuotaSubKelas > totalKursiFisikKelasIni) {
          throw Exception("Total kuota ($totalKuotaSubKelas) untuk kelas $namaKelas melebihi total kursi fisik ($totalKursiFisikKelasIni).");
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst("Exception: ", ""))));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      int jadwalBerhasil = 0;
      final rangkaianGerbongTipe = _selectedKereta!.rangkaian
          .map((rg) {
        try { return _semuaTipeGerbong.firstWhere((g) => g.id == rg.idTipeGerbong); }
        catch(e) { return null; }
      }).whereType<GerbongTipeModel>().toList();

      for (final tanggal in _selectedDates) {
        List<JadwalPerhentianModel> detailPerhentianUntukJadwal = [];
        DateTime hariTerakhir = tanggal;

        for (int i = 0; i < _selectedKereta!.templateRute.length; i++) {
          final template = _selectedKereta!.templateRute[i];
          DateTime hariBerangkat = hariTerakhir;
          DateTime hariTiba = hariTerakhir;

          if (i > 0) {
            final perhentianSebelumnya = _selectedKereta!.templateRute[i - 1];
            if (template.jamTiba != null && perhentianSebelumnya.jamBerangkat != null) {
              if (template.jamTiba!.hour < perhentianSebelumnya.jamBerangkat!.hour) {
                hariTiba = hariTerakhir.add(const Duration(days: 1));
              }
            }
          }
          if (template.jamTiba != null && template.jamBerangkat != null) {
            if (template.jamBerangkat!.hour < template.jamTiba!.hour) {
              hariBerangkat = hariTiba;
            } else if (template.jamBerangkat!.hour > template.jamTiba!.hour) {
              hariBerangkat = hariTiba.add(const Duration(days: 1));
            }
          }

          hariTerakhir = hariBerangkat;

          Timestamp? waktuTibaTimestamp = (template.jamTiba != null)
              ? Timestamp.fromDate(DateTime(hariTiba.year, hariTiba.month, hariTiba.day, template.jamTiba!.hour, template.jamTiba!.minute))
              : null;
          Timestamp? waktuBerangkatTimestamp = (template.jamBerangkat != null)
              ? Timestamp.fromDate(DateTime(hariBerangkat.year, hariBerangkat.month, hariBerangkat.day, template.jamBerangkat!.hour, template.jamBerangkat!.minute))
              : null;

          detailPerhentianUntukJadwal.add(JadwalPerhentianModel(
            idStasiun: template.stasiunId,
            namaStasiun: template.namaStasiun,
            waktuTiba: waktuTibaTimestamp,
            waktuBerangkat: waktuBerangkatTimestamp,
            urutan: template.urutan,
          ));
        }

        final jadwalData = JadwalModel(
          id: _isEditing ? widget.jadwalToEdit!.id : '',
          idKereta: _selectedKereta!.id,
          namaKereta: _selectedKereta!.nama,
          detailPerhentian: detailPerhentianUntukJadwal,
          daftarKelasHarga: daftarKelasHargaFinal,
        );

        if (_isEditing) {
          await _adminService.updateJadwal(jadwalData);
        } else {
          final docRef = await _adminService.addJadwal(jadwalData);
          await _adminService.generateKursiUntukJadwal(docRef.id, rangkaianGerbongTipe);
        }
        jadwalBerhasil++;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$jadwalBerhasil jadwal berhasil ${ _isEditing ? "diperbarui" : "dibuat"} dan kursi telah digenerate!')),
        );
        Navigator.pop(context);
      }

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan jadwal: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
      borderSide: BorderSide(color: Colors.blueGrey.shade700, width: 2.0),
      borderRadius: BorderRadius.circular(8.0),
    );

    return Scaffold(
      // --- PERUBAHAN AppBar ---
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Colors.blueGrey,
        title: Text(
          _isEditing ? "Edit Jadwal" : "Buat Jadwal Baru",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w200,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // --- PERUBAHAN Body ---
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            // --- Bungkus dengan Card ---
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
                      // --- PERUBAHAN Dropdown Style ---
                      DropdownButtonFormField<KeretaModel>(
                        value: _selectedKereta,
                        items: _keretaList.map((kereta) => DropdownMenuItem(value: kereta, child: Text(kereta.nama))).toList(),
                        onChanged: _isEditing ? null : _onKeretaSelected,
                        decoration: InputDecoration(
                          labelText: 'Pilih Kereta',
                          enabledBorder: defaultOutlineInputBorder,
                          focusedBorder: focusedOutlineInputBorder,
                          prefixIcon: Icon(Icons.train_outlined, color: Colors.blueGrey.shade700),
                          filled: _isEditing,
                          fillColor: Colors.grey[200],
                        ),
                        validator: (value) => value == null ? 'Kereta harus dipilih' : null,
                      ),

                      if (_selectedKereta != null) ...[
                        const SizedBox(height: 24),
                        _buildInfoKeretaTerpilih(),
                        const SizedBox(height: 24),

                        _buildSectionHeader("Tanggal Keberangkatan"),
                        const SizedBox(height: 8),
                        // --- PERUBAHAN Date Picker Style ---
                        InkWell(
                          onTap: _isEditing ? null : _showMultiDatePicker,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              enabledBorder: defaultOutlineInputBorder,
                              focusedBorder: focusedOutlineInputBorder,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                              filled: _isEditing,
                              fillColor: Colors.grey[200],
                            ),
                            child: Row(children: [
                              Icon(Icons.calendar_month, color: Colors.blueGrey.shade700),
                              const SizedBox(width: 12),
                              Expanded(child: Text(_selectedDates.isEmpty ? "Pilih satu atau beberapa tanggal" : "${_selectedDates.length} tanggal dipilih")),
                            ]),
                          ),
                        ),
                        if (_isEditing)
                          const Padding(
                            padding: EdgeInsets.only(top: 8.0, left: 12.0),
                            child: Text(
                              'Tanggal tidak dapat diubah pada mode edit.',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ),
                        const SizedBox(height: 24),

                        ..._hargaPerKelas.entries.map((entry) {
                          return _buildHargaKelasSection(entry.key, entry.value, defaultOutlineInputBorder, focusedOutlineInputBorder);
                        }).toList(),

                        const SizedBox(height: 32),
                        // --- PERUBAHAN ElevatedButton Style ---
                        ElevatedButton.icon(
                          onPressed: _isLoading || _isSubmitting ? null : _submitForm,
                          icon: _isSubmitting ? Container(width: 20, height: 20, margin: const EdgeInsets.only(right: 8), child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) : const Icon(Icons.save_alt_outlined),
                          label: Text(_isEditing ? 'Simpan Perubahan Harga' : 'Simpan & Generate Jadwal'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueGrey,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                        ),
                        if (_isSubmitting) ...[
                          const SizedBox(height: 16),
                          const Center(child: Text("Menyimpan jadwal dan men-generate kursi...", textAlign: TextAlign.center, style: TextStyle(color: Colors.blueGrey))),
                        ],
                      ],
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

  Widget _buildInfoKeretaTerpilih() {
    if (_selectedKereta == null) return const SizedBox.shrink();
    return Card(
      elevation: 0,
      color: Colors.blueGrey[50],
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.blueGrey.shade100),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Info Kereta: ${_selectedKereta!.nama}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            const Divider(),
            if (_selectedKereta!.templateRute.isNotEmpty)
              Text("Rute: ${_selectedKereta!.templateRute.first.namaStasiun} ❯ ${_selectedKereta!.templateRute.last.namaStasiun}"),
            Text("Rangkaian: ${_selectedKereta!.rangkaian.length} gerbong"),
          ],
        ),
      ),
    );
  }

  Widget _buildHargaKelasSection(String namaKelas, List<KelasHargaInput> inputs, InputBorder defaultBorder, InputBorder focusedBorder) {
    int totalKursiFisik = _selectedKereta!.rangkaian
        .map((rg) {
      try { return _semuaTipeGerbong.firstWhere((g) => g.id == rg.idTipeGerbong); }
      catch (e) { return null; }
    })
        .whereType<GerbongTipeModel>()
        .where((g) => g.kelas.name == namaKelas)
        .fold(0, (sum, g) => sum + g.jumlahKursi);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader("Harga Kelas: ${namaKelas[0].toUpperCase()}${namaKelas.substring(1)} (Kursi: $totalKursiFisik)"),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                ...List.generate(inputs.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: inputs[index].subKelasController,
                            decoration: InputDecoration(labelText: "Sub-Kelas", border: defaultBorder, focusedBorder: focusedBorder),
                            validator: (v) => v == null || v.isEmpty ? 'Wajib' : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 4,
                          child: TextFormField(
                            controller: inputs[index].hargaController,
                            decoration: InputDecoration(labelText: "Harga (Rp)", border: defaultBorder, focusedBorder: focusedBorder),
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            validator: (v) => v == null || v.isEmpty ? 'Wajib' : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: inputs[index].kuotaController,
                            decoration: InputDecoration(labelText: "Kuota", border: defaultBorder, focusedBorder: focusedBorder),
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            validator: (v) => v == null || v.isEmpty ? 'Wajib' : null,
                          ),
                        ),
                        if (inputs.length > 1) // Hanya tampilkan tombol hapus jika ada lebih dari 1
                          IconButton(onPressed: () => _removeHargaSubKelas(namaKelas, index), icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent)),
                      ],
                    ),
                  );
                }),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text("Tambah Sub-Kelas"),
                    onPressed: () => _addHargaSubKelas(namaKelas),
                    style: TextButton.styleFrom(foregroundColor: Colors.blueGrey.shade800),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Helper class untuk mengelola state input harga
class KelasHargaInput {
  final TextEditingController subKelasController;
  final TextEditingController hargaController;
  final TextEditingController kuotaController;

  KelasHargaInput({String subKelas = '', String harga = '', String kuota = ''})
      : subKelasController = TextEditingController(text: subKelas),
        hargaController = TextEditingController(text: harga),
        kuotaController = TextEditingController(text: kuota);

  void dispose() {
    subKelasController.dispose();
    hargaController.dispose();
    kuotaController.dispose();
  }
}

// Widget untuk multi-date picker
class MultiDatePicker extends StatefulWidget {
  final List<DateTime> initialDates;
  final Function(List<DateTime>) onDatesSelected;

  const MultiDatePicker({super.key, required this.initialDates, required this.onDatesSelected});

  @override
  _MultiDatePickerState createState() => _MultiDatePickerState();
}

class _MultiDatePickerState extends State<MultiDatePicker> {
  late List<DateTime> _selectedDates;
  DateTime _focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedDates = List.from(widget.initialDates);
    // Jika ada tanggal awal, fokuskan ke tanggal pertama
    if (_selectedDates.isNotEmpty) {
      _focusedDay = _selectedDates.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      focusedDay: _focusedDay,
      firstDay: DateTime.now().subtract(const Duration(days: 30)),
      lastDay: DateTime.now().add(const Duration(days: 365)),
      calendarFormat: CalendarFormat.month,
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
      ),
      calendarStyle: CalendarStyle(
        selectedDecoration: const BoxDecoration(
          color: Colors.blueGrey,
          shape: BoxShape.circle,
        ),
        todayDecoration: BoxDecoration(
          color: Colors.blueGrey.shade200,
          shape: BoxShape.circle,
        ),
      ),
      selectedDayPredicate: (day) => _selectedDates.any((d) => isSameDay(d, day)),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _focusedDay = focusedDay;
          final isAlreadySelected = _selectedDates.any((d) => isSameDay(d, selectedDay));
          if (isAlreadySelected) {
            _selectedDates.removeWhere((d) => isSameDay(d, selectedDay));
          } else {
            _selectedDates.add(selectedDay);
          }
        });
        widget.onDatesSelected(_selectedDates);
      },
    );
  }
}