import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Untuk Timestamp
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../models/passenger_model.dart';
import '../../../../services/auth_service.dart';

class FormPenumpangScreen extends StatefulWidget {
  final PassengerModel? penumpangToEdit;

  const FormPenumpangScreen({super.key, this.penumpangToEdit});

  @override
  State<FormPenumpangScreen> createState() => _FormPenumpangScreenState();
}

class _FormPenumpangScreenState extends State<FormPenumpangScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  late TextEditingController _namaLengkapController;
  late TextEditingController _nomorIdController;

  String? _selectedTipePenumpang;
  String? _selectedTipeId;
  DateTime? _selectedTanggalLahir;
  String? _selectedJenisKelamin;

  final List<String> _tipePenumpangOptions = ['Dewasa', 'Bayi (< 3 Tahun)'];
  final List<String> _tipeIdOptions = ['KTP', 'Paspor', 'SIM', 'Lainnya'];

  bool get _isEditing => widget.penumpangToEdit != null;

  @override
  void initState() {
    super.initState();
    _namaLengkapController = TextEditingController(text: widget.penumpangToEdit?.namaLengkap ?? '');
    _nomorIdController = TextEditingController(text: widget.penumpangToEdit?.nomorId ?? '');

    if (_isEditing) {
      final p = widget.penumpangToEdit!;
      _selectedTipePenumpang = p.tipePenumpang;
      _selectedTipeId = p.tipeId;
      _selectedTanggalLahir = p.tanggalLahir.toDate();
      _selectedJenisKelamin = p.jenisKelamin;
    } else {
      _selectedTipePenumpang = _tipePenumpangOptions.first;
    }
  }

  @override
  void dispose() {
    _namaLengkapController.dispose();
    _nomorIdController.dispose();
    super.dispose();
  }

  Future<void> _pilihTanggalLahir(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedTanggalLahir ?? DateTime.now().subtract(const Duration(days: 365 * 10)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedTanggalLahir) {
      setState(() {
        _selectedTanggalLahir = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      // Show error if any field is invalid
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap lengkapi semua field yang wajib diisi.')),
      );
      return;
    }

    if (_selectedTipePenumpang == null || _selectedTipeId == null || _selectedTanggalLahir == null || _selectedJenisKelamin == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harap lengkapi semua field.')));
      return;
    }


    _formKey.currentState!.save();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Anda harus login untuk menyimpan penumpang.')));
      return;
    }

    final passengerData = PassengerModel(
      id: _isEditing ? widget.penumpangToEdit!.id : null,
      namaLengkap: _namaLengkapController.text,
      tipeId: _selectedTipeId!,
      nomorId: _nomorIdController.text,
      tanggalLahir: Timestamp.fromDate(_selectedTanggalLahir!),
      jenisKelamin: _selectedJenisKelamin!,
      tipePenumpang: _selectedTipePenumpang!,
      isPrimary: _isEditing ? widget.penumpangToEdit!.isPrimary : false,
    );

    try {
      if (_isEditing) {
        await _authService.updatePassenger(user.uid, passengerData);
      } else {
        await _authService.addPassenger(user.uid, passengerData);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Penumpang berhasil ${ _isEditing ? "diperbarui" : "ditambahkan"}!')),
        );
        Navigator.pop(context, true); // Kirim true untuk menandakan ada perubahan
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan penumpang: $e')),
        );
      }
    }
  }

  Future<void> _deletePassenger() async {
    if (!_isEditing || widget.penumpangToEdit?.id == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (widget.penumpangToEdit!.isPrimary == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data penumpang utama tidak dapat dihapus dari sini.')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Konfirmasi Hapus"),
        content: Text("Anda yakin ingin menghapus penumpang '${widget.penumpangToEdit!.namaLengkap}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text("Batal")),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text("Hapus", style: TextStyle(color: Colors.red.shade700))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _authService.deletePassenger(user.uid, widget.penumpangToEdit!.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Penumpang berhasil dihapus!')),
          );
          Navigator.pop(context, true); // Kirim true untuk menandakan ada perubahan
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus penumpang: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFC50000),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: Text(
          _isEditing ? "Ubah Penumpang" : "Tambah Penumpang Baru",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: isSmallScreen ? 18 : 20),
        ),
      ),
      body: SingleChildScrollView( // Added SingleChildScrollView to make it scrollable
        padding: EdgeInsets.all(isSmallScreen ? 16.0 : 20.0), // Responsive padding
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch children to fill width
            children: <Widget>[
              TextFormField(
                controller: _namaLengkapController,
                decoration: InputDecoration(
                  labelText: "Nama Lengkap",
                  border: const OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: isSmallScreen ? 12 : 14), // Responsive padding
                ),
                validator: (value) => (value == null || value.isEmpty) ? "Nama tidak boleh kosong" : null,
              ),
              SizedBox(height: isSmallScreen ? 12.0 : 16.0), // Responsive spacing
              DropdownButtonFormField<String>(
                value: _selectedTipePenumpang,
                decoration: InputDecoration(
                  labelText: "Tipe Penumpang",
                  border: const OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: isSmallScreen ? 12 : 14), // Responsive padding
                  isDense: true, // Make it more compact
                ),
                items: _tipePenumpangOptions.map((String value) {
                  return DropdownMenuItem<String>(value: value, child: Text(value, style: TextStyle(fontSize: isSmallScreen ? 14 : null))); // Responsive font size
                }).toList(),
                onChanged: (value) => setState(() => _selectedTipePenumpang = value),
                validator: (value) => value == null ? "Pilih tipe penumpang" : null,
              ),
              SizedBox(height: isSmallScreen ? 12.0 : 16.0), // Responsive spacing
              Row(
                crossAxisAlignment: CrossAxisAlignment.start, // Align top for overflow prevention
                children: [
                  Expanded(
                    flex: isSmallScreen ? 2 : 2, // Adjust flex for small screens, maintain ratio
                    child: DropdownButtonFormField<String>(
                      value: _selectedTipeId,
                      decoration: InputDecoration(
                        labelText: "Tipe ID",
                        border: const OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: isSmallScreen ? 12 : 14), // Responsive padding
                        isDense: true, // Make it more compact
                      ),
                      items: _tipeIdOptions.map((String value) {
                        return DropdownMenuItem<String>(value: value, child: Text(value, style: TextStyle(fontSize: isSmallScreen ? 14 : null))); // Responsive font size
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedTipeId = value),
                      validator: (value) => value == null ? "Pilih tipe ID" : null,
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 8.0 : 12.0), // Responsive spacing
                  Expanded(
                    flex: isSmallScreen ? 3 : 3, // Adjust flex, give more space to Nomor ID
                    child: TextFormField(
                      controller: _nomorIdController,
                      decoration: InputDecoration(
                        labelText: "Nomor ID",
                        border: const OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: isSmallScreen ? 12 : 14), // Responsive padding
                        isDense: true, // Make it more compact
                      ),
                      validator: (value) => (value == null || value.isEmpty) ? "Nomor ID tidak boleh kosong" : null,
                    ),
                  ),
                ],
              ),
              SizedBox(height: isSmallScreen ? 12.0 : 16.0), // Responsive spacing
              TextFormField(
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Tanggal Lahir',
                    hintText: _selectedTanggalLahir == null
                        ? 'Pilih Tanggal Lahir'
                        : DateFormat('dd MMMM yyyy', 'id_ID').format(_selectedTanggalLahir!), // Changed format for full year
                    border: const OutlineInputBorder(),
                    suffixIcon: const Icon(Icons.calendar_today),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: isSmallScreen ? 12 : 14), // Responsive padding
                  ),
                  onTap: () => _pilihTanggalLahir(context),
                  validator: (value){
                    if(_selectedTanggalLahir == null) return 'Tanggal lahir tidak boleh kosong';
                    return null;
                  }
              ),
              SizedBox(height: isSmallScreen ? 12.0 : 16.0), // Responsive spacing
              Text("Jenis Kelamin", style: TextStyle(fontSize: isSmallScreen ? 15 : 16)), // Responsive font size
              Row(
                children: <Widget>[
                  Expanded(
                    child: RadioListTile<String>(
                      title: Text('Laki-laki', style: TextStyle(fontSize: isSmallScreen ? 10 : null)), // Responsive font size
                      value: 'Laki-laki', groupValue: _selectedJenisKelamin,
                      onChanged: (value) => setState(() => _selectedJenisKelamin = value),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: Text('Perempuan', style: TextStyle(fontSize: isSmallScreen ? 10 : null)), // Responsive font size
                      value: 'Perempuan', groupValue: _selectedJenisKelamin,
                      onChanged: (value) => setState(() => _selectedJenisKelamin = value),
                    ),
                  ),
                ],
              ),
              if (_selectedJenisKelamin == null)
                Padding(
                  padding: EdgeInsets.only(left: isSmallScreen ? 12.0 : 16.0, top: isSmallScreen ? 0 : 4), // Responsive padding
                  child: Text("Pilih jenis kelamin", style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: isSmallScreen ? 11 : 12)), // Responsive font size
                ),
              SizedBox(height: isSmallScreen ? 24.0 : 32.0), // Responsive spacing
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF304FFE),
                  minimumSize: Size(double.infinity, isSmallScreen ? 45 : 50), // Responsive button height
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12)), // Responsive border radius
                ),
                child: Text(_isEditing ? "SIMPAN PERUBAHAN" : "SIMPAN PENUMPANG", style: TextStyle(fontSize: isSmallScreen ? 15 : 16)), // Responsive font size
              ),
              if (_isEditing) ...[
                SizedBox(height: isSmallScreen ? 8.0 : 12.0), // Responsive spacing
                OutlinedButton(
                  onPressed: _deletePassenger,
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(double.infinity, isSmallScreen ? 45 : 50), // Responsive button height
                    side: BorderSide(color: Colors.red.shade300),
                    foregroundColor: Colors.red.shade700,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12)), // Responsive border radius
                  ),
                  child: Text("HAPUS PENUMPANG", style: TextStyle(fontSize: isSmallScreen ? 15 : 16)), // Responsive font size
                ),
              ],
              SizedBox(height: isSmallScreen ? 8 : 16), // Extra bottom padding for scroll
            ],
          ),
        ),
      ),
    );
  }
}
