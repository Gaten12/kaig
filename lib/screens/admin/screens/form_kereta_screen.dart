import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Untuk TextInputFormatter
import '../../../models/KeretaModel.dart'; // Pastikan path ini benar
import '../services/admin_firestore_service.dart'; // Pastikan path ini benar

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
    _namaController =
        TextEditingController(text: widget.keretaToEdit?.nama ?? '');
    _kelasUtamaController =
        TextEditingController(text: widget.keretaToEdit?.kelasUtama ?? '');
    _jumlahKursiController = TextEditingController(
        text: widget.keretaToEdit?.jumlahKursi.toString() ?? '');
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
        id: _isEditing
            ? widget.keretaToEdit!.id
            : '', // ID akan di-generate oleh Firestore saat add
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
            SnackBar(
                content: Text(
                    'Kereta berhasil ${_isEditing ? "diperbarui" : "ditambahkan"}!')),
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
    // Definisikan BorderSide yang akan digunakan berulang kali
    final BorderSide defaultBorderSide =
    BorderSide(color: Colors.grey.shade400); // Warna abu-abu muda
    final BorderSide focusedBorderSide = BorderSide(
        color: Colors.blueGrey.shade700, width: 2.0); // Warna tema saat fokus
    final BorderSide errorBorderSide =
    const BorderSide(color: Colors.red, width: 1.0); // Warna merah untuk error

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
          _isEditing ? "Edit Kereta" : "Tambah Kereta Baru",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w200,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white), // Agar tombol back juga putih
      ),
      body: Center( // Menengahkan Card di layar
        child: SingleChildScrollView( // Memastikan form bisa di-scroll
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card( // Menggunakan Card untuk membungkus form
              elevation: 4.0, // Memberi sedikit bayangan
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0), // Memberi sudut rounded
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0), // Padding di dalam Card
                child: Form(
                  key: _formKey,
                  child: Column( // Mengubah ListView menjadi Column
                    mainAxisSize: MainAxisSize.min, // Agar Column tidak mengambil tinggi maksimal
                    children: <Widget>[
                      TextFormField(
                        controller: _namaController,
                        decoration: InputDecoration(
                          labelText: 'Nama Kereta',
                          enabledBorder: defaultOutlineInputBorder,
                          focusedBorder: focusedOutlineInputBorder,
                          errorBorder: errorOutlineInputBorder,
                          focusedErrorBorder: focusedErrorOutlineInputBorder,
                          prefixIcon: Icon(Icons.train_rounded, color: Colors.blueGrey.shade700),
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
                        decoration: InputDecoration(
                          labelText: 'Kelas Utama Kereta (mis: Eksekutif, Ekonomi)',
                          enabledBorder: defaultOutlineInputBorder,
                          focusedBorder: focusedOutlineInputBorder,
                          errorBorder: errorOutlineInputBorder,
                          focusedErrorBorder: focusedErrorOutlineInputBorder,
                          prefixIcon: Icon(Icons.airline_seat_recline_normal_outlined, color: Colors.blueGrey.shade700),
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
                        decoration: InputDecoration(
                          labelText: 'Jumlah Kursi Total',
                          enabledBorder: defaultOutlineInputBorder,
                          focusedBorder: focusedOutlineInputBorder,
                          errorBorder: errorOutlineInputBorder,
                          focusedErrorBorder: focusedErrorOutlineInputBorder,
                          prefixIcon: Icon(Icons.event_seat_outlined, color: Colors.blueGrey.shade700),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Jumlah kursi tidak boleh kosong';
                          }
                          if (int.tryParse(value) == null ||
                              int.parse(value) <= 0) {
                            return 'Masukkan jumlah kursi yang valid (lebih dari 0)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24.0),
                      ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey, // Menyamakan dengan AppBar
                          foregroundColor: Colors.white, // Warna teks tombol
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder( // Memberi sudut rounded pada tombol
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: Text(
                          _isEditing ? 'Simpan Perubahan' : 'Tambah Kereta',
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