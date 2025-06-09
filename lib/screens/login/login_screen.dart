import 'package:flutter/material.dart';
import 'password_screen.dart'; // Akan kita buat
import '../register/daftar_akun_screen.dart'; // Untuk tombol "Daftar Sekarang"

class LoginEmailScreen extends StatefulWidget {
  @override
  _LoginEmailScreenState createState() => _LoginEmailScreenState();
}

class _LoginEmailScreenState extends State<LoginEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _email;

  void _submitEmail() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      // Navigasi ke layar input password dengan membawa email
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LoginPasswordScreen(email: _email!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
        return Scaffold(
      // Menggunakan warna merah sebagai background utama
      backgroundColor: const Color(0xFFC50000),
      body: SingleChildScrollView(
        child: Stack(
          children: [
            // === Bagian Atas (Latar Belakang Merah dengan Logo) ===
            Container(
              height: screenHeight,
              width: double.infinity,
              color: const Color(0xFFC50000),
            ),
            Positioned(
              top: screenHeight * 0.15, // Posisi logo dari atas
              left: 0,
              right: 0,
              child: Image.asset(
                'images/logo.png', // Pastikan path logo benar
                height: 150, // Sesuaikan ukuran logo jika perlu
              ),
            ),

            // === Bagian Bawah (Form Putih dengan Sudut Melengkung) ===
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30.0),
                    topRight: Radius.circular(30.0),
                  ),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // --- Judul ---
                      const Text(
                        'Selamat Datang di TrainOrder!',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // --- Sub-judul ---
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                          children: const <TextSpan>[
                            TextSpan(text: 'Silakan '),
                            TextSpan(
                                text: 'masuk',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            TextSpan(text: ' atau '),
                            TextSpan(
                                text: 'daftar sekarang!',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            TextSpan(
                                text:
                                    ' untuk mulai menjelajahi semua layanan yang kami sediakan.'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // --- Input Email ---
                      const Text(
                        'Email',
                        style: TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        decoration: InputDecoration(
                          hintText: 'Masukkan Email',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(
                              color: Colors.grey[300]!,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(
                              color: Colors.grey[300]!,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: const BorderSide(
                              color: Colors.blue, // Warna border saat di-fokus
                            ),
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                        onSaved: (value) => _email = value,
                      ),
                      const SizedBox(height: 24),

                      // --- Tombol Masuk ---
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitEmail,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFF304FFE), // Warna biru solid
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          child: const Text(
                            'MASUK',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40), // Spasi menuju link daftar

                      // --- Link Daftar ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Tidak Punya Akun? ',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => DaftarAkunScreen()),
                              );
                            },
                            child: const Text(
                              'Daftar Sekarang',
                              style: TextStyle(
                                color: Color(0xFF304FFE), // Warna biru
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}