import 'package:flutter/material.dart';
import '../../models/user_data_daftar.dart';
import 'buat_kata_sandi_screen.dart';

class DaftarAkunScreen extends StatefulWidget {
  const DaftarAkunScreen({super.key});

  @override
  State<DaftarAkunScreen> createState() => _DaftarAkunScreenState();
}

class _DaftarAkunScreenState extends State<DaftarAkunScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Membuat objek UserDataDaftar hanya dengan email,
      // data lain akan diisi nanti di halaman profil.
      final dataPendaftaran = UserDataDaftar(
        namaLengkap: '',
        noTelepon: '',
        email: _emailController.text,
        tipeId: '',
        nomorId: '',
        tanggalLahir: DateTime.now(),
        jenisKelamin: '',
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
        padding: EdgeInsets.all(isSmallScreen ? 16.0 : 20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              Text(
                'Masukkan email Anda untuk memulai pendaftaran. Kata sandi akan dibuat di langkah berikutnya.',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.black87,
                  fontSize: isSmallScreen ? 14.0 : 16.0,
                ),
              ),
              SizedBox(height: isSmallScreen ? 18.0 : 24.0),
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
              SizedBox(height: isSmallScreen ? 24.0 : 32.0),
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