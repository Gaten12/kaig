import 'package:flutter/material.dart';
import '../../models/user_data_daftar.dart'; // Model untuk data pendaftaran
import '../login/auth_service.dart';  // Service untuk interaksi dengan Firebase Auth & Firestore
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
  bool _isKataSandiVisible = false;
  bool _isUlangiKataSandiVisible = false;

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Buat Kata Sandi',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFC50000), // Warna merah gelap seperti di gambar
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKeyKataSandi,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'Buat kata sandimu sekarang untuk melindungi akunmu. Untuk keamanan data kamu, jangan bagikan password ini ke siapa pun ya!',
                textAlign: TextAlign.left,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              // Teks email yang didaftarkan tidak dihapus
              Text(
                'Email yang akan didaftarkan: ${widget.userData.email}',
                textAlign: TextAlign.left,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _kataSandiController,
                decoration: InputDecoration(
                  labelText: 'Kata Sandi',
                  hintText: 'Masukkan Kata Sandi',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isKataSandiVisible ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isKataSandiVisible = !_isKataSandiVisible;
                      });
                    },
                  ),
                ),
                obscureText: !_isKataSandiVisible,
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _ulangiKataSandiController,
                decoration: InputDecoration(
                  labelText: 'Ulangi Kata Sandi',
                  hintText: 'Masukkan Ulang Kata Sandi',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                   suffixIcon: IconButton(
                    icon: Icon(
                      _isUlangiKataSandiVisible ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isUlangiKataSandiVisible = !_isUlangiKataSandiVisible;
                      });
                    },
                  ),
                ),
                obscureText: !_isUlangiKataSandiVisible,
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
              const SizedBox(height: 40),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: const Color(0xFF304FFE), // Warna biru gelap seperti di gambar
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _daftar,
                  child: const Text('Simpan Kata Sandi', style: TextStyle(fontSize: 16)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}