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

  // Color Constants
  static const Color charcoalGray = Color(0xFF374151);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color electricBlue = Color(0xFF3B82F6);

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
                'Stasiun berhasil ${_isEditing ? "diperbarui" : "ditambahkan"}!',
                style: const TextStyle(color: pureWhite),
              ),
              backgroundColor: electricBlue,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Gagal menyimpan stasiun: $e',
                style: const TextStyle(color: pureWhite),
              ),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Define BorderSide dengan color scheme baru
    final BorderSide defaultBorderSide = BorderSide(
      color: charcoalGray.withOpacity(0.3),
      width: 1.5,
    );
    final BorderSide focusedBorderSide = BorderSide(
      color: electricBlue,
      width: 2.0,
    );
    const BorderSide errorBorderSide = BorderSide(
      color: Colors.red,
      width: 1.5,
    );

    // Define InputBorder untuk konsistensi
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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: charcoalGray,
        elevation: 0,
        title: Text(
          _isEditing ? "Edit Stasiun" : "Tambah Stasiun Baru",
          style: const TextStyle(
            color: pureWhite,
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        iconTheme: const IconThemeData(color: pureWhite, size: 28),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Card(
              elevation: 8.0,
              shadowColor: charcoalGray.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              color: pureWhite,
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // Header Section
                      Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: electricBlue.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isEditing ? Icons.edit : Icons.add_location,
                                size: 32,
                                color: electricBlue,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _isEditing ? 'Edit Data Stasiun' : 'Tambah Stasiun Baru',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: charcoalGray,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isEditing 
                                ? 'Perbarui informasi stasiun kereta api'
                                : 'Masukkan data stasiun kereta api baru',
                              style: TextStyle(
                                fontSize: 14,
                                color: charcoalGray.withOpacity(0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Form Fields
                      TextFormField(
                        controller: _namaController,
                        style: TextStyle(
                          color: charcoalGray,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Nama Stasiun',
                          labelStyle: TextStyle(
                            color: charcoalGray.withOpacity(0.7),
                            fontSize: 16,
                          ),
                          hintText: 'Contoh: Stasiun Gambir',
                          hintStyle: TextStyle(
                            color: charcoalGray.withOpacity(0.4),
                          ),
                          enabledBorder: defaultOutlineInputBorder,
                          focusedBorder: focusedOutlineInputBorder,
                          errorBorder: errorOutlineInputBorder,
                          focusedErrorBorder: focusedErrorOutlineInputBorder,
                          prefixIcon: Icon(
                            Icons.train,
                            color: electricBlue,
                            size: 24,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Nama stasiun tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20.0),
                      
                      TextFormField(
                        controller: _kodeController,
                        style: TextStyle(
                          color: charcoalGray,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.0,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Kode Stasiun',
                          labelStyle: TextStyle(
                            color: charcoalGray.withOpacity(0.7),
                            fontSize: 16,
                          ),
                          hintText: 'Contoh: GMR',
                          hintStyle: TextStyle(
                            color: charcoalGray.withOpacity(0.4),
                          ),
                          enabledBorder: defaultOutlineInputBorder,
                          focusedBorder: focusedOutlineInputBorder,
                          errorBorder: errorOutlineInputBorder,
                          focusedErrorBorder: focusedErrorOutlineInputBorder,
                          prefixIcon: Icon(
                            Icons.confirmation_number,
                            color: electricBlue,
                            size: 24,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
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
                      ),
                      const SizedBox(height: 20.0),
                      
                      TextFormField(
                        controller: _kotaController,
                        style: TextStyle(
                          color: charcoalGray,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Kota',
                          labelStyle: TextStyle(
                            color: charcoalGray.withOpacity(0.7),
                            fontSize: 16,
                          ),
                          hintText: 'Contoh: Jakarta Pusat',
                          hintStyle: TextStyle(
                            color: charcoalGray.withOpacity(0.4),
                          ),
                          enabledBorder: defaultOutlineInputBorder,
                          focusedBorder: focusedOutlineInputBorder,
                          errorBorder: errorOutlineInputBorder,
                          focusedErrorBorder: focusedErrorOutlineInputBorder,
                          prefixIcon: Icon(
                            Icons.location_city,
                            color: electricBlue,
                            size: 24,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Kota tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32.0),
                      
                      // Submit Button
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [electricBlue, electricBlue.withOpacity(0.8)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(12.0),
                          boxShadow: [
                            BoxShadow(
                              color: electricBlue.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isEditing ? Icons.save : Icons.add,
                                color: pureWhite,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isEditing ? 'Simpan Perubahan' : 'Tambah Stasiun',
                                style: const TextStyle(
                                  color: pureWhite,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
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
    );
  }
}