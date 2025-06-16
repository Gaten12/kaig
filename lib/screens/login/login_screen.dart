import 'package:flutter/material.dart';
import 'package:kaig/services/auth_service.dart'; // Import service
import '../register/daftar_akun_screen.dart';
import 'password_screen.dart';


// Ubah menjadi StatefulWidget
class LoginEmailScreen extends StatefulWidget {
  const LoginEmailScreen({super.key});

  @override
  State<LoginEmailScreen> createState() => _LoginEmailScreenState();
}

class _LoginEmailScreenState extends State<LoginEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false; // State untuk mengelola loading

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // --- FUNGSI SUBMIT YANG DIPERBARUI ---
  Future<void> _submitEmail() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final email = _emailController.text.trim();

      // Panggil fungsi pengecekan dari service
      final emailTerdaftar = await _authService.cekEmailTerdaftar(email);

      // Hentikan loading setelah pengecekan selesai
      if (mounted) {
        setState(() => _isLoading = false);
      } else {
        return; // Jika widget sudah tidak ada, hentikan proses
      }

      // Logika navigasi berdasarkan hasil pengecekan
      if (emailTerdaftar) {
        // Jika email terdaftar, lanjut ke halaman password
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LoginPasswordScreen(email: email),
          ),
        );
      } else {
        // Jika tidak terdaftar, tampilkan pesan error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Email tidak terdaftar. Silakan lakukan pendaftaran."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selamat Datang di TrainOrder!'),
        automaticallyImplyLeading: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'Silakan masuk atau daftar sekarang untuk mulai menjelajahi semua layanan yang kami sediakan.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 30),
              TextFormField(
                controller: _emailController, // Gunakan controller
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'Masukkan Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
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
              const SizedBox(height: 20),
              // Tampilkan loading indicator jika sedang proses
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _submitEmail,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text('LANJUTKAN'),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Tidak Punya Akun? '),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => DaftarAkunScreen()),
                      );
                    },
                    child: const Text('Daftar Sekarang'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}