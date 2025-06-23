import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart'; // Pastikan path ini benar
import '../customer/utama/home_screen.dart'; // Layar Customer
import '../../screens/admin/screens/admin_home_screen.dart';
import '../lupa_password/lupa_password_screen.dart';
import 'login_screen.dart'; // Layar Admin


class LoginPasswordScreen extends StatefulWidget {
  final String email; // Email dari layar sebelumnya

  const LoginPasswordScreen({super.key, required this.email});

  @override
  State<LoginPasswordScreen> createState() => _LoginPasswordScreenState();
}

class _LoginPasswordScreenState extends State<LoginPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
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
    _formKey.currentState!.save();

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

          print("[LoginPasswordScreen] Dokumen user tidak ditemukan untuk UID: ${firebaseUser.uid}. Arahkan ke HomeScreen sebagai fallback.");
          if (mounted) {
            await _auth.signOut();
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => LoginEmailScreen()),
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
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600; // Define a breakpoint for small screens

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(

        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Masukkan Kata Sandi',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFB71C1C), // Warna merah gelap
        elevation: 0,
      ),
      body: SingleChildScrollView( // Wrapped with SingleChildScrollView to prevent overflow
        padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16.0 : 24.0, vertical: 20.0),
        child: ConstrainedBox( // Use ConstrainedBox to ensure content takes up enough space
          constraints: BoxConstraints(
            minHeight: screenHeight - (AppBar().preferredSize.height + MediaQuery.of(context).padding.top),
          ),
          child: IntrinsicHeight( // Allow column to take intrinsic height
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Buat kamu yang sudah pernah bergabung, silahkan gunakan akun lamamu. Demi keamanan, jangan pernah bagikan kata sandimu ke siapapun ya!',
                    style: TextStyle(fontSize: isSmallScreen ? 13 : 14, color: Colors.black54),
                  ),
                  SizedBox(height: isSmallScreen ? 18 : 24), // Responsive spacing
                  TextFormField(
                    controller: _passwordController,
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
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: isSmallScreen ? 12 : 14), // Responsive padding
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
                  SizedBox(height: isSmallScreen ? 8 : 12), // Responsive spacing
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ForgotPasswordScreen(initialEmail: widget.email),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft,
                      ),
                      child: const Text(
                        'Lupa Kata Sandi?',
                        style: TextStyle(color: Color(0xFF304FFE)),
                      ),
                    ),
                  ),
                  const Spacer(), // Pushes content to the top, and button to the bottom
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SizedBox(
                    width: double.infinity,
                    height: isSmallScreen ? 45 : 50, // Responsive button height
                    child: ElevatedButton(
                      onPressed: _loginUserAndNavigate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF304FFE),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12), // Adjusted vertical padding
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: Text(
                        'LANJUTKAN',
                        style: TextStyle(fontSize: isSmallScreen ? 15 : 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 12.0 : 20.0), // Add some bottom padding
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}