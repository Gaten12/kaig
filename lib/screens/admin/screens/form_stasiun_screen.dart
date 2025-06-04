import 'package:flutter/material.dart';
import '../../../models/stasiun_model.dart';
import '../services/admin_firestore_service.dart';

class FormStasiunScreen extends StatefulWidget {
  final StasiunModel? stasiunToEdit;

  const FormStasiunScreen({super.key, this.stasiunToEdit});

  @override
  State<FormStasiunScreen> createState() => _FormStasiunScreenState();
}

class _FormStasiunScreenState extends State<FormStasiunScreen> {
  final _formKey = GlobalKey<FormState>();
  final AdminFirestoreService _adminService = AdminFirestoreService();

  late TextEditingController _namaController;
  late TextEditingController _kodeController;
  late TextEditingController _kotaController;

  bool get _isEditing => widget.stasiunToEdit != null;

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(text: widget.stasiunToEdit?.nama ?? '');
    _kodeController = TextEditingController(text: widget.stasiunToEdit?.kode ?? '');
    _kotaController = TextEditingController(text: widget.stasiunToEdit?.kota ?? '');
  }

  @override
  void dispose() {
    _namaController.dispose();
    _kodeController.dispose();
    _kotaController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Kode stasiun dijadikan huruf besar sebagai standar
      final kodeStasiun = _kodeController.text.toUpperCase();

      // Jika editing, ID sudah ada. Jika baru, ID bisa di-generate atau sama dengan kode.
      // Sesuai AdminFirestoreService.addStasiun, kita asumsikan kode adalah ID.
      // Jika stasiunToEdit.id adalah documentID yang berbeda dari kode, perlu penyesuaian.
      final stasiunId = _isEditing ? widget.stasiunToEdit!.id : kodeStasiun;


      final stasiun = StasiunModel(
        id: stasiunId, // Penting: ID harus konsisten dengan cara Anda menyimpan/mengupdate
        nama: _namaController.text,
        kode: kodeStasiun,
        kota: _kotaController.text,
        // isFavorit dan deskripsiTambahan tidak di-set dari form ini, bisa ditambahkan jika perlu
      );

      try {
        if (_isEditing) {
          await _adminService.updateStasiun(stasiun);
        } else {
          // Cek apakah stasiun dengan kode ini sudah ada (jika kode adalah ID)
          // Untuk simplisitas, kita langsung add/set. Handle duplikasi jika perlu.
          await _adminService.addStasiun(stasiun);
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Stasiun berhasil ${ _isEditing ? "diperbarui" : "ditambahkan"}!')),
          );
          Navigator.pop(context); // Kembali ke layar list
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menyimpan stasiun: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? "Edit Stasiun" : "Tambah Stasiun Baru"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(
                  labelText: 'Nama Stasiun',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama stasiun tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _kodeController,
                decoration: InputDecoration(
                  labelText: 'Kode Stasiun (Singkatan)',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.code_outlined),
                  // Jika kode adalah ID dan tidak bisa diubah saat edit:
                  // enabled: !_isEditing,
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Kode stasiun tidak boleh kosong';
                  }
                  if (value.length > 5) { // Contoh batasan panjang kode
                    return 'Kode stasiun maksimal 5 karakter';
                  }
                  return null;
                },
                // Kode tidak bisa diubah jika sedang mengedit dan kode adalah ID
                // readOnly: _isEditing, // Jika kode adalah ID dan tidak boleh diubah
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _kotaController,
                decoration: const InputDecoration(
                  labelText: 'Kota',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_city_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Kota tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text(_isEditing ? 'Simpan Perubahan' : 'Tambah Stasiun', style: const TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
