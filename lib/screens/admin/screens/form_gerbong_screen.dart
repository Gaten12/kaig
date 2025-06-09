import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/gerbong_tipe_model.dart'; // Pastikan path ini benar
import '../services/admin_firestore_service.dart'; // Pastikan path ini benar

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

  // Opsi layout manual tidak lagi diperlukan jika menggunakan enum TipeLayoutGerbong
  // final List<String> _layoutOptions = ['2-2', '3-2', '2-1', '1-1'];

  bool get _isEditing => widget.gerbongToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final gerbong = widget.gerbongToEdit!;
      _selectedKelas = gerbong.kelas;
      _subTipeController = TextEditingController(text: gerbong.subTipe);
      _selectedLayout = gerbong.tipeLayout;
      _jumlahKursiController =
          TextEditingController(text: gerbong.jumlahKursi.toString());
    } else {
      _subTipeController = TextEditingController();
      _jumlahKursiController = TextEditingController();
      // _selectedKelas = KelasUtama.values.first; // Contoh inisialisasi default jika diperlukan
      // _selectedLayout = TipeLayoutGerbong.values.first; // Contoh inisialisasi default
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

    // Validasi tambahan untuk dropdown jika belum dipilih
    if (_selectedKelas == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Harap pilih kelas utama.")),
      );
      return;
    }
    if (_selectedLayout == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Harap pilih tipe layout kursi.")),
      );
      return;
    }

    final gerbong = GerbongTipeModel(
      id: _isEditing
          ? widget.gerbongToEdit!.id
          : '', // ID akan di-generate Firestore saat add, atau Anda bisa membuat ID unik di client jika diperlukan
      kelas: _selectedKelas!,
      subTipe: _subTipeController.text.trim(),
      tipeLayout: _selectedLayout!,
      jumlahKursi: int.tryParse(_jumlahKursiController.text.trim()) ?? 0,
    );

    try {
      if (_isEditing) {
        await _adminService.updateGerbongTipe(gerbong);
      } else {
        await _adminService.addGerbongTipe(gerbong);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Tipe Gerbong berhasil ${_isEditing ? "diperbarui" : "ditambahkan"}!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan tipe gerbong: $e')),
        );
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
      borderSide: errorBorderSide.copyWith(
          width: 2.0), // Error dan fokus, sedikit lebih tebal
      borderRadius: BorderRadius.circular(8.0),
    );

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Colors.blueGrey,
        title: Text(
          _isEditing ? "Edit Tipe Gerbong" : "Tambah Tipe Gerbong Baru",
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
                      DropdownButtonFormField<KelasUtama>(
                        value: _selectedKelas,
                        decoration: InputDecoration(
                          labelText: 'Pilih Kelas Utama',
                          enabledBorder: defaultOutlineInputBorder,
                          focusedBorder: focusedOutlineInputBorder,
                          errorBorder: errorOutlineInputBorder,
                          focusedErrorBorder: focusedErrorOutlineInputBorder,
                          prefixIcon: Icon(Icons.star_outline,
                              color: Colors.blueGrey.shade700),
                        ),
                        items: KelasUtama.values.map((KelasUtama kelas) {
                          return DropdownMenuItem<KelasUtama>(
                            value: kelas,
                            child: Text(kelas.name[0].toUpperCase() +
                                kelas.name.substring(1)),
                          );
                        }).toList(),
                        onChanged: (value) =>
                            setState(() => _selectedKelas = value),
                        validator: (value) =>
                        value == null ? 'Pilih kelas utama' : null,
                      ),
                      const SizedBox(height: 16.0),
                      TextFormField(
                        controller: _subTipeController,
                        decoration: InputDecoration(
                          labelText: 'Nama/Sub-Tipe (mis: New Generation)',
                          enabledBorder: defaultOutlineInputBorder,
                          focusedBorder: focusedOutlineInputBorder,
                          errorBorder: errorOutlineInputBorder,
                          focusedErrorBorder: focusedErrorOutlineInputBorder,
                          prefixIcon: Icon(Icons.text_fields_outlined,
                              color: Colors.blueGrey.shade700),
                        ),
                        validator: (value) => (value == null || value.isEmpty)
                            ? 'Sub-tipe tidak boleh kosong'
                            : null,
                      ),
                      const SizedBox(height: 16.0),
                      DropdownButtonFormField<TipeLayoutGerbong>(
                        value: _selectedLayout,
                        decoration: InputDecoration(
                          labelText: 'Tipe Layout Kursi',
                          enabledBorder: defaultOutlineInputBorder,
                          focusedBorder: focusedOutlineInputBorder,
                          errorBorder: errorOutlineInputBorder,
                          focusedErrorBorder: focusedErrorOutlineInputBorder,
                          prefixIcon: Icon(Icons.grid_view_outlined,
                              color: Colors.blueGrey.shade700),
                        ),
                        items: TipeLayoutGerbong.values
                            .map((TipeLayoutGerbong layout) {
                          return DropdownMenuItem<TipeLayoutGerbong>(
                            value: layout,
                            child: Text(layout.deskripsi),
                          );
                        }).toList(),
                        onChanged: (value) =>
                            setState(() => _selectedLayout = value),
                        validator: (value) =>
                        value == null ? 'Pilih tipe layout' : null,
                      ),
                      const SizedBox(height: 16.0),
                      TextFormField(
                        controller: _jumlahKursiController,
                        decoration: InputDecoration(
                          labelText: 'Jumlah Kursi',
                          enabledBorder: defaultOutlineInputBorder,
                          focusedBorder: focusedOutlineInputBorder,
                          errorBorder: errorOutlineInputBorder,
                          focusedErrorBorder: focusedErrorOutlineInputBorder,
                          prefixIcon: Icon(Icons.event_seat_outlined,
                              color: Colors.blueGrey.shade700),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
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
                          backgroundColor: Colors.blueGrey,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: Text(
                          _isEditing ? 'Simpan Perubahan' : 'Tambah Tipe Gerbong',
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