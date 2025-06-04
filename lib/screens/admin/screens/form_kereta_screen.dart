import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Untuk TextInputFormatter
import '../../../models/KeretaModel.dart';
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
  late TextEditingController _kelasUtamaController;
  late TextEditingController _jumlahKursiController;

  bool get _isEditing => widget.keretaToEdit != null;

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(text: widget.keretaToEdit?.nama ?? '');
    _kelasUtamaController = TextEditingController(text: widget.keretaToEdit?.kelasUtama ?? '');
    _jumlahKursiController = TextEditingController(text: widget.keretaToEdit?.jumlahKursi.toString() ?? '');
  }

  @override
  void dispose() {
    _namaController.dispose();
    _kelasUtamaController.dispose();
    _jumlahKursiController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final kereta = KeretaModel(
        // Jika editing, ID diambil dari keretaToEdit.
        // Jika baru, ID akan di-generate oleh Firestore saat add, jadi bisa string kosong atau null.
        // Namun, karena addKereta di service tidak mengembalikan ID ke model ini,
        // dan updateKereta butuh ID, maka ID harus ada di model.
        // Untuk add, kita bisa biarkan ID kosong, dan service akan meng-generate.
        // Untuk update, kita pakai ID yang ada.
        id: _isEditing ? widget.keretaToEdit!.id : '', // ID akan di-generate oleh Firestore saat add
        nama: _namaController.text,
        kelasUtama: _kelasUtamaController.text,
        jumlahKursi: int.tryParse(_jumlahKursiController.text) ?? 0,
      );

      try {
        if (_isEditing) {
          await _adminService.updateKereta(kereta);
        } else {
          await _adminService.addKereta(kereta);
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Kereta berhasil ${ _isEditing ? "diperbarui" : "ditambahkan"}!')),
          );
          Navigator.pop(context); // Kembali ke layar list
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menyimpan kereta: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? "Edit Kereta" : "Tambah Kereta Baru"),
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
                  labelText: 'Nama Kereta',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.train_rounded),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama kereta tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _kelasUtamaController,
                decoration: const InputDecoration(
                  labelText: 'Kelas Utama Kereta (mis: Eksekutif, Ekonomi)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.airline_seat_recline_normal_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Kelas utama tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _jumlahKursiController,
                decoration: const InputDecoration(
                  labelText: 'Jumlah Kursi Total',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.event_seat_outlined),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Jumlah kursi tidak boleh kosong';
                  }
                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                    return 'Masukkan jumlah kursi yang valid (lebih dari 0)';
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
                child: Text(_isEditing ? 'Simpan Perubahan' : 'Tambah Kereta', style: const TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}