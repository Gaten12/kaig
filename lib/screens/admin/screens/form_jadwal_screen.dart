import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart'; // Package untuk multi-date picker
import '../../../models/JadwalModel.dart';
import '../../../models/KeretaModel.dart';
import '../../../models/jadwal_kelas_info_model.dart';
import '../../../models/gerbong_tipe_model.dart';
import '../../../models/jadwal_perhentian_model.dart';
import '../services/admin_firestore_service.dart';


class FormJadwalScreen extends StatefulWidget {
  // Mode edit untuk jadwal sekarang lebih kompleks, untuk sementara kita fokus pada add new
  // final JadwalModel? jadwalToEdit; 
  const FormJadwalScreen({super.key});

  @override
  State<FormJadwalScreen> createState() => _FormJadwalScreenState();
}

class _FormJadwalScreenState extends State<FormJadwalScreen> {
  final _formKey = GlobalKey<FormState>();
  final AdminFirestoreService _adminService = AdminFirestoreService();

  // State untuk data master
  List<KeretaModel> _keretaList = [];
  List<GerbongTipeModel> _semuaTipeGerbong = [];

  // State untuk form
  KeretaModel? _selectedKereta;
  List<DateTime> _selectedDates = [];
  // Map untuk menyimpan harga per sub-kelas. Key: nama kelas, Value: List dari input harga
  Map<String, List<KelasHargaInput>> _hargaPerKelas = {};

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
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
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal memuat data master: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onKeretaSelected(KeretaModel? kereta) {
    if (kereta == null) return;
    setState(() {
      _selectedKereta = kereta;
      _hargaPerKelas.clear(); // Reset harga saat kereta baru dipilih

      // Inisialisasi map harga berdasarkan kelas yang ada di rangkaian kereta
      final kelasDiRangkaian = _getKelasFromRangkaian(kereta.idRangkaianGerbong);
      for (var kelas in kelasDiRangkaian) {
        _hargaPerKelas[kelas.name] = [KelasHargaInput()]; // Tambah satu input default
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
    await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Pilih Tanggal Keberangkatan"),
          content: SizedBox(
            width: double.maxFinite,
            child: MultiDatePicker(
              initialDates: _selectedDates,
              onDatesSelected: (dates) {
                setState(() {
                  _selectedDates = dates;
                });
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
    if (!_formKey.currentState!.validate()) return;
    if (_selectedKereta == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Harap pilih kereta.")));
      return;
    }
    if (_selectedDates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Harap pilih minimal satu tanggal keberangkatan.")));
      return;
    }

    // Validasi semua input harga tidak kosong
    for (var entry in _hargaPerKelas.entries) {
      for (var input in entry.value) {
        if (input.subKelasController.text.isEmpty || input.hargaController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Harap lengkapi semua field harga untuk kelas ${entry.key}.")));
          return;
        }
      }
    }

    setState(() => _isLoading = true);

    try {
      // 1. Kumpulkan semua detail kelas dan harga dari form
      List<JadwalKelasInfoModel> daftarKelasHargaFinal = [];
      _hargaPerKelas.forEach((namaKelas, inputs) {
        for (var input in inputs) {
          daftarKelasHargaFinal.add(JadwalKelasInfoModel(
            namaKelas: namaKelas,
            subKelas: input.subKelasController.text.toUpperCase(),
            harga: int.tryParse(input.hargaController.text) ?? 0,
            ketersediaan: '', // Tidak lagi diinput manual
          ));
        }
      });

      // 2. Loop untuk setiap tanggal yang dipilih
      for (final tanggal in _selectedDates) {
        // Buat detail perhentian dengan timestamp yang benar untuk tanggal ini
        List<JadwalPerhentianModel> detailPerhentianUntukJadwal = _selectedKereta!.templateRute.map((template) {
          Timestamp? waktuTibaTimestamp;
          Timestamp? waktuBerangkatTimestamp;

          DateTime hariTiba = tanggal;
          DateTime hariBerangkat = tanggal;

          // Logika sederhana untuk menangani perjalanan lintas hari
          if (template.jamTiba != null && template.jamBerangkat != null) {
            // Jika jam tiba lebih kecil dari jam berangkat (misal tiba 01:00, berangkat 23:00), berarti lintas hari
            if (template.jamTiba!.hour < template.jamBerangkat!.hour) {
              // Ini adalah logika yang salah dan terlalu sederhana.
              // Logika yang benar harus membandingkan dengan waktu perhentian sebelumnya.
            }
          }
          // Logika yang lebih baik:
          if (template.urutan > 0) { // Jika bukan stasiun awal
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
            }
          }


          if(template.jamTiba != null) {
            waktuTibaTimestamp = Timestamp.fromDate(DateTime(hariTiba.year, hariTiba.month, hariTiba.day, template.jamTiba!.hour, template.jamTiba!.minute));
          }
          if(template.jamBerangkat != null) {
            waktuBerangkatTimestamp = Timestamp.fromDate(DateTime(hariBerangkat.year, hariBerangkat.month, hariBerangkat.day, template.jamBerangkat!.hour, template.jamBerangkat!.minute));
          }

          return JadwalPerhentianModel(
            idStasiun: template.stasiunId,
            namaStasiun: template.namaStasiun,
            waktuTiba: waktuTibaTimestamp,
            waktuBerangkat: waktuBerangkatTimestamp,
            urutan: template.urutan,
          );
        }).toList();

        // 3. Buat objek JadwalModel
        final jadwalBaru = JadwalModel(
          id: '', // Akan di-generate oleh Firestore
          idKereta: _selectedKereta!.id,
          namaKereta: _selectedKereta!.nama,
          detailPerhentian: detailPerhentianUntukJadwal,
          daftarKelasHarga: daftarKelasHargaFinal,
        );

        // 4. Simpan Jadwal ke Firestore
        final docRef = await _adminService.addJadwal(jadwalBaru);

        // 5. Generate Kursi untuk Jadwal yang baru dibuat
        final List<GerbongTipeModel> rangkaianGerbong = _selectedKereta!.idRangkaianGerbong
            .map((id) => _semuaTipeGerbong.firstWhere((g) => g.id == id))
            .toList();

        await _adminService.generateKursiUntukJadwal(docRef.id, rangkaianGerbong);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_selectedDates.length} jadwal berhasil dibuat dan kursi telah digenerate!')),
        );
        Navigator.pop(context);
      }

    } catch (e) {
      print("Error saat menyimpan jadwal: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan jadwal: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Buat Jadwal Baru")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<KeretaModel>(
                value: _selectedKereta,
                items: _keretaList.map((kereta) => DropdownMenuItem(value: kereta, child: Text(kereta.nama))).toList(),
                onChanged: _onKeretaSelected,
                decoration: const InputDecoration(labelText: 'Pilih Kereta', border: OutlineInputBorder()),
                validator: (value) => value == null ? 'Kereta harus dipilih' : null,
              ),

              if (_selectedKereta != null) ...[
                const SizedBox(height: 24),
                _buildInfoKeretaTerpilih(),
                const SizedBox(height: 24),

                // Tanggal Keberangkatan
                const Text("Tanggal Keberangkatan", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _showMultiDatePicker,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
                    child: Row(children: [
                      const Icon(Icons.calendar_month, color: Colors.grey),
                      const SizedBox(width: 12),
                      Expanded(child: Text(_selectedDates.isEmpty ? "Pilih satu atau beberapa tanggal" : "${_selectedDates.length} tanggal dipilih")),
                    ]),
                  ),
                ),
                const SizedBox(height: 24),

                // Harga Sub-Kelas
                ..._hargaPerKelas.entries.map((entry) {
                  return _buildHargaKelasSection(entry.key, entry.value);
                }).toList(),

                const SizedBox(height: 32),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save_alt_outlined),
                  label: const Text('Simpan & Generate Jadwal'),
                  onPressed: _isLoading ? null : _submitForm, // Nonaktifkan saat loading
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                ),
                if (_isLoading) ...[
                  const SizedBox(height: 16),
                  const Center(child: CircularProgressIndicator()),
                  const Center(child: Text("Menyimpan jadwal dan men-generate kursi...")),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoKeretaTerpilih() {
    if (_selectedKereta == null) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Info Kereta: ${_selectedKereta!.nama}", style: const TextStyle(fontWeight: FontWeight.bold)),
            const Divider(),
            Text("Rute: ${_selectedKereta!.templateRute.first.namaStasiun} ❯ ${_selectedKereta!.templateRute.last.namaStasiun}"),
            Text("Rangkaian: ${_selectedKereta!.idRangkaianGerbong.length} gerbong"),
          ],
        ),
      ),
    );
  }

  Widget _buildHargaKelasSection(String namaKelas, List<KelasHargaInput> inputs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Harga untuk Kelas: ${namaKelas[0].toUpperCase()}${namaKelas.substring(1)}", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...List.generate(inputs.length, (index) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: inputs[index].subKelasController,
                      decoration: const InputDecoration(labelText: "Sub-Kelas", border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? 'Wajib' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: inputs[index].hargaController,
                      decoration: const InputDecoration(labelText: "Harga (Rp)", border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Wajib' : null,
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
  final TextEditingController subKelasController = TextEditingController();
  final TextEditingController hargaController = TextEditingController();

  void dispose() {
    subKelasController.dispose();
    hargaController.dispose();
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
