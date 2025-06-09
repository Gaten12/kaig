import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:table_calendar/table_calendar.dart'; // Package untuk multi-date picker
import '../../../models/JadwalModel.dart';
import '../../../models/KeretaModel.dart';
import '../../../models/jadwal_kelas_info_model.dart';
import '../../../models/gerbong_tipe_model.dart';
import '../../../models/jadwal_perhentian_model.dart';
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
      // PERBAIKAN: Cast hasil Future.wait ke tipe yang benar
      _keretaList = results[0] as List<KeretaModel>;
      _semuaTipeGerbong = results[1] as List<GerbongTipeModel>;

      // Logika untuk mode edit
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
    // Set kereta yang dipilih
    try {
      _selectedKereta = _keretaList.firstWhere((k) => k.id == jadwal.idKereta);
    } catch (e) {
      print("Gagal menemukan kereta yang akan di-edit: $e");
    }

    // Set tanggal yang dipilih (mode edit hanya untuk 1 tanggal)
    _selectedDates = [jadwal.tanggalBerangkatUtama.toDate()];

    // Inisialisasi map harga dan isi dengan data yang ada
    _hargaPerKelas.clear();
    final kelasDiRangkaian = _getKelasFromRangkaian(_selectedKereta?.idRangkaianGerbong ?? []);
    for (var kelas in kelasDiRangkaian) {
      _hargaPerKelas[kelas.name] = []; // Buat list kosong dulu
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

      final kelasDiRangkaian = _getKelasFromRangkaian(kereta.idRangkaianGerbong);
      for (var kelas in kelasDiRangkaian) {
        _hargaPerKelas[kelas.name] = [KelasHargaInput()];
      }
    });
  }

  Set<KelasUtama> _getKelasFromRangkaian(List<String> idGerbongList) {
    Set<KelasUtama> kelasSet = {};
    for (var idGerbong in idGerbongList) {
      try {
        final gerbong = _semuaTipeGerbong.firstWhere((g) => g.id == idGerbong);
        kelasSet.add(gerbong.kelas);
      } catch (e) {
        print("Gerbong dengan ID $idGerbong tidak ditemukan di master data.");
      }
    }
    return kelasSet;
  }

  void _showMultiDatePicker() async {
    // Mode edit tidak mengizinkan perubahan tanggal untuk simplisitas
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
    if (_selectedKereta == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Harap pilih kereta.")));
      return;
    }
    if (_selectedDates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Harap pilih minimal satu tanggal keberangkatan.")));
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
            throw Exception("Harap lengkapi semua field (Sub-Kelas, Harga, Kuota) untuk kelas $namaKelas.");
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

        int totalKursiFisikKelasIni = _selectedKereta!.idRangkaianGerbong
            .map((idGerbong) {
          try { return _semuaTipeGerbong.firstWhere((g) => g.id == idGerbong); }
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
      for (final tanggal in _selectedDates) {
        List<JadwalPerhentianModel> detailPerhentianUntukJadwal = _selectedKereta!.templateRute.map((template) {
          DateTime hariBerangkat = tanggal;
          DateTime hariTiba = tanggal;

          if (template.urutan > 0) {
            final perhentianSebelumnya = _selectedKereta!.templateRute[template.urutan - 1];
            if (template.jamTiba != null && perhentianSebelumnya.jamBerangkat != null) {
              if (template.jamTiba!.hour < perhentianSebelumnya.jamBerangkat!.hour) {
                hariTiba = tanggal.add(const Duration(days: 1));
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

          Timestamp? waktuTibaTimestamp = (template.jamTiba != null)
              ? Timestamp.fromDate(DateTime(hariTiba.year, hariTiba.month, hariTiba.day, template.jamTiba!.hour, template.jamTiba!.minute))
              : null;
          Timestamp? waktuBerangkatTimestamp = (template.jamBerangkat != null)
              ? Timestamp.fromDate(DateTime(hariBerangkat.year, hariBerangkat.month, hariBerangkat.day, template.jamBerangkat!.hour, template.jamBerangkat!.minute))
              : null;

          return JadwalPerhentianModel(
            idStasiun: template.stasiunId,
            namaStasiun: template.namaStasiun,
            waktuTiba: waktuTibaTimestamp,
            waktuBerangkat: waktuBerangkatTimestamp,
            urutan: template.urutan,
          );
        }).toList();

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
          final rangkaianGerbong = _selectedKereta!.idRangkaianGerbong
              .map((id) => _semuaTipeGerbong.firstWhere((g) => g.id == id))
              .toList();
          await _adminService.generateKursiUntukJadwal(docRef.id, rangkaianGerbong);
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
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Colors.blueGrey,
        title: Text(_isEditing ? "Edit Jadwal" : "Buat Jadwal Baru",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w200,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView( // Ditambahkan agar Card bisa di-scroll jika kontennya panjang
        padding: const EdgeInsets.all(16.0),
        child: Card( // <--- WIDGET CARD DITAMBAHKAN DI SINI
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column( // Menggunakan Column karena ListView di dalam Card tidak ideal
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<KeretaModel>(
                    value: _selectedKereta,
                    items: _keretaList.map((kereta) => DropdownMenuItem(value: kereta, child: Text(kereta.nama))).toList(),
                    onChanged: _isEditing ? null : _onKeretaSelected,
                    decoration: InputDecoration(
                      labelText: 'Pilih Kereta',
                      border: const OutlineInputBorder(),
                      filled: _isEditing,
                      fillColor: Colors.grey[200],
                    ),
                    validator: (value) => value == null ? 'Kereta harus dipilih' : null,
                  ),

                  if (_selectedKereta != null) ...[
                    const SizedBox(height: 24),
                    _buildInfoKeretaTerpilih(),
                    const SizedBox(height: 24),

                    const Text("Tanggal Keberangkatan", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _showMultiDatePicker,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: _isEditing ? Colors.grey : Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                          color: _isEditing ? Colors.grey[200] : null,
                        ),
                        child: Row(children: [
                          Icon(Icons.calendar_month, color: _isEditing ? Colors.grey.shade700 : Colors.grey),
                          const SizedBox(width: 12),
                          Expanded(child: Text(_selectedDates.isEmpty ? "Pilih satu atau beberapa tanggal" : "${_selectedDates.length} tanggal dipilih")),
                        ]),
                      ),
                    ),
                    if (_isEditing)
                      const Padding(
                        padding: EdgeInsets.only(top: 4.0),
                        child: Text(
                          'Tanggal tidak dapat diubah pada mode edit. Buat jadwal baru untuk tanggal lain.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    const SizedBox(height: 24),

                    ..._hargaPerKelas.entries.map((entry) {
                      return _buildHargaKelasSection(entry.key, entry.value);
                    }).toList(),

                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save_alt_outlined),
                      label: Text(_isEditing ? 'Simpan Perubahan Harga' : 'Simpan & Generate Jadwal'),
                      onPressed: _isLoading || _isSubmitting ? null : _submitForm,
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.blueGrey,
                      ),
                    ),
                    if (_isSubmitting) ...[
                      const SizedBox(height: 16),
                      const Center(child: CircularProgressIndicator()),
                      const SizedBox(height: 8),
                      const Center(child: Text("Menyimpan jadwal dan men-generate kursi...", textAlign: TextAlign.center)),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoKeretaTerpilih() {
    if (_selectedKereta == null) return const SizedBox.shrink();
    // Diubah menjadi Container karena sudah di dalam Card utama
    return Container(
      decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8)
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Info Kereta: ${_selectedKereta!.nama}", style: const TextStyle(fontWeight: FontWeight.bold)),
            const Divider(),
            if (_selectedKereta!.templateRute.isNotEmpty)
              Text("Rute: ${_selectedKereta!.templateRute.first.namaStasiun} ❯ ${_selectedKereta!.templateRute.last.namaStasiun}"),
            Text("Rangkaian: ${_selectedKereta!.idRangkaianGerbong.length} gerbong"),
          ],
        ),
      ),
    );
  }

  Widget _buildHargaKelasSection(String namaKelas, List<KelasHargaInput> inputs) {
    int totalKursiFisik = _selectedKereta!.idRangkaianGerbong
        .map((idGerbong) {
      try { return _semuaTipeGerbong.firstWhere((g) => g.id == idGerbong); }
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
          Text("Harga untuk Kelas: ${namaKelas[0].toUpperCase()}${namaKelas.substring(1)} (Total Kursi Fisik: $totalKursiFisik)", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
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
                      decoration: const InputDecoration(labelText: "Sub-Kelas", border: OutlineInputBorder()),
                      validator: (v) => v == null || v.isEmpty ? 'Wajib' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 4,
                    child: TextFormField(
                      controller: inputs[index].hargaController,
                      decoration: const InputDecoration(labelText: "Harga (Rp)", border: OutlineInputBorder(), prefixText: "Rp "),
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
                      decoration: const InputDecoration(labelText: "Kuota", border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) => v == null || v.isEmpty ? 'Wajib' : null,
                    ),
                  ),
                  IconButton(onPressed: () => _removeHargaSubKelas(namaKelas, index), icon: const Icon(Icons.remove_circle_outline, color: Colors.red)),
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
            ),
          )
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
  }

  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      focusedDay: _focusedDay,
      firstDay: DateTime.now().subtract(const Duration(days: 30)),
      lastDay: DateTime.now().add(const Duration(days: 365)),
      calendarFormat: CalendarFormat.month,
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