import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/gerbong_tipe_model.dart';
import '../services/admin_firestore_service.dart';

class FormGerbongScreen extends StatefulWidget {
  final GerbongTipeModel? gerbongToEdit;

  const FormGerbongScreen({super.key, this.gerbongToEdit});

  @override
  State<FormGerbongScreen> createState() => _FormGerbongScreenState();
}

class _FormGerbongScreenState extends State<FormGerbongScreen> {
  final _formKey = GlobalKey<FormState>();
  final AdminFirestoreService _adminService = AdminFirestoreService();

  late TextEditingController _subTipeController;
  late TextEditingController _jumlahKursiController;
  KelasUtama? _selectedKelas;
  TipeLayoutGerbong? _selectedLayout;

  final List<String> _layoutOptions = ['2-2', '3-2', '2-1', '1-1']; // Opsi layout manual

  bool get _isEditing => widget.gerbongToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final gerbong = widget.gerbongToEdit!;
      _selectedKelas = gerbong.kelas;
      _subTipeController = TextEditingController(text: gerbong.subTipe);
      _selectedLayout = gerbong.tipeLayout;
      _jumlahKursiController = TextEditingController(text: gerbong.jumlahKursi.toString());
    } else {
      _subTipeController = TextEditingController();
      _jumlahKursiController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _subTipeController.dispose();
    _jumlahKursiController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedKelas == null || _selectedLayout == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Harap lengkapi semua pilihan.")));
      return;
    }

    final gerbong = GerbongTipeModel(
      id: _isEditing ? widget.gerbongToEdit!.id : '', // ID akan di-generate Firestore saat add
      kelas: _selectedKelas!,
      subTipe: _subTipeController.text,
      tipeLayout: _selectedLayout!,
      jumlahKursi: int.tryParse(_jumlahKursiController.text) ?? 0,
    );

    try {
      if (_isEditing) {
        await _adminService.updateGerbongTipe(gerbong);
      } else {
        await _adminService.addGerbongTipe(gerbong);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tipe Gerbong berhasil ${ _isEditing ? "diperbarui" : "ditambahkan"}!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan gerbong: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? "Edit Tipe Gerbong" : "Tambah Tipe Gerbong"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<KelasUtama>(
                value: _selectedKelas,
                decoration: const InputDecoration(labelText: 'Pilih Kelas Utama', border: OutlineInputBorder()),
                items: KelasUtama.values.map((KelasUtama kelas) {
                  return DropdownMenuItem<KelasUtama>(
                    value: kelas,
                    child: Text(kelas.name[0].toUpperCase() + kelas.name.substring(1)),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedKelas = value),
                validator: (value) => value == null ? 'Pilih kelas utama' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _subTipeController,
                decoration: const InputDecoration(labelText: 'Nama/Sub-Tipe (mis: New Generation 2024)', border: OutlineInputBorder()),
                validator: (value) => (value == null || value.isEmpty) ? 'Sub-tipe tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<TipeLayoutGerbong>(
                value: _selectedLayout,
                decoration: const InputDecoration(labelText: 'Tipe Layout Kursi', border: OutlineInputBorder()),
                items: TipeLayoutGerbong.values.map((TipeLayoutGerbong layout) {
                  return DropdownMenuItem<TipeLayoutGerbong>(
                    value: layout,
                    child: Text(layout.deskripsi),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedLayout = value),
                validator: (value) => value == null ? 'Pilih tipe layout' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _jumlahKursiController,
                decoration: const InputDecoration(labelText: 'Jumlah Kursi', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Jumlah kursi tidak boleh kosong';
                  if (int.tryParse(value) == null || int.parse(value) <= 0) return 'Masukkan jumlah yang valid';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: Text(_isEditing ? 'Simpan Perubahan' : 'Tambah Tipe Gerbong'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}