import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Untuk User
import '../services/auth_service.dart'; // Pastikan path ini benar
import 'login/login_screen.dart'; // Layar login jika belum ada user
import 'utama/home_screen.dart';    // Layar home jika sudah ada user

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Tidak perlu instance AuthService di sini jika kita menggunakan FirebaseAuth langsung
  // atau jika AuthService menyediakan stream/getter statis.

  @override
  void initState() {
    super.initState();
    _navigate();
  }

  void _navigate() async {
    // Tunggu inisialisasi Firebase jika belum (biasanya di main.dart)
    // Jika Anda sudah memastikan FirebaseApp.initializeApp() selesai di main.dart,
    // baris berikut mungkin tidak selalu diperlukan di sini, tapi aman untuk ada.
    // WidgetsFlutterBinding.ensureInitialized(); // Pastikan binding siap
    // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform); // Jika belum di main

    await Future.delayed(const Duration(seconds: 3)); // Durasi splash screen

    if (!mounted) return; // Cek jika widget masih terpasang

    // Cara 1: Menggunakan FirebaseAuth.instance secara langsung (paling umum)
    final User? currentUser = FirebaseAuth.instance.currentUser;

    // Cara 2: Jika AuthService Anda menyediakan stream atau getter untuk currentUser
    // final AuthService authService = AuthService(); // Jika AuthService perlu di-instance
    // final User? currentUser = authService.getCurrentUser(); // Contoh getter
    // Atau dengarkan stream:
    // authService.authStateChanges.listen((User? user) {
    //   if (user == null) {
    //     Navigator.of(context).pushReplacement(
    //       MaterialPageRoute(builder: (context) => const LoginEmailScreen()),
    //     );
    //   } else {
    //     Navigator.of(context).pushReplacement(
    //       MaterialPageRoute(builder: (context) => const HomeScreen()),
    //     );
    //   }
    // });
    // return; // Jika menggunakan stream, navigasi akan ditangani di dalam listener

    if (currentUser != null) {
      // Pengguna sudah login
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      // Tidak ada pengguna yang login
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LoginEmailScreen()), // Arahkan ke LoginEmailScreen
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Sebaiknya gunakan warna latar belakang yang sesuai tema
      // backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Pastikan 'assets/logo.png' ada di pubspec.yaml dan path-nya benar
            Image.asset('assets/logo.png', height: 120),
            const SizedBox(height: 20),
            const Text(
              'TrainOrder', // Ganti dengan nama aplikasi Anda
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                // color: Colors.white, // Jika background gelap
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              // valueColor: AlwaysStoppedAnimation<Color>(Colors.white), // Jika background gelap
            ),
          ],
        ),
      ),
    );
  }
}