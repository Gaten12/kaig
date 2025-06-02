import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utama/home_screen.dart';
import '../lupa_password/lupa_password_screen.dart';

class LoginPasswordScreen extends StatefulWidget {
  final String email;

  LoginPasswordScreen({required this.email});

  @override
  _LoginPasswordScreenState createState() => _LoginPasswordScreenState();
}

class _LoginPasswordScreenState extends State<LoginPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _password;
  bool _isLoading = false;
  bool _obscureText = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _loginUser() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isLoading = true;
      });

      try {
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: widget.email,
          password: _password!,
        );

        // Navigasi ke halaman utama setelah login berhasil
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login Berhasil! User: ${userCredential.user?.email}')),
        );
        // Idealnya, gunakan state management untuk mengarahkan ke HomeScreen
        // dan membersihkan stack navigasi login.
        Navigator.of(context).popUntil((route) => route.isFirst);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),   (Route<dynamic> route) => false,
        );

      } on FirebaseAuthException catch (e) {
        String message = 'Login gagal.';
        if (e.code == 'user-not-found') {
          message = 'Email tidak ditemukan atau pengguna telah dihapus.';
        } else if (e.code == 'wrong-password') {
          message = 'Kata sandi salah.';
        } else if (e.code == 'invalid-credential') {
          message = 'Kredensial tidak valid. Pastikan email dan password benar.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: ${e.toString()}'), backgroundColor: Colors.red),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Masukkan Kata Sandi'),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Buat kamu yang sudah pernah bergabung, silahkan gunakan akun lamamu. Demi keamanan, jangan pernah bagikan kata sandimu ke siapapun ya!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 30),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Kata Sandi',
                  hintText: 'Masukkan Kata Sandi',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  ),
                ),
                obscureText: _obscureText,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Kata sandi tidak boleh kosong';
                  }
                  if (value.length < 6) {
                    return 'Kata sandi minimal 6 karakter';
                  }
                  return null;
                },
                onSaved: (value) => _password = value,
              ),
              SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ForgotPasswordScreen(initialEmail: widget.email)), // Gunakan initialEmail
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Fitur Lupa Kata Sandi belum diimplementasikan.')),
                    );
                  },
                  child: Text('Lupa Kata Sandi?'),
                ),
              ),
              SizedBox(height: 20),
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _loginUser,
                child: Text('LANJUTKAN'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}