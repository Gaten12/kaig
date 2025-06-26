import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/gerbong_tipe_model.dart';
import '../services/admin_firestore_service.dart';

class FormTipeGerbongScreen extends StatefulWidget {
  final GerbongTipeModel? tipeToEdit;

  const FormTipeGerbongScreen({super.key, this.tipeToEdit});

  @override
  State<FormTipeGerbongScreen> createState() => _FormTipeGerbongScreenState();
}

class _FormTipeGerbongScreenState extends State<FormTipeGerbongScreen> {
  final _formKey = GlobalKey<FormState>();
  final _adminService = AdminFirestoreService();

  // [DIHAPUS] Controller untuk subkelas tidak diperlukan lagi
  late final TextEditingController _namaController;
  late final TextEditingController _jumlahKursiController;
  late final TextEditingController _kelasController;
  late final TextEditingController _imageAssetController;
  TipeLayoutGerbong _selectedLayout = TipeLayoutGerbong.layout_2_2;

  bool get _isEditing => widget.tipeToEdit != null;

  @override
  void initState() {
    super.initState();
    final tipe = widget.tipeToEdit;
    _namaController = TextEditingController(text: tipe?.namaTipe ?? '');
    _jumlahKursiController = TextEditingController(text: tipe?.jumlahKursi.toString() ?? '');
    _kelasController = TextEditingController(text: tipe?.kelas ?? '');
    _imageAssetController = TextEditingController(text: tipe?.imageAssetPath ?? '');
    if (tipe != null) {
      _selectedLayout = tipe.tipeLayout;
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _jumlahKursiController.dispose();
    _kelasController.dispose();
    _imageAssetController.dispose();
    // [DIHAPUS] _subkelasController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // [MODIFIKASI] Membuat objek tanpa subkelas
    final gerbongTipe = GerbongTipeModel(
      id: widget.tipeToEdit?.id ?? '',
      namaTipe: _namaController.text,
      jumlahKursi: int.parse(_jumlahKursiController.text),
      kelas: _kelasController.text,
      tipeLayout: _selectedLayout,
      imageAssetPath: _imageAssetController.text,
    );

    try {
      if (_isEditing) {
        await _adminService.updateGerbongTipe(gerbongTipe);
      } else {
        await _adminService.addGerbongTipe(gerbongTipe);
      }

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tipe gerbong berhasil ${_isEditing ? 'diperbarui' : 'ditambahkan'}'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Tipe Gerbong' : 'Tambah Tipe Gerbong'),
        backgroundColor: Colors.blueGrey,
      ),
      body: SingleChildScrollView(
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTextFormField(
                      controller: _namaController,
                      label: 'Nama Tipe',
                      hint: 'e.g., Eksekutif Stainless Steel 2024',
                      icon: Icons.train_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildTextFormField(
                      controller: _imageAssetController,
                      label: 'Nama File Gambar',
                      hint: 'e.g., eksekutif_ss_2024.png',
                      icon: Icons.image_outlined,
                    ),
                    const SizedBox(height: 16),
                    // [MODIFIKASI] Field Kelas dan Jumlah Kursi dipisah agar lebih jelas
                    _buildTextFormField(
                      controller: _kelasController,
                      label: 'Kelas',
                      hint: 'e.g., Eksekutif, Bisnis, Ekonomi',
                      icon: Icons.star_border_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildTextFormField(
                      controller: _jumlahKursiController,
                      label: 'Jumlah Kursi',
                      hint: 'e.g., 50',
                      icon: Icons.event_seat_outlined,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 16),
                    // [DIHAPUS] Baris yang berisi TextFormField untuk Subkelas dihilangkan
                    _buildDropdownLayout(),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: _submitForm,
                      icon: const Icon(Icons.save_alt_outlined),
                      label: Text(_isEditing ? 'Simpan Perubahan' : 'Tambah Tipe Gerbong'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '$label tidak boleh kosong';
        }
        return null;
      },
    );
  }

  Widget _buildDropdownLayout() {
    return DropdownButtonFormField<TipeLayoutGerbong>(
      value: _selectedLayout,
      decoration: InputDecoration(
        labelText: 'Tipe Layout Kursi',
        prefixIcon: const Icon(Icons.grid_on_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
      items: TipeLayoutGerbong.values.map((TipeLayoutGerbong layout) {
        return DropdownMenuItem<TipeLayoutGerbong>(
          value: layout,
          child: Text(layout.deskripsi),
        );
      }).toList(),
      onChanged: (TipeLayoutGerbong? newValue) {
        if (newValue != null) {
          setState(() {
            _selectedLayout = newValue;
          });
        }
      },
      validator: (value) => value == null ? 'Pilih tipe layout' : null,
    );
  }
}