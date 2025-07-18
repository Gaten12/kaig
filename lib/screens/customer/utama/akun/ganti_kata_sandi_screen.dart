import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class GantiKataSandiScreen extends StatefulWidget {
  const GantiKataSandiScreen({super.key});

  @override
  State<GantiKataSandiScreen> createState() => _GantiKataSandiScreenState();
}

class _GantiKataSandiScreenState extends State<GantiKataSandiScreen> {
  final _formKey = GlobalKey<FormState>();
  final _kataSandiLamaController = TextEditingController();
  final _kataSandiBaruController = TextEditingController();
  final _konfirmasiSandiBaruController = TextEditingController();

  bool _isLoading = false;
  bool _obscureSandiLama = true;
  bool _obscureSandiBaru = true;
  bool _obscureKonfirmasiSandi = true;

  @override
  void dispose() {
    _kataSandiLamaController.dispose();
    _kataSandiBaruController.dispose();
    _konfirmasiSandiBaruController.dispose();
    super.dispose();
  }

  Future<void> _gantiKataSandi() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Pengecekan kecocokan kata sandi tetap di sini untuk alur yang lebih baik
    if (_kataSandiBaruController.text != _konfirmasiSandiBaruController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kata sandi baru dan konfirmasi tidak cocok."), backgroundColor: Color(0xFFC50000)),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        throw Exception("Pengguna tidak ditemukan atau tidak memiliki email.");
      }

      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: _kataSandiLamaController.text,
      );

      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(_kataSandiBaruController.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Kata sandi berhasil diubah!"), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();
      }

    } on FirebaseAuthException catch (e) {
      String pesanError = "Terjadi kesalahan.";
      if (e.code == 'wrong-password') {
        pesanError = "Kata sandi sekarang yang Anda masukkan salah.";
      } else if (e.code == 'weak-password') {
        // Pesan ini mungkin tidak akan muncul karena validasi kita lebih ketat
        pesanError = "Kata sandi baru terlalu lemah.";
      } else {
        pesanError = e.message ?? "Gagal mengubah kata sandi.";
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(pesanError), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Terjadi kesalahan: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ganti Kata Sandi"),
        backgroundColor: const Color(0xFFC50000),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.grey.withAlpha((255 * 0.1).round()), spreadRadius: 1, blurRadius: 5)
                ]
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Ganti kata sandimu untuk melindungi akunmu. Untuk keamanan data kamu, jangan bagikan password ini ke siapa pun ya!",
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 24),
                  // Field Kata Sandi Sekarang
                  Text("Kata Sandi Sekarang", style: TextStyle(color: Colors.grey.shade700)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _kataSandiLamaController,
                    obscureText: _obscureSandiLama,
                    decoration: _inputDecoration(
                        "Masukkan Kata Sandi Sekarang",
                            () => setState(() => _obscureSandiLama = !_obscureSandiLama),
                        _obscureSandiLama
                    ),
                    validator: (value) => (value == null || value.isEmpty) ? 'Harap masukkan kata sandi Anda saat ini' : null,
                  ),
                  const SizedBox(height: 16),

                  // Field Kata Sandi Baru
                  Text("Kata Sandi Baru", style: TextStyle(color: Colors.grey.shade700)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _kataSandiBaruController,
                    obscureText: _obscureSandiBaru,
                    decoration: _inputDecoration(
                        "Masukkan Kata Sandi Baru",
                            () => setState(() => _obscureSandiBaru = !_obscureSandiBaru),
                        _obscureSandiBaru
                    ),
                    // --- VALIDATOR YANG DIPERBARUI ---
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Kata sandi baru tidak boleh kosong';
                      }
                      if (value.length < 8) {
                        return 'Kata sandi minimal 8 karakter';
                      }
                      if (!RegExp(r'[a-zA-Z]').hasMatch(value)) {
                        return 'Kata sandi harus mengandung huruf';
                      }
                      if (!RegExp(r'[0-9]').hasMatch(value)) {
                        return 'Kata sandi harus mengandung angka';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Field Ulangi Kata Sandi Baru
                  Text("Ulangi Kata Sandi Baru", style: TextStyle(color: Colors.grey.shade700)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _konfirmasiSandiBaruController,
                    obscureText: _obscureKonfirmasiSandi,
                    decoration: _inputDecoration(
                        "Masukkan Ulang Kata Sandi Baru",
                            () => setState(() => _obscureKonfirmasiSandi = !_obscureKonfirmasiSandi),
                        _obscureKonfirmasiSandi
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Harap konfirmasi kata sandi baru Anda';
                      if (value != _kataSandiBaruController.text) return 'Kata sandi tidak cocok';
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Tombol Lanjutkan
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    ElevatedButton(
                      onPressed: _gantiKataSandi,
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: const Color(0xFF304FFE),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      ),
                      child: const Text("LANJUTKAN", style: TextStyle(fontWeight: FontWeight.bold)),
                    )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hintText, VoidCallback toggleVisibility, bool isObscured) {
    return InputDecoration(
        hintText: hintText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        suffixIcon: IconButton(
          icon: Icon(isObscured ? Icons.visibility_off : Icons.visibility),
          onPressed: toggleVisibility,
        )
    );
  }
}