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

  // Definisi warna tema
  static const Color _charcoalGray = Color(0xFF374151);
  static const Color _pureWhite = Color(0xFFFFFFFF);
  static const Color _electricBlue = Color(0xFF3B82F6);

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
        SnackBar(
          content: const Text("Harap pilih kelas utama.", style: TextStyle(color: _pureWhite)),
          backgroundColor: _charcoalGray,
        ),
      );
      return;
    }
    if (_selectedLayout == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Harap pilih tipe layout kursi.", style: TextStyle(color: _pureWhite)),
          backgroundColor: _charcoalGray,
        ),
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
              'Tipe Gerbong berhasil ${_isEditing ? "diperbarui" : "ditambahkan"}!',
              style: const TextStyle(color: _pureWhite),
            ),
            backgroundColor: _electricBlue,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan tipe gerbong: $e', style: const TextStyle(color: _pureWhite)),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Definisikan BorderSide dengan warna tema baru
    final BorderSide defaultBorderSide = BorderSide(color: _charcoalGray.withAlpha((255 * 0.3).round()));
    final BorderSide focusedBorderSide = const BorderSide(color: _electricBlue, width: 2.0);
    const BorderSide errorBorderSide = BorderSide(color: Colors.red, width: 1.0);

    // Definisikan InputBorder untuk konsistensi
    final OutlineInputBorder defaultOutlineInputBorder = OutlineInputBorder(
      borderSide: defaultBorderSide,
      borderRadius: BorderRadius.circular(12.0),
    );

    final OutlineInputBorder focusedOutlineInputBorder = OutlineInputBorder(
      borderSide: focusedBorderSide,
      borderRadius: BorderRadius.circular(12.0),
    );

    final OutlineInputBorder errorOutlineInputBorder = OutlineInputBorder(
      borderSide: errorBorderSide,
      borderRadius: BorderRadius.circular(12.0),
    );

    final OutlineInputBorder focusedErrorOutlineInputBorder = OutlineInputBorder(
      borderSide: errorBorderSide.copyWith(width: 2.0),
      borderRadius: BorderRadius.circular(12.0),
    );

    return Scaffold(
      backgroundColor: _pureWhite,
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: _charcoalGray,
        elevation: 0,
        title: Text(
          _isEditing ? "Edit Tipe Gerbong" : "Tambah Tipe Gerbong Baru",
          style: const TextStyle(
            color: _pureWhite,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: _pureWhite),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _charcoalGray.withAlpha((255 * 0.5).round()),
              _pureWhite,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 8.0,
                shadowColor: _charcoalGray.withAlpha((255 * 0.2).round()),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                color: _pureWhite,
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        // Header dengan ikon
                        Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: _electricBlue.withAlpha((255 * 0.1).round()),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Icon(
                            Icons.train_outlined,
                            size: 48,
                            color: _electricBlue,
                          ),
                        ),
                        const SizedBox(height: 24.0),
                        
                        DropdownButtonFormField<KelasUtama>(
                          value: _selectedKelas,
                          decoration: InputDecoration(
                            labelText: 'Pilih Kelas Utama',
                            labelStyle: TextStyle(color: _charcoalGray.withAlpha((255 * 0.7).round())),
                            enabledBorder: defaultOutlineInputBorder,
                            focusedBorder: focusedOutlineInputBorder,
                            errorBorder: errorOutlineInputBorder,
                            focusedErrorBorder: focusedErrorOutlineInputBorder,
                            prefixIcon: Icon(Icons.star_outline, color: _electricBlue),
                            filled: true,
                            fillColor: _charcoalGray.withAlpha((255 * 0.02).round()),
                          ),
                          dropdownColor: _pureWhite,
                          items: KelasUtama.values.map((KelasUtama kelas) {
                            return DropdownMenuItem<KelasUtama>(
                              value: kelas,
                              child: Text(
                                kelas.name[0].toUpperCase() + kelas.name.substring(1),
                                style: const TextStyle(color: _charcoalGray),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) => setState(() => _selectedKelas = value),
                          validator: (value) => value == null ? 'Pilih kelas utama' : null,
                        ),
                        const SizedBox(height: 20.0),
                        
                        TextFormField(
                          controller: _subTipeController,
                          style: const TextStyle(color: _charcoalGray),
                          decoration: InputDecoration(
                            labelText: 'Nama/Sub-Tipe (mis: New Generation)',
                            labelStyle: TextStyle(color: _charcoalGray.withAlpha((255 * 0.7).round())),
                            enabledBorder: defaultOutlineInputBorder,
                            focusedBorder: focusedOutlineInputBorder,
                            errorBorder: errorOutlineInputBorder,
                            focusedErrorBorder: focusedErrorOutlineInputBorder,
                            prefixIcon: Icon(Icons.text_fields_outlined, color: _electricBlue),
                            filled: true,
                            fillColor: _charcoalGray.withAlpha((255 * 0.02).round()),
                          ),
                          validator: (value) => (value == null || value.isEmpty)
                              ? 'Sub-tipe tidak boleh kosong'
                              : null,
                        ),
                        const SizedBox(height: 20.0),
                        
                        DropdownButtonFormField<TipeLayoutGerbong>(
                          value: _selectedLayout,
                          decoration: InputDecoration(
                            labelText: 'Tipe Layout Kursi',
                            labelStyle: TextStyle(color: _charcoalGray.withAlpha((255 * 0.7).round())),
                            enabledBorder: defaultOutlineInputBorder,
                            focusedBorder: focusedOutlineInputBorder,
                            errorBorder: errorOutlineInputBorder,
                            focusedErrorBorder: focusedErrorOutlineInputBorder,
                            prefixIcon: Icon(Icons.grid_view_outlined, color: _electricBlue),
                            filled: true,
                            fillColor: _charcoalGray.withAlpha((255 * 0.02).round()),
                          ),
                          dropdownColor: _pureWhite,
                          items: TipeLayoutGerbong.values.map((TipeLayoutGerbong layout) {
                            return DropdownMenuItem<TipeLayoutGerbong>(
                              value: layout,
                              child: Text(
                                layout.deskripsi,
                                style: const TextStyle(color: _charcoalGray),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) => setState(() => _selectedLayout = value),
                          validator: (value) => value == null ? 'Pilih tipe layout' : null,
                        ),
                        const SizedBox(height: 20.0),
                        
                        TextFormField(
                          controller: _jumlahKursiController,
                          style: const TextStyle(color: _charcoalGray),
                          decoration: InputDecoration(
                            labelText: 'Jumlah Kursi',
                            labelStyle: TextStyle(color: _charcoalGray.withAlpha((255 * 0.7).round())),
                            enabledBorder: defaultOutlineInputBorder,
                            focusedBorder: focusedOutlineInputBorder,
                            errorBorder: errorOutlineInputBorder,
                            focusedErrorBorder: focusedErrorOutlineInputBorder,
                            prefixIcon: Icon(Icons.event_seat_outlined, color: _electricBlue),
                            filled: true,
                            fillColor: _charcoalGray.withAlpha((255 * 0.02).round()),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                        const SizedBox(height: 32.0),
                        
                        Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [_electricBlue, _electricBlue.withAlpha((255 * 0.8).round())],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12.0),
                            boxShadow: [
                              BoxShadow(
                                color: _electricBlue.withAlpha((255 * 0.3).round()),
                                blurRadius: 8.0,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: _pureWhite,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _isEditing ? Icons.edit_outlined : Icons.add_circle_outline,
                                  color: _pureWhite,
                                ),
                                const SizedBox(width: 8.0),
                                Text(
                                  _isEditing ? 'Simpan Perubahan' : 'Tambah Tipe Gerbong',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
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
      ),
    );
  }
}