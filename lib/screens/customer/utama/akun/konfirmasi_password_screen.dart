import 'package:flutter/material.dart';
import 'package:kaig/screens/login/auth_service.dart';

class KonfirmasiPasswordScreen extends StatefulWidget {
  final Future<void> Function() onPasswordConfirmed;

  const KonfirmasiPasswordScreen({super.key, required this.onPasswordConfirmed});

  @override
  State<KonfirmasiPasswordScreen> createState() => _KonfirmasiPasswordScreenState();
}

class _KonfirmasiPasswordScreenState extends State<KonfirmasiPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _konfirmasi() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final isSuccess = await _authService.verifikasiPassword(_passwordController.text);

    if (mounted) {
      if (isSuccess) {
        // Jika password benar, jalankan aksi selanjutnya
        await widget.onPasswordConfirmed();
      } else {
        setState(() {
          _errorMessage = "Kata sandi salah. Silakan coba lagi.";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Masukkan Kata Sandi"),
        backgroundColor: const Color(0xFFC50000),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Align(
                alignment: Alignment.centerLeft, 
                child: Text("Masukkan kata sandi email lamamu untuk melanjutkan."),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Kata Sandi",
                  border: const OutlineInputBorder(),
                  errorText: _errorMessage,
                ),
                validator: (v) => (v == null || v.isEmpty) ? "Kata sandi tidak boleh kosong" : null,
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _konfirmasi,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF304FFE),
                  minimumSize: const Size(double.infinity, 50)),
                child: const Text("LANJUTKAN"),
              )
            ],
          ),
        ),
      ),
    );
  }
}