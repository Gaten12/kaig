import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/user_data_daftar.dart';
import 'buat_kata_sandi_screen.dart';

class DaftarAkunScreen extends StatefulWidget {
  const DaftarAkunScreen({super.key});

  @override
  State<DaftarAkunScreen> createState() => _DaftarAkunScreenState();
}

class _DaftarAkunScreenState extends State<DaftarAkunScreen> {
  final _formKey = GlobalKey<FormState>();

  final _namaLengkapController = TextEditingController();
  final _noTeleponController = TextEditingController();
  final _emailController = TextEditingController();
  final _nomorIdController = TextEditingController();

  String? _selectedTipeId;
  DateTime? _selectedTanggalLahir;
  String? _selectedJenisKelamin;

  final List<String> _tipeIdOptions = ['KTP', 'Paspor', 'SIM'];

  @override
  void dispose() {
    _namaLengkapController.dispose();
    _noTeleponController.dispose();
    _emailController.dispose();
    _nomorIdController.dispose();
    super.dispose();
  }

  Future<void> _pilihTanggalLahir(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedTanggalLahir ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Pilih Tanggal Lahir',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );
    if (picked != null && picked != _selectedTanggalLahir) {
      setState(() {
        _selectedTanggalLahir = picked;
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_selectedTipeId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan pilih Tipe ID.')),
        );
        return;
      }
      if (_selectedTanggalLahir == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan pilih Tanggal Lahir.')),
        );
        return;
      }
      if (_selectedJenisKelamin == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan pilih Jenis Kelamin.')),
        );
        return;
      }

      final dataPendaftaran = UserDataDaftar(
        namaLengkap: _namaLengkapController.text,
        noTelepon: _noTeleponController.text,
        email: _emailController.text,
        tipeId: _selectedTipeId!,
        nomorId: _nomorIdController.text,
        tanggalLahir: _selectedTanggalLahir!,
        jenisKelamin: _selectedJenisKelamin!,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BuatKataSandiScreen(userData: dataPendaftaran),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFC50000),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Daftar Akun', style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              Text(
                'Daftar akun TrainOrder sekarang untuk mulai menjelajahi berbagai layanan dan fitur unggulan yang telah kami siapkan untukmu.',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.black87,
                  fontSize: isSmallScreen ? 14.0 : 16.0,
                ),
              ),
              SizedBox(height: isSmallScreen ? 18.0 : 24.0),

              // Nama Lengkap
              TextFormField(
                controller: _namaLengkapController,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap',
                  hintText: 'Masukkan Nama Lengkap',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama lengkap tidak boleh kosong';
                  }
                  return null;
                },
              ),
              SizedBox(height: isSmallScreen ? 12.0 : 16.0),

              // No. Telepon
              TextFormField(
                controller: _noTeleponController,
                decoration: const InputDecoration(
                  labelText: 'No. Telepon',
                  hintText: 'Masukkan Nomor Telepon',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nomor telepon tidak boleh kosong';
                  }
                  return null;
                },
              ),
              SizedBox(height: isSmallScreen ? 12.0 : 16.0),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'Masukkan Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email tidak boleh kosong';
                  }
                  if (!value.contains('@') || !value.contains('.')) {
                    return 'Format email tidak valid';
                  }
                  return null;
                },
              ),
              SizedBox(height: isSmallScreen ? 12.0 : 16.0),

              // Tipe ID & Nomor ID
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: isSmallScreen ? 3 : 2,
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Tipe ID',
                        border: const OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                            vertical: isSmallScreen ? 10.0 : 12.0,
                            horizontal: 10.0),
                        isDense: true,
                      ),
                      value: _selectedTipeId,
                      hint: const Text('Pilih Tipe'),
                      items: _tipeIdOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child:
                          Text(value, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedTipeId = newValue;
                          // Kosongkan field Nomor ID saat Tipe ID berubah
                          _nomorIdController.clear();
                        });
                      },
                      validator: (value) =>
                      value == null ? 'Pilih tipe ID' : null,
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 4.0 : 8.0),
                  Expanded(
                    flex: isSmallScreen ? 4 : 3,
                    child: TextFormField(
                      controller: _nomorIdController,
                      decoration: InputDecoration(
                        labelText: 'Nomor ID',
                        hintText: 'Masukkan Nomor ID',
                        border: const OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                            vertical: isSmallScreen ? 10.0 : 12.0,
                            horizontal: 10.0),
                      ),
                      // --- Perubahan Logika di Sini ---
                      // Keyboard type menjadi dinamis
                      keyboardType: _selectedTipeId == 'Paspor'
                          ? TextInputType.text
                          : TextInputType.number,
                      // Input formatter menjadi dinamis
                      inputFormatters: _selectedTipeId == 'Paspor'
                      // Izinkan huruf dan angka untuk paspor
                          ? [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]'))]
                      // Izinkan hanya angka untuk KTP/SIM
                          : [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nomor ID tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: isSmallScreen ? 12.0 : 16.0),

              // Tanggal Lahir
              TextFormField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Tanggal Lahir',
                  hintText: _selectedTanggalLahir == null
                      ? 'Pilih Tanggal Lahir'
                      : DateFormat('dd MMMM yyyy', 'id_ID')
                      .format(_selectedTanggalLahir!),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.calendar_today_outlined),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                      vertical: isSmallScreen ? 10.0 : 12.0,
                      horizontal: 10.0),
                ),
                onTap: () => _pilihTanggalLahir(context),
                validator: (value) {
                  if (_selectedTanggalLahir == null) {
                    return 'Tanggal lahir tidak boleh kosong';
                  }
                  return null;
                },
              ),
              SizedBox(height: isSmallScreen ? 12.0 : 16.0),

              // Jenis Kelamin
              Text('Jenis Kelamin',
                  style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.bold)),
              Row(
                children: <Widget>[
                  Expanded(
                    child: RadioListTile<String>(
                      title: Text('Laki-laki',
                          style: TextStyle(fontSize: isSmallScreen ? 11 : null)),
                      value: 'Laki-laki',
                      groupValue: _selectedJenisKelamin,
                      onChanged: (value) {
                        setState(() {
                          _selectedJenisKelamin = value;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: Text('Perempuan',
                          style: TextStyle(fontSize: isSmallScreen ? 11 : null)),
                      value: 'Perempuan',
                      groupValue: _selectedJenisKelamin,
                      onChanged: (value) {
                        setState(() {
                          _selectedJenisKelamin = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: isSmallScreen ? 18.0 : 24.0),

              // Tombol Lanjutkan
              SizedBox(
                width: double.infinity,
                height: isSmallScreen ? 45.0 : 50.0,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF304FFE),
                    foregroundColor: Colors.white,
                    textStyle:
                    TextStyle(fontSize: isSmallScreen ? 16.0 : 18.0),
                  ),
                  onPressed: _submitForm,
                  child: const Text('LANJUTKAN'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}