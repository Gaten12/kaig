import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Untuk format tanggal
import '../../models/user_data_daftar.dart'; // Model UserDataDaftar
import 'buat_kata_sandi_screen.dart'; // Layar berikutnya

class DaftarAkunScreen extends StatefulWidget {
  const DaftarAkunScreen({super.key});

  @override
  State<DaftarAkunScreen> createState() => _DaftarAkunScreenState();
}

class _DaftarAkunScreenState extends State<DaftarAkunScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers untuk setiap input field
  final _namaLengkapController = TextEditingController();
  final _noTeleponController = TextEditingController();
  final _emailController = TextEditingController();
  final _nomorIdController = TextEditingController();

  // Variabel untuk menyimpan nilai dari Dropdown, DatePicker, dan RadioButton
  String? _selectedTipeId;
  DateTime? _selectedTanggalLahir;
  String? _selectedJenisKelamin;

  final List<String> _tipeIdOptions = ['KTP', 'Paspor', 'SIM']; // Contoh opsi Tipe ID

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
      // Pastikan semua input yang tidak menggunakan controller juga sudah dipilih
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

      // Buat instance UserDataDaftar
      final dataPendaftaran = UserDataDaftar(
        namaLengkap: _namaLengkapController.text,
        noTelepon: _noTeleponController.text,
        email: _emailController.text,
        tipeId: _selectedTipeId!,
        nomorId: _nomorIdController.text,
        tanggalLahir: _selectedTanggalLahir!,
        jenisKelamin: _selectedJenisKelamin!,
      );

      // Navigasi ke BuatKataSandiScreen dengan membawa data
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFC50000), // Warna latar belakang AppBar (Merah Maroon)
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white), // Ikon kembali berwarna putih
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Daftar Akun', style: TextStyle(color: Colors.white)), // Teks AppBar berwarna putih
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              Text(
                'Daftar akun TrainOrder sekarang untuk mulai menjelajahi berbagai layanan dan fitur unggulan yang telah kami siapkan untukmu.',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.black87, // Sesuaikan warna teks jika perlu
                    ),
              ),
              const SizedBox(height: 24.0),

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
              const SizedBox(height: 16.0),

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
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nomor telepon tidak boleh kosong';
                  }
                  // Anda bisa menambahkan validasi format nomor telepon yang lebih spesifik
                  return null;
                },
              ),
              const SizedBox(height: 16.0),

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
              const SizedBox(height: 16.0),

              // Tipe ID & Nomor ID (dalam satu baris)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2, // Sesuaikan rasio lebar
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Tipe ID',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      value: _selectedTipeId,
                      hint: const Text('Pilih Tipe'),
                      items: _tipeIdOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedTipeId = newValue;
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Pilih tipe ID' : null,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    flex: 3, // Sesuaikan rasio lebar
                    child: TextFormField(
                      controller: _nomorIdController,
                      decoration: const InputDecoration(
                        labelText: 'Nomor ID',
                        hintText: 'Masukkan Nomor ID',
                        border: OutlineInputBorder(),
                      ),
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
              const SizedBox(height: 16.0),

              // Tanggal Lahir
              TextFormField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Tanggal Lahir',
                  hintText: _selectedTanggalLahir == null
                      ? 'Pilih Tanggal Lahir'
                      : DateFormat('dd MMMM yyyy', 'id_ID').format(_selectedTanggalLahir!), // Format ke bahasa Indonesia
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.calendar_today_outlined),
                ),
                onTap: () => _pilihTanggalLahir(context),
                validator: (value) {
                  // Validasi dilakukan saat submit form karena field ini readOnly
                  // dan nilainya di-set oleh _selectedTanggalLahir
                  if (_selectedTanggalLahir == null) {
                    return 'Tanggal lahir tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),

              // Jenis Kelamin
              const Text('Jenis Kelamin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Row(
                children: <Widget>[
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Laki-laki'),
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
                      title: const Text('Perempuan'),
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
              // Anda bisa menambahkan validator tersembunyi jika ingin memastikan salah satu dipilih
              // Atau validasi dilakukan saat submit form.
              const SizedBox(height: 24.0),

              // Tombol Lanjutkan
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: const Color(0xFF304FFE), // Warna tombol "LANJUTKAN" (Biru)
                  foregroundColor: Colors.white, // Warna teks tombol "LANJUTKAN"
                ),
                onPressed: _submitForm,
                child: const Text('LANJUTKAN'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}