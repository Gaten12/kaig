// lib/src/home/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'PesanTiketScreen.dart'; // Untuk mendapatkan info user
// Jika Anda sudah memiliki UserModel dan service untuk mengambilnya:
// import '../../data/models/user_model.dart';
// import '../../data/services/firestore_service.dart'; // atau service yang relevan

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // Untuk BottomNavigationBar, 0 = Beranda

  // Data Pengguna - idealnya didapatkan dari state management atau argumen constructor
  User? _currentUser;
  String _userName = "Pengguna"; // Default name

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      // Jika Anda menyimpan nama lengkap di Firestore, Anda perlu mengambilnya.
      // Contoh jika nama diambil dari displayName Firebase Auth (jarang diisi saat email/pass reg):
        _userName = _currentUser!.displayName ?? "Pengguna";

      // Contoh jika nama diambil dari Firestore (membutuhkan FirestoreService):
      // FirestoreService firestoreService = FirestoreService();
      // UserModel? userModel = await firestoreService.getUser(_currentUser!.uid);
      // if (userModel != null && mounted) {
      //   setState(() {
      //     _userName = userModel.namaLengkap; // Asumsi ada field namaLengkap di UserModel
      //   });
      // } else if (mounted) {
      //   // Jika tidak ada namaLengkap, bisa ambil dari email atau default
      //   _userName = _currentUser!.email!.split('@')[0]; // Ambil bagian sebelum @ dari email
      // }
      if (mounted) {
        // Untuk sementara, kita ambil bagian sebelum @ dari email sebagai nama
        _userName = _currentUser!.email?.split('@')[0] ?? "Pengguna";
        if (_userName.length > 10) { // Potong jika terlalu panjang
          _userName = _userName.substring(0, 10) + "...";
        }
        setState(() {});
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Di sini Anda akan menangani navigasi atau perubahan tampilan body
    // berdasarkan index yang dipilih.
    // Untuk saat ini, kita hanya fokus pada tampilan Beranda (_selectedIndex = 0)
    switch (index) {
      case 0:
      // Halaman Beranda (sudah di sini)
        break;
      case 1:
      // Navigasi ke Halaman Kereta (buat layar baru nanti)
        print("Navigate to Kereta Screen");
        break;
      case 2:
      // Navigasi ke Halaman Tiket Saya
        print("Navigate to Tiket Saya Screen");
        break;
      case 3:
      // Navigasi ke Halaman Promo
        print("Navigate to Promo Screen");
        break;
      case 4:
      // Navigasi ke Halaman Akun
        print("Navigate to Akun Screen");
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Selamat Datang, $_userName'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () {
              // Aksi untuk ikon keranjang belanja
              print("Shopping cart tapped");
            },
          ),
        ],
      ),
      body: _buildHomeScreenBody(), // Body akan kita bangun terpisah
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home), // Icon saat aktif
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.train_outlined),
            activeIcon: Icon(Icons.train),
            label: 'Kereta',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Tiket Saya',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_offer_outlined),
            activeIcon: Icon(Icons.local_offer),
            label: 'Promo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Akun',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor, // Warna item yang dipilih
        unselectedItemColor: Colors.grey, // Warna item yang tidak dipilih
        showUnselectedLabels: true, // Menampilkan label untuk item yang tidak dipilih
        type: BottomNavigationBarType.fixed, // Agar semua item terlihat jika lebih dari 3
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildHomeScreenBody() {
    // Hanya tampilkan body jika _selectedIndex adalah 0 (Beranda)
    if (_selectedIndex != 0) {
      // Untuk tab lain, bisa tampilkan placeholder atau widget yang sesuai
      return Center(child: Text('Tampilan untuk: ${_getLabelForIndex(_selectedIndex)}'));
    }

    return ListView( // Menggunakan ListView agar bisa di-scroll jika konten panjang
      padding: const EdgeInsets.all(16.0),
      children: <Widget>[
        // Bagian Menu
        const Text(
          'Menu',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _buildMenuItem(
              context,
              iconData: Icons.tram_outlined,
              label: 'Pesan Tiket',
              onTap: () {
                print('Pesan Tiket tapped');
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PesanTiketScreen()), // Navigasi ke PesanTiketScreen
                );
              },
            ),
            _buildMenuItem(
              context,
              iconData: Icons.directions_transit_outlined, // Atau Icons.train
              label: 'Commuter Line',
              onTap: () {
                print('Commuter Line tapped');
                // Navigasi ke layar Commuter Line
              },
            ),
          ],
        ),
        const SizedBox(height: 24.0),

        // Bagian Promo Terbaru
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Promo Terbaru',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                print('Lihat Semua Promo tapped');
                // Navigasi ke layar semua promo
              },
              child: const Text('Lihat Semua'),
            ),
          ],
        ),
        const SizedBox(height: 16.0),
        Container(
          height: 150, // Tinggi placeholder gambar promo
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12.0),
            // Anda bisa menambahkan gambar di sini nanti
            // image: DecorationImage(
            //   image: NetworkImage('URL_GAMBAR_PROMO'), // atau AssetImage
            //   fit: BoxFit.cover,
            // ),
          ),
          child: const Center(
            child: Text(
              'Gambar Promo',
              style: TextStyle(fontSize: 18, color: Colors.black54),
            ),
          ),
        ),
        // Anda bisa menambahkan lebih banyak item promo di sini jika diperlukan
      ],
    );
  }

  // Helper widget untuk membuat item menu
  Widget _buildMenuItem(BuildContext context, {required IconData iconData, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          CircleAvatar(
            radius: 35, // Ukuran lingkaran ikon
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Icon(iconData, size: 30, color: Theme.of(context).primaryColor),
          ),
          const SizedBox(height: 8.0),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  // Helper untuk mendapatkan label tab (jika diperlukan untuk body non-Beranda)
  String _getLabelForIndex(int index) {
    switch (index) {
      case 0: return 'Beranda';
      case 1: return 'Kereta';
      case 2: return 'Tiket Saya';
      case 3: return 'Promo';
      case 4: return 'Akun';
      default: return '';
    }
  }
}