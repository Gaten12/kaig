import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart'; // Pastikan path ini benar
import '../customer/utama/home_screen.dart'; // Layar Customer
import '../../screens/admin/screens/admin_home_screen.dart';
import '../lupa_password/lupa_password_screen.dart';
import 'login_screen.dart'; // Layar Admin
// import 'forgot_password_screen.dart'; // Jika ada
// import 'login_email_screen.dart'; // Jika perlu navigasi kembali

class LoginPasswordScreen extends StatefulWidget {
  final String email; // Email dari layar sebelumnya

  const LoginPasswordScreen({super.key, required this.email});

  @override
  State<LoginPasswordScreen> createState() => _LoginPasswordScreenState();
}

class _LoginPasswordScreenState extends State<LoginPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController(); // Ganti nama jika perlu
  bool _isLoading = false;
  bool _obscureText = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginUserAndNavigate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save(); // Meskipun tidak ada onSaved eksplisit, ini praktik baik

    setState(() {
      _isLoading = true;
    });

    print("[LoginPasswordScreen] Memulai proses login untuk email: ${widget.email}");

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: widget.email,
        password: _passwordController.text,
      );

      User? firebaseUser = userCredential.user;
      print("[LoginPasswordScreen] Login Firebase berhasil. UID: ${firebaseUser?.uid}");

      if (firebaseUser != null && mounted) {
        print("[LoginPasswordScreen] Mengambil role pengguna dari Firestore...");
        // Logika pengecekan peran disalin dari SplashScreen._fetchUserRoleAndNavigate
        DocumentSnapshot<Map<String, dynamic>> userDoc =
        await _firestore.collection('users').doc(firebaseUser.uid).get();

        print("[LoginPasswordScreen] Dokumen user exists? ${userDoc.exists}");
        if (userDoc.exists) {
          print("[LoginPasswordScreen] Data dokumen user: ${userDoc.data()}");
          UserModel userModel = UserModel.fromFirestore(userDoc);
          print("[LoginPasswordScreen] Role pengguna dari model: ${userModel.role}");

          if (!mounted) return;

          if (userModel.role == 'admin') {
            print("[LoginPasswordScreen] Navigasi ke AdminHomeScreen.");
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const AdminHomeScreen()),
                  (Route<dynamic> route) => false,
            );
          } else {
            print("[LoginPasswordScreen] Navigasi ke HomeScreen (Customer).");
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
                  (Route<dynamic> route) => false,
            );
          }
        } else {
          // Dokumen user tidak ditemukan di Firestore setelah login berhasil
          // Ini kasus yang aneh, mungkin data user belum dibuat atau ada masalah sinkronisasi.
          // Sebagai fallback, arahkan ke HomeScreen Customer atau tampilkan error.
          print("[LoginPasswordScreen] Dokumen user tidak ditemukan untuk UID: ${firebaseUser.uid}. Arahkan ke HomeScreen sebagai fallback.");
          if (mounted) {
            await _auth.signOut();
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => LoginEmailScreen()), // Kembali ke login
                  (Route<dynamic> route) => false,
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Data pengguna tidak lengkap. Menuju halaman utama.')),
            );
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
                  (Route<dynamic> route) => false,
            );
          }
        }
      } else {
        // firebaseUser null setelah signIn, seharusnya tidak terjadi jika tidak ada exception
        print("[LoginPasswordScreen] firebaseUser null setelah signIn berhasil (seharusnya tidak terjadi).");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login gagal, coba lagi.')),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      print("[LoginPasswordScreen] FirebaseAuthException: ${e.code} - ${e.message}");
      String message = 'Login gagal.';
      if (e.code == 'user-not-found') {
        message = 'Email tidak ditemukan.';
      } else if (e.code == 'wrong-password') {
        message = 'Kata sandi salah.';
      } else if (e.code == 'invalid-email') {
        message = 'Format email tidak valid.';
      } else if (e.code == 'invalid-credential') {
        message = 'Kredensial tidak valid.';
      }
      // Tambahkan penanganan error lain jika perlu
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (e, s) {
      print("[LoginPasswordScreen] Error tidak terduga saat login: $e");
      print("[LoginPasswordScreen] Stacktrace: $s");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      print("[LoginPasswordScreen] Proses login selesai.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Masukkan Kata Sandi'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Email: ${widget.email}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Masukkan kata sandi Anda.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 30),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Kata Sandi',
                  hintText: 'Masukkan Kata Sandi',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  prefixIcon: const Icon(Icons.lock_outline),
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
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ForgotPasswordScreen(initialEmail: widget.email)));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fitur Lupa Kata Sandi belum diimplementasikan.')),
                    );
                  },
                  child: const Text('Lupa Kata Sandi?'),
                ),
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _loginUserAndNavigate,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text('LOGIN'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}