import 'package:flutter/material.dart';
import '../../../models/stasiun_model.dart'; // Pastikan path ini benar
import '../services/admin_firestore_service.dart'; // Pastikan path ini benar

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
    _namaController =
        TextEditingController(text: widget.stasiunToEdit?.nama ?? '');
    _kodeController =
        TextEditingController(text: widget.stasiunToEdit?.kode ?? '');
    _kotaController =
        TextEditingController(text: widget.stasiunToEdit?.kota ?? '');
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

      final kodeStasiun = _kodeController.text.toUpperCase();
      final stasiunId = _isEditing ? widget.stasiunToEdit!.id : kodeStasiun;

      final stasiun = StasiunModel(
        id: stasiunId,
        nama: _namaController.text,
        kode: kodeStasiun,
        kota: _kotaController.text,
      );

      try {
        if (_isEditing) {
          await _adminService.updateStasiun(stasiun);
        } else {
          await _adminService.addStasiun(stasiun);
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Stasiun berhasil ${_isEditing ? "diperbarui" : "ditambahkan"}!')),
          );
          Navigator.pop(context);
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
    // Definisikan BorderSide yang akan digunakan berulang kali
    final BorderSide defaultBorderSide =
    BorderSide(color: Colors.grey.shade400); // Warna abu-abu muda
    final BorderSide focusedBorderSide =
    BorderSide(color: Colors.blueGrey.shade700, width: 2.0); // Warna tema saat fokus
    const BorderSide errorBorderSide =
    BorderSide(color: Colors.red, width: 1.0); // Warna merah untuk error

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
      borderSide: errorBorderSide.copyWith(width: 2.0), // Error dan fokus, sedikit lebih tebal
      borderRadius: BorderRadius.circular(8.0),
    );


    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Colors.blueGrey,
        title: Text(
          _isEditing ? "Edit Stasiun" : "Tambah Stasiun Baru",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w200,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
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
                    children: <Widget>[
                      TextFormField(
                        controller: _namaController,
                        decoration: InputDecoration(
                          labelText: 'Nama Stasiun',
                          enabledBorder: defaultOutlineInputBorder,
                          focusedBorder: focusedOutlineInputBorder,
                          errorBorder: errorOutlineInputBorder,
                          focusedErrorBorder: focusedErrorOutlineInputBorder,
                          prefixIcon: Icon(Icons.business_outlined, color: Colors.blueGrey.shade700),
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
                          enabledBorder: defaultOutlineInputBorder,
                          focusedBorder: focusedOutlineInputBorder,
                          errorBorder: errorOutlineInputBorder,
                          focusedErrorBorder: focusedErrorOutlineInputBorder,
                          prefixIcon: Icon(Icons.code_outlined, color: Colors.blueGrey.shade700),
                        ),
                        textCapitalization: TextCapitalization.characters,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Kode stasiun tidak boleh kosong';
                          }
                          if (value.length > 5) {
                            return 'Kode stasiun maksimal 5 karakter';
                          }
                          return null;
                        },
                        // readOnly: _isEditing,
                      ),
                      const SizedBox(height: 16.0),
                      TextFormField(
                        controller: _kotaController,
                        decoration: InputDecoration(
                          labelText: 'Kota',
                          enabledBorder: defaultOutlineInputBorder,
                          focusedBorder: focusedOutlineInputBorder,
                          errorBorder: errorOutlineInputBorder,
                          focusedErrorBorder: focusedErrorOutlineInputBorder,
                          prefixIcon: Icon(Icons.location_city_outlined, color: Colors.blueGrey.shade700),
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
                          backgroundColor: Colors.blueGrey,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: Text(
                          _isEditing ? 'Simpan Perubahan' : 'Tambah Stasiun',
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
}