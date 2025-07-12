import 'package:flutter/material.dart';
import 'package:kaig/services/auth_service.dart';
import '../../../models/user_data_daftar.dart';
import '../login/login_screen.dart'; // Import telah ditambahkan

class BuatKataSandiScreen extends StatefulWidget {
  final UserDataDaftar userData;

  const BuatKataSandiScreen({super.key, required this.userData});

  @override
  State<BuatKataSandiScreen> createState() => _BuatKataSandiScreenState();
}

class _BuatKataSandiScreenState extends State<BuatKataSandiScreen> {
  final _formKeyKataSandi = GlobalKey<FormState>();
  final _kataSandiController = TextEditingController();
  final _ulangiKataSandiController = TextEditingController();
  final AuthService _authService = AuthService();
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
    if (!_formKeyKataSandi.currentState!.validate() || !mounted) return;

    setState(() => _isLoading = true);

    try {
      final userCredential = await _authService.registerWithEmailPassword(
        widget.userData.email,
        _kataSandiController.text,
        widget.userData,
      );

      if (!mounted) return;

      if (userCredential != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pendaftaran berhasil! Silakan masuk.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) =>  LoginEmailScreen()),
              (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mendaftar: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
        backgroundColor: const Color(0xFFC50000),
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
                    return 'Kata sandi tidak boleh kosong';
                  }
                  if (value.length < 8) {
                    return 'Kata sandi minimal 8 karakter';
                  }
                  // --- PERUBAHAN DI SINI ---
                  // Pengecekan wajib ada huruf
                  if (!RegExp(r'[a-zA-Z]').hasMatch(value)) {
                    return 'Kata sandi harus mengandung huruf';
                  }
                  // Pengecekan wajib ada angka
                  if (!RegExp(r'[0-9]').hasMatch(value)) {
                    return 'Kata sandi harus mengandung angka';
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
                    return 'Ulangi kata sandi tidak boleh kosong';
                  }
                  if (value != _kataSandiController.text) {
                    return 'Kata sandi tidak cocok';
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
                    backgroundColor: const Color(0xFF304FFE),
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