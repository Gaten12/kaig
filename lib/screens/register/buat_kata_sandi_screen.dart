import 'package:flutter/material.dart';
import '../../models/user_data_daftar.dart'; // Model untuk data pendaftaran
import '../../services/auth_service.dart';  // Service untuk interaksi dengan Firebase Auth & Firestore
import '../login/login_screen.dart';       // Layar login email untuk navigasi setelah berhasil

class BuatKataSandiScreen extends StatefulWidget {
  final UserDataDaftar userData; // Data dari layar pendaftaran sebelumnya

  const BuatKataSandiScreen({super.key, required this.userData});

  @override
  State<BuatKataSandiScreen> createState() => _BuatKataSandiScreenState();
}

class _BuatKataSandiScreenState extends State<BuatKataSandiScreen> {
  final _formKeyKataSandi = GlobalKey<FormState>();
  final _kataSandiController = TextEditingController();
  final _ulangiKataSandiController = TextEditingController();
  final AuthService _authService = AuthService(); // Instance dari AuthService
  bool _isLoading = false;

  @override
  void dispose() {
    _kataSandiController.dispose();
    _ulangiKataSandiController.dispose();
    super.dispose();
  }

  Future<void> _daftar() async {
    if (_formKeyKataSandi.currentState!.validate()) {
      setState(() => _isLoading = true);
      print("[BuatKataSandiScreen] Memulai proses _daftar...");
      try {
        print("[BuatKataSandiScreen] Memanggil _authService.registerWithEmailPassword untuk email: ${widget.userData.email}");
        final userCredential = await _authService.registerWithEmailPassword(
          widget.userData.email,
          _kataSandiController.text,
          widget.userData,
        );
        print("[BuatKataSandiScreen] Hasil userCredential: ${userCredential?.user?.uid}");

        if (userCredential != null && mounted) {
          print("[BuatKataSandiScreen] Pendaftaran berhasil, navigasi ke LoginEmailScreen...");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pendaftaran berhasil! Silakan login.')),
          );
          // Menggunakan pushAndRemoveUntil untuk membersihkan stack navigasi
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => LoginEmailScreen()),
                (Route<dynamic> route) => false, // Hapus semua rute sebelumnya
          );
        } else if (mounted) {
          print("[BuatKataSandiScreen] Pendaftaran gagal atau userCredential null setelah service call.");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pendaftaran gagal. Hasil tidak valid.')),
          );
        }
      } catch (e, s) { // Menangkap error dan stack trace
        print("[BuatKataSandiScreen] Error saat daftar: $e");
        print("[BuatKataSandiScreen] Stack trace: $s");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal daftar: ${e.toString()}')),
          );
        }
      } finally {
        print("[BuatKataSandiScreen] Blok finally dieksekusi.");
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } else {
      print("[BuatKataSandiScreen] Form tidak valid.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Kata Sandi')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKeyKataSandi,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text('Email akan didaftarkan: ${widget.userData.email}', textAlign: TextAlign.center),
              const SizedBox(height: 20),
              TextFormField(
                controller: _kataSandiController,
                decoration: const InputDecoration(
                  labelText: 'Kata Sandi Baru',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Kata Sandi tidak boleh kosong';
                  }
                  if (value.length < 6) {
                    return 'Kata Sandi minimal 6 karakter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _ulangiKataSandiController,
                decoration: const InputDecoration(
                  labelText: 'Ulangi Kata Sandi Baru',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ulangi Kata Sandi tidak boleh kosong';
                  }
                  if (value != _kataSandiController.text) {
                    return 'Kata Sandi tidak cocok';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: _daftar,
                  child: const Text('DAFTAR AKUN'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}