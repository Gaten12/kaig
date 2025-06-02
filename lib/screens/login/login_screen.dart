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
    return Scaffold(
      appBar: AppBar(
        title: Text('Selamat Datang di TrainOrder!'),
        automaticallyImplyLeading: true, // Tombol kembali
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Anda bisa menambahkan LOGO di sini jika diinginkan, sesuai wireframe
              // Container(
              //   width: 100,
              //   height: 100,
              //   color: Colors.grey[300],
              //   alignment: Alignment.center,
              //   child: Text('LOGO', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              //   margin: EdgeInsets.only(bottom: 30),
              // ),
              Text(
                'Silakan masuk atau daftar sekarang untuk mulai menjelajahi semua layanan yang kami sediakan.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 30),
              TextFormField(
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
                onSaved: (value) => _email = value,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitEmail,
                child: Text('MASUK'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 15),
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Tidak Punya Akun? '),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => DaftarAkunScreen()), // Arahkan ke layar registrasi
                      );
                    },
                    child: Text('Daftar Sekarang'),
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