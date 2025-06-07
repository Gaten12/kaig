import 'package:flutter/material.dart';
import 'list_jadwal_screen.dart';
import 'list_kereta_screen.dart';
import 'list_stasiun_screen.dart';
import '../../../services/auth_service.dart'; // Untuk logout
import '../../../screens/login/login_screen.dart'; // Untuk navigasi setelah logout

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    // Daftar item menu
    final List<Map<String, dynamic>> menuItems = [
      {
        "title": "Kelola Stasiun",
        "icon": Icons.account_balance_outlined,
        "onTap": () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ListStasiunScreen()),
          );
        },
      },
      {
        "title": "Kelola Kereta",
        "icon": Icons.train_outlined,
        "onTap": () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ListKeretaScreen()),
          );
        },
      },
      {
        "title": "Kelola Jadwal",
        "icon": Icons.calendar_today_outlined,
        "onTap": () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ListJadwalScreen()),
          );
        },
      },
      // Tambahkan menu admin lainnya di sini
    ];

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Colors.blueGrey,
        title: const Text(
          "Admin Dashboard",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w200,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            color: Colors.white,
            onPressed: () async {
              await authService.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => LoginEmailScreen()),
                      (Route<dynamic> route) => false,
                );
              }
            },
          )
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, // Menampilkan 2 item per baris
          crossAxisSpacing: 12.0, // Jarak horizontal antar item
          mainAxisSpacing: 12.0, // Jarak vertikal antar item
          childAspectRatio: 1.0, // Rasio aspek item (lebar/tinggi)
        ),
        itemCount: menuItems.length,
        itemBuilder: (context, index) {
          final item = menuItems[index];
          return _buildAdminMenuItem(
            context,
            title: item["title"],
            icon: item["icon"],
            onTap: item["onTap"],
          );
        },
      ),
    );
  }

  Widget _buildAdminMenuItem(BuildContext context,
      {required String title,
        required IconData icon,
        required VoidCallback onTap}) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0), // Membuat sudut Card lebih bulat
      ),
      child: InkWell( // Menggunakan InkWell agar efek ripple saat ditekan terlihat
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.0),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Pusatkan konten secara vertikal
            crossAxisAlignment: CrossAxisAlignment.center, // Pusatkan konten secara horizontal
            children: <Widget>[
              Icon(icon, size: 80, color: Theme.of(context).primaryColor), // Ukuran ikon diperbesar
              const SizedBox(height: 8.0), // Jarak antara ikon dan teks
              Text(
                title,
                textAlign: TextAlign.center, // Teks rata tengah
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis, // Menangani teks yang terlalu panjang
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}