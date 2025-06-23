import 'package:flutter/material.dart';
import 'password_screen.dart';
import '../register/daftar_akun_screen.dart';

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
    // Menggunakan MediaQuery untuk mendapatkan ukuran layar.
    // Ini adalah kunci untuk membuat layout responsif.
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600; // Contoh breakpoint untuk layar kecil

    return Scaffold(
      backgroundColor: const Color(0xFFC50000), // Warna merah gelap
      body: SingleChildScrollView(
        // SingleChildScrollView memungkinkan konten discroll jika melebihi ukuran layar
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: screenHeight, // Memastikan konten minimal setinggi layar
          ),
          child: IntrinsicHeight(
            // IntrinsicHeight membantu Column mengambil tinggi minimum yang diperlukan anak-anaknya
            child: Column(
              children: [
                // Bagian atas (logo) dengan padding responsif
                Padding(
                  padding: EdgeInsets.only(
                    top: screenHeight * 0.15,
                    bottom: isSmallScreen ? 30 : 50, // Padding bottom lebih kecil di layar kecil
                  ),
                  child: Image.asset(
                    'images/logo.png',
                    height: isSmallScreen ? 120 : 180, // Ukuran logo responsif
                  ),
                ),
                // Bagian bawah (form login) yang akan mengisi sisa ruang
                Expanded(
                  child: Container(
                    padding: EdgeInsets.fromLTRB(
                        isSmallScreen ? 24 : screenWidth * 0.1, // Padding horizontal responsif
                        32,
                        isSmallScreen ? 24 : screenWidth * 0.1,
                        24),
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
                          Text(
                            'Selamat Datang di TrainOrder!',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 20 : 24, // Ukuran font responsif
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14 : 16, // Ukuran font responsif
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
                                borderSide: BorderSide(
                                  color: Colors.blue,
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
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _submitEmail,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                const Color(0xFF304FFE), // Warna biru
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
                          const SizedBox(height: 40),
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
        ),
      ),
    );
  }
}