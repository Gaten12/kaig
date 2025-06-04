import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Untuk mengambil data user
import '../../../models/user_model.dart'; // Model User Anda
import 'utama/home_screen.dart'; // Layar Customer
import '../admin/screens/admin_home_screen.dart'; // Layar Admin
import '../login/login_screen.dart'; // Layar Login

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkCurrentUserAndNavigate();
  }

  Future<void> _checkCurrentUserAndNavigate() async {
    // Beri sedikit jeda untuk splash screen
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    User? firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser != null) {
      // User sudah login, cek rolenya
      try {
        DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .get();

        if (userDoc.exists && mounted) {
          UserModel userModel = UserModel.fromFirestore(userDoc);
          if (userModel.role == 'admin') {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const AdminHomeScreen()),
            );
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          }
        } else {
          // Dokumen user tidak ditemukan, mungkin user dihapus atau data korup
          // Arahkan ke login, atau handle error
          if (mounted) {
            print("Dokumen user tidak ditemukan untuk UID: ${firebaseUser.uid}. Logout dan arahkan ke login.");
            await FirebaseAuth.instance.signOut(); // Logout user
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => LoginEmailScreen()),
            );
          }
        }
      } catch (e) {
        // Error saat mengambil data user, arahkan ke login
        print("Error mengambil data user: $e. Logout dan arahkan ke login.");
        if (mounted) {
          try {
            await FirebaseAuth.instance.signOut(); // Coba logout jika ada error
          } catch (signOutError) {
            print("Error saat coba signOut: $signOutError");
          }
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => LoginEmailScreen()),
          );
        }
      }
    } else {
      // User belum login, arahkan ke layar login
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LoginEmailScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // UI Splash Screen Anda
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Ganti dengan logo aplikasi Anda
            // Image.asset('assets/logo.png', height: 120),
            const Icon(Icons.train_rounded, size: 100, color: Colors.blue),
            const SizedBox(height: 20),
            const Text(
              'Aplikasi Tiket Kereta', // Nama aplikasi Anda
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
