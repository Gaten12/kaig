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

  // Controllers untuk setiap field
  late final TextEditingController _namaController;
  late final TextEditingController _jumlahKursiController;
  late final TextEditingController _kelasController;
  late final TextEditingController _subkelasController;
  late final TextEditingController _imageAssetController;
  TipeLayoutGerbong _selectedLayout = TipeLayoutGerbong.layout_2_2; // Nilai default

  bool get _isEditing => widget.tipeToEdit != null;

  @override
  void initState() {
    super.initState();
    final tipe = widget.tipeToEdit;
    // Inisialisasi controller dengan data yang ada jika sedang mengedit
    _namaController = TextEditingController(text: tipe?.namaTipe ?? '');
    _jumlahKursiController = TextEditingController(text: tipe?.jumlahKursi.toString() ?? '');
    _kelasController = TextEditingController(text: tipe?.kelas ?? '');
    _subkelasController = TextEditingController(text: tipe?.subkelas.toString() ?? '');
    _imageAssetController = TextEditingController(text: tipe?.imageAssetPath ?? '');
    if (tipe != null) {
      _selectedLayout = tipe.tipeLayout;
    }
  }

  @override
  void dispose() {
    // Selalu dispose controller untuk menghindari memory leak
    _namaController.dispose();
    _jumlahKursiController.dispose();
    _kelasController.dispose();
    _subkelasController.dispose();
    _imageAssetController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    // Validasi form sebelum submit
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Tampilkan loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final gerbongTipe = GerbongTipeModel(
      id: widget.tipeToEdit?.id ?? '', // Gunakan id lama jika edit, atau kosong jika baru
      namaTipe: _namaController.text,
      jumlahKursi: int.parse(_jumlahKursiController.text),
      kelas: _kelasController.text,
      subkelas: int.parse(_subkelasController.text),
      tipeLayout: _selectedLayout,
      imageAssetPath: _imageAssetController.text,
    );

    try {
      if (_isEditing) {
        await _adminService.updateGerbongTipe(gerbongTipe);
      } else {
        await _adminService.addGerbongTipe(gerbongTipe);
      }

      // Tutup loading indicator
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      // Tampilkan notifikasi sukses
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tipe gerbong berhasil ${_isEditing ? 'diperbarui' : 'ditambahkan'}'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Kembali ke halaman sebelumnya dan kirim sinyal sukses
      }
    } catch (e) {
      // Tutup loading indicator
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      // Tampilkan notifikasi error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: Colors.red,
          ),
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
                    _buildTextFormField(
                      controller: _jumlahKursiController,
                      label: 'Jumlah Kursi',
                      hint: 'e.g., 50',
                      icon: Icons.event_seat_outlined,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextFormField(
                            controller: _kelasController,
                            label: 'Kelas',
                            hint: 'e.g., Eksekutif',
                            icon: Icons.star_border_outlined,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextFormField(
                            controller: _subkelasController,
                            label: 'Subkelas',
                            hint: 'e.g., 1',
                            icon: Icons.looks_one_outlined,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      items: TipeLayoutGerbong.values.map((TipeLayoutGerbong layout) {
        return DropdownMenuItem<TipeLayoutGerbong>(
          value: layout,
          child: Text(layout.deskripsi), // Menggunakan getter 'deskripsi'
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