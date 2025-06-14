import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Untuk Timestamp
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../models/passenger_model.dart';
import '../keranjang/auth_service.dart';

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
    // ... (validasi tetap sama) ...
    if (!_formKey.currentState!.validate()) return;
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFC50000),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: Text(
          _isEditing ? "Ubah Penumpang" : "Tambah Penumpang Baru",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: _namaLengkapController,
                decoration: const InputDecoration(labelText: "Nama Lengkap", border: OutlineInputBorder()),
                validator: (value) => (value == null || value.isEmpty) ? "Nama tidak boleh kosong" : null,
              ),
              const SizedBox(height: 16.0),
              DropdownButtonFormField<String>(
                value: _selectedTipePenumpang,
                decoration: const InputDecoration(labelText: "Tipe Penumpang", border: OutlineInputBorder()),
                items: _tipePenumpangOptions.map((String value) {
                  return DropdownMenuItem<String>(value: value, child: Text(value));
                }).toList(),
                onChanged: (value) => setState(() => _selectedTipePenumpang = value),
                validator: (value) => value == null ? "Pilih tipe penumpang" : null,
              ),
              const SizedBox(height: 16.0),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedTipeId,
                      decoration: const InputDecoration(labelText: "Tipe ID", border: OutlineInputBorder()),
                      items: _tipeIdOptions.map((String value) {
                        return DropdownMenuItem<String>(value: value, child: Text(value));
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedTipeId = value),
                      validator: (value) => value == null ? "Pilih tipe ID" : null,
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _nomorIdController,
                      decoration: const InputDecoration(labelText: "Nomor ID", border: OutlineInputBorder()),
                      validator: (value) => (value == null || value.isEmpty) ? "Nomor ID tidak boleh kosong" : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Tanggal Lahir',
                    hintText: _selectedTanggalLahir == null
                        ? 'Pilih Tanggal Lahir'
                        : DateFormat('dd MMMM yyyy', 'id_ID').format(_selectedTanggalLahir!),
                    border: const OutlineInputBorder(),
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                  onTap: () => _pilihTanggalLahir(context),
                  validator: (value){
                    if(_selectedTanggalLahir == null) return 'Tanggal lahir tidak boleh kosong';
                    return null;
                  }
              ),
              const SizedBox(height: 16.0),
              const Text("Jenis Kelamin", style: TextStyle(fontSize: 16)),
              Row(
                children: <Widget>[
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Laki-laki'), value: 'Laki-laki', groupValue: _selectedJenisKelamin,
                      onChanged: (value) => setState(() => _selectedJenisKelamin = value),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Perempuan'), value: 'Perempuan', groupValue: _selectedJenisKelamin,
                      onChanged: (value) => setState(() => _selectedJenisKelamin = value),
                    ),
                  ),
                ],
              ),
              if (_selectedJenisKelamin == null)
                Padding(
                  padding: const EdgeInsets.only(left: 12.0, top:0),
                  child: Text("Pilih jenis kelamin", style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
                ),
              const SizedBox(height: 32.0),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF304FFE),
                  minimumSize: const Size(double.infinity, 50)
                  ),
                
                child: Text(_isEditing ? "SIMPAN PERUBAHAN" : "SIMPAN PENUMPANG"),
              ),
              if (_isEditing) ...[
                const SizedBox(height: 12.0),
                OutlinedButton(
                  onPressed: _deletePassenger,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    side: BorderSide(color: Colors.red.shade300),
                    foregroundColor: Colors.red.shade700,
                  ),
                  child: const Text("HAPUS PENUMPANG"),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
